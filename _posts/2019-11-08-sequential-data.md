---
layout: post
title: Ingestion of sequential data from BigQuery into TensorFlow
date: 2019-11-08T08:00:00+01:00
keywords:
  - Apache Beam
  - BigQuery
  - Cloud Dataflow
  - Cloud Storage
  - Google Cloud Platform
  - Keras
  - TensorFlow
  - data science
  - machine learning
---

How hard can it be to ingest sequential data into a [TensorFlow] model? As
always, the answer is, “It depends.” Where are the sequences in question stored?
Can they fit in main memory? Are they of the same length? In what follows, we
shall build a flexible and scalable workflow for feeding sequential observations
into a TensorFlow graph starting from [BigQuery] as the data warehouse.

To make the discussion tangible, consider the following problem. Suppose the
goal is to predict the peak temperature at an arbitrary weather station present
in the [Global Historical Climatology Network] for each day between June 1 and
August 31. More concretely, given observations from June 1 up to an arbitrary
day before August 31, the objective is to complete the sequence until August 31.
For instance, if we find ourselves in Stockholm on June 12, we ask for the
maximum temperatures from June 12 to August 31 given the temperature values
between June 1 to June 11 at a weather station in Stockholm.

To set the expectations right, in this article, we are not going to build a
predictive model but to cater for its development by making the data from the
aforementioned database readily available in a TensorFlow graph. The final chain
of states and operations is as follows:

1. Historical temperature measurements from the Global Historical Climatology
   Network are stored in a [public data set][ghcn-d] in BigQuery. Each row
   corresponds to a weather station and a date. There are missing observations
   due to such reasons as measurements not passing quality checks.

2. Relevant measurements are grouped in BigQuery by the weather station and
   year. Therefore, each row corresponds to a weather station and a year,
   implying that all information about a particular example (a specific weather
   station on a specific year) is gathered in one place.

3. The sequences are read, analyzed, and transformed by [Cloud Dataflow].

    * The data are split into a training, a validation, and a testing set of
      examples.

    * The training set is used to compute statistics needed for transforming the
      measurements to a form suitable for the subsequent modeling.
      Standardization is used as an example.

    * The training and validation sets are transformed using the statistics
      computed with respect to the training set in order to avoid performing
      these computations during the training-with-validation phase. The
      corresponding transform is available for the testing phase.

4. The processed training and validation examples and the raw testing examples
   are written by Dataflow to [Cloud Storage] in the [TFRecord] format, which is
   a format native to TensorFlow.

5. The files containing TFRecords are read by the [`tf.data`] API of TensorFlow
   and eventually transformed into a data set of appropriately padded batches of
   examples.

The above workflow is not as simple as reading data from a Pandas DataFrame
comfortably resting in main memory; however, it is much more scalable. This
pipeline can handle arbitrary amounts of data. Moreover, it operates on
complete examples, not on individual measurements.

In the rest of the article, the aforementioned steps will be described in more
detail. The corresponding source code can be found in the following repository
on GitHub:

* [example-weather-forecast].

# Data

It all starts with data. The data come from the Global Historical Climatology
Network, which is [available in BigQuery][ghcn-d] for public use. Steps 1 and 2
in the list above are covered by the [following query][data.sql]:

```sql
WITH
-- Select relevant measurements
data_1 AS (
  SELECT
    id,
    date,
    -- Find the date of the previous observation
    LAG(date) OVER (station_year) AS date_last,
    latitude,
    longitude,
    -- Convert to degrees Celsius
    value / 10 AS temperature
  FROM
    `bigquery-public-data.ghcn_d.ghcnd_201*`
  INNER JOIN
    `bigquery-public-data.ghcn_d.ghcnd_stations` USING (id)
  WHERE
    -- Take years from 2010 to 2019
    CAST(_TABLE_SUFFIX AS INT64) BETWEEN 0 AND 9
    -- Take months from June to August
    AND EXTRACT(MONTH FROM date) BETWEEN 6 AND 8
    -- Take the maximum temperature
    AND element = 'TMAX'
    -- Take observations passed spatio-temporal quality-control checks
    AND qflag IS NULL
  WINDOW
    station_year AS (
      PARTITION BY id, EXTRACT(YEAR FROM date)
      ORDER BY date
    )
),
-- Group into examples (a specific station and a specific year)
data_2 AS (
  SELECT
    id,
    MIN(date) AS date,
    latitude,
    longitude,
    -- Compute gaps between observations
    ARRAY_AGG(
      DATE_DIFF(date, IFNULL(date_last, date), DAY)
      ORDER BY date
    ) AS duration,
    ARRAY_AGG(temperature ORDER BY date) AS temperature
  FROM
    data_1
  GROUP BY
    id, latitude, longitude, EXTRACT(YEAR FROM date)
)
-- Partition into training, validation, and testing sets
SELECT
  *,
  CASE
    WHEN EXTRACT(YEAR FROM date) < 2019 THEN 'analysis,training'
    WHEN MOD(ABS(FARM_FINGERPRINT(id)), 100) < 50 THEN 'validation'
    ELSE 'testing'
  END AS mode
FROM
  data_2
```

The query fetches peak temperatures, denoted by `temperature`, for all available
weather stations between June and August in 2010–2019. The crucial part is the
usage of `ARRAY_AGG`, which is what makes it possible to gather all relevant
data about a specific station and a specific year in the same row. The number of
days since the previous measurement, which is denoted by `duration`, is also
computed. Ideally, `duration` should always be one (except for the first day,
which has no predecessor); however, this is not the case, which makes the
resulting time series vary in length.

In addition, in order to illustrate the generality of this approach, two
contextual (that is, non-sequential) explanatory variables are added: `latitude`
and `longitude`. They are scalars stored side by side with `duration` and
`temperature`, which are arrays.

Another important moment in the final `SELECT` statement, which defines a column
called `mode`. This column indicates what each example is used for, allowing one
to use the same query for different purposes and to avoid inconsistencies due to
multiple queries. In this case, observations prior to 2019 are reserved for
training, while the rest is split pseudo-randomly and reproducibly into two
approximately equal parts: one is for validation, and one is for testing. This
last operation is explained in detail in “[Repeatable sampling of data sets in
BigQuery for machine learning][Lak Lakshmanan]” by Lak Lakshmanan.

# Preprocessing

In this section, we cover Steps 4 and 5 in the list given at the beginning. This
job is done by [TensorFlow Extended], which is a library for building
machine-learning pipelines. Internally, it relies on [Apache Beam] as a language
for defining pipelines. Once an adequate pipeline is created, it can be executed
using an executor, and the executor that we shall use is [Cloud Dataflow].

Before we proceed to the pipeline itself, the construction process is
orchestrated by a [configuration file][preprocessing.json], which will
be referred to as `config` in the pipeline code (to be discussed shortly):

```json
{
  "data": {
    "path": "configs/training/data.sql",
    "schema": [
      { "name": "latitude", "kind": "float32", "transform": "z" },
      { "name": "longitude", "kind": "float32", "transform": "z" },
      { "name": "duration", "kind": ["float32"], "transform": "z" },
      { "name": "temperature", "kind": ["float32"], "transform": "z" }
    ]
  },
  "modes": [
    { "name": "analysis" },
    { "name": "training", "transform": "analysis", "shuffle": true },
    { "name": "validation", "transform": "analysis" },
    { "name": "testing", "transform": "identity" }
  ]
}
```

It is worth noting that this way of working with a separate configuration file
is not something standard that comes with TensorFlow or Beam. It is a
convenience that we build for ourselves in order to keep the main logic reusable
and extendable without touching the code.

The `data` block describes where the data can be found and provides a schema for
the columns that are used. (Recall the SQL query given earlier and note that
`id`, `date`, and `partition` are omitted.) For instance, `latitude` is a scale
of type `FLOAT32`, while `temperature` is a sequence of type `FLOAT32`. Both are
standardized to have a zero mean and a unit standard deviation, which is
indicated by `"transform": "z"` and is typically needed for training neural
networks.

The `modes` block defines four passes over the data, corresponding to four
operating modes. In each mode, a specific subset of examples is considered,
which is given by the `mode` column returned by the query. There are two types
of modes: analysis and transform; recall Step 3. Whenever the `transform` key is
present, it is a transform mode; otherwise, it is an analysis mode. In this
example, there are one analysis and three transform modes.

Below is an excerpt from a [Python class][pipeline.py] responsible for building
the pipeline:

```python
# config = ...
# schema = ...

# Read the SQL code
query = open(config['data']['path']).read()
# Create a BigQuery source
source = beam.io.BigQuerySource(query=query, use_standard_sql=True)
# Create metadata needed later
spec = schema.to_feature_spec()
meta = dataset_metadata.DatasetMetadata(
    schema=dataset_schema.from_feature_spec(spec))
# Read data from BigQuery
data = pipeline \
    | 'read' >> beam.io.Read(source)
# Loop over modes whose purpose is analysis
transform_functions = {}
for mode in config['modes']:
    if 'transform' in mode:
        continue
    name = mode['name']
    # Select examples that belong to the current mode
    data_ = data \
        | name + '-filter' >> beam.Filter(partial(_filter, mode))
    # Analyze the examples
    transform_functions[name] = (data_, meta) \
        | name + '-analyze' >> tt_beam.AnalyzeDataset(_analyze)
    path = _locate(config, name, 'transform')
    # Store the transform function
    transform_functions[name] \
        | name + '-write-transform' >> transform_fn_io.WriteTransformFn(path)
# Loop over modes whose purpose is transformation
for mode in config['modes']:
    if not 'transform' in mode:
        continue
    name = mode['name']
    # Select examples that belong to the current mode
    data_ = data \
        | name + '-filter' >> beam.Filter(partial(_filter, mode))
    # Shuffle examples if needed
    if mode.get('shuffle', False):
        data_ = data_ \
            | name + '-shuffle' >> beam.transforms.Reshuffle()
    # Transform the examples using an appropriate transform function
    if mode['transform'] == 'identity':
        coder = tft.coders.ExampleProtoCoder(meta.schema)
    else:
        data_, meta_ = ((data_, meta), transform_functions[mode['transform']]) \
            | name + '-transform' >> tt_beam.TransformDataset()
        coder = tft.coders.ExampleProtoCoder(meta_.schema)
    path = _locate(config, name, 'examples', 'part')
    # Store the transformed examples as TFRecords
    data_ \
        | name + '-encode' >> beam.Map(coder.encode) \
        | name + '-write-examples' >> beam.io.tfrecordio.WriteToTFRecord(path)
```

At the very beginning, a BigQuery source is created, which is then branched out
according to the operating modes found in the configuration file. Specifically,
the first for-loop corresponds to the analysis modes, and the second for-loop
goes over the transform modes. The former ends with `WriteTransformFn`, which
saves the resulting transform, and the latter ends with `WriteToTFRecord`, which
writes the resulting examples as TFRecords.

The distinction between the contextual and sequential features is given by the
[`schema`][schema.py] object created based on the `schema` block in the
configuration file. The call `schema.to_feature_spec()` shown above alternates
between [`tf.io.FixedLenFeature`] and [`tf.io.VarLenFeature`] and produces a
feature specification that is understood by TensorFlow and TensorFlow Extended.

The [repository][example-weather-forecast] provides a wrapper for executing the
pipeline on Cloud Dataflow. The following figure shows the flow of the data with
respect to the four operating modes:

![](/assets/images/2019-11-08-sequential-data/dataflow.svg)

The outcome is a hierarchy of files on Cloud Storage:

```
.
└── data/
    └── training/
        └── 2019-11-01-12-00-00/
            ├── analysis/
            │   └── transform/
            │       ├── transform_fn/...
            │       └── transform_metadata/...
            ├── testing/
            │   └── examples/
            │       ├── part-000000-of-00004
            │       ├── ...
            │       └── part-000003-of-00004
            ├── training/
            │   └── examples/
            │       ├── part-000000-of-00006
            │       ├── ...
            │       └── part-000005-of-00006
            └── validation/
                └── examples/
                    ├── part-000000-of-00004
                    ├── ...
                    └── part-000003-of-00004
```

Here, `data/training` contains all data needed for the training phase, which
collectively refers to training entwined with validation and followed by
testing. Moving forward, this hierarchy is meant to accommodate the application
phase as well by populating a `data/application` entry next to the
`data/training` one. It can also accommodate trained models and the results of
applying these models by having a `model` entry with a structure similar to the
one of the `data` entry.

In the listing above, the files whose name starts with `part-` are the ones
containing TFRecords. It can be seen that, for each mode, the corresponding
examples have been split into multiple files, which is done for more efficient
access during the usage stage discussed in the next section.

# Execution

At this point, the data have made it all the way to the execution phase,
referring to training, validation, and testing; however, the data are yet to be
injected into a TensorFlow graph, which is the topic of this section. As before,
relevant parameters are kept in a [separate configuration file][execution.json]:

```json
{
  "data": {
    "schema": [
      { "name": "latitude", "kind": "float32" },
      { "name": "longitude", "kind": "float32" },
      { "name": "duration", "kind": ["float32"] },
      { "name": "temperature", "kind": ["float32"] }
    ],
    "modes": {
      "training": {
        "spec": "transformed",
        "shuffle_macro": { "buffer_size": 100 },
        "interleave": { "cycle_length": 100, "num_parallel_calls": -1 },
        "shuffle_micro": { "buffer_size": 512 },
        "map": { "num_parallel_calls": -1 },
        "batch": { "batch_size": 128 },
        "prefetch": { "buffer_size": 1 },
        "repeat": {}
      },
      "validation": {
        "spec": "transformed",
        "shuffle_macro": { "buffer_size": 100 },
        "interleave": { "cycle_length": 100, "num_parallel_calls": -1 },
        "map": { "num_parallel_calls": -1 },
        "batch": { "batch_size": 128 },
        "prefetch": { "buffer_size": 1 },
        "repeat": {}
      },
      "testing": {
        "spec": "original",
        "interleave": { "cycle_length": 100, "num_parallel_calls": -1 },
        "map": { "num_parallel_calls": -1 },
        "batch": { "batch_size": 128 },
        "prefetch": { "buffer_size": 1 }
      }
    }
  }
}
```

It can be seen that the file contains only one block: `data`. This is sufficient
for the purposes of this article; however, it is also meant to cover the
construction of the model in mind, including its hyperparameters, and the
execution process, including the optimizer and evaluation metrics.

The `data` block is similar to the one we saw before. In this case, `modes`
describes various calls to the [`tf.data`] API related to shuffling, batching,
and so on. Those who are familiar with the API will probably immediately
recognize them. It is now instructive to go straight to the Python code.

Below is an excerpt from a [Python class][data.py] responsible for building the
pipeline on the TensorFlow side:

```python
# config = ...

# List all files matching a given pattern
pattern = [self.path, name, 'examples', 'part-*']
dataset = tf.data.Dataset.list_files(os.path.join(*pattern))
# Shuffle the files if needed
if 'shuffle_macro' in config:
    dataset = dataset.shuffle(**config['shuffle_macro'])
# Convert the files into datasets of examples stored as TFRecords and
# amalgamate these datasets into one dataset of examples
dataset = dataset \
    .interleave(tf.data.TFRecordDataset, **config['interleave'])
# Shuffle the examples if needed
if 'shuffle_micro' in config:
    dataset = dataset.shuffle(**config['shuffle_micro'])
# Preprocess the examples with respect to a given spec, pad the examples
# and form batches of different sizes, and postprocess the batches
dataset = dataset \
    .map(_preprocess, **config['map']) \
    .padded_batch(padded_shapes=_shape(), **config['batch']) \
    .map(_postprocess, **config['map'])
# Prefetch the batches if needed
if 'prefetch' in config:
    dataset = dataset.prefetch(**config['prefetch'])
# Repeat the data once the source is exhausted if needed
if 'repeat' in config:
    dataset = dataset.repeat(**config['repeat'])
```

The pipeline is self-explanatory. It is simply a chain of operations stacked on
top of each other. It is, however, worth taking a closer look at the
preprocessing and postprocessing mappings, which can be seen before and after
the padding step, respectively:

```python
def _preprocess(proto):
    spec = self.transforms[config['transform']] \
        .transformed_feature_spec()
    example = tf.io.parse_single_example(proto, spec)
    return (
        {name: example[name] for name in self.contextual_names},
        {
            # Convert the sequential columns from sparse to dense
            name: self.schema[name].to_dense(example[name])
            for name in self.sequential_names
        },
    )

def _postprocess(contextual, sequential):
    sequential = {
        # Convert the sequential columns from dense to sparse
        name: self.schema[name].to_sparse(sequential[name])
        for name in self.sequential_names
    }
    return {**contextual, **sequential}
```

Currently, `tf.data` does not support padding sparse tensors, which is the
representation used for sequential features in TensorFlow. In the running
example about forecasting weather, such features are `duration` and
`temperature`. This is the reason such features are converted to their dense
counterparts in `_preprocess`. However, the final representation has to be
sparse still. Therefore, the sequential features are converted back to the
sparse format in `_postprocess`. Hopefully, this back-and-forth conversion will
be rendered obsolete in future versions.

Having executed the above steps, we have an instance of [`tf.data.Dataset`],
which is the ultimate goal, as it is the standard way of ingesting data into a
TensorFlow graph. At this point, one might create a Keras model leveraging
[`tf.keras.layers.DenseFeatures`] and [`tf.keras.experimental.SequenceFeatures`]
for constructing the input layer and then pass the data set to the `fit`
function of the model. A [skeleton][model.py] for this part can be found in the
repository.

# Conclusion

In this article, we have discussed a scalable approach to the ingestion of
sequential observations from BigQuery into a TensorFlow graph. The key tools
that have been used to this end are TensorFlow Extended in combination with
Cloud Dataflow and the `tf.data` API of TensorFlow.

In addition, the provided code has been written to be general and easily
customizable. It has been achieved by separating the configuration part from the
implementation one.

# References

* Lak Lakshmanan, “[Repeatable sampling of data sets in BigQuery for machine
  learning][Lak Lakshmanan],” 2016.

[Global Historical Climatology Network]: https://www.ncdc.noaa.gov/data-access/land-based-station-data/land-based-datasets/global-historical-climatology-network-ghcn
[Lak Lakshmanan]: https://www.oreilly.com/learning/repeatable-sampling-of-data-sets-in-bigquery-for-machine-learning

[Apache Beam]: https://beam.apache.org/
[BigQuery]: https://cloud.google.com/bigquery/
[Cloud Dataflow]: https://cloud.google.com/dataflow/
[Cloud Storage]: https://cloud.google.com/storage/
[TFRecord]: https://www.tensorflow.org/tutorials/load_data/tfrecord
[TensorFlow Extended]: https://www.tensorflow.org/tfx
[TensorFlow]: https://www.tensorflow.org
[ghcn-d]: https://console.cloud.google.com/marketplace/details/noaa-public/ghcn-d
[`tf.data`]: https://www.tensorflow.org/guide/data
[`tf.data.Dataset`]: https://www.tensorflow.org/api_docs/python/tf/data/Dataset
[`tf.io.FixedLenFeature`]: https://www.tensorflow.org/api_docs/python/tf/io/FixedLenFeature
[`tf.io.VarLenFeature`]: https://www.tensorflow.org/api_docs/python/tf/io/VarLenFeature
[`tf.keras.experimental.SequenceFeatures`]: https://www.tensorflow.org/api_docs/python/tf/keras/experimental/SequenceFeatures
[`tf.keras.layers.DenseFeatures`]: https://www.tensorflow.org/api_docs/python/tf/keras/layers/DenseFeatures

[example-weather-forecast]: https://github.com/chain-rule/example-weather-forecast

[data.py]: https://github.com/chain-rule/example-weather-forecast/blob/master/forecast/data.py
[data.sql]: https://github.com/chain-rule/example-weather-forecast/blob/master/configs/training/data.sql
[execution.json]: https://github.com/chain-rule/example-weather-forecast/blob/master/configs/training/execution.json
[model.py]: https://github.com/chain-rule/example-weather-forecast/blob/master/forecast/model.py
[pipeline.py]: https://github.com/chain-rule/example-weather-forecast/blob/master/forecast/pipeline.py
[preprocessing.json]: https://github.com/chain-rule/example-weather-forecast/blob/master/configs/training/preprocessing.json
[schema.py]: https://github.com/chain-rule/example-weather-forecast/blob/master/forecast/schema.py
