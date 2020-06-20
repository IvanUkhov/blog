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
survey, and this pattern is not random. For instance, new customers might reply
less eagerly than those who are senior. This renders the obtained responses
unrepresentative of the target population. In this article, we tackle
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
individual values of $$M$$ grouping variables where variable $$i$$ has $$m_i$$
possible values, for $$i = 1, \dots, M$$. For instance, it might be important to
know the score for different age groups, in which case the variable would be the
customer’s age with values such as 18–25, 26–35, and so on. This implies that,
in total, $$\sum_i m_i$$ scores have to be estimated.

Depending on the size of the business, one might or might not try to reach out
to all customers, except for those who have opted out of communications.
Regardless of the decision, the resulting sample size, which is denoted by
$$n$$, is likely to be substantially smaller than $$N$$, as the response rate is
typically low. Therefore, there is uncertainty about the opinion of those who
abstained or were not targeted.

More importantly, a random sample is desired; however, certain subpopulations of
customers might end up being significantly overrepresented due to participation
bias, driving the score astray. Let us quantify this concern. We begin by taking
the Cartesian product of the aforementioned $$M$$ variables. This results in $$K
= \prod_i m_i$$ distinct combinations of the variables’ values, which are
referred to as cells in what follows. For each cell, the number of detractors,
neutrals, and promoters observed in the sample are computed and denoted by
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

Given $$y$$, the observed net promoter score for value $$j$$ of variable $$i$$
can be evaluated as follows:

$$
s^i_j = 100 \times \frac{\sum_{k \in I^i_j}(p_k - d_k)}{\sum_{k \in I^i_j} n_k} \tag{3}
$$

where $$I^i_j$$ is an index set traversing cells with variable $$i$$ set to
value $$j$$, which has the effect of marginalizing out other variables
conditioned on the chosen value of variable $$i$$, that is, on value $$j$$.

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
misrepresent the population. (It should be noted, however, that equality within
each tuple does not guarantee the absence of participation bias, since there
might be other, potentially unobserved, dimensions along which there are
deviations.)

The survey has been conducted, and there are deviations. What do we do with all
these responses that have come in? Should we discard and run a new survey,
hoping that, this time, it would be different?

# Solution

The fact that the sample covers only a fraction of the population is, of course,
no news, and the solution is standard: one has to infer the net promoter score
for the population given the sample and domain knowledge. This is what was done
in the [previous article][article] for one grouping variable. However, due to
participation bias, additional measures are needed as follows.

Taking inspiration from political science, we proceed in two steps.

1. Using an adequate model, $$K = \prod_i m_i$$ net promoter scores are
   inferred—one for each cell, that is, for each combination of the values of
   the grouping variables.

2. The $$\prod_i m_i$$ “cell-scores” are combined to produce $$\sum_i m_i$$
   “value-scores”—one for each value of each variable. This is done in such a
   way that the contribution of each cell to the score is equal to the relative
   size of that cell in the population given by Equation (4).

The two steps are discussed in the following two subsections.

## Modeling

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
\mu_i = \left(0, \mu^u_i, \mu^p_i\right)
$$

is the average log-odds of the three categories with respect to a reference
category, which, by conventions, is taken to be the first one, that is,
detractors. The first entry is zero, since $$\text{logit}(1) = 0$$. Therefore,
there are only two linear models: one is for neutrals ($$\mu^u_i$$), and one is
for promoters ($$\mu^p_i$$).

Now, there are many alternatives when it comes to the two linear parts. In this
article, we use the following architecture. Both the model for neutrals and the
one for promoters have the same structure, and for brevity, only the former is
described. For the log-odds of neutrals, the model is

$$
\mu^u_i = b^u + \sum_{j = 1}^M \delta^{uj}_{I_j[i]}
$$

where

$$
\delta^{uj} = \left(\delta^{uj}_1, \dots, \delta^{uj}_{m_j}\right)
$$

is a vector of deviations from intercept $$b^u$$ specific to grouping variable
$$j$$ (one entry for each value of the variable), and $$I_j[i]$$ yields the
index of the value that cell $$i$$ has, for $$i = 1, \dots, K$$ and $$j = 1,
\dots, M$$.

Let us now turn to the multilevel aspect. For each grouping variable, the
corresponding values, represented by the elements of $$\delta^{uj}$$, are
allowed to be different but assumed to have something in common and thus
originate from a common distribution. To this end, they are assigned
distributions with a shared parameter as follows:

$$
\delta^{uj}_i | \sigma^{uj} \sim \text{Gaussian}\left(0, \sigma^{uj}\right)
$$

for $$i = 1, \dots, m_j$$. The mean is zero, since $$\delta^{uj}_i$$ represents
a deviation.

Lastly, we have to decide on prior distributions of the intercept, $$b^u$$, and
the standard deviations, $$\sigma^{uj}$$ for $$j = 1, \dots, M$$. The intercept
is given the following prior:

$$
b^u \sim \text{Student’s t}(5, 0, 1).
$$

The mean is zero in order to center at even odds. Regarding the standard
deviations, they are given the following prior:

$$
\sigma^{uj} \sim \text{half-Student’s t}(5, 0, 1).
$$

In order to understand the implications of these prior choices, let us take a
look at the prior distribution assuming two grouping variables:



![](/assets/images/2020-02-03-net-promoter/prior-distribution-1.svg)

The left and right dashed lines demarcate tail regions that, for practical
purposes, can be thought of as “never” and “always,” respectively. For instance,
log-odds of five or higher are so extreme that detractors are rendered nearly
non-existent when compared to neutrals. These regions are arguably unrealistic.
The prior does not exclude these possibilities; however, it does not favor them
either. The vast majority of the probability mass is still in the middle around
zero.

The overall model is then as follow:

$$
\begin{align}
& y_i | \theta_i \sim \text{Multinomial}(n_i, \theta_i),
\text{ for } i = 1, \dots, K; \\
& \theta_i = \text{Softmax}\left(\mu_i\right),
\text{ for } i = 1, \dots, K; \\
& \mu_i = (0, \mu^u_i, \mu^p_i),
\text{ for } i = 1, \dots, K; \\
& \mu^u_i = b^u + \sum_{j = 1}^M \delta^{uj}_{I_j[i]},
\text{ for } i = 1, \dots, K; \\
& \mu^p_i = b^p + \sum_{j = 1}^M \delta^{pj}_{I_j[i]},
\text{ for } i = 1, \dots, K; \\
& b^u \sim \text{Student’s t}(5, 0, 1); \\
& b^p \sim \text{Student’s t}(5, 0, 1); \\
& b^{uj}_k | \sigma^{uj} \sim \text{Gaussian}\left(0, \sigma^{uj}\right),
\text{ for } j = 1, \dots, M \text{ and } k = 1, \dots, m_j; \tag{5a} \\
& b^{pj}_k | \sigma^{pj} \sim \text{Gaussian}\left(0, \sigma^{pj}\right),
\text{ for } j = 1, \dots, M \text{ and } k = 1, \dots, m_j; \tag{5b} \\
& \sigma^{uj} \sim \text{half-Student’s t}(5, 0, 1),
\text{ for } j = 1, \dots, M; \text{ and} \\
& \sigma^{pj} \sim \text{half-Student’s t}(5, 0, 1),
\text{ for } j = 1, \dots, M.
\end{align}
$$

The model has $$2 \times (1 + \sum_i m_i + M)$$ parameters in total. The
structure that can be seen in Equations (5a) and (5b) is what makes the model
multilevel. This is an important feature, since it allows for information
sharing between the individual values of the grouping variables. In particular,
this has a regularizing effect on the estimates, which is also known as
shrinkage resulting from partial pooling.

Having defined the model, the posterior distribution can now be obtained by
means of Markov chain Monte Carlo sampling. This procedure is standard and can
be performed using, for instance, Stan or a higher-level package, such as
[`brms`], which is what is exemplified in the Implementation section. The result
is a collection of draws of the parameters from the posterior distribution. For
each draw of the parameters, a draw of the net promoter score can be computed
using the following formula:

$$
s_i = 100 \times (\theta^p_i - \theta^d_i) \tag{6}
$$

for $$i = 1, \dots, K$$. This means that we have obtained a (joint) posterior
distribution of the net promoter score over the $$K$$ cells. It is now time to
combine the scores for the cells on the level of the values of the $$M$$
grouping variables, which results in $$\sum_i m_i$$ scores in total.

## Poststratification

Step 2 is poststratification, whose purpose is to correct for potential
deviations of the sample from the population; recall the discussion around
Equation (4). The foundation laid in the previous subsection makes the work here
straightforward. The idea is as follows. Each draw from the posterior
distribution consists of $$K$$ values for the net promoter score, one for each
cell. All one has to do in order to correct for a mismatch in proportions is to
take a weighted average of these scores where the weights are the counts
observed in the population:

$$
s^i_j = \frac{\sum_{k \in I^i_j} N_k \, s_k}{\sum_{k \in I^i_j} N_k}
$$

where $$I^i_j$$ is as in Equation (3), for $$i = 1, \dots, M$$ and $$j = 1,
\dots, m_i$$. The above gives a poststratified draw from the posterior
distribution of the net promoter score for variable $$i$$ and value $$j$$. In
practice, depending on the tool used, one might perform the poststratification
procedure differently, such as predicting counts of detractors, neutrals, and
promoters in the cells given their in-population sizes and then aggregating
those counts and following the definition of the net promoter score.

# Implementation

In what follows, we consider a contrived example with the sole purpose of
illustrating how the presented workflow can be implemented in practice. To this
end, we generate some data with two grouping variables, age and seniority, and
then perform inference using [`brms`], which leverages Stan under the hood. For
a convenient manipulation of posterior draws, [`tidybayes`] is used as well.

```r
library(brms)
library(tidybayes)
library(tidyverse)

set.seed(42)
options(mc.cores = parallel::detectCores())

# Load data
data <- load_data()
# => list(
# =>   population = tibble(age, seniority, cell_size),
# =>   sample = tibble(age, seniority, cell_size,
# =>                   cell_counts = (detractors, neutrals, promoters))
# => )

# Modeling
priors <- c(
  prior('student_t(5, 0, 1)', class = 'Intercept', dpar = 'muneutral'),
  prior('student_t(5, 0, 1)', class = 'Intercept', dpar = 'mupromoter'),
  prior('student_t(5, 0, 1)', class = 'sd', dpar = 'muneutral'),
  prior('student_t(5, 0, 1)', class = 'sd', dpar = 'mupromoter')
)
formula <- brmsformula(
  cell_counts | trials(cell_size) ~ (1 | age) + (1 | seniority))
model <- brm(formula, data$sample, multinomial(), priors,
             control = list(adapt_delta = 0.99), seed = 42)

# Poststratification
prediction <- data$population %>%
  add_predicted_draws(model) %>%
  spread(.category, .prediction) %>%
  group_by(age, .draw) %>%
  summarize(score = 100 * sum(promoter - detractor) / sum(cell_size)) %>%
  mean_hdi()
```

The final aggregation is given for age; it is similar for seniority. It can be
seen in the above listing that modern tools allow for rather complex ideas to be
expressed and explored in a very laconic way.

The curious reader is encouraged to run the above code. The appendix contains a
function for generating synthetic data. It should be noted, however, that `brms`
and `tidybayes` should be of versions greater than 2.11.1 and 2.0.1,
respectively, which, at the time of writing, are available for installation only
on GitHub. The appendix contains instructions for updating the packages.

# Conclusion

In this article, we have discussed a multilevel multinomial model for inferring
the net promoter score with respect to several grouping variables in accordance
with the business needs. It has been argued that poststratification is an
essential stage of the inference process, since it mitigates the deleterious
consequences of participation bias on the subsequent decision-making.

There are still some aspects that could be improved. For instance, there is a
natural ordering to the three categories of customers, detractors, neutrals, and
promoters; however, it is currently ignored. Furthermore, there is some
information thrown away when customer-level scores, which range from zero to
ten, are aggregated on the category level. Lastly, the net promoter survey often
happens in periodic waves, which calls for a single model capturing and learning
from changes over time.

# Acknowledgments

I would like to thank [Andrew Gelman] for the guidance on multilevel modeling
and [Paul-Christian Bürkner] for the help with understanding the `brms` package.

# References

* Andrew Gelman et al., “[Using multilevel regression and poststratification to
  estimate dynamic public opinion][MRT],” 2018.
* Andrew Gelman and Jennifer Hill, _[Data Analysis Using Regression and
  Multilevel/Hierarchical Models][MLM]_, Cambridge University Press, 2006.
* Andrew Gelman and Thomas Little, “[Poststratification into many categories
  using hierarchical logistic regression][MRP],” Survey Methodology, 1997.
* Paul-Christian Bürkner, “[brms: An R package for Bayesian multilevel models
  using Stan][brms],” Journal of Statistical Software, 2017.

# Appendix

The following listing defines a function that makes the illustrative example
given in the Implementation section self-sufficient. By default, the population
contains one million customers, and the sample contains one percent. There are
two grouping variables: age with six values and seniority with seven values.

```r
load_data <- function(N = 1000000, n = 10000) {
  softmax <- function(x) exp(x) / sum(exp(x))

  # Age
  age_values <- c('18–25', '26–35', '36–45', '46–55', '56–65', '66+')
  age_probabilities <- softmax(c(2, 3, 3, 2, 2, 1))

  # Seniority
  seniority_values <- c('6M', '1Y', '2Y', '3Y', '4Y', '5Y', '6Y+')
  seniority_probabilities <- softmax(c(3, 2, 2, 2, 1, 1, 1))

  # Score
  score_values <- seq(0, 10)
  score_probabilities <- softmax(c(1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4))

  # Generate a population
  population <- tibble(age = sample(age_values, N,
                                    prob = age_probabilities,
                                    replace = TRUE),
                       seniority = sample(seniority_values, N,
                                          prob = seniority_probabilities,
                                          replace = TRUE))

  # Take a sample from the population
  sample <- population %>%
    sample_n(n) %>%
    mutate(score = sample(score_values, n,
                          prob = score_probabilities,
                          replace = TRUE)) %>%
    mutate(category = case_when(score < 7 ~ 'detractor',
                                score > 8 ~ 'promoter',
                                TRUE ~ 'neutral'))

  # Summarize the population
  population <- population %>%
    group_by(age, seniority) %>%
    count(name = 'cell_size')

  # Summarize the sample
  sample <- sample %>%
    group_by(age, seniority) %>%
    summarize(detractors = sum(category == 'detractor'),
              neutrals = sum(category == 'neutral'),
              promoters = sum(category == 'promoter')) %>%
    mutate(cell_size = detractors + neutrals + promoters)

  # Bind counts of neutrals, detractors, and promoters (needed for brms)
  sample$cell_counts <- with(sample, cbind(detractors, neutrals, promoters))
  colnames(sample$cell_counts) <- c('detractor', 'neutral', 'promoter')

  # Remove unused columns
  sample <- sample %>% select(-detractors, -neutrals, -promoters)

  list(population = population, sample = sample)
}
```

Lastly, the following snippet shows how to update `brms` and `tidybayes` from
GitHub:

```r
if (packageVersion('brms') < '2.11.2') {
  remotes::install_github('paul-buerkner/brms', upgrade = 'never')
}

if (packageVersion('tidybayes') < '2.0.1.9000') {
  remotes::install_github('mjskay/tidybayes', upgrade = 'never')
}
```

[Andrew Gelman]: http://www.stat.columbia.edu/~gelman/
[MLM]: https://doi.org/10.1017/CBO9780511790942
[MRP]: http://www.stat.columbia.edu/~gelman/research/published/poststrat3.pdf
[MRT]: http://www.stat.columbia.edu/~gelman/research/unpublished/MRT(1).pdf
[Paul-Christian Bürkner]: https://paul-buerkner.github.io/
[`brms`]: https://github.com/paul-buerkner/brms
[`tidybayes`]: https://github.com/mjskay/tidybayes
[article]: /2019/08/19/net-promoter.html
[brms]: http://dx.doi.org/10.18637/jss.v080.i01
