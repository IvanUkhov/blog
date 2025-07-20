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

## Sessions

Even though the number of sessions is a natural number, it is commonplace to
model it as a real number. One could, for instance, use a Gaussian distribution
to this end. However, to respect the fact that is cannot be negative, we shall
use a log-Gaussian distribution instead, which is even more adequate if the
popularity of the stores taken collectively spans multiple orders of magnitude:

$$
\begin{align}
x_j & \sim \text{log-Gaussian}(\mu_{i_j}, \sigma_{i_j}) \tag{1}
\end{align}
$$

where $$\mu_{i_j}$$ and $$\sigma_{i_j}$$ are the location and scale for store
$$i_j$$. The above is the likelihood of the data. To complete the model, one has
to specify priors for the two parameters. For each one, we will use a linear
combination of a global and a store-specific component. For the location
parameter, it is just that:

$$
\begin{align}
\mu_{i_j} & = \mu_\text{global} + \mu_{\text{local}, i_j}. \tag{2}
\end{align}
$$

For the scale parameter, which is positive, we also apply a nonlinear
transformation on top of the linear combination to ensure the end result stays
positive:

$$
\begin{align}
\sigma_{i_j} & = \text{softplus}(\sigma_\text{global} + \sigma_{\text{local}, i_j}) \tag{3}
\end{align}
$$

where $$\text{softplus}(x) = \ln(1 + \text{exp}(x))$$. Technically, it can be
zero if $$\sigma_\text{global} + \sigma_{\text{local}, i_j}$$ goes to
$$-\infty$$, but it is not a concern in practice, as we shell see when we come
to the implementation.

With this reparameterization, there are $$2n + 2$$ parameters in the model. We
shall put a Gaussian prior on each one as follows:

$$
\begin{align}
\mu_\text{global} & \sim \text{Gaussian}(\mu_0, 1); \tag{4} \\
\mu_{\text{local}, i_j} & \sim \text{Gaussian}(0, 1), \text{ for } i_j \in \{ 1, \dots, n \}; \tag{5} \\
\sigma_\text{global} & \sim \text{Gaussian}(\sigma_0, 1); \text{ and} \tag{6} \\
\sigma_{\text{local}, i_j} & \sim \text{Gaussian}(0, 1), \text{ for } i_j \in \{ 1, \dots, n \}. \tag{7}
\end{align}
$$

It can be seen that the local ones are standard Gaussian, while the global ones
have the mean set to non-zeros values (to be discussed shortly), with the
standard deviation set to one still. Since we work on a logarithmic scale due to
the usage of a log-Gaussian distribution in Equation 1, this standard
parameterization should be adequate for websites having a number of sessions per
week that is below a few thousand provided that the global distributions are
centered appropriately via $$\mu_0$$ and $$\sigma_0$$.

In the above formulation, there are only two hyperparameters, which require
custom values: $$\mu_0$$ and $$\sigma_0$$. To get a bit of intuition for what
they control, it is helpful to temporarily set the local parameters (Equations 5
and 7) to zero. Then $$\mu_{i_j}$$ simplifies to $$\mu_\text{global}$$ and
$$\sigma_{i_j}$$ to $$\text{softplus}(\sigma_\text{global})$$. Furthermore,
$$\text{softplus}$$ can be dropped, since the corresponding non-linearity
manifest itself only close to zero. Hence, $$\mu_\text{global}$$ and
$$\sigma_\text{global}$$ can simply be thought of as the location and scale
parameters of the log-Gaussian distribution in Equation 1. With this in mind,
they can be used to control the distribution's shape, that is, our prior
assumptions about the number of weekly sessions.

That does not quite help with the intuition still, as the location and scale
parameters of a log-Gaussian distribution are _not_ its mean and standard
deviation, which would have been more familiar concepts to work with. However,
it is possible to derive the location and scale parameters given a mean and a
standard deviation one has in mind. More specifically, they are as follows:

$$
\begin{align}
\text{location} & = \ln(\text{mean}) - \frac{1}{2} \ln\left( 1 + \left( \frac{\text{deviation}}{\text{mean}} \right)^2 \right) \text{ and} \\
\text{scale} & = \sqrt{\ln\left( 1 + \left(\frac{\text{deviation}}{\text{mean}}\right)^2 \right)}.
\end{align}
$$

Bringing $$\text{softplus}$$ back into the picture, we obtain the following for
the hyperparameters:

$$
\begin{align}
\mu_0 & = \ln(\text{mean}) - \frac{1}{2} \ln\left( 1 + \left( \frac{\text{deviation}}{\text{mean}} \right)^2 \right) \text{ and} \\
\sigma_0 & = \text{softplus}^{-1} \left( \sqrt{\ln\left( 1 + \left(\frac{\text{deviation}}{\text{mean}}\right)^2 \right)} \right)
\end{align}
$$

where $$\text{softplus}^{-1}(x) = \ln(\text{exp}(x) - 1)$$. The end result is
that we can think of a mean and a standard deviation for the situation at hand,
and it would be enough to complete the model.

To recapitulate, the number of sessions is modeled according to Equation 1 where
the location and scale parameters are given by Equation 2 and 3, respectively,
with the priors set as in Equations 4–7 and the two hyperparameters set based on
prior expectations for the mean and standard deviation according to Equation 8
and 9, respectively.

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
