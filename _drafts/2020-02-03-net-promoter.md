---
layout: post
title: Bayesian inference of the net promoter score via multilevel regression with poststratification
date: 2020-02-03
math: true
keywords:
  - Bayesian statistics
  - R
  - Stan
  - brms
  - data science
  - multilevel modeling
  - net promoter score
  - poststratification
---

Customer surveys are naturally prone to biases. One prominent example is
participation bias, which arises when individuals decide not to respond to the
survey, and this pattern is not random. For instance, new customers might rely
less eagerly than those who are senior. This renders the obtained responses
unrepresentative of the target population. In this article, we shall tackle
participation bias for the case of the net promoter survey by means of
multilevel regression and poststratification.

More specifically, the discussion here is a sequel to “[A Bayesian approach to
the inference of the net promoter score][article],” where we built a
hierarchical model for inferring the net promoter score for an arbitrary
segmentation of a customer base. The reader is encouraged to skim over that
article to recall the mechanics of the score and the structure of the model that
was constructed. In that article, there was an assumption made that the sample
was representative of the population, which, as mentioned earlier, is often not
the case. In what follows, we mitigate this problem using a technique called
poststratification. The technique works by matching proportions observed in the
sample with those observed in the population with respect to several dimensions,
such as age, country, and gender. However, in order to be able to poststratify,
the model has to have access to all these dimensions at once, which the model
built earlier is not suited for. To enable this, we switch gears to multilevel
multinomial regression.

# Problem

Suppose the survey is to measure the net promoter score for a population that
consists of $$N$$ customers. The score is to be reported with respect to
individual levels of $$M$$ grouping factors where factor $$i$$ has $$m_i$$
levels, for $$i = 1, \dots, M$$. For instance, it might be important to know the
score for different age groups, in which case the factor would be the customer’s
age with levels such as 18–25, 26–35, and so on. This implies that, in total,
$$\sum_i m_i$$ scores have to be estimated.

Depending on the size of the business, one might or might not try to reach out
to all customers, except for those who have opted out of communications.
Regardless of the decision, the resulting sample size, which is denoted by
$$n$$, is likely to be substantially smaller than $$N$$, as the response rate is
typically low. Therefore, there is uncertainty about the opinion of those who
abstained or were not targeted.

More importantly, a random sample is desired; however, certain subpopulations of
customers might end up being significantly overrepresented due to participation
bias, driving the score astray. Let us quantify this concern. We begin by taking
the Cartesian product of the aforementioned $$M$$ factors. This results in $$K =
\prod_i m_i$$ distinct combinations of the factors’ levels, which are referred
to as cells in what follows. For each cell, the number of detractors, neutrals,
and promoters that have been observed in the sample are computed and denoted by
$$d_i$$, $$u_i$$, and $$p_i$$, respectively. The number of respondents in call
$$i$$ is then

$$
n_i = d_i + u_i + p_i \tag{1}
$$

for $$i = 1, \dots, K$$. For convenience, all counts are arranged in the
following matrix:

$$
y = \left(
\begin{matrix}
y_1 \\
\vdots \\
y_i \\
\vdots \\
y_K
\end{matrix}
\right)
= \left(
\begin{matrix}
d_1 & u_1 & p_1 \\
\vdots & \vdots & \vdots \\
d_i & u_i & p_i \\
\vdots & \vdots & \vdots \\
d_K & u_K & p_K
\end{matrix}
\right). \tag{2}
$$

Given $$y$$, the observed net promoter score for level $$j$$ of factor $$i$$ can
be evaluated as follows:

$$
\hat{s}_{ij} = 100 \times \frac{\sum_{k \in I_{ij}}(p_k - d_k)}{\sum_{k \in I_{ij}} n_k} \tag{3}
$$

where the hat emphasizes the fact that it is an estimate from the data, and
$$I_{ij}$$ is an index set traversing cells with factor $$i$$ set to level
$$j$$, which has the effect of marginalizing out other factors conditioned on
the chosen value of factor $$i$$, that is, on level $$j$$.

We can now compare $$n_i$$, computed according to Equation (1), with its
counterpart in the population (the total number of customers who belong to cell
$$i$$), which is denoted by $$N_i$$, taking into consideration the sample size
$$n$$ and the population size $$N$$. Problems occur when the ratios within one
or more of the following tuples largely disagree:

$$
\left(\frac{n_i}{n}, \frac{N_i}{N}\right) \tag{4}
$$

for $$i = 1, \dots, K$$. When this happens, the scores given by Equation (3) or
any analyses oblivious of this disagreement cannot be trusted, since they
misrepresent the population. (It should noted, however, that equality within
each tuple does not guarantee absence of participation bias, since there might
be other, potentially unobserved, dimensions along which there are deviations.)

The survey has been conducted, and there are deviations. What do we do with all
these responses that have come in? Should we discard and run a new survey,
hoping that, this time, it would be different?

# Solution

The fact that the sample covers only a fraction of the population is, of course,
no news, and the solution is standard: one has to infer the net promoter score
for the population given the sample and domain knowledge. This is what was done
in the [previous article][article] for one grouping factor. However, due to
participation bias, additional measures are needed as follows.

Taking inspiration from political science, we proceed in two steps.

1. Using an adequate model, $$K = \prod_i m_i$$ net promoter scores are
   inferred—one for each cell, that is, for each combination of the levels of
   the grouping factors.

2. The $$\prod_i m_i$$ “cell-scores” are combined to produce $$\sum_i m_i$$
   “level-scores”—one for each level of each factor. This is done in such a way
   that the contribution of each cell to the score is equal to the relative size
   of that cell in the population given by Equation (4).

Step 1 can, in principle, be undertaken by any model of choice. A prominent
candidate is multilevel multinomial regression, which is what we shall explore.
_Multilevel_ refers to having a hierarchical structure where parameters on a
higher level give birth to parameters on a lower level, which, in particular,
enables information exchange through a common ancestor. _Multinomial_ refers to
the distribution used for modeling the response variable. The family of
multinomial distributions is appropriate, since we work with counts of events
falling into one of several categories: promoters, neutrals, and detractors; see
Equation (2). The response for each cell is then as follows:

$$
y_i | \theta_i \sim \text{Multinomial}(n_i, \theta_i)
$$

where $$n_i$$ is given by Equation (1), and

$$\theta_i = \left\langle\theta^d_i, \theta^u_i, \theta^p_i\right\rangle$$

is a simplex (sums up to 1) of probabilities of the three categories.

Multinomial regression belongs to the class of generalized linear models. This
means that the inference takes place in a linear domain, and that $$\theta_i$$
is obtained by applying a deterministic transformation to the corresponding
linear model or models; the inverse of this transformation is known as the link
function. In the case of multinomial regression, the aforementioned
transformation is the softmax function, which is a generalization of the
logistic function allowing more than two categories:

$$
\theta_i = \text{Softmax}\left(\mu_i\right)
$$

where

$$
\mu_i = (0, \mu^u_i, \mu^p_i)
$$

is the average log-odds of the three categories with respect to a reference
category, which, by conventions, is taken to be the first category, that is,
detractors. The first entry is zero, since $$\text{logit}(1) = 0$$. Therefore,
there are only two linear models: one is for neutrals ($$\mu^u_i$$), and one is
for promoters ($$\mu^p_i$$).

Then

$$
\begin{align}
& y_i | \theta_i \sim \text{Multinomial}(n_i, \theta_i), \\
& \theta_i = \text{Softmax}\left(0, \mu^u_i, \mu^p_i\right), \\
& \mu^u_i = b^u + b^u_{\text{age}[i]}, \\
& \mu^p_i = b^p + b^p_{\text{age}[i]}, \\
& b^u \sim \text{Student’s t}(3, 0, 1), \\
& b^p \sim \text{Student’s t}(3, 0, 1), \\
& b^u_{\text{age}[i]} | \sigma^u_\text{age} \sim \text{Gaussian}(0, \sigma^u_\text{age}), \\
& b^p_{\text{age}[i]} | \sigma^p_\text{age} \sim \text{Gaussian}(0, \sigma^p_\text{age}), \\
& \sigma^u_\text{age} \sim \text{half-Student’s t}(3, 0, 1), \text{ and} \\
& \sigma^p_\text{age} \sim \text{half-Student’s t}(3, 0, 1).
\end{align}
$$

# Implementation

# Conclusion

# Acknowledgments

I also would like to thank [Paul-Christian Bürkner][paul] for his help with
understanding the `brms` package.

# References

* Andrew Gelman et al., “[Using multilevel regression and poststratification to
  estimate dynamic public opinion][MRT],” 2018.
* Andrew Gelman and Jennifer Hill, _[Data Analysis Using Regression and
  Multilevel/Hierarchical Models][MLM]_, Cambridge University Press, 2006.
* Andrew Gelman and Thomas Little, “[Poststratification into many categories
  using hierarchical logistic regression][MRP],” Survey Methodology, 1997.
* Paul-Christian Bürkner, “[brms: An R package for Bayesian multilevel models
  using Stan][brms],” Journal of Statistical Software, 2017.

[MLM]: https://doi.org/10.1017/CBO9780511790942
[MRP]: http://www.stat.columbia.edu/~gelman/research/published/poststrat3.pdf
[MRT]: http://www.stat.columbia.edu/~gelman/research/unpublished/MRT(1).pdf
[article]: /2019/08/19/net-promoter.html
[brms]: http://dx.doi.org/10.18637/jss.v080.i01
[paul]: https://paul-buerkner.github.io/
