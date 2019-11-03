---
layout: post
title: Ingestion of sequential data from BigQuery into TensorFlow
date: 2019-12-31
keywords:
  - BigQuery
  - Cloud Dataflow
  - Cloud Storage
  - Google Cloud Platform
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
goal is to predict the average temperature at an arbitrary weather station
present in the [Global Historical Climatology Network] for each day between June
1 and August 31. More concretely, given observations from June 1 up to an
arbitrary day before August 31, the objective is to complete the sequence until
August 31. For instance, if we find ourselves in Stockholm on June 12, we ask
for the daily averages from June 12 to August 31 given the temperature values
between June 1 to June 11 at a weather station in Stockholm.

To set the expectations right, in this article, we are not going to build a
predictive model but to cater for its development by making the data from the
aforementioned network readily available in a TensorFlow graph. The chain of
states and operations is roughly as follows:

1. Historical temperature measurements from the Global Historical Climatology
   Network are stored in a [public dataset][ghcn-d] in BigQuery. Each row
   corresponds to a weather station and a date. There are missing observations
   due to such reasons as measurements not passing quality checks.

2. Relevant measurements are grouped by the weather station and year. Therefore,
   each row corresponds to a weather station and a year, implying that all
   information about a particular example (a specific weather station on a
   specific year) is gathered in one place.

3. The sequences are read, analyzed, and transformed by [Cloud Dataflow].

    * The data are split into a training, a validation, and a testing set of
      examples.

    * The training set is used to compute statistics needed for transforming the
      measurements to a form suitable for the subsequent modeling.
      Standardization is used as an example.

    * The training and validation sets are transformed using the statistics
      computed with respect to the training set to avoid performing these
      computations during the training-with-validation phase. The corresponding
      transform is available for the testing and application phrases.

4. The processed training and validation examples and the raw testing examples
   are written by Dataflow to [Cloud Storage] in the [TFRecord] format, which is
   a format native to TensorFlow.

5. The files containing TFRecords are read by the [tf.data] API of TensorFlow
   and eventually transformed into a dataset of appropriately padded batches of
   examples.

The above workflow is not as simple as reading data from a Pandas DataFrame
comfortably resting in main memory; however, it is much more scalable. This
pipeline can handle arbitrary amounts of data. Moreover, it operates on
complete examples, not on individual measurements.

In the rest of the article, the aforementioned steps will be described in more
detail. The corresponding source code can be found in the following repository:

* [example-weather-forecast].

# Processing

# Ingestion

# Conclusion

[Global Historical Climatology Network]: https://www.ncdc.noaa.gov/data-access/land-based-station-data/land-based-datasets/global-historical-climatology-network-ghcn

[BigQuery]: https://cloud.google.com/bigquery/
[Cloud Dataflow]: https://cloud.google.com/dataflow/
[Cloud Storage]: https://cloud.google.com/storage/
[TFRecord]: https://www.tensorflow.org/tutorials/load_data/tfrecord
[TensorFlow]: https://www.tensorflow.org
[ghcn-d]: https://console.cloud.google.com/marketplace/details/noaa-public/ghcn-d
[tf.data]: https://www.tensorflow.org/guide/data

[example-weather-forecast]: https://github.com/chain-rule/example-weather-forecast
