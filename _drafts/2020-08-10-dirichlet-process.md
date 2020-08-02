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
P & \sim \text{Dirichlet Process}(\nu).
\end{align}
$$

A draw from a Dirichlet process is a discrete probability distribution $$P$$.
The probability measure of this distribution admits the follow representation:

$$
P(\cdot) = \sum_{i = 1}^\infty p_i \delta_{x_i}(\cdot) \tag{1}
$$

where $$\{ p_i \}$$ is a set of probabilities that sum up to one; $$\{ x_i \}$$
is a set of points in $$\mathcal{X}$$; and $$\delta_x(\cdot)$$ is the Dirac
measure, meaning that $$\delta_x(X) = 1$$ if $$x \in X$$ for any $$X \subset
\mathcal{X}$$, and it is zero otherwise.

A draw from a Dirichlet process, as in Equation (1), can be obtained using the
so-called stick-breaking construction, which prescribes $$\{ p_i \}$$ and $$\{
x_i \}$$. To begin with, for practical computations, the infinite summation is
to be truncated to retain the only first $$m$$ elements:

$$
P(\cdot) = \sum_{i = 1}^m p_i \delta_{x_i}(\cdot).
$$

Then atoms $$\{ x_i \}_{i = 1}^m$$ are drawn independently from the normalized
base measure

$$
P_0(\cdot) = \frac{\nu(\cdot)}{\nu_0}
$$

where $$\nu_0 = \nu({\mathcal{X})}$$, which is the total volume, making $$P_0$$
a probability distribution.

The calculation of probabilities $$\{ p_i \}$$ is more elaborate, and this is
where the construction gets its name, “stick breaking.” Specifically, we shall
take an imaginary stick of length 1, representing the total probability, and
keep breaking it into two parts where, for each iteration, the left part yields
$$p_i$$, and the right one, the remainder, is carried over to the next
iteration. How much to break off is decided on by drawing $$m$$ independent
realizations from a carefully chosen beta distribution:

$$
q_i \sim \text{Beta}(1, \nu_0) \text{ for } i = 1, \dots, m.
$$

All of them lie in the unit interval and are the proportions to break off of the
remainder. Then the desired probabilities are given by the following expression:

$$
p_i = q_i \prod_{j = 1}^{i - 1} (1 - q_j) \text{ for } i = 1, \dots, m,
$$

which, as noted earlier, are the left parts of the remainder of the stick during
each iteration. For instance, $$p_1 = q_1$$, $$p_2 = q_2 (1 - q_1)$$, and so on.
Due to the truncation, the probabilities $$\{ p_i \}_{i = 1}^m$$ do not sum up
to one, and it is common to set $$q_m = 1$$ so that $$p_m$$ takes up the
remaining probability mass.

Let

$$
\nu(\cdot) = \nu_0 \, \text{Gaussian}(\, \cdot \, | \mu_0, \tau_0).
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
P_\theta & \sim \text{Dirichlet Process}(\nu).
\end{align}
$$

Let

$$
\begin{align}
\theta_i &= (\mu_i, \tau_i), \text{ for } i = 1, \dots, n; \\
P_y (\theta_i) &= \text{Gaussian}(\mu_i, \tau_i), \text{ for } i = 1, \dots, n; \text{ and} \\
\nu(\cdot) &= \nu_0 \, \text{Gaussian–Gamma}(\, \cdot \, | \mu_0, n_0, \alpha_0, \beta_0).
\end{align}
$$

In the above, $$\text{Gaussian–Gamma}(\cdot)$$ refers to the probability measure
of a Gaussian–gamma distribution, which is bivariate, as desired in this case.
Some intuition about this distribution can be built by decomposing it into a
conditional Gaussian and an unconditional gamma:

$$
\begin{align}
\mu | \tau & \sim \text{Gaussian}(\mu_0, n_0 \tau) \text{ and} \\
\tau & \sim \text{Gamma}(\alpha_0, \beta_0).
\end{align}
$$

The Gaussian–gamma distribution is a conjugate prior for the Gaussian data
distribution with unknown mean and variance, assumed here. This means that the
posterior is also Gaussian–gamma. Given a data set with $$n_1$$ observations
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
