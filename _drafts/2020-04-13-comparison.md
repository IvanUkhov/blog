---
layout: post
title: What is the easiest way to compare two data sets?
date: 2020-04-13
keywords:
  - Python
  - data science
---

One has probably come across this problem numerous times. There are two versions
of a tabular data set with a lot of columns of different types, and one wants to
quickly identify any differences between the two. For example, the pipeline
providing data to a predictive model might have been updated, and the goal is to
understand if there have been any side effects of this update on the training
data.

One solution is to start to iterate over the columns of the two tables,
computing five-number summaries and plotting histograms or identifying distinct
values and plotting bar charts, depending on the column’s type. This, however,
can quickly get out of hand and evolve into an endeavor for the rest of the day.

A more favorable alternative is to leverage what already exists in the data
community. In this short note, we share a tree-line approach based on
[TensorFlow Data Validation]. The key take-away is as follows:

```python
import tensorflow_data_validation as dv

statistics_1 = dv.generate_statistics_from_dataframe(data_1)
statistics_2 = dv.generate_statistics_from_dataframe(data_2)
dv.visualize_statistics(lhs_statistics=statistics_1,
                        rhs_statistics=statistics_2)
```

[TensorFlow Data Validation]: https://www.tensorflow.org/tfx/data_validation/get_started
