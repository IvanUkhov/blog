---
layout: post
title: Heteroscedastic Gaussian process regression
date: 2020-06-22T08:00:00+02:00
math: true
stan: true
keywords:
  - Bayesian statistics
  - Gaussian process
  - R
  - Stan
  - data science
  - heteroscedasticity
  - regression
---



Gaussian process regression is a nonparametric Bayesian technique for modeling
relationships between variables of interest. The vast flexibility and rigor
mathematical foundation of this approach make it the default choice in many
problems involving small- to medium-sized data sets. In this article, we
illustrate how Gaussian process regression can be utilized in practice. To make
the case more compelling, we consider a setting where linear regression would be
inadequate. The focus will be _not_ on getting the job done as fast as possible
but on learning the technique and understanding the choices being made.

# Data

Consider the following example taken from [_Semiparametric
Regression_][Ruppert 2003] by Ruppert _et al._:



![](/assets/images/2020-06-22-gaussian-process/data-1.svg)

The figure shows 221 observations collected in a [light detection and
ranging][LIDAR] experiment. Each observation can be interpreted as the sum of
the true underlying response at the corresponding distance and random noise. It
can be clearly seen that the variance of the noise varies with the distance: the
spread is substantially larger toward the right-hand side. This phenomenon is
known as heteroscedasticity. Homoscedasticity (the absence of
heteroscedasticity) is one of the key assumptions of linear regression. Applying
linear regression to the above problem would yield suboptimal results. The
estimates of the regression coefficients would still be unbiased; however, the
standard errors of the coefficients would be incorrect and hence misleading. A
different modeling technique is needed in this case.

The above data set will be our running example. For formally and slightly more
generally, we assume that there is a data set of $$m$$ observations:

$$
\left\{
  (\mathbf{x}_i, y_i): \,
  \mathbf{x}_i \in \mathbb{R}^d; \,
  y_i \in \mathbb{R}; \,
  i = 1, \dots, m
\right\}
$$

where the independent variable, $$\mathbf{x}$$, is $$d$$-dimensional, and the
dependent variable, $$y$$, is scalar. In the running example, $$d$$ is 1, and
$$m$$ is 221. It is time for modeling.

# Model

To begin with, consider the following model with additive noise:

$$
y_i = f(\mathbf{x}_i) + \epsilon_i, \text{ for } i = 1, \dots, m. \tag{1}
$$

In the above, $$f: \mathbb{R}^d \to \mathbb{R}$$ represents the true but unknown
underlying function, and $$\epsilon_i$$ represents the perturbation of the
$$i$$th observation by random noise. In the classical linear-regression setting,
the unknown function is modeled as a linear combination of (arbitrary
transformations of) the $$d$$ covariates. Instead of assuming any particular
functional form, we put a Gaussian process prior on the function:

$$
f(\mathbf{x}) \sim \text{Gaussian Process}\left( 0, k(\mathbf{x}, \mathbf{x}') \right).
$$

The above notation means that, before observing any data, the function is a draw
from a Gaussian process with zero mean and a covariance function $$k$$. The
covariance function dictates the degree of correlation between two arbitrary
locations $$\mathbf{x}$$ and $$\mathbf{x}'$$ in $$\mathbb{R}^d$$. For instance,
a frequent choice for $$k$$ is the squared-exponential covariance function:

$$
k(\mathbf{x}, \mathbf{x}')
= \sigma_\text{process}^2 \exp\left( -\frac{\|\mathbf{x} - \mathbf{x}'\|_2^2}{2 \, \ell_\text{process}^2} \right)
$$

where $$\|\cdot\|_2$$ stands for the Euclidean norm, $$\sigma_\text{process}^2$$
is the variance (to see this, substitute $$\mathbf{x}$$ for $$\mathbf{x}'$$),
and $$\ell_\text{process}$$ is known as the length scale. While the variance
parameter is intuitive, the length-scale one requires an illustration. The
parameter controls the speed with which the correlation fades with the distance.
The following figure shows 10 random draws for $$\ell_\text{process} = 0.1$$:



![](/assets/images/2020-06-22-gaussian-process/prior-process-short-1.svg)

With $$\ell_\text{process} = 0.5$$, the behavior changes to the following:



![](/assets/images/2020-06-22-gaussian-process/prior-process-long-1.svg)

It can be seen that it takes a greater distance for a function with a larger
length scale (_top_) to change to the same extent compared to a function with a
smaller length scale (_bottom_).

Let us now return to Equation 1 and discuss the error terms, $$\epsilon_i$$. In
linear regression, they are modeled as independent identically distributed
Gaussian random variables:

$$
\epsilon_i \sim \text{Gaussian}\left( 0, \sigma_\text{noise}^2 \right),
\text{ for } i = 1, \dots, m. \tag{2}
$$

This is also the approach one can take with Gaussian process regression;
however, one does not have to. There are reasons to believe the problem at hand
is heteroscedastic, and it should be reflected in the model. To this end, the
magnitude of the noise is allowed to vary with the covariates:

$$
\epsilon_i | \mathbf{x}_i \sim \text{Gaussian}\left(0, \sigma^2_{\text{noise}, i}\right),
\text{ for } i = 1, \dots, m. \tag{3}
$$

The error terms are still independent (given the covariates) but not identically
distributed. At this point, one has to make a choice about the dependence of
$$\sigma_{\text{noise}, i}$$ on $$\mathbf{x}_i$$. This dependence could be
modeled with another Gaussian process with an appropriate link function to
ensure $$\sigma_{\text{noise}, i}$$ is nonnegative. Another reasonable choice is
a generalized linear model, which is what we shall use:

$$
\ln \sigma^2_{\text{noise}, i} = \alpha_\text{noise} + \boldsymbol{\beta}^\intercal_\text{noise} \, \mathbf{x}_i,
\text{ for } i = 1, \dots, m, \tag{4}
$$

where $$\alpha$$ is the intercept of the regression line, and
$$\boldsymbol{\beta} \in \mathbb{R}^d$$ contains the slopes.

Thus far, a model for the unknown function $$f$$ and a model for the noise have
been prescribed. In total, there are $$d + 3$$ parameters:
$$\sigma_\text{process}$$, $$\ell_\text{process}$$, $$\alpha_\text{noise}$$, and
$$\beta_{\text{noise}, i}$$ for $$i = 1, \dots, d$$. The first two are
positive, and the rest are arbitrary. The final piece is prior distributions for
these parameters.

The variance of the coveriance function, $$\sigma^2_\text{process}$$,
corresponds to the amount of variance in the data that is explained by the
Gaussian process. It poses no particular problem and can be tackled with a
half-Gaussian or a half-Student’s t distribution:

$$
\sigma_\text{process} \sim \text{Half-Gaussian}\left( 0, 1 \right).
$$

The notation means that the standard Gaussian distribution is truncated at zero
and renormalized. The nontrivial mass around zero implied by the prior is
considered to be beneficial in this case.[^1]

A prior for the length scale of the covariance function,
$$\ell_\text{process}$$, should be chosen with care. Small values—especially,
those below the resolution of the data—give the Gaussian process extreme
flexibility and easily leads to overfitting. Moreover, there are numerical
ramifications of the length scale approaching zero as well: the quality of
Hamiltonian Monte Carlo sampling degrades.[^2] The bottom line is that a prior
penalizing values close to zero is needed. A reasonable choice is an inverse
gamma distribution:

$$
\ell_\text{process} \sim \text{Inverse Gamma}\left( 1, 1 \right).
$$

To understand the implications, let us perform a prior predictive check for this
component in isolation:



![](/assets/images/2020-06-22-gaussian-process/prior-process-length-scale-1.svg)

It can be seen that the density is very low in the region close to zero, while
being rather permissive to the right of that region, especially considering the
scale of the distance in the data; recall the very first figure. Consequently,
the choice is adequate.

The choice of priors for the parameters of the noise is complicated by the
nonlinear link function; see Equation 4. What is important to realize is that
small amounts of noise correspond to negative values in the linear space, which
is probably what one should be expecting given the scale of the response.
Therefore, the priors should allow for large negative values. Let us make an
educated assumption and perform a prior predictive check to understand the
consequences. Consider the following:

$$
\begin{align}
\alpha_\text{noise} & \sim \text{Gaussian}\left( -1, 1 \right) \text{ and} \\
\beta_{\text{noise}, i} & \sim \text{Gaussian}\left( 0, 1 \right),
\text{ for } i = 1, \dots, d.\\
\end{align}
$$

The density of $$\sigma_\text{noise}$$ without considering the regression slopes
is depicted below (note the logarithmic scale on the horizontal axis):



![](/assets/images/2020-06-22-gaussian-process/prior-noise-sigma-1.svg)

The variability in the intercept, $$\alpha_\text{noise}$$, allows the standard
deviation, $$\sigma_\text{noise}$$, to comfortably vary from small to large
values, keeping in mind the scale of the response. Here are two draws from the
prior distribution of the noise, including Equations 3 and 4:



![](/assets/images/2020-06-22-gaussian-process/prior-noise-1.svg)

The large ones are perhaps unrealistic and could be addressed by further
shifting the distribution of the intercept. However, they should not cause
problems for the inference.

Putting everything together, the final model is as follows:

$$
\begin{align}
y_i
& = f(\mathbf{x}_i) + \epsilon_i,
\text{ for } i = 1, \dots, m; \\

f(\mathbf{x})
& \sim \text{Gaussian Process}\left( 0, k(\mathbf{x}, \mathbf{x}') \right); \\

k(\mathbf{x}, \mathbf{x}')
& = \sigma_\text{process}^2 \exp\left( -\frac{\|\mathbf{x} - \mathbf{x}'\|_2^2}{2 \, \ell_\text{process}^2} \right); \\

\epsilon_i | \mathbf{x}_i
& \sim \text{Gaussian}\left( 0, \sigma^2_{\text{noise}, i} \right),
\text{ for } i = 1, \dots, m; \\

\ln \sigma^2_{\text{noise}, i}
& = \alpha_\text{noise} + \boldsymbol{\beta}_\text{noise}^\intercal \, \mathbf{x}_i,
\text{ for } i = 1, \dots, m; \\

\sigma_\text{process}
& \sim \text{Half-Gaussian}\left( 0, 1 \right); \\

\ell_\text{process}
& \sim \text{Inverse Gamma}\left( 1, 1 \right); \\

\alpha_\text{noise}
& \sim \text{Gaussian}\left( -1, 1 \right); \text{ and} \\

\beta_{\text{noise}, i}
& \sim \text{Gaussian}\left( 0, 1 \right),
\text{ for } i = 1, \dots, d.\\
\end{align}
$$

This concludes the modeling part. The remaining two steps are to infer the
parameters and to make predictions using the posterior predictive distribution.

# Inference

The model is analytically intractable; one has to resort to sampling or
variational methods for inferring the parameters. We shall use Hamiltonian
Markov chain Monte Carlo sampling via [Stan]. The model can be seen in the
following listing, where the notation closely follows the one used throughout
the article:

```c
data {
  int<lower = 1> d;
  int<lower = 1> m;
  vector[d] x[m];
  vector[m] y;
}

transformed data {
  vector[m] mu = rep_vector(0, m);
  matrix[m, d] X;
  for (i in 1:m) {
    X[i] = x[i]';
  }
}

parameters {
  real<lower = 0> sigma_process;
  real<lower = 0> ell_process;
  real alpha_noise;
  vector[d] beta_noise;
}

model {
  matrix[m, m] K = cov_exp_quad(x, sigma_process, ell_process);
  vector[m] sigma_noise_squared = exp(alpha_noise + X * beta_noise);
  matrix[m, m] L = cholesky_decompose(add_diag(K, sigma_noise_squared));

  y ~ multi_normal_cholesky(mu, L);
  sigma_process ~ normal(0, 1);
  ell_process ~ inv_gamma(1, 1);
  alpha_noise ~ normal(-1, 1);
  beta_noise ~ normal(0, 1);
}
```

In the `parameters` block, one can find the $$d + 3$$ parameters identified
earlier. In regards to the `model` block, it is worth noting that there is no
any Gaussian process distribution in Stan. Instead, a multivariate Gaussian
distribution is utilized to model $$f$$ at $$\mathbf{X} = (\mathbf{x}_i)_{i =
1}^m \in \mathbb{R}^{m \times d}$$ and eventually $$\mathbf{y} = (y_i)_{i =
1}^m$$, which is for a good reason. Even though a Gaussian process is an
infinite-dimensional object, in practice, one always works with finite amounts
of data. For instance, in the running example, there are only 221 data points.
By definition, a Gaussian process is a stochastic process with the condition
that any finite collection of points from this process has a multivariate
Gaussian distribution. This fact combined with the conditional independence of
the process and the noise given the covariates yields the following and explains
the usage of a multivariate Gaussian distribution:

$$
\mathbf{y} | \mathbf{X}, \sigma_\text{process}, \ell_\text{process}, \alpha_\text{noise}, \boldsymbol{\beta}_\text{noise}
\sim \text{Multivariate Gaussian}\left( \mathbf{0}, \mathbf{K} + \mathbf{D} \right)
$$

where $$\mathbf{K} \in \mathbb{R}^{m \times m}$$ is a covariance matrix computed
by evaluating the covariance function $$k$$ at all pairs of locations in the
observed data, and $$\mathbf{D} = \text{diag}(\sigma^2_{\text{noise}, i})_{i =
1}^m \in \mathbb{R}^{m \times m}$$ is a diagonal matrix of the variances of the
noise at the corresponding locations.



After running the inference, the following posterior distributions are obtained:



![](/assets/images/2020-06-22-gaussian-process/posterior-parameters-1.svg)

The intervals are at the bottom of the densities are 66% and 95% equal-tailed
probability intervals, and the dots indicate the medians. Let us also take a
look at the 95% probability interval for the noise with respect to the distance:



![](/assets/images/2020-06-22-gaussian-process/posterior-predictive-noise-1.svg)

As expected, the variance of the noise increases with the distance.

# Prediction

Suppose there are $$n$$ locations $$\mathbf{X}_\text{new} =
(\mathbf{x}_{\text{new}, i})_{i = 1}^n \in \mathbb{R}^{n \times d}$$ where one
wishes to make predictions. Let $$\mathbf{f}_\text{new} \in \mathbb{R}^n$$ be
the values of $$f$$ at those locations. Assuming all the data and parameters
given, the joint distribution of $$\mathbf{y}$$ and $$\mathbf{f}_\text{new}$$ is
as follows:

$$
\left[
  \begin{matrix}
    \mathbf{y} \\
    \mathbf{f}_\text{new}
  \end{matrix}
\right]
\sim \text{Multivariate Gaussian}\left(
  \mathbf{0},
  \left[
    \begin{matrix}
      \mathbf{K} + \mathbf{D} & k(\mathbf{X}, \mathbf{X}_\text{new}) \\
      k(\mathbf{X}_\text{new}, \mathbf{X}) & k(\mathbf{X}_\text{new}, \mathbf{X}_\text{new})
    \end{matrix}
  \right]
\right)
$$

where, with a slight abuse of notation, $$k(\cdot, \cdot)$$ stands for a
covariance matrix computed by evaluating the covariance function $$k$$ at the
specified locations, which is analogous to $$\mathbf{K}$$. It is well known (see
[Rasmussen et al. 2006][Rasmussen 2006], for instance) that the marginal
distribution of $$\mathbf{f}_\text{new}$$ is a multivariate Gaussian with the
following mean vector and covariance matrix, respectively:

$$
\begin{align}
E(\mathbf{f}_\text{new})
& = k(\mathbf{X}_\text{new}, \mathbf{X})(\mathbf{K} + \mathbf{D})^{-1} \, \mathbf{y} \quad \text{and} \\
\text{cov}(\mathbf{f}_\text{new})
& = k(\mathbf{X}_\text{new}, \mathbf{X}_\text{new})
- k(\mathbf{X}_\text{new}, \mathbf{X})(\mathbf{K} + \mathbf{D})^{-1} k(\mathbf{X}, \mathbf{X}_\text{new}).
\end{align}
$$

The final component is the noise, as per Equation 1. The noise does not change
the mean of the multivariate Gaussian distribution but does magnify the
variance:

$$
\begin{align}
E(\mathbf{y}_\text{new})
& = k(\mathbf{X}_\text{new}, \mathbf{X})(\mathbf{K} + \mathbf{D})^{-1} \, \mathbf{y} \quad \text{and} \\
\text{cov}(\mathbf{y}_\text{new})
& = k(\mathbf{X}_\text{new}, \mathbf{X}_\text{new})
- k(\mathbf{X}_\text{new}, \mathbf{X})(\mathbf{K} + \mathbf{D})^{-1} k(\mathbf{X}, \mathbf{X}_\text{new})
+ \text{diag}(\sigma^2_\text{noise}(\mathbf{X}_\text{new}))
\end{align}
$$

where $$\text{diag}(\sigma^2_\text{noise}(\cdot))$$ stands for a diagonal matrix
composed of the noise variance evaluated at the specified locations, which is
analogous to $$\mathbf{D}$$.

Given a set of draws from the joint posterior distribution of the parameters and
the last two expressions, it is now straightforward to draw samples from the
posterior predictive distribution of the response: for each draw of the
parameters, one has to evaluate the mean vector and the covariance matrix and
sample the corresponding multivariate Gaussian distribution. The result is given
in the following figure:



![](/assets/images/2020-06-22-gaussian-process/posterior-predictive-heteroscedastic-1.svg)

The graph shows the mean value of the posterior predictive distribution given by
the black line along with a 95% equal-tailed probability band about the mean. It
can be seen that the uncertainty in the predictions is adequately captured along
the entire support. Naturally, the full predictive posterior distribution is
available at any location of interest.

Before we conclude, let us illustrate what would happen if the data were modeled
as having homogeneous noise. To this end, the variance of the noise is assumed
to be independent of the covariates, as in Equation 2. After repeating the
inference and prediction processes, the following is obtained:





![](/assets/images/2020-06-22-gaussian-process/posterior-predictive-homoscedastic-1.svg)

The inference is inadequate, which can be seen by the probability band: the
variance is largely overestimated on the left-hand side and underestimated on
the right-hand side. This justifies well the choice of heteroscedastic
regression presented earlier.

# Conclusion

In this article, it has been illustrated how a functional relationship can be
modeled using a Gaussian process as a prior. Particular attention has been
dedicated to adequately capturing error terms in the presence of
heteroscedasticity. In addition, a practical implementation has been discussed,
and the experimental results have demonstrated the appropriateness of this
approach.

For the curious reader, the source code of this [notebook] along with a number
of auxiliary [scripts], such as the definition of the model in Stan, can be
found on GitHub.

# Acknowledgments

I would like to thank [Mattias Villani] for the insightful and informative
graduate course in statistics titled “[Advanced Bayesian learning][Villani
2020],” which was the inspiration behind writing this article.

# References

* Carl Rasmussen _et al._, [_Gaussian Processes for Machine
  Learning_][Rasmussen 2006], the MIT Press, 2006.
* David Ruppert _et al._, [_Semiparametric Regression_][Ruppert 2003], Cambridge
  University Press, 2003.

# Footnotes

[^1]: “[Priors for marginal standard deviation][Stan 2020-standard-deviation],”
      Stan User’s Guide, 2020.

[^2]: “[Priors for length-scale][Stan 2020-length-scale],” Stan User’s Guide,
      2020.

[LIDAR]: https://en.wikipedia.org/wiki/Lidar
[Mattias Villani]: https://www.mattiasvillani.com/
[Rasmussen 2006]: http://www.gaussianprocess.org/gpml
[Ruppert 2003]: http://www.stat.tamu.edu/~carroll/semiregbook
[Stan 2020-length-scale]: https://mc-stan.org/docs/2_19/stan-users-guide/fit-gp-section.html#priors-for-length-scale
[Stan 2020-standard-deviation]: https://mc-stan.org/docs/2_19/stan-users-guide/fit-gp-section.html#priors-for-marginal-standard-deviation
[Stan]: https://mc-stan.org/
[Villani 2020]: https://github.com/mattiasvillani/AdvBayesLearnCourse

[notebook]: https://github.com/IvanUkhov/blog/blob/master/_posts/2020-06-22-gaussian-process.Rmd
[scripts]: https://github.com/IvanUkhov/blog/tree/master/_scripts/2020-06-22-gaussian-process
