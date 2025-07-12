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
observations. A weekly observation is a tuple $$(i_j, t_j, x_j, y_j)$$ for $$j
\in \{1, \ldots, m\}$$ where $$i_j \in \{1, \ldots, n\}$$ is the index of the
store observed, $$t_j \in \mathbb{N}_+$$ is the index of the week of
observation, $$x_j \in \mathbb{N}$$ is the total number of sessions that week,
and $$y_j \leq x_j$$ is the number of sessions that resulted in at least one
purchase.

With the above notation, the conversion rate for store $$i_j$$ and week $$t_j$$
is given by $$y_j / x_j$$. Note, however, that there is no requirement on the
alignment of observation across the stores and the continuity of observation
within a given store: different stores might be observed on different weeks, and
there might be weeks missing between the first and the last observation.
