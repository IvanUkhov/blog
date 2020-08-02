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
y_i | P & \sim P, \text{ for } i = 1, \dots, n; \text{ and} \\
P & \sim \text{Dirichlet process}(m).
\end{align}
$$

Let

$$
m(\cdot) = m_0 \, \text{Gaussian}(\, \cdot \, | \mu_0, \tau_0).
$$

In the above, $$\text{Gaussian}(\cdot)$$ refers to the probability measure of a
Gaussian distribution. In this case, we use the precision-based parameterization
of the Gaussian family of distributions where $$\tau_0$$ is the reciprocal of
the usual variance parameter.

# Mixing prior

$$
\begin{align}
y_i | \theta_i & \sim P_y \left( \theta_i \right), \text{ for } i = 1, \dots, n; \\
\theta_i | P_\theta & \sim P_\theta, \text{ for } i = 1, \dots, n; \text{ and} \\
P_\theta & \sim \text{Dirichlet process}(m).
\end{align}
$$

Let

$$
\begin{align}
\theta_i &= (\mu_i, \tau_i), \text{ for } i = 1, \dots, n; \\
P_y (\theta_i) &= \text{Gaussian}(\mu_i, \tau_i), \text{ for } i = 1, \dots, n; \text{ and} \\
m(\cdot) &= m_0 \, \text{Gaussian–Gamma}(\, \cdot \, | \mu_0, n_0, \alpha_0, \beta_0).
\end{align}
$$

In the above, $$\text{Gaussian–Gamma}(\cdot)$$ refers to the probability measure
of a Gaussian–Gamma distribution, which is bivariate, as desired in this case.
Some intuition about this distribution can be built by decomposing it into a
conditional Gaussian and an unconditional Gamma:

$$
\begin{align}
\mu | \tau & \sim \text{Gaussian}(\mu_0, n_0 \tau) \text{ and} \\
\tau & \sim \text{Gamma}(\alpha_0, \beta_0).
\end{align}
$$

The Gaussian–Gamma distribution is a conjugate prior for the Gaussian data
distribution with unknown mean and variance, assumed here. This means that the
posterior is also Gaussian–Gamma. Given a data set with $$n_1$$ observations
$$x_1, \dots, x_{n_1}$$, the mapping of the four parameters of the prior to
those of the posterior is as follows:[^1]

$$
\begin{align}
\mu_0 & \to \frac{n_0}{n_0 + n_1} \mu_0 + \frac{n_1}{n_0 + n_1} \mu_x, \\
n_0 & \to n_0 + n_1, \\
\alpha_0 & \to \alpha_0 + \frac{n_1}{2}, \text{ and} \\
\beta_0 & \to \beta_0 + \frac{1}{2} \left( \frac{n_0 \, n_1}{n_0 + n_1} (\mu_x - \mu_0)^2 + n_1 s^2_x \right)
\end{align}
$$

where $$\mu_x = \sum_{i = 1}^{n_1} x_i / n_1$$ and $$s^2_x = \sum_{i = 1}^{n_1}
(x_i - \mu_x)^2 / n_1$$.

# References

* Andrew Gelman et al., _[Bayesian Data Analysis][BDA]_, Chapman and Hall/CRC,
  2014.

# Footnotes

[^1]: “[Posterior distribution of the parameters][Wikipedia],” Wikipedia, 2020.

[BDA]: http://www.stat.columbia.edu/~gelman/book/
[Wikipedia]: https://en.wikipedia.org/wiki/Normal-gamma_distribution#Posterior_distribution_of_the_parameters
