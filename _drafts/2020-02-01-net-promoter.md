---
layout: post
title: Bayesian inference of the net promoter score via multilevel regression with poststratification
date: 2020-02-01
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

Customer surveys are naturally prone to participation bias, which arises when
individuals decide not to respond to the survey in question, and this pattern is
not random. An example could be new customers replying less eagerly than those
who are senior. This renders the collected sample of responses unrepresentative
of the target population. In this article, we shall tackle participation bias
for the case of the net promoter survey by means of multilevel Bayesian
regression and poststratification.

This article is a sequel to “[A Bayesian approach to the inference of the net
promoter score][article],” where we built a hierarchical model for inferring the
net promoter score for an arbitrary segmentation of a customer base. The reader
is encouraged to skim over that article in order to recall the mechanics of the
net promoter score and the structure of the model that was constructed. In the
previous article, we made the assumption that the sample was representative of
the population, which, as mentioned earlier, is often not the case. In this
article, we mitigate this problem using a technique called poststratification.
The technique works by matching proportions observed in the sample with those
observed in the population with respect to multiple dimensions, such as age
group, country, and gender. However, in order to be able to poststratify, the
model has to encompass all these dimensions, which the model built earlier is
not suitable for. To this end, we switch gears to multilevel multinomial
regression.

# Problem

Suppose the survey targets a population that consists of $$N$$ customers. Each
customer is described by $$M$$ categorical characteristics, such as demographics
and business-specific indicators. For instance, each person might be
characterized by their age group, gender, and subscription plan.

# Solution

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
& y_i | \theta_i \sim \text{Multinomial}(n_i, \theta_i), \\
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

# Implementation

# Conclusion

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
