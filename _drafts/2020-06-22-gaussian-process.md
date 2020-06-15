---
layout: post
title: Heteroscedastic regression by virtue of Gaussian processes
date: 2020-06-22
math: true
keywords:
  - Bayesian statistics
  - Gaussian process
  - R
  - Stan
  - data science
  - heteroscedasticity
  - regression
---



The topic of the article is Gaussian process regression.

# Data

The data come from a [light detection and ranging experiment][LIDAR] taken from
[_Semiparametric Regression_][SR] by Ruppert _et al._ There are the
following 221 observations:



![](/assets/images/2020-06-22-gaussian-process/data-1.svg)

It can be clearly seen that the variance of the response, the log ratio, depends
on the distance. This phenomenon is known as heteroscedasticity. The absence of
heteroscedasticity is one of the core assumptions of linear regression.

# Acknowledgments

I would like to thank Mattias Villani.

# References

* Carl Rasmussen _et al._, [_Gaussian Processes for Machine
  Learning_][GPML], the MIT Press, 2006.

* David Ruppert _et al._, [_Semiparametric Regression_][SR], Cambridge
  University Press, 2003.

* Mattias Villani, “[Advanced Bayesian learning][ABL],” Stockholm
  University, 2020.

[ABL]: https://github.com/mattiasvillani/AdvBayesLearnCourse
[GPML]: http://www.gaussianprocess.org/gpml
[LIDAR]: https://en.wikipedia.org/wiki/Lidar
[SR]: http://www.stat.tamu.edu/~carroll/semiregbook
