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
y_i & \sim P, \text{ for } i = 1, \dots, n; \text{ and} \\
P & \sim \text{Dirichlet process}\left( \alpha \right).
\end{align}
$$

# Mixing prior

$$
\begin{align}
y_i & \sim \text{Gaussian}\left( \mu_i, \tau_i \right), \text{ for } i = 1, \dots, n; \\
(\mu_i, \tau_i) & \sim P, \text{ for } i = 1, \dots, n; \text{ and} \\
P & \sim \text{Dirichlet process}\left( \alpha \right).
\end{align}
$$
