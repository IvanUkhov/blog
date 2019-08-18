---
layout: post
title: A Bayesian approach to the inference of the net promoter score
date: 2019-08-19
math: true
keywords:
  - Bayesian statistics
  - R
  - Stan
  - data science
  - net promoter score
javascript: >
  window.onload = function() {
    var keywords = ['data', 'model', 'parameters', 'transformed'];
    var types = ['real', 'simplex', 'vector'];
    document
      .querySelectorAll('.language-c .n')
      .forEach(function(element) {
        if (keywords.indexOf(element.innerText) != -1) {
          element.style.cssText = 'font-weight: 600';
        }
        if (types.indexOf(element.innerText) != -1) {
          element.className += ' kt';
        }
      });
  };
---

The net promoter score is a widely adopted metric for gauging customers’
satisfaction with a product. The popularity of the score is arguably attributed
to the simplicity of measurement and the intuitiveness of interpretation.
Moreover, it is claimed to be correlated with revenue growth, which, ignoring
causality, makes it even more appealing. In this article, we leverage Bayesian
inference in order to estimate the net promoter score for an arbitrary
segmentation of a customer base. The outcome of the inference is a distribution
over all possible values of the score weighted by probabilities, which provides
exhaustive information for the subsequent decision-making.

A bare-bones net promoter survey is composed of only one question: “How likely
are you to recommend us to a friend?” The answer is an integer ranging from 0 to
10 inclusively. If the grade is between 0 and 6 inclusively, the person in
question is said to be a detractor. If it is 7 or 8, the person is said to be a
neutral. Lastly, if it is 9 or 10, the person is deemed a promoter. The net
promoter score itself is then the percentage of promoters minus the percentage
of detractors. The minimum and maximum attainable values of the score are −100
and 100, respectively. In this case, the greater, the better.

As it is usually the case with surveys, a small but representative subset of
customers is reached out to, and the collected responses are then used to draw
conclusions about the target population of customers. Our objective is to
facilitate this last step by estimating the net promoter score given a set of
responses and necessarily quantify and put front and center the uncertainty in
our estimates.

Before we proceed, since a net promoter survey is an observational study, which
is prone to such biases as participation and response biases, great care must be
taken when analyzing the results. In this article, however, we focus on the
inference of the net promoter score under the assumption that the given sample
of responses is representative of the target population.

# Problem

In practice, one is interested to know the net promoter scope for different
subpopulations of customers, such as countries of operation and age groups,
which is the scenario that we shall target. To this end, suppose that there are
$$m$$ segments of interest, and each customer belongs to strictly one of them.
The results of a net promoter survey can then be summarized using the following
$$m \times 3$$ matrix:

$$
y = \left(
\begin{matrix}
d_1 & n_1 & p_1 \\
\vdots & \vdots & \vdots \\
d_i & n_i & p_i \\
\vdots & \vdots & \vdots \\
d_m & n_m & p_m
\end{matrix}
\right)
$$

where $$d_i$$, $$n_i$$, and $$p_i$$ denote the number of detractors, neutrals,
and promoters in segment $$i$$, respectively. For segment $$i$$, the _observed_
net promoter score can be computed as follows:

$$
\hat{s}_i = 100 \times \frac{p_i - d_i}{d_i + n_i + p_i}.
$$

However, this observed score is a single scalar value calculated using $$d_i +
n_i + p_i$$ data points, which is only a subset of the corresponding
subpopulation. It may or may not correspond well to the actual net promoter
score of that subpopulation. We have no reason to trust it, since the above
estimate alone does not tell us anything about the uncertainty associated with
it. Uncertainty quantification is essential for sound decision-making, which is
what we are after.

Ideally, for each segment, given the observed data, we would like to have a
distribution of all possible values of the score with probabilities attached.
Such a probability distribution would be exhaustive information, from which any
other statistic could be easily derived. Here we tackle the problem by means of
Bayesian inference, which we discuss next.

# Solution

In order to perform Bayesian inference of the net promoter score, we need to
decide on an adequate Bayesian model for the problem at hand. Recall first that
we are interested in inferring scores for several segments. Even though there
might be segment-specific variations in the product, such as special offers in
certain countries, or in customers’ perception of the product, such as
age-related preferences, it is conceptually the same product that the customers
were asked to evaluate. It is then sensible to expect the scores in different
segments to have something in common. With this in mind, we construct a
hierarchical model with parameters shared by the segments.

First, let

$$
\theta_i = (\theta_{id}, \theta_{in}, \theta_{ip}) \in \langle 0, 1 \rangle^3
$$

be a triplet of parameters corresponding to the proportion of detractors,
neutrals, and promoters in segment $$i$$, respectively, with the constraint that
they have to sum up to one. The constraint makes the triplet a simplex, which is
what is emphasized by the angle brackets on the right-hand side. These are the
main parameters we are interested in inferring. If the true value of
$$\theta_i$$ was known, the net promoter score would be computed as follows:

$$
\hat{s}_i = 100 \times (\theta_{ip} - \theta_{id}).
$$

Parameter $$\theta_i$$ can also be thought of as a vector of probabilities of
observing one of the three types of customers in segment $$i$$, that is,
detractors, neutrals, and promoters. Then the natural model for the observed
data is a multinomial distribution with $$d_i + n_i + p_i$$ trials and
probabilities $$\theta_i$$:

$$
y_i | \theta_i \sim \text{Multinomial}(d_i + n_i + p_i, \theta_i)
$$

where $$y_i$$ refers to the $$i$$th row of matrix $$y$$ introduced earlier. The
family of multinomial distributions is a generalization of the family of
binomial distributions to more than two outcomes.

The above gives a data distribution. In order to complete the modeling part, we
need to decide on a prior probability distribution for $$\theta_i$$. Each
$$\theta_i$$ is a simplex of probabilities. In such a case, a reasonable choice
is a Dirichlet distribution:

$$
\theta_i | \phi \sim \text{Dirichlet}(\phi)
$$

where $$\phi = (\phi_d, \phi_n, \phi_p)$$ is a vector of strictly positive
parameters. This family of distributions is a generalization of the family of
beta distributions to more than two categories. Note that $$\phi$$ is the same
for all segments, which is what enables information sharing. In particular, it
means that the less reliable estimates for segments with fewer observations will
be shrunk toward the more reliable estimates for segments with more
observations. In other words, with this architecture, segments with fewer
observations are able to draw strength from those with more observations.

How about $$\phi$$? This triplet is a characteristic of the product irrespective
of the segment. Its individual components can be utilized in order to encode
one’s prior knowledge about the net promoter score. Specifically, $$\phi_d$$,
$$\phi_n$$, and $$\phi_p$$ could be set to imaginary observations of detractors,
neutrals, and promoters, respectively, reflecting one’s beliefs prior to
conducting the survey. The higher these imaginary counts are, the more certain
one claims to be about the true score. One could certainly set these
hyperparameters to fixed values; however, a more comprehensive solution is to
infer them from the data as well, giving the model more flexibility by making it
hierarchical. In addition, an inspection of $$\phi$$ afterward can provide
insights into the overall satisfaction with the product.

We now need to specify a prior, or rather a hyperprior, for $$\phi$$. We proceed
under the assumption that we have little knowledge about the true score. Even if
there were surveys in the past, it is still a valid choice, especially when the
product evolves rapidly, rendering prior surveys marginally relevant.

Now, it is more convenient to think in terms of expected values and variances
instead of imaginary counts, which is what $$\phi$$ represents. Let us find an
alternative parameterization of the Dirichlet distribution. The expected value
of this distribution is as follows:

$$
\mu = (\mu_d, \mu_n, \mu_p) = \frac{\phi}{\phi_d + \phi_n + \phi_p} \in \langle 0, 1 \rangle^3.
$$

It can be seen that it is a simplex of proportions of detractors, neutrals, and
promoters of the whole population, which is similar to $$\theta_i$$ describing
segment $$i$$. Regarding the variance,

$$
\sigma^2 = \frac{1}{\phi_d + \phi_n + \phi_p}
$$

is considered to capture it sufficiently well. Solving the system of the last
two equations for $$\phi$$ yields the following result:

$$
\phi = \frac{\mu}{\sigma^2}.
$$

The prior for $$\theta_i$$ can then be rewritten as follows:

$$
\theta_i | \mu, \sigma \sim \text{Dirichlet}\left(\frac{\mu}{\sigma^2}\right).
$$

This new parameterization requires two hyperpriors: one is for $$\mu$$, and one
is for $$\sigma$$. For $$\mu$$, a reasonable choice is a uniform distribution
(over a simplex), and for $$\sigma$$, a half-Cauchy distribution:

$$
\begin{align}
& \mu \sim \text{Uniform}(\langle 0, 1 \rangle^3) \text{ and} \\
& \sigma \sim \text{half-Cauchy}(0, 1).
\end{align}
$$

The two distributions are relatively week, which is intended in order to let the
data speak for themselves. At this point, all parameters have been defined. Of
course, one could go further if the problem at hand had a deeper structure;
however, in this case, it is arguably not justifiable.

The final model is as follows:

$$
\begin{align}
y_i | \theta_i & \sim \text{Multinomial}(d_i + n_i + p_i, \theta_i), \\
\theta_i | \mu, \sigma & \sim \text{Dirichlet}(\mu / \sigma^2), \\
\mu & \sim \text{Uniform}(\langle 0, 1 \rangle^3), \text{ and} \\
\sigma & \sim \text{half-Cauchy}(0, 1).
\end{align}
$$

The posterior distribution factorizes as follows:

$$
p(\theta_1, \dots, \theta_m, \mu, \sigma | y) \propto
p(y | \theta_1, \dots, \theta_m) \,
p(\theta_1 | \mu, \sigma) \cdots
p(\theta_m | \mu, \sigma) \,
p(\mu) \,
p(\sigma),
$$

which relies on the usual assumption of independence given the parameters. One
could make a few simplifications by, for instance, leveraging the conjugacy of
the Dirichlet distribution with respect to the multinomial distribution;
however, it is not needed in practice, as we shall see shortly.

The above posterior distribution is our ultimate goal. It is the one that gives
us a complete picture of what the true net promoter score in each segment might
be given the available evidence, that is, the responses from the survey. All
that is left is to draw a large enough sample from this distribution and start
to summarize and visualize the results.

Unfortunately, as one might probably suspect, drawing samples from the posterior
is not an easy task. It does not correspond to any standard distribution and
hence does not have a readily available random number generator. Fortunately,
the topic is sufficiently mature, and there have been developed techniques for
sampling complex distributions, such as the family of Markov chain Monte Carlo
methods. Unfortunately, the most effective and efficient of these techniques are
notoriously complex themselves, and it might be extremely difficult and tedious
to implement and apply them correctly in practice. Fortunately, the need for
versatile tools for modeling and inference with the focus on the problem at hand
and not on implementation details has been recognized and addressed. Nontrivial
scenarios can be tackled with a surprisingly small amount of effort nowadays,
which we illustrate next.

# Implementation

In this section, we implement the model using the probabilistic programming
language [Stan]. Stan is straightforward to integrate into one’s workflow, as it
has interfaces for many general-purpose programming languages, including Python
and R. Here we only highlight the main points of the implementation and leave it
to the curious reader to discover Stan on their own.

The following listing is a complete implementation of the model:

```c
// The data
data {
  int<lower = 0> m; // The number of segments
  int<lower = 0> n; // The number of categories, which is always three
  int y[m, n]; // The observed counts of detractors, neutrals, and promoters
}

// The parameters of the model
parameters {
  simplex[n] mu;
  real<lower = 0> sigma;
  simplex[n] theta[m];
}

// The parameters that are derived using the above ones
transformed parameters {
  vector<lower = 0>[n] phi;
  phi = mu / sigma^2;
}

// The model
model {
  mu ~ uniform(0, 1);
  sigma ~ cauchy(0, 1);
  for (i in 1:m) {
    theta[i] ~ dirichlet(phi);
    y[i] ~ multinomial(theta[i]);
  }
}
```

It can be seen that the code is very laconic and follows closely the development
given in the previous section, including the notation. It is worth noting that,
in the model block, we seemingly use unconstrained uniform and Cauchy
distributions; however, the constraints are enforced by the definitions of the
corresponding hyperparameters, `mu` and `sigma`.

This is practically all that is needed; the rest will be taken care of by Stan,
which is actually a lot of work, including an adequate initialization, an
efficient execution, and necessary diagnostics and quality checks. Under the
hood, the sampling of the posterior in Stan is based on the Hamiltonian Monte
Carlo algorithm and the no-U-turn sampler, which are considered to be the
state-of-the-art.

The output of the sampling procedure is a set of draws from the posterior
distribution, which, again, is exhaustive information about the net promoter
score in the segments of interest. In particular, one can quantify the
uncertainty in and the probability of any statement one makes about the score.
For instance, if a concise summary is needed, one could compute the mean of the
score and accompany it with a high-posterior-density credible interval,
capturing the true value with the desired probability. However, if applicable,
the full distribution should be integrated into the decision-making process.

# Conclusion

In this article, we have constructed a hierarchical Bayesian model for inferring
the net promoter score for an arbitrary segmentation of a customer base. The
model features shared parameters, which enable information exchange between the
segments. This allows for a more robust estimation of the score, especially in
the case of segments with few observations. The final output of the inference is
a probability distribution over all possible values of the score in each
segment, which lays a solid foundation for the subsequent decision-making. We
have also seen how seamlessly the model can be implemented in practice using
modern tools for statistical inference, such as Stan.

Lastly, note that the presented model is only one alternative; there are many
other. How would _you_ model the net promoter score? What changes would you
make? Make sure to leave a comment.

# References

* Andrew Gelman et al., _[Bayesian Data Analysis][book]_, Chapman and Hall/CRC,
  2014.
* Andrew Gelman, “[Some practical questions about prior distributions][blog],”
  2009.

[Stan]: https://mc-stan.org/
[blog]: https://statmodeling.stat.columbia.edu/2009/10/21/some_practical/
[book]: http://www.stat.columbia.edu/~gelman/book/
