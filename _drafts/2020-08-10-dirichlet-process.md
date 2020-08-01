---
layout: post
title: Breaking sticks, or density estimation via the Dirichlet process
date: 2020-08-10T08:00:00+02:00
math: true
keywords:
  - Bayesian statistics
  - Dirichlet process
  - R
  - data science
---

She sells seashells by the seashore.

# Direct prior

$$
\begin{align}
y_i & \sim P, \text{ for } i = 1, \dots, n; \\
P & \sim \text{Dirichlet process}\left( m \right); \text{ and } \\
m(\cdot) & = m_0 \, \text{Gaussian}\left(\, \cdot \, | \mu_0, \tau_0 \right).
\end{align}
$$

In the above, $$\text{Gaussian}(\cdot)$$ refers to the probability measure of a
Gaussian distribution. In this case, we use the precision-based parameterization
of the family of Gaussian distributions where $$\tau_0$$ is the reciprocal of
the usual variance parameter.

# Mixing prior

$$
\begin{align}
y_i & \sim \text{Gaussian}\left( \mu_i, \tau_i \right), \text{ for } i = 1, \dots, n; \\
(\mu_i, \tau_i) & \sim P, \text{ for } i = 1, \dots, n; \\
P & \sim \text{Dirichlet process}\left( m \right); \text{ and} \\
m(\cdot) & = m_0 \, \text{Gaussian–Gamma}\left(\, \cdot \, | \mu_0, n_0, \alpha_0, \beta_0 \right).
\end{align}
$$

In the above, $$\text{Gaussian–Gamma}(\cdot)$$ refers to the probability measure
of a Gaussian–Gamma distribution, which is bivariate, as desired in this case.
Some intuition about this distribution can be built by decomposing it into a
conditional Gaussian and an unconditional Gamma:

$$
\begin{align}
\mu_i | \tau_i & \sim \text{Gaussian}\left( \mu_0, n_0 \tau_i \right) \text{ and} \\
\tau_i & \sim \text{Gamma}\left( \alpha_0, \beta_0 \right).
\end{align}
$$

The Gaussian–Gamma distribution is a conjugate prior for the Gaussian data
distribution with unknown mean and variance, assumed here. This means that the
posterior is also Gaussian–Gamma. Given a data set with $$n_1$$ observations
$$x_1, \dots, x_{n_1}$$, the mapping of the four parameters of the prior to
those of the posterior is as follows:

$$
\begin{align}
\mu_0 & \to \frac{n_0}{n_0 + n_1} \mu_0 + \frac{n_1}{n_0 + n_1} \bar{x}; \\
n_0 & \to n_0 + n_1; \\
\alpha_0 & \to \alpha_0 + \frac{n_1}{2}; \text{ and} \\
\beta_0 & \to \beta_0 + \frac{1}{2} \sum_{i = 1}^{n_1} (x_i - \bar{x})^2 + \frac{n_0 \, n_1}{2(n_0 + n_1)} (\bar{x} - \mu_0)^2.
\end{align}
$$
