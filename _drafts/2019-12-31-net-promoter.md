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
---

The net promoter score is a widely adopted metric for gauging customers’
satisfaction with a product. The popularity of the score is largely attributed
to the simplicity of measurement and the easy of interpretation. Moreover, it is
claimed to be correlated with revenue growth, which, ignoring causality, might
make it even more appealing. In this article, we utilize Bayesian statistics in
order to infer the net promoter score for a customer base given the results of a
net promoter survey.

A bare-bones net promoter survey is composed of only one question: “How likely
are you to recommend us to a friend?” The answer is an integer ranging from zero
to ten. If the answer is between zero and six, the person in question is said to
be a detractor. If it is seven or eight, the person is said to be a neutral.
Lastly, if it is nine or ten, the person is said to be a promoter. The net
promoter score itself is then the percentage of promoters minus the percentage
of detractors. The minimum and maximum attainable values of the score are −100
and 100, respectively.

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
