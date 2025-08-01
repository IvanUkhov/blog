---
layout: post
title: Building guardrails with Bayesian statistics
date: 2025-07-30T08:00:00+01:00
math: true
stan: true
keywords:
  - Bayesian statistics
  - R
  - Stan
  - anomaly detection
  - conversion rate
  - guardrails
  - website traffic
---



Suppose you run several online stores, and their number keeps growing. It is
becoming increasingly difficult to monitor the performance of any given store,
simply because there are too many of them. There is a fair chance that something
unexpected will happen and have a negative impact on either the website traffic
or the conversion rate, that is, purchases—without you realizing it. To keep
your hand on the pulse, you decide to put guardrails in place, which will inform
you if something goes wrong. In this article, we shall take a look at how to
build such guardrails using Bayesian statistics.


# Problem

Let $$n$$ be the number of stores and $$m$$ be the number of weekly
observations. A weekly observation is a tuple $$(i_j, t_j, x_j, y_j)$$, for $$j
\in \{1, \dots, m\}$$, where $$i_j \in \{1, \dots, n\}$$ is the index of the
store observed, $$t_j \in \mathbb{N}_+$$ is the index of the week of
observation, $$x_j \in \mathbb{N}$$ is the total number of sessions that week,
and $$y_j \leq x_j$$ is the number of sessions that resulted in at least one
purchase. With this notation, the conversion rate for store $$i_j$$ and week
$$t_j$$ is given by $$p_j = y_j / x_j$$ provided that $$x_j > 0$$.

Note that there is no requirement on the alignment of observations across the
stores and the continuity of observation within a given store: different stores
might be observed on different weeks, and there might be weeks missing between
the first and the last observation of a store.

Given $$\{(i_j, t_j, x_j, y_j)\}_{j = 1}^m$$, the goal is to find a threshold
for the number of sessions, denoted by $$\hat{x}_i$$, and a threshold for the
conversion rate, denoted by $$\hat{p}_i$$, so that whenever $$x_k \geq
\hat{x}_i$$ and $$p_k \geq \hat{p}_i$$ for an unseen week $$t_k$$, the
performance of store $$i \in \{1, \dots, n\}$$ is considered usual, uneventful.
Conversely, when either metric falls below the corresponding guardrail, the
situation is considered concerning enough to perform a closer investigation of
the performance of the corresponding store.

The problem can be classified as anomaly detection. The topic is well studied,
and there are many approaches to this end. Here we shall look at it from a
Bayesian perspective.

# Solution

The idea is to build a statistical model and fit it to the data. In Bayesian
inference, it means that there will be a fully fledged probability distribution
available in the end, providing an exhaustive description of the situation at
hand. This distribution can then be used to estimate a wide range of quantities
of interest. In particular, one can choose an appropriate quantile on the left
tail of the distribution and use it as a guardrail. If an upper bound is
required, one can do the same with respect to the right tail.

Let us start with the modeling, and we will then come back to the inference. To
begin with, we need to acknowledge the fact that the number of sessions $$x_j$$,
which is a count, is very different from the conversion rate $$p_j$$, which is a
proportion. Hence, one would need to build two different models. In addition, we
shall ignore the information about which week each observation belongs to, that
is, $$\{ t_j \}_{j = 1}^m$$, and come back to and motivate this choice in the
conclusion.

## Modeling: Number of sessions

Even though the number of sessions is a natural number, it is commonplace to
model it as a real number. One could, for instance, use a Gaussian distribution
to this end. However, to respect the fact that it cannot be negative, we shall
use a log-Gaussian distribution instead, which is even more adequate if the
popularity of the stores taken collectively spans multiple orders of magnitude:

$$
x_j | \mu_{i_j}, \sigma_{i_j} \sim \text{Log-Gaussian}(\mu_{i_j}, \sigma_{i_j}) \tag{1}
$$

where $$\mu_{i_j}$$ and $$\sigma_{i_j}$$ are the location and scale for store
$$i_j$$. The above is the likelihood of the data. To complete the model, one has
to specify priors for the two parameters. For each one, we will use a linear
combination of a global and a store-specific component. For the location
parameter, it is just that:

$$
\mu_{i_j} = \mu_\text{global} + \mu_{\text{local}, i_j}. \tag{2}
$$

For the scale parameter, which is positive, we also apply a nonlinear
transformation on top of the linear combination to ensure the end result stays
positive:

$$
\sigma_{i_j} = \text{softplus}(\sigma_\text{global} + \sigma_{\text{local}, i_j}) \tag{3}
$$

where $$\text{softplus}(x) = \ln(1 + \text{exp}(x))$$. Technically, it can be
zero if $$\sigma_\text{global} + \sigma_{\text{local}, i_j}$$ goes to
$$-\infty$$, but it is not a concern in practice, as we shall see when we come
to the implementation.

With this reparameterization, there are $$2n + 2$$ parameters in the model. We
shall put a Gaussian prior on each one as follows:

$$
\begin{align}
\mu_\text{global} & \sim \text{Gaussian}(\mu_0, 1), \tag{4} \\
\mu_{\text{local}, i_j} & \sim \text{Gaussian}(0, 1), \tag{5} \\
\sigma_\text{global} & \sim \text{Gaussian}(\sigma_0, 1), \text{ and} \tag{6} \\
\sigma_{\text{local}, i_j} & \sim \text{Gaussian}(0, 1). \tag{7}
\end{align}
$$

It can be seen that the local ones are standard Gaussian, while the global ones
have the mean set to non-zero values (to be discussed shortly), with the
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

It is always a good idea to perform a prior predictive check, which can be done
by sampling from the prior distribution and performing a kernel density
estimation. For instance, assuming a mean and a standard deviation of 500 and
setting the local variable to zero for simplicity, we obtain the following prior
probability density:



![](/assets/images/2025-07-30-guardrails/sessions-prior-1.svg)

It can be seen that it covers well the area that we hypothesize to be plausible.
The distribution also has a very long tail, which is truncated here, allowing
for the number of sessions to be untypically large.

To recapitulate, the number of sessions is modeled according to Equation 1 where
the location and scale parameters are given by Equation 2 and 3, respectively,
with the priors set as in Equations 4–7 and the two hyperparameters set based on
prior expectations for the mean and standard deviation according to Equation 8
and 9, respectively.

## Modeling: Conversion rate

The conversion rate is a proportion, that is, a real number between zero and
one, which is obtained by dividing the number of purchases by the number of
sessions: $$p_j = y_j / x_j$$. Since we have the constituents at our disposal,
it makes sense to model it using a binomial distribution:

$$
y_j | \alpha_{i_j} \sim \text{Binomial}(x_j, \alpha_{i_j}) \tag{8}.
$$

In this framework, one thinks of $$x_j$$ and $$y_j$$ as the number of trials and
the number of successes, respectively, and of $$\alpha_{i_j}$$ as the
probability of success. In our case, a trial is a session, a success is having
at least one purchase within that session, and the probability of success is the
conversion rate.

Similarly to the number of sessions, we will use a linear combination for the
parameters:

$$
\alpha_{i_j} = \text{logit}^{-1}(\alpha_\text{global} + \alpha_{\text{local}, i_j}) \tag{9}
$$

where $$\text{logit}^{-1}(x) = 1 / (1 + \text{exp}(-x))$$, used to ensure the
output stays in $$[0, 1]$$. There is a global component, which all stores share,
and each one has its own local.

There are $$n + 1$$ parameters in the model, which we shall consider to be _a
priori_ distributed according to Gaussian distributions as follows:

$$
\begin{align}
\alpha_\text{global} & \sim \text{Gaussian}(\alpha_0, 1) \text{ and} \tag{10} \\
\alpha_{\text{local}, i_j} & \sim \text{Gaussian}(0, 1). \tag{11} \\
\end{align}
$$

As before, the number of hyperparameters is kept to a minimum; there is only one
in this case: $$\alpha_0$$. The interpretation of $$\alpha_0$$ is that it
controls the base conversion rate, which one can see by temporarily setting the
local parameters (Equation 11) to zero. Equation 9 then reduces to
$$\alpha_{i_j} = \text{logit}^{-1}(\alpha_\text{global})$$. Therefore, assuming
one has an average conversion rate in mind, the parameter can be set as follows:

$$
\alpha_0 = \text{logit}(\text{mean}) \tag{12}
$$

where $$\text{logit}(x) = \ln(x / (1 - x))$$.

Let us perform a prior predictive check for the conversion rate as well.
Assuming a conversion rate of 2.5%, that is, $$\alpha_0 = \text{logit}(0.025)$$,
we obtain the following prior probability density:



![](/assets/images/2025-07-30-guardrails/purchases-prior-1.svg)

Here we assume 500 sessions per week and divide the sampled number of
conversions by that number. It can be seen that the density is mostly
concentrated on what one might consider realistic conversion rates but allows
for optimistic scenarios as well if that turns out to be the case.

To summarize, the conversion rate is modeled indirectly via the number of
sessions with purchases in accordance with Equation 8 where the
success-probability parameter is given by Equation 9, with the priors set as in
Equations 10 and 11 and the hyperparameter as in Equation 12.

## Inference

What do we do with the two models now? Traditionally, given a model, the outcome
of Bayesian inference is a posterior distribution over the parameters of the
model:

$$
f(\theta | \mathcal{D}) = \int f(\mathcal{D} | \theta) \, f(\theta) \, d\theta.
$$

In the above, $$\theta$$ is collectively referring to all parameters, which for
the number of sessions is

$$
\theta = \{
  \mu_\text{global}, \mu_{\text{local}, 1}, \dots, \mu_{\text{local}, n},
  \sigma_\text{global}, \sigma_{\text{local}, 1}, \dots, \sigma_{\text{local}, n}
\}
$$

and for the conversion rate is

$$
\theta = \{
  \alpha_\text{global}, \alpha_{\text{local}, 1}, \dots, \alpha_{\text{local}, n}
\},
$$

and $$\mathcal{D}$$ is the observed data, which is $$\{ x_j \}_{j = 1}^m$$ for
the number of sessions and $$\{ y_j \}_{j = 1}^m$$ for the conversion rate,
assuming $$\{ x_j \}_{j = 1}^m$$ to be implicitly known in the latter case.
Next, $$f(\theta)$$ stands for the density of the prior distribution of the
parameters, which is given by Equations 4, 5, 6, and 7 for the number of
sessions and by Equations 10 and 11 for the conversion rate, and $$f(\mathcal{D}
| \theta)$$ is the density of the likelihood of the data, which is given by
Equations 1 and 8, respectively. When the two are combined, we arrive at the
density of the posterior distribution of the parameters given the data,
$$f(\theta | \mathcal{D})$$.

However, we are not so much after the parameters themselves, that is,
$$\theta$$, but rather after the data, that is, $$\mathcal{D}$$. More
specifically, we would like to know what to expect from the data in the future
given what we have seen in the past. If we acquire a probability distribution
over what we can reasonably expect to observe next week, we would be able to
judge whether what we actually observe is anomalous or not.

The desired distribution has a name: the posterior predictive distribution. It
is also an artifact of Bayesian inference, and formally, the distribution is as
follows:

$$
f(\mathcal{D}_\text{new} | \mathcal{D}) = \int f(\mathcal{D}_\text{new} | \theta) \, f(\theta | \mathcal{D}) \, d\theta.
$$

In other words, it is the distribution of unseen data $$\mathcal{D}_\text{new}$$
given the observed data $$\mathcal{D}$$ where the uncertainty in the parameters
is integrated out via the posterior distribution of the parameters $$\theta$$.

In practice, given a model with data, all of the above is done by the
probabilistic programming language of choice, such as [Stan], and its tooling.
Since such languages target the general case where the model cannot be tackled
analytically, the resulting distributions are given in the form of posterior
draws. For the posterior predictive distribution, it would be a collection of
$$l$$ hypothetical replicas (on the order of thousands) of the original
observations: $$\{ \mathcal{D}_\text{new}^k \}_{k = 1}^l$$. That is, for each
original observation of a store on a specific week, there will be $$l$$ draws.
To calculate a guardrail for a specific store then, we can simply collect all
draws that belong to that store, choose a percentile, and calculate the
corresponding quantile:

$$
\text{guardrail} = \text{quantile}(\text{draws}, \text{percentile}).
$$

For the number of sessions for store $$i$$, the guardrail is as follows:

$$
\hat{x}_i = \text{quantile}\left( \left\{ x_{\text{new}, j}^k: \, i_j = i, \, k = 1, \dots, l \right\}, \text{percentile} \right).
$$

Likewise, for the conversion rate, we have the following:

$$
\hat{p}_i = \text{quantile}\left( \left\{ \frac{y_{\text{new}, j}^k}{x_j^k}: \, i_j = i, \, k = 1, \dots, l \right\}, \text{percentile} \right).
$$

If the percentile is chosen to be, for instance, 2.5%, the guardrail will be
flagging the outcomes, that is, the number of sessions or the conversion rate
for the week that has just passed, that have dropped so much that the
probability of this happening is estimated to be at most 2.5%. One can, of
course, tweak this threshold as one sees fit, depending on how cautious one
wants to be.

Due to the separation of the models' parameters into global and local, they are
considered hierarchical or multilevel. This structure allows for partial pooling
of information: what is observed for one store not only helps with the inference
for that store but also for all other stores. In particular, stores with little
data get more sensible estimates due to the presence of those with more.

To sum up, once formulated, each model can be implemented in a probabilistic
programming language and fitted to the historical data. The result is a set of
replications of the original observations, yielding a probability distribution
over what one might expect to see in the future. The corresponding guardrail is
then an appropriately chosen quantile of this distribution.

# Conclusion

In this article, we have taken a look at how to build guardrails using Bayesian
statistics. They are derived in a principled way as opposed to being set based
on a gut feeling.

What makes this approach different from other data-driven techniques is the end
product: a probability distribution. Moreover, this distribution respects one's
prior domain knowledge—or gut feeling again—but necessarily updates it with
evidence, that is, with actual observations. Having such a probability
distribution for the situation at hand is all one can ask for, since it provides
an exhaustive description. Furthermore, the distribution is provided in the form
of draws, and working with draws is arguably more intuitive and flexible, as one
does not depend on any mathematical derivations, which might not even be
tractable. With this in mind, calculating guardrails is only one of many
possible applications, and even this very calculation can be done in numerous
ways. One can, for instance, devise a utility function assigning a cost to each
outcome and choose a guardrail by minimizing the expected cost.

The time aspect, that is, $$\{ t_j \}_{j = 1}^m$$, has been ignored in this
article. However, it might be justified in the setting of anomaly detection
where a relatively short time horizon is considered sufficient or even desired.
One might, for instance, limit the number of weeks to a rolling quarter (around
13 weeks) and keep on estimating the guardrails for the upcoming week. In this
case, one would not expect to have any prominent annual seasonal effects or
alike, and it is then not worth complicating the model. Moreover, the rolling
nature of this approach with a shorter window also helps to accommodate any slow
trend changes, which fall outside the scope of anomaly detection. However, it is
always possible to extend the model to have the time aspect modeled explicitly
if that is desired.

# Appendix

In this auxiliary section, we provide reference implementations of the two
models in [Stan]. The notation is the same as in the rest of the article. For
the number of sessions, it is as follows:

```c
data {
  int<lower=1> n; // Number of stores
  int<lower=1> m; // Number of observations
  array[m] int<lower=1, upper=n> i; // Mapping from observations to stores
  vector[m] x; // Number of sessions
}

transformed data {
  real mean = 500; // Prior mean
  real deviation = 500; // Prior standard deviation
  real mu_0 = log(mean) - 0.5 * log(1 + pow(deviation / mean, 2));
  real sigma_0 = sqrt(log(1 + pow(deviation / mean, 2)));
}

parameters {
  real mu_global;
  vector[n] mu_local;
  real sigma_global;
  vector[n] sigma_local;
}

transformed parameters {
  vector[n] mu = mu_global + mu_local;
  // The value is shifted by a small amount to avoid numerical issues.
  vector[n] sigma = log1p_exp(sigma_global + sigma_local) + 1e-3;
}

model {
  // Prior distributions
  mu_global ~ normal(mu_0, 1);
  mu_local ~ normal(0, 1);
  sigma_global ~ normal(log(exp(sigma_0) - 1), 1);
  sigma_local ~ normal(0, 1);
  // Likelihood of the data
  for (j in 1:m) {
    x[j] ~ lognormal(mu[i[j]], sigma[i[j]]);
  }
}

generated quantities {
  // Posterior predictive distribution
  vector[m] x_new;
  for (j in 1:m) {
    x_new[j] = lognormal_rng(mu[i[j]], sigma[i[j]]);
  }
}
```

Note that the posterior predictive distribution is part of the program; once
executed, it will not require any additional postprocessing. As for the
conversion rate, the implementation is as follows:

```c
data {
  int<lower=1> n; // Number of stores
  int<lower=1> m; // Number of observations
  array[m] int<lower=1, upper=n> i; // Mapping from observations to stores
  array[m] int<lower=0> x; // Number of sessions
  array[m] int<lower=0> y; // Number of sessions with purchases
}

transformed data {
  real mean = 0.025; // Prior mean
  real alpha_0 = mean;
}

parameters {
  real alpha_global;
  vector[n] alpha_local;
}

transformed parameters {
  vector[n] alpha = alpha_global + alpha_local;
}

model {
  // Prior distributions
  alpha_global ~ normal(logit(alpha_0), 1);
  alpha_local ~ normal(0, 1);
  // Likelihood of the data
  for (j in 1:m) {
    y[j] ~ binomial_logit(x[j], alpha[i[j]]);
  }
}

generated quantities {
  // Posterior predictive distribution
  vector<lower=0, upper=1>[m] y_new;
  for (j in 1:m) {
    y_new[j] = 1.0 * binomial_rng(x[j], inv_logit(alpha[i[j]])) / x[j];
  }
}
```

[Stan]: https://mc-stan.org/
