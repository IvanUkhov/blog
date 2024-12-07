---
layout: post
title: Kalman, Rauch, Tung, and Striebel walk into a bar
date: 2021-06-01T08:00:00+01:00
math: true
keywords:
  - Bayesian statistics
  - Kalman filter
  - Rauch–Tung–Striebel smoother
  - data science
---

She sells seashells by the seashore.

Consider the following linear dynamic system:

$$
\begin{align}
y_t & = H \, z_t + \epsilon \quad \text{and} \tag{1} \\
z_{t + 1} & = F \, z_t + \eta \tag{2} \\
\end{align}
$$

where

$$
\begin{align}
\epsilon & \sim \text{Gaussian}(0, R) \text{ and} \\
\eta & \sim \text{Gaussian}(0, Q).
\end{align}
$$

# References

* Jeffrey Miller. “[Lecture notes on advanced stochastic modeling][Miller
  (2016)],” Duke University, 2016.

[Miller (2016)]: https://jwmi.github.io/ASM/index.html
