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
website traffic or the conversion rate, that is, purchases—without you realizing
it. To your hand on the pulse, you decide to put guardrails in place, which
would inform you if something goes wrong. In this article, we shall take a look
at how to build such guardrails using Bayesian statistics.

# Problem

Let $$n$$ be the number of stores and $$m$$ be the number of weekly
observations. A weekly observation is a tuple $$(i_j, t_j, x_j, y_j)$$, for $$j
\in \{1, \ldots, m\}$$, where $$i_j \in \{1, \ldots, n\}$$ is the index of the
store observed, $$t_j \in \mathbb{N}_+$$ is the index of the week of
observation, $$x_j \in \mathbb{N}$$ is the total number of sessions that week,
and $$y_j \leq x_j$$ is the number of sessions that resulted in at least one
purchase. With this notation, the conversion rate for store $$i_j$$ and week
$$t_j$$ is given by $$p_j = y_j / x_j$$ provided that $$x_j > 0$$.

Note that there is no requirement on the alignment of observation across the
stores and the continuity of observation within a given store: different stores
might be observed on different weeks, and there might be weeks missing between
the first and the last observation of a store.

Given $$\mathcal{D} = \{(i_j, t_j, x_j, y_j)\}_{j = 1}^m$$, the goal is to find
a threshold for the number of sessions, denoted by $$\hat{x}_i$$, and a
threshold for the conversion rate, denoted by $$\hat{p}_i$$, so that whenever
$$x_k \geq \hat{x}_i$$ and $$p_k \geq \hat{p}_i$$ for an unseen week $$t_k$$,
the performance of store $$i \in \{1, \ldots, n\}$$ is considered usual,
uneventful. Conversely, when either metric falls below the corresponding
guardrail, the situation is considered concerning enough to perform a closer
investigation of the performance of the corresponding store.

The problem can be classified as anomaly detection. The topic is well studied,
and there are many approaches to this end. Here we shall look at it from a
Bayesian perspective.

# Solution

The idea is to build a statistical model and fit it to the data. In Bayesian
statistics, it means that there will be a fully-fledged probability distribution
available in the end, which will provide an exhaustive description of the
situation at hand. This distribution can then be used to estimate a wide range
of quantities of interest. In particular, one can choose an appropriate quantile
on the left tail of the distribution and use it as a guardrail. If an upper
bound is required, one can do the same with respect to the right tail.

First, we need to acknowledge that the number of sessions $$x_j$$, which is a
count, is very much different from the conversion rate $$p_j$$, which is a
proportion. Hence, one would need to build two different models for the two
metrics. Let us start with the number of sessions.

Even though the number of sessions is a count, that is, a natural number, it is
commonplace to model it as a continuous variable. One could use a Gaussian
distribution, for instance. However, to respect the fact that is cannot be
negative, we shall use a log-Gaussian distribution instead:

$$
\begin{align}
x_j & \sim \text{log-Gaussian}(\mu_{i_j}, \sigma_{i_j})
\end{align}
$$

where $$\mu_{i_j}$$ and $$\sigma_{i_j}$$ are the location and scale of store
$$i_j$$, respectively.

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

Furthermore, we calculated only a lower bound, but it is equally easy to
calculate an upper one in case one wants to keep an eye on unusually successful
weeks.
