---
layout: post
title: What is the easiest way to compare two data sets?
date: 2020-04-10T08:00:00+02:00
keywords:
  - Python
  - TensorFlow
  - data science
  - exploratory data analysis
head: >
  <script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js'></script>
  <script type='text/javascript' src='https://cdnjs.cloudflare.com/ajax/libs/webcomponentsjs/1.3.3/webcomponents-lite.js'></script>
body: >
  <script type='text/javascript'>
    var path = '/assets/scripts/2020-04-10-comparison';
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
        var training = $.getJSON({ url: path + '/training.json' });
        var testing = $.getJSON({ url: path + '/testing.json' });
        $.when(training, testing).done(function(training, testing) {
          var proto = overview.getStatsProto([
            { data: training[0], name: 'training' },
            { data: testing[0], name: 'testing' }
          ]);
          overview.protoInput = proto;
          overview.data = testing[0];
        });
      };
      document.head.appendChild(link);
    });
  </script>
  <style>
    #facets-overview-container {
      margin-top: 5em;
      margin-bottom: 5em;
    }

    @media screen and (min-width: 800px) {
      #facets-overview-container {
        width: 130%;
        margin-left: -15%;
      }
    }
  </style>
---

One has probably come across this problem numerous times. There are two versions
of a tabular data set with a lot of columns of different types, and one wants to
quickly identify any differences between the two. For example, the pipeline
providing data to a predictive model might have been updated, and the goal is to
understand if there have been any side effects of this update for the training
data.

One solution is to start to iterate over the columns of the two tables,
computing five-number summaries and plotting histograms or identifying distinct
values and plotting bar charts, depending on the column’s type. However, this
can quickly get out of hand and evolve into an endeavor for the rest of the day.

An alternative is to leverage the amazing tools that already exist in the data
community.

# Solution

The key takeaway is the following three lines of code, excluding the import:

```python
import tensorflow_data_validation as dv

statistics_1 = dv.generate_statistics_from_dataframe(data_1)
statistics_2 = dv.generate_statistics_from_dataframe(data_2)
dv.visualize_statistics(lhs_statistics=statistics_1,
                        rhs_statistics=statistics_2)
```

This is all it takes to get a versatile dashboard embedded right into a cell of
a Jupyter notebook. The visualization itself is based on [Facets], and it is
conveniently provided by [TensorFlow Data Validation] (which does not have much
to do with TensorFlow and can be used stand-alone).

It is pointless to try to describe in words what the dashboard can do; instead,
here is a demonstration taken from [Facets] where the tool is applied the [UCI
Census Income] data set:

<div id='facets-overview-container'></div>

Go ahead and give a try to all the different controls!

In this case, it is helpful to toggle the “percentages” checkbox, since the data
sets are of different sizes. Then it becomes apparent that the two partitions
are fairly balanced. The only problem is that `Target`, which represents income,
happened to be encoded incorrectly in the partition for testing.

Lastly, an example in a Jupyter notebook can be found on [GitHub][notebook].

# Conclusion

It can be difficult to navigate and particularly challenging to compare wide
data sets. A lot of effort can be put into this exercise. However, the landscape
of open-source tools has a lot to offer too. Facets is one such example. The
library and its straightforward availability via TensorFlow Data Validation are
arguably less known. This short note can hopefully rectify this to some extent.

[Facets]: https://pair-code.github.io/facets
[TensorFlow Data Validation]: https://www.tensorflow.org/tfx/data_validation/get_started
[UCI Census Income]: http://archive.ics.uci.edu/ml/datasets/Census+Income
[notebook]: https://github.com/chain-rule/example-comparison/blob/master/census.ipynb
