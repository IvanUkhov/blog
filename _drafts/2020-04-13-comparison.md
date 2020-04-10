---
layout: post
title: What is the easiest way to compare two data sets?
date: 2020-04-13
keywords:
  - Python
  - data science
head: >
  <script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js'></script>
  <script type='text/javascript' src='https://cdnjs.cloudflare.com/ajax/libs/webcomponentsjs/1.3.3/webcomponents-lite.js'></script>
body: >
  <script type='text/javascript'>
    var path = '/assets/scripts/2020-04-13-comparison';
    var complete = false;
    window.addEventListener('WebComponentsReady', function() {
      if (complete) {
        return;
      }
      complete = true;
      var link = document.createElement('link');
      link.rel = 'import';
      link.href = path + '/facets.html';
      link.onload = function() {
        var overview = document.createElement('facets-overview');
        document.getElementById('facets-overview-container').appendChild(overview);
        var train = $.getJSON({ url: path + '/train.json' });
        var test = $.getJSON({ url: path + '/test.json' });
        $.when(train, test).done(function(train, test) {
          var proto = overview.getStatsProto([
            { data: train[0], name: 'train' },
            { data: test[0], name: 'test' }
          ]);
          overview.protoInput = proto;
          overview.data = test[0];
        });
      };
      document.head.appendChild(link);
    });
  </script>
  <style>
    #facets-overview-container {
      width: 130%;
      margin-left: -15%;
      margin-top: 5em;
      margin-bottom: 5em;
    }
  </style>
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

An alternative is to leverage what already exists in the data community.
Specifically, there is the following three-line takeaway based on [Facets
Overview] via [TensorFlow Data Validation]:

```python
import tensorflow_data_validation as dv

statistics_1 = dv.generate_statistics_from_dataframe(data_1)
statistics_2 = dv.generate_statistics_from_dataframe(data_2)
dv.visualize_statistics(lhs_statistics=statistics_1,
                        rhs_statistics=statistics_2)
```

This is all it takes to get a versatile dashboard embedded into right into a
cell of a Jupyter notebook.

It is pointless to try to describe in words what it can do; instead, here is a
demonstration taken from [Facets Overview]’s page where the tool is applied the
[UCI Census Income] data set:

<div id='facets-overview-container'></div>

The dashboard is split into two sections: one is for numerical features, and one
is for categorical.

[Facets Overview]: https://pair-code.github.io/facets#facets-overview
[TensorFlow Data Validation]: https://www.tensorflow.org/tfx/data_validation/get_started
[UCI Census Income]: http://archive.ics.uci.edu/ml/datasets/Census+Income
