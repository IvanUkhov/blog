---
layout: post
title: A Bayesian approach to the inference of the net promoter score
date: 2019-12-31
math: true
keywords:
  - Bayesian statistics
  - R
  - Stan
  - data science
  - net promoter score
javascript: >
  window.onload = function() {
    var keywords = ['data', 'model', 'parameters', 'transformed'];
    var types = ['real', 'simplex', 'vector'];
    document
      .querySelectorAll('.language-c .n')
      .forEach(function(element) {
        if (keywords.indexOf(element.innerText) != -1) {
          element.style.cssText = 'font-weight: 600';
        }
        if (types.indexOf(element.innerText) != -1) {
          element.className += ' kt';
        }
      });
  };
---

The net promoter score is a widely adopted metric for gauging customers’
satisfaction with a product. The popularity of the score is largely attributed
to the simplicity of measurement and the easy of interpretation. Moreover, it is
claimed to be correlated with revenue growth, which, ignoring causality, might
make it even more appealing. In this article, we construct a hierarchical
Bayesian model and infer the net promoter score for an arbitrary segmentation of
a customer base.

A bare-bones net promoter survey is composed of only one question: “How likely
are you to recommend us to a friend?” The answer is an integer ranging from 0 to
10 inclusively. If the answer is between 0 and 6, the person in question is said
to be a detractor. If it is 7 or 8, the person is said to be a neutral. Lastly,
if it is 9 or 10, the person is said to be a promoter. The net promoter score
itself is then the percentage of promoters minus the percentage of detractors.
The minimum and maximum attainable values of the score are −100 and 100,
respectively.

As it is usually the case with surveys, a small but representative subset of
customers is reached out to, and the collected responses are then used to draw
conclusions about the target population of customers. Our objective is to
facilitate this last step by estimating the net promoter score given a set of
responses and necessarily quantify and put front and center the uncertainty in
our estimates.

Before we proceed, since a net promoter survey is an observational study, which
is prone to such biases as participation and response biases, great care must be
taken when analyzing the results. In this article, however, we focus on the
inference of the net promoter score under the assumption that the given sample
of responses is representative of the target population.

# Modeling

In practice, one is interested to know the net promoter scope for different
subpopulations of customers, such as countries of operation and age groups,
which is the scenario that we shall target. To this end, suppose that there are
$$m$$ segments. The results of a net promoter survey can then be summarized
using the following $$m \times 3$$ matrix:

$$
y = \left(
\begin{matrix}
d_1 & n_1 & p_1 \\
\cdots & \cdots & \cdots \\
d_m & n_m & p_m
\end{matrix}
\right)
$$

where $$d_i$$, $$n_i$$, and $$p_i$$ denote the number of detractors, neutrals,
and promoters in segment $$i$$, respectively. For segment $$i$$, the _observed_
net promoter score can be computed as follows:

$$
\hat{s}_i = 100 \times \frac{p_i - d_i}{d_i + n_i + p_i}.
$$

# Implementation

```c
data {
  int<lower = 0> m;
  int<lower = 0> n;
  int y[m, n];
}

parameters {
  simplex[n] mu;
  real<lower = 0> sigma;
  simplex[n] theta[m];
}

transformed parameters {
  vector<lower = 0>[n] phi;
  phi = mu / sigma^2;
}

model {
  mu ~ uniform(0, 1);
  sigma ~ cauchy(0, 1);
  for (i in 1:m) {
    theta[i] ~ dirichlet(phi);
    y[i] ~ multinomial(theta[i]);
  }
}
```

# Conclusion
