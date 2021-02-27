---
layout: post
title: On Bayesian structural time series
date: 2021-06-01T08:00:00+01:00
math: true
keywords:
  - Bayesian statistics
  - TensorFlow
  - data science
  - structural time series
---

She sells seashells by the seashore.

A structural time series model is described via a pair of equations:

$$
\begin{align}
y_t & = Z^T_t \, \alpha_t + \epsilon_t \quad \text{and} \tag{1} \\
\alpha_{t + 1} & = T_t \, \alpha_t + R_t \, \eta_t \tag{2} \\
\end{align}
$$

where

$$
\begin{align}
\epsilon_t & \sim \text{Gaussian}(0, H_t) \text{ and} \\
\eta_t & \sim \text{Gaussian}(0, Q_t).
\end{align}
$$

# References

* Steven Scott and Hal Varian, “[Predicting the present with Bayesian structural
  time series][Scott (2014)],” International Journal of Mathematical Modelling
  and Numerical Optimisation, 2014.

[Scott (2014)]: https://research.google/pubs/pub41335/
