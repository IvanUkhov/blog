---
layout: post
title: Bayesian inference of the net promoter score via multilevel regression with poststratification
date: 2020-02-01
math: true
---

She sells seashells by the seashore.

# Model

Let

$$
\begin{align}
& y_i = (y^d_i, y^n_i, y^p_i), \\
& \theta_i = (\theta^d_i, \theta^n_i, \theta^p_i), \text{ and} \\
& n_i = y^d_i + y^n_i + y^p_i.
\end{align}
$$

Then

$$
\begin{align}
& y_i \sim \text{Multinomial}(n_i, \theta_i), \\
& \theta_i = \text{Softmax}\left(0, \mu^n_i, \mu^p_i\right), \\
& \mu^n_i = b^n_0 + b^n_{\text{age}[i]}, \\
& \mu^p_i = b^p_0 + b^p_{\text{age}[i]}, \\
& b^n_0 \sim \text{Student’s t}(3, 0, 10), \\
& b^p_0 \sim \text{Student’s t}(3, 0, 10), \\
& b^n_{\text{age}[i]} | \sigma^n_\text{age} \sim \text{Gaussian}(0, \sigma^n_\text{age}), \\
& b^p_{\text{age}[i]} | \sigma^p_\text{age} \sim \text{Gaussian}(0, \sigma^p_\text{age}), \\
& \sigma^n_\text{age} \sim \text{half-Student’s t}(3, 0, 10), \text{ and} \\
& \sigma^p_\text{age} \sim \text{half-Student’s t}(3, 0, 10).
\end{align}
$$
