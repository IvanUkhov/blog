---
layout: post
title: Sample size determination using historical data and simulation
date: 2019-09-25
math: true
keywords:
  - R
  - bootstrap
  - hypothesis testing
  - sample size determination
  - simulation
---

In order to test a hypothesis, one has to design and execute an adequate
experiment. Typically, it is neither feasible nor desirable to involve the whole
population. Instead, a relatively small subset of the population is studied, and
given the outcome for this small sample, relevant conclusions are drawn with
respect to the population. An important question to answer is then, What is the
minimal sample size needed for the experiment to succeed? In what follows, we
answer this question using solely historical data and computer simulation,
without invoking any classical statistical procedures.

Although, as we shall see, the ideas are straightforward, direct calculations
were impossible to perform before computers. To be able to answer this kind of
questions back then, statisticians developed mathematical theories in order to
approximate the calculations for specific situations. Since nothing else was
possible, these approximations and the various terms and conditions under which
they operate made up a large part of traditional textbooks and courses in
statistics. However, the advent of today’s computing power has enabled one to
estimate required sample sizes in a more direct and intuitive way, with the only
prerequisites being an understanding of statistical inference, the availability
of historical data describing the status quo, and the ability to write a few
lines of code in a programming language.

# Problem

For concreteness, consider the following scenario. We run an online business and
hypothesize that a specific change in promotion campaigns, such as making them
personalized, will have a positive effect on a specific performance metric, such
as the average deposit. In order to investigate if it is the case, we decide to
perform a two-sample test. There are the following two competing hypotheses.

* The null hypothesis postulates that the change has no effect on the metric.

* The alternative hypothesis postulates that the change has a positive effect on
  the metric.

There will be two groups: a control group and a treatment group. The former will
be exposed to the current promotion policy, while the latter to the new one.
There are also certain requirements imposed on the test. First, we have a level
of statistical significance $$\alpha$$ and a level of practical significance
$$\delta$$ in mind. The former puts a limit on the false-positive rate, and the
latter indicates the smallest effect that we still care about; anything smaller
is as good as zero for any practical purpose. In addition, we require the test
to have a prescribed false-negative rate $$\beta$$, ensuring that the test has
enough statistical power.

For our purposes, the test is considered well designed if it is capable of
detecting a difference as small as $$\delta$$ so that the false-positive and
false-negative rates are controlled to levels $$\alpha$$ and $$\beta$$,
respectively. Typically, parameters $$\alpha$$ and $$\delta$$ are held constant,
and the desired false-positive rate $$\beta$$ is attained by varying the number
of participants in each group, which we denote by $$n$$. Note that we do not
want any of the parameters to be smaller than the prescribed values, as it would
be wasteful.

So what should the sample size be for the test to be well designed?

# Solution

Depending on the distribution of the data and on the chosen metric, one might or
might not be able to find a suitable test among the standard ones, while
ensuring that the test’s assumptions can safely be considered satisfied. More
importantly, a textbook solution might not be the most intuitive one, which, in
particular, might lead to misuse of the test. It is the understanding that
matters.

Here we take a more pragmatic and rather general approach that circumvents the
above concerns. It requires only historical data and basic programming skills.
Despite its simplicity, the method below goes straight to the core of what the
famed statistical tests are doing behind all the math. The approach belongs to
the class of so-called bootstrap techniques and is as follows.

Suppose we have historical data on customers’ behavior under the current
promotion policy, which is commonplace in practice. An important realization is
that this data set represents what we expect to observe in the control group. It
is also what is expected of the treatment group provided that the null
hypothesis is true, that is, when the proposed change has no effect. This
realization enables one to simulate what would happen if each group was limited
to an arbitrary number of participants. Then, by varying this size parameter, it
is possible to find the smallest value that makes the test well designed, that
is, make the test satisfy the requirements on $$\alpha$$, $$\beta$$, and
$$\delta$$, as discussed in the previous section.

This is all. The rest is an elaboration of the above idea.

The simulation entails the following. To begin with, note that what we are
interested in testing is the difference between the performance metric applied
to the treatment group and the same metric applied to the control group, which
is referred to as the test statistic:

```
Test statistic = Metric(Treatment sample) - Metric(Control sample).
```

`Treatment sample` and `Control sample` stand for sets of observations, and
`Metric(Sample)` stands for computing the performance metric given such a
sample. For instance, each observation could be the total deposit of a customer,
and the metric could be the average value:

```
Metric(Sample) = Sum of observations / Number of observations.
```

Note, however, that it is an example; the metric can be arbitrary, and this is a
huge advantage of this approach to sample size determination based on data and
simulation.

Large positive values of the test statistic speak in favor of the treatment
(that is, the new promotion policy in our example), while those that are close
to zero suggest that the treatment is futile.

A sample of $$n$$ observations corresponding to the status quo (that is, the
current policy in our example) can be easily obtained by drawing $$n$$ data
points with replacement from the historical data:

```
Sample = Choose random with replacement(Data, N).
```

This expression is used for `Control sample` under both the null and alternative
hypotheses. As alluded to earlier, this is also how `Treatment sample` is
obtained under the null. Regarding the alternative hypothesis being true, one
has to express the hypothesized outcome as a distribution for the case of the
minimal detectable difference, $$\delta$$. The simplest and reasonable solution
is to sample the data again, apply the metric, and then adjust the result to
reflect the alternative hypothesis:

```
Metric(Choose random with replacement(Data, N)) + Delta.
```

Here, again, one is free to change the logic under the alternative according to
the situation at hand. For instance, instead of an additive effect, one could
simulate a multiplicative one.

The above is a way to simulate a single instance of the experiment under either
the null or alternative hypothesis; the result is a single value for the test
statistic. The next step is to estimate how the test statistic would vary if the
experiment was repeated many times in the two scenarios. This simply means that
the procedure should be repeated multiple times:

```
Repeat many times {
  Sample 1 = Choose random with replacement(Data, N)
  Sample 2 = Choose random with replacement(Data, N)
  Metric 1 = Metric(Sample 1)
  Metric 2 = Metric(Sample 2)
  Test statistic under null = Metric 1 - Metric 2

  Sample 3 = Choose random with replacement(Data, N)
  Sample 4 = Choose random with replacement(Data, N)
  Metric 3 = Metric(Sample 3) + Delta
  Metric 4 = Metric(Sample 4)
  Test statistic under alternative = Metric 3 - Metric 4
}
```

This yields a collection of values for the test statistic under the null
hypothesis and a collection of values for the test statistic under the
alternative hypothesis. Each one contains realizations from the so-called
sampling distribution in the corresponding scenario. The following figure gives
an illustration:

![](/assets/images/2019-09-25-bootstrap/sampling-distribution-1.svg)

The blue shape is the sampling distribution under the null hypothesis, and the
red one is the sampling distribution under the alternative hypothesis. We shall
come back to this figure shortly.

These two distributions of the test statistic are what we are after, as they
allow one to compute the false-positive rate and eventually choose a sample
size. First, given $$\alpha$$, the sampling distribution under the null (the
blue one) is used in order to find a value beyond which the probability mass is
equal to $$\alpha$$:

```
Critical value = Quantile([Test statistic under null], 1 - alpha).
```

`Quantile` computes the quantile specified by the second argument given a set of
observations. This quantity is called the critical value of the test. In the
figure above, it is denoted by a dashed line. When the test statistic falls to
the right of the critical value, we reject the null hypothesis; otherwise, we
fail to reject it. Second, the sampling distribution in the case of the
alternative hypothesis being true (the red one) is used in order to compute the
false-negative rate:

```
Attained beta = Mean([Test statistic under alternative < Critical value]).
```

It corresponds to the probability mass of the sampling distribution under the
alternative to the left of the critical value. In the figure, it is the red area
to the left of the dashed line.

The final step is to put the above procedure in an optimization loop that
minimizes the distance between the target and attained $$\beta$$’s with respect
to the sample size:

```
Optimize N until Attained beta is close to Target beta {
  Repeat many times {
    Test statistic under null = ...
    Test statistic under alternative = ...
  }
  Critical value = ...
  Attained beta = ...
}
```

This concludes the calculation of the size that the control and treatment groups
should have in order for the upcoming test in promotion campaigns to be well
designed in terms of the level of statistical significance $$\alpha$$, the
false-negative rate $$\beta$$, and the level of practical significance
$$\delta$$.

An example of how this technique could be implemented in practice can be found
in the appendix.

# Conclusion

In this article, we have discussed an approach to sample size determination that
is based on historical data and computer simulation rather than on mathematical
formulae tailored for specific situations. It is general and straightforward to
implement. More importantly, the technique is intuitive, since it directly
follows the narrative of null hypothesis significance testing. It does require
prior knowledge of the key concepts in statistical inference. However, this
knowledge is arguably essential for those who are involved in scientific
experimentation. It constitutes the core of statistical literacy.

# Acknowledgments

This article was inspired by a blog post authored by [Allen Downey] and a talk
given by [John Rauser]. I also would like to thank [Aaron Rendahl] for his
feedback on the introduction to the method presented here and for his help with
the implementation given in the appendix.

# References

* Allen Downey, “[There is only one test!][Allen Downey],” 2011.
* John Rauser, “[Statistics without the agonizing pain][John Rauser],” 2014.
* Joseph Lee Rodgers, “[The bootstrap, the jackknife, and the randomization
  test: A sampling taxonomy][Joseph Rodgers],” Multivariate Behavioral Research,
  2010.

# Appendix

The following listing shows an implementation of the bootstrap approach in R:


{% highlight r %}
library(tidyverse)

set.seed(42)

# Artificial data for illustration
observation_count <- 20000
data <- tibble(value = rlnorm(observation_count))

# Performance metric
metric <- mean
# Statistical significance
alpha <- 0.05
# False-negative rate
beta <- 0.2
# Practical significance
delta <- 0.1 * metric(data$value)

simulate <- function(sample_size, replication_count) {
  # Function for drawing a single sample of size sample_size
  run_one <- function() sample(data$value, sample_size, replace = TRUE)
  # Function for drawing replication_count samples of size sample_size
  run_many <- function() replicate(replication_count, { metric(run_one()) })

  # Simulation under the null hypothesis
  control_null <- run_many()
  treatment_null <- run_many()
  difference_null <- treatment_null - control_null

  # Simulation under the alternative hypothesis
  control_alternative <- run_many()
  treatment_alternative <- run_many() + delta
  difference_alternative <- treatment_alternative - control_alternative

  # Computation of the critical value
  critical_value <- quantile(difference_null, 1 - alpha)
  # Computation of the false-negative rate
  beta <- mean(difference_alternative < critical_value)

  list(difference_null = difference_null,
       difference_alternative = difference_alternative,
       critical_value = critical_value,
       beta = beta)
}

# Number of replications
replication_count <- 1000
# Interval of possible values for the sample size
search_interval <- c(1, 10000)
# Root finding to attain the desired value by varying the sample size
target <- function(n) beta - simulate(as.integer(n), replication_count)$beta
sample_size <- as.integer(uniroot(target, interval = search_interval)$root)
{% endhighlight %}



The illustrative figure shown in the solution section displays the sampling
distribution of the test statistic under the null and alternative for the sample
size found by this code snippet.

[Aaron Rendahl]: http://users.stat.umn.edu/~rend0020/
[Allen Downey]: http://allendowney.blogspot.com/2011/05/there-is-only-one-test.html
[John Rauser]: https://www.youtube.com/watch?v=5Dnw46eC-0o
[Joseph Rodgers]: https://doi.org/10.1207/S15327906MBR3404_2
