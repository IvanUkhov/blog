---
layout: post
title: A Bayesian approach to the inference of the net promoter score
date: 2019-12-31
math: true
---

The net promoter score is a widely adopted metric for gauging customers’
satisfaction with a product. The popularity of the score is largely attributed
to the simplicity of measurement and the easy of interpretation. It is also
claimed to be correlated with revenue growth, which, ignoring causality, might
make it even more appealing. In this article, we apply Bayesian statistics in
order to infer the net promoter score for the whole customer base based on
surveying a small subset of customers.

A bare-bones net promoter survey is composed of only one question: “How likely
are you to recommend us to a friend?” The answer is an integer from zero to ten.
If the answer is between zero and six, the person is said to be a detractor. If
the answer is seven or eight, the person is said to be a neutral. Lastly, if the
grade is nine or ten, the person is said to be a promoter. The net promoter
score itself is then the percentage of promoters minus the percentage of
detractors.
