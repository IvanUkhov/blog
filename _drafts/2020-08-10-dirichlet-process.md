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

A Dirichlet process is a stochastic process, that is, an indexed sequence of
random variables. Each realization of this process is a discrete probability
distribution, which makes the process a distribution over distributions,
similarly to a Dirichlet distribution. The process has only one parameter: the
measure $$\nu: \mathcal{B} \to [0, \infty]$$, which is a measure in a suitable
measure space $$(\mathcal{X}, \mathcal{B}, \nu)$$ where $$\mathcal{X}$$ is a
set, and $$\mathcal{B}$$ is a $$\sigma$$-algebra on $$\mathcal{X}$$. We shall
use the following notation:

$$
P \sim \text{Dirichlet Process}(\nu)
$$

where $$P$$ is a _random_ probability distribution that is distributed according
to the Dirichlet process. Note that measure $$\nu$$ does not have to be a
probability measure; that is, $$\nu(\mathcal{X}) = 1$$ is not required. In order
to obtain a probability measure, one can divide $$\nu$$ by the total volume
$$\nu_0 = \nu(\mathcal{X})$$:

$$
P_0(\cdot) = \frac{1}{\nu_0} \nu(\cdot).
$$

Given a data set of $$n$$ observations $$\{ x_i \}_{i = 1}^n$$, a Dirichlet
process can be used as a prior:

$$
\begin{align}
x_i | P & \sim P, \text{ for } i = 1, \dots, n; \text{ and} \\
P & \sim \text{Dirichlet Process}(\nu). \tag{1}
\end{align}
$$

It is important to realize that the $$x_i$$’s are assumed to be distributed
_not_ according to the Dirichlet process but according to a distribution drawn
from the Dirichlet process.

Due to the conjugacy property of the Dirichlet process, which substantially
simplifies the inference, the posterior is also a Dirichlet process as follows:

$$
P | \{ x_i \}_{i = 1}^n
\sim \text{Dirichlet Process}\left( \nu + \sum_{i = 1}^n \delta_{x_i} \right) \tag{2}
$$

where $$\delta_x(\cdot)$$ is the Dirac measure, meaning that $$\delta_x(X) = 1$$
if $$x \in X$$ for any $$X \subset \mathcal{X}$$, and it is zero otherwise. It
can be seen that the base measure has simply been augmented with unit masses
placed at the $$n$$ observed data points.

As noted earlier, a draw from a Dirichlet process is a discrete probability
distribution $$P$$. The probability measure of this distribution admits the
follow representation:

$$
P(\cdot) = \sum_{i = 1}^\infty p_i \delta_{x_i}(\cdot) \tag{3}
$$

where $$\{ p_i \}$$ is a set of probabilities that sum up to one, and $$\{ x_i
\}$$ is a set of points in $$\mathcal{X}$$.

A draw as shown in Equation (3) can be obtained using the so-called
stick-breaking construction, which prescribes $$\{ p_i \}$$ and $$\{ x_i \}$$.
To begin with, for practical computations, the infinite summation is truncated
to retain the only first $$m$$ elements:

$$
P(\cdot) = \sum_{i = 1}^m p_i \delta_{x_i}(\cdot).
$$

Atoms $$\{ x_i \}_{i = 1}^m$$ are drawn independently from the normalized base
measure $$P_0$$. The calculation of probabilities $$\{ p_i \}$$ is more
elaborate, and this is where the construction gets its name, “stick breaking.”
Specifically, we shall take an imaginary stick of length one, representing the
total probability, and keep breaking it into two parts where, for each
iteration, the left part yields $$p_i$$, and the right one, the remainder, is
carried over to the next iteration. How much to break off is decided on by
drawing $$m$$ independent realizations from a carefully chosen beta
distribution:

$$
q_i \sim \text{Beta}(1, \nu_0), \text{ for } i = 1, \dots, m. \tag{4}
$$

All of them lie in the unit interval and are the proportions to break off of the
remainder. Then the desired probabilities are given by the following expression:

$$
p_i = q_i \prod_{j = 1}^{i - 1} (1 - q_j), \text{ for } i = 1, \dots, m,
$$

which, as noted earlier, are the left parts of the remainder of the stick during
each iteration. For instance, $$p_1 = q_1$$, $$p_2 = q_2 (1 - q_1)$$, and so on.
Due to the truncation, the probabilities $$\{ p_i \}_{i = 1}^m$$ do not sum up
to one, and it is common to set $$q_m := 1$$ so that $$p_m$$ takes up the
remaining probability mass.

Now, let us complete the model by choosing a concrete measure:

$$
\nu(\cdot) = \nu_0 \, \text{Gaussian}(\, \cdot \, | \mu_0, \tau_0).
$$

In the above, $$\text{Gaussian}(\cdot)$$ refers to the probability measure of a
Gaussian distribution. In this case, we use the precision-based parameterization
of the Gaussian family of distributions where $$\tau_0$$ is the reciprocal of
the usual variance parameter. Multiplier $$\nu_0 = \nu(\mathcal{X}) > 0$$ is
there to allow us to control the total volume of the space implied by the
Dirichlet prior.

# Mixing prior

The model discussed in the previous section has a serious limitation: it assumes
a discrete probability distribution for the data-generating process, which can
be seen in the prior and posterior given in Equation (1) and (2), respectively,
and it is also apparent in the decomposition given in Equation (3). In some
cases, it might be appropriate; however, there is arguably more situations where
it is inadequate.

Instead of using a Dirichlet process as a direct prior for the given data, it
can be used as a prior for mixing distributions from a given family. The
resulting posterior will then naturally inherit the properties of the family,
such as continuity. The general form is as follows:

$$
\begin{align}
y_i | \theta_i & \sim P_1 \left( \theta_i \right), \text{ for } i = 1, \dots, n; \tag{5} \\
\theta_i | P_0 & \sim P_0, \text{ for } i = 1, \dots, n; \text{ and} \\
P_0 & \sim \text{Dirichlet Process}(\nu).
\end{align}
$$

To begin with, the $$i$$th data point, $$y_i$$, is distributed according to a
distribution $$P_1$$ with parameters $$\theta_i$$. For instance, $$P_1$$ could
refer to the Gaussian family with $$\theta_i = (\mu_i, \tau_i)$$, identifying a
particular member of the family by its mean and precision. Parameters $$\{
\theta_i \}_{i = 1}^n$$ are unknown and distributed according to a distribution
$$P_0$$. Distribution $$P_0$$ is not known either and gets a Dirichlet process
prior with measure $$\nu$$.

Similarly to Equation (3), we have the following decomposition:

$$
P_2(\cdot) = \sum_{i = 1}^\infty p_i P_0(\cdot | \theta_i) \tag{6}
$$

where $$P_2$$ is the probability measure of the mixture.

Unlike the previous model, there is no conjugacy in this case, and hence the
posterior is not a Dirichlet process. There is, however, a relatively simple
Markov chain Monte Carlo sampling strategy based on the stick-breaking
construction. It belongs to the class of Gibbs samplers and is as follows.

As before, the infinite decomposition in Equation (6) has to be made finite to
be usable in practice:

$$
P_2(\cdot) = \sum_{i = 1}^m p_i P_0(\cdot | \theta_i).
$$

Here, $$m$$ represents an upper limit on the number of mixture components. Each
data point $$x_i$$, for $$i = 1, \dots, n$$, is then mapped to one of the $$m$$
components, which we denote by $$k_i \in \{ 1, \dots, m \}$$. In other words,
$$k_i$$ takes values from 1 to $$m$$ and gives the index of the component that
the $$i$$th observation is mapped to. The Gibbs sampler has the following three
steps.

To set the stage, there are $$m + m \times |\theta| + n$$ parameters to be
inferred where $$|\theta|$$ denotes the number of parameters of $$P_1$$. These
parameters are $$\{ p_i \}_{i = 1}^m$$, $$\{ \theta_i \}_{i = 1}^m$$, and $$\{
k_i \}_{i = 1}^n$$. As usual in Gibbs sampling, the parameters assume random but
compatible initial values.

First, the mapping of the observations onto the mixture components, $$\{ k_i
\}$$, is updated as follows:

$$
k_i \sim \text{Categorical}\left(
  m,
  \left\{ \frac{p_j P_0(x_i | \theta_j)}{\sum_{l = 1}^m p_l P_0(x_i | \theta_l)} \right\}_{j = 1}^m
\right), \text{ for } i = 1, \dots, n.
$$

That is, each entry in $$k$$ is a draw from a categorical distribution with
$$m$$ categories whose unnormalized probabilities are given by $$p_j P_0(x_i |
\theta_j)$$, for $$j = 1, \dots, m$$.

Second, the probabilities of the mixture components, $$\{ p_i \}$$, are updated
using the stick-breaking construction described earlier. This time, however, the
beta distribution for sampling $$\{ q_i \}$$ in Equation (4) is replaced with
the following:

$$
q_i \sim \text{Beta}\left( 1 + n_i, \nu_0 + \sum_{j = i + 1}^m n_j \right), \text{ for } i = 1, \dots, m,
$$

where $$n_i$$ is the number of data points that are currently allocated to
component $$i$$. As before, in order for the $$p_i$$’s to sum up to one, it is
common to set $$q_m := 1$$.

Third.

(_Blocked_ refers to sampling multiple variables together from their joint
distribution as opposed to sampling them individually from the corresponding
conditional distributions.)

It can be seen in Equation (5) that each data point can potentially has its own
unique set of parameters. However, this is not what usually happens in practice.
Instead, many data points share the same parameters, which is akin to
clustering: the data come from a mixture of a handful of distributions.

For concreteness, consider the following choices:

$$
\begin{align}
\theta_i &= (\mu_i, \tau_i), \text{ for } i = 1, \dots, n; \\
P_1 (\theta_i) &= \text{Gaussian}(\mu_i, \tau_i), \text{ for } i = 1, \dots, n; \text{ and} \\
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
distribution with unknown mean and variance, which we assume here. This means
that the posterior is also Gaussian–gamma. Given a data set with $$n_1$$
observations $$x_1, \dots, x_{n_1}$$, the mapping of the four parameters of the
prior to those of the posterior is as follows:[^1]

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
* Rick Durrett, _[Probability: Theory and Examples][PTE]_, Cambridge University
  Press, 2010

# Footnotes

[^1]: “[Posterior distribution of the parameters][Wikipedia],” Wikipedia, 2020.

[BDA]: http://www.stat.columbia.edu/~gelman/book/
[PTE]: https://services.math.duke.edu/~rtd/PTE/pte.html
[Wikipedia]: https://en.wikipedia.org/wiki/Normal-gamma_distribution#Posterior_distribution_of_the_parameters
