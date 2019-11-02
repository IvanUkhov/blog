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
Can they fit in the main memory? Are they of the same length? In what follows,
we shall build a flexible and scalable workflow for feeding sequential
observations into a TensorFlow graph start from [BigQuery] as a data warehouse.

To make the discussion tangible, consider the following problem. Suppose the
goal is to predict the average temperature at an arbitrary weather station in
the [Global Historical Climatology Network] for each day between June 1 and
August 31. Specifically, given observations from May 1 up to an arbitrary day
between June 1 and August 31, the objective is to complete the sequence until
August 31. For instance, if we find ourselves in Stockholm on June 12, we ask
for the average daily temperature from June 12 to August 31 given the
temperature values between May 1 to June 11 at a weather station in Stockholm.

We are not going to build a predictive model but to cater for its development by
providing the data.

The final chain of states and operations is as follows:

1. Historical temperature measurements from the Global Historical Climatology
   Network are stored in a [public dataset][ghcn-d] in BigQuery. Each record
   corresponds to a weather station and a date.

2. Sequences are formed by grouping the measurements by the weather station and
   year. There are missing observations due to such reasons as not passing
   quality checks.

3. The sequences are read, analyzed, and transformed by [Cloud Dataflow].

    * The input data are split into a training set, a validation set, and a
      testing set.

    * The training set is used to compute statistics needed for transforming the
      measurements to a form suitable for neural networks and, in particular,
      for standardizing the data.

    * The training, validation, and testing sets of temperature sequences are
      transformed using the statistics computed from the training set.

4. The processed sequences are written by Dataflow to [Cloud Storage] in the
   [TFRecord] format, which is a serialization format native to TensorFlow.

5. The files containing TFRecords are read by the [tf.data] API of TensorFlow
   and eventually transformed into a dataset of appropriately padded batches of
   sequential data.

The above workflow is not as simple as reading data from a Pandas DataFrame
comfortably fitted in the main memory; however, it is much scalable. This
pipeline can handle arbitrary amounts of data.

The source code of what follows can be found in the following repository:

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
