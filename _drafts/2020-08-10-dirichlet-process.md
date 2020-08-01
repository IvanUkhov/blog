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
Gaussian distribution.

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
