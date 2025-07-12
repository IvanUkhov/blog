---
layout: post
title: Building guardrails with Bayesian statistics
date: 2025-08-01T08:00:00+01:00
math: true
keywords:
  - Bayesian statistics
  - R
  - Stan
  - anomaly detection
  - conversion rate
  - guardrails
  - website traffic
---

Suppose you run several online stores, and their number keeps on growing. It is
becoming increasingly difficult to monitor the performance of any given one as
there are simply too many of them. There is a fair chance that something
unexpected happens, and that it will have a negative impact on either the
website traffic or the conversion rate—without you realizing it. To stay
vigilant, it might be prudent to have guardrails in place that would inform you
when something goes wrong. In this article, we shall take a look at how to build
such guardrails using Bayesian statistics.

# Problem

Let $$n$$ be the number of stores and $$m$$ be the number of weekly
observations. A weekly observation is a tuple $$(i_j, t_j, x_j, y_j)$$, for $$j
\in \{1, \ldots, m\}$$, where $$i_j \in \{1, \ldots, n\}$$ is the index of the
store observed, $$t_j \in \mathbb{N}_+$$ is the index of the week of
observation, $$x_j \in \mathbb{N}$$ is the total number of sessions that week,
and $$y_j \leq x_j$$ is the number of sessions that resulted in at least one
purchase. With this notation, the conversion rate (proportion) for store $$i_j$$
and week $$t_j$$ is given by $$p_j = y_j / x_j$$ provided that $$x_j > 0$$.

Note that there is no requirement on the alignment of observation across the
stores and the continuity of observation within a given store: different stores
might be observed on different weeks, and there might be weeks missing between
the first and the last observation of a store.

Given $$\{(i_j, t_j, x_j, y_j)\}_{j = 1}^m$$, the goal is to find a threshold
$$\hat{x}_i$$ for the number of sessions and a threshold $$\hat{p}_i$$ for the
conversion rate above which the two metrics are considered to lie within their
normal ranges for store $$i \in \{1, \ldots, n\}$$. Conversely, when either
metric falls below its threshold, the situation is considered concerning enough
to perform a closer investigation of the corresponding store.

# Solution

The problem can be classified as anomaly detection. The topic is well studied,
and there are many approaches to this end. Here we take a Bayesian perspective.

# Conclusion

The time aspect, that is, $$\{ t_j \}_{j = 1}^m$$, has been ignored in this
article. However, it might be justified in the setting of anomaly detection
where a relatively short time horizon is considered sufficient or even desired.
One might, for instance, limit the number of weeks to a rolling quarter (around
13 weeks) and keep on estimating the guardrails for the upcoming week. In this
case, one would not expect to have any prominent annual seasonal effects or
alike, and it is then not worth complicating the model. Moreover, the rolling
nature of this approach with a shorter window also helps to accommodate any slow
trend changes, which fall outside the scope of anomaly detection.
