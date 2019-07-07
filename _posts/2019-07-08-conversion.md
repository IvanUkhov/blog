---
layout: post
title: On the expected utility in conversion rate optimization
date: 2019-07-08
math: true
---

It can be not only extremely useful but also deeply satisfying to dust off one’s
math skills from time to time. In this article, we approach the classical
problem of conversion rate optimization—which is frequently faced by companies
operating online—and derive the expected utility of switching from variant A to
variant B under some modeling assumptions. This information can subsequently be
utilized in order to support the corresponding decision-making process.

An R implementation of the math below can be found in the following repository:

* [conversion-rate].

However, it was written for personal exploratory purposes and has no
documentation at the moment. If you decide to dive in, you will be on your own.

Lastly, this article is largely inspired by a series of excellent blog posts by
[Evan Miller], [Chris Stucchio], and [David Robinson], which are strongly
recommended.

# Problem

Suppose, as a business, you send communications to your customers in order to
increase their engagement with the product. Furthermore, suppose you suspect
that a certain change to the usual way of working might increase the uplift. In
order to test your hypothesis, you set up an A/B test. The only decision you
care about is whether or not you should switch from variant A to variant B where
variant A is the baseline (the usual way of working). The twist is that, from
the perspective of the business, variant B comes with its own gain if it is the
winner, and its own loss if it is the loser. The goal is to incorporate this
information in the final decision, making necessary assumptions along the way.

# Solution

Let $$A$$ and $$B$$ be two random variables modeling the conversion rates of the
two variants, variant A and variant B. Furthermore, let $$p$$ be the probability
density function of the joint distribution of $$A$$ and $$B$$. In what follows,
concrete values assumed by the variables are denoted by $$a$$ and $$b$$,
respectively.

Define the utility function as

$$
U(a, b) = G(a, b) I(a < b) + L(a, b) I(a > b)
$$

where $$G$$ and $$L$$ are referred to as the gain and loss functions,
respectively. The gain function takes effect when variant B has a higher
conversion rate than the one of variant A, and the loss function takes effect
when variant A is better than variant B, which is what is enforced by the two
indicator functions (the equality is not essential). The expected utility is
then as follows:

$$
\begin{align}
E(U(A, B))
&= \int_0^1 \int_0^1 U(a, b) p(a, b) \, db \, da \\
&=
\int_0^1 \int_a^1 G(a, b) p(a, b) \, db \, da +
\int_0^1 \int_0^a L(a, b) p(a, b) \, db \, da.
\end{align}
$$

We assume further the gain and loss are linear:

$$
\begin{align}
& G(a, b) = w_g (b - a) \text{ and} \\
& L(a, b) = w_l (b - a).
\end{align}
$$

In the above, $$w_g$$ and $$w_l$$ are two non-negative scaling factors, which
can be used to encode business preferences. Then we have that

$$
\begin{align}
E(U(A, B)) =
&
w_g \int_0^1 \int_a^1 b \, p(a, b) \, db \, da -
w_g \int_0^1 \int_a^1 a \, p(a, b) \, db \, da + {} \\
&
w_l \int_0^1 \int_0^a b \, p(a, b) \, db \, da -
w_l \int_0^1 \int_0^a a \, p(a, b) \, db \, da.
\end{align}
$$

For convenience, denote the four integrals by $$G_1$$, $$G_2$$, $$L_1$$, and
$$L_2$$, respectively, in which case we have that

$$
E(U(A, B)) = w_g \, G_1 - w_g \, G_2 + w_l \, L_1 - w_l \, L_2.
$$

Now, assume $$A$$ has a beta distribution with parameters $$\alpha_a$$ and
$$\beta_a$$, and $$B$$ has a beta distribution with parameters $$\alpha_b$$ and
$$\beta_b$$. In other words,

$$
\begin{align}
& A \sim \text{Beta}(\alpha_a, \beta_a) \text{ and} \\
& B \sim \text{Beta}(\alpha_b, \beta_b).
\end{align}
$$

In practice, these distributions are posterior distributions due to Bayesian
analysis. They combine the prior knowledge of the decision-maker and the
knowledge obtained from the data that is continuously streaming from the A/B
test. Assume further that, given the parameters, the variables are independent.
In this case,

$$
p(a, b) =
\frac{a^{\alpha_a - 1} (1 - a)^{\beta_a - 1}}{B(\alpha_a, \beta_a)}
\frac{b^{\alpha_b - 1} (1 - b)^{\beta_b - 1}}{B(\alpha_b, \beta_b)}.
$$

We can now compute the expected utility. The first integral is as follows:

$$
\begin{align}
G_1
&=
\int_0^1 \int_a^1
\frac{a^{\alpha_a - 1} (1 - a)^{\beta_a - 1}}{B(\alpha_a, \beta_a)}
\frac{b^{\alpha_b} (1 - b)^{\beta_b - 1}}{B(\alpha_b, \beta_b)} \, db \, da  \\
&=
\frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)}
\int_0^1 \int_a^1
\frac{a^{\alpha_a - 1} (1 - a)^{\beta_a - 1}}{B(\alpha_a, \beta_a)}
\frac{b^{\alpha_b} (1 - b)^{\beta_b - 1}}{B(\alpha_b + 1, \beta_b)} \, db \, da \\
&=
\frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)}
h(\alpha_a, \beta_a, \alpha_b + 1, \beta_b)
\end{align}
$$

where, which a slight abuse of notation, $$B$$ is the beta function and

$$
h(\alpha_1, \beta_1, \alpha_2, \beta_2) = P(X_1 < X_2)
$$

for any

$$
\begin{align}
& X_1 \sim \text{Beta}(\alpha_1, \beta_1) \text{ and} \\
& X_2 \sim \text{Beta}(\alpha_2, \beta_2).
\end{align}
$$

The function $$h$$ has an analytical expression that can be found in the blog
posts mentioned above. Similarly,

$$
G_2 =
\frac{B(\alpha_a + 1, \beta_a)}{B(\alpha_a, \beta_a)}
h(\alpha_a + 1, \beta_a, \alpha_b, \beta_b).
$$

Regarding the last two integrals in the expression of the utility function,

$$
\begin{align}
L_1
&=
\int_0^1 \int_0^a
\frac{a^{\alpha_a - 1} (1 - a)^{\beta_a - 1}}{B(\alpha_a, \beta_a)}
\frac{b^{\alpha_b} (1 - b)^{\beta_b - 1}}{B(\alpha_b, \beta_b)} \, db \, da  \\
&=
\frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)}
\int_0^1 \int_0^a
\frac{a^{\alpha_a - 1} (1 - a)^{\beta_a - 1}}{B(\alpha_a, \beta_a)}
\frac{b^{\alpha_b} (1 - b)^{\beta_b - 1}}{B(\alpha_b + 1, \beta_b)} \, db \, da \\
&=
\frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)}
h(\alpha_b + 1, \beta_b, \alpha_a, \beta_a).
\end{align}
$$

Also,

$$
L_2 =
\frac{B(\alpha_a + 1, \beta_a)}{B(\alpha_a, \beta_a)}
h(\alpha_b, \beta_b, \alpha_a + 1, \beta_a).
$$

Assembling the integrals together, we obtain

$$
\begin{align}
E(U(A, B)) =
& w_g \, \frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)}
h(\alpha_a, \beta_a, \alpha_b + 1, \beta_b) - {} \\
& w_g \, \frac{B(\alpha_a + 1, \beta_a)}{B(\alpha_a, \beta_a)}
h(\alpha_a + 1, \beta_a, \alpha_b, \beta_b) + {} \\
& w_l \, \frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)}
h(\alpha_b + 1, \beta_b, \alpha_a, \beta_a) - {} \\
& w_l \, \frac{B(\alpha_a + 1, \beta_a)}{B(\alpha_a, \beta_a)}
h(\alpha_b, \beta_b, \alpha_a + 1, \beta_a).
\end{align}
$$

It is worth noting that, in the case of the assumed linear model, we have the
following relationship between $$G$$ and $$L$$:

$$
\begin{align}
G_1 - G_2
&=
\frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)}
h(\alpha_a, \beta_a, \alpha_b + 1, \beta_b) -
\frac{B(\alpha_a + 1, \beta_a)}{B(\alpha_a, \beta_a)}
h(\alpha_a + 1, \beta_a, \alpha_b, \beta_b) \\
&=
\frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)}
(1 - h(\alpha_b + 1, \beta_b, \alpha_a, \beta_a)) -
\frac{B(\alpha_a + 1, \beta_a)}{B(\alpha_a, \beta_a)}
(1 - h(\alpha_b, \beta_b, \alpha_a + 1, \beta_a)) \\
&=
\frac{B(\alpha_b + 1, \beta_b)}{B(\alpha_b, \beta_b)} -
\frac{B(\alpha_a + 1, \beta_a)}{B(\alpha_a, \beta_a)} -
(L_1 - L_2) \\
&=
\Delta - (L_1 - L_2)
\end{align}
$$

where $$\Delta$$ is the different between the above two ratios of beta
functions. Therefore,

$$
\begin{align}
E(U(A, B))
&= w_g (G_1 - G_2) + w_l (L_1 - L_2) \\
&= w_g (G_1 - G_2) + w_l (\Delta - (G_1 - G_2)) \\
&= (w_g - w_l) (G_1 - G_2) + w_l \, \Delta.
\end{align}
$$

# Conclusion

The decision-maker is now well equipped to take the decision. Having done
Bayesian analysis and obtained the posterior distributions of the conversion
rates, the derived formula allows one to choose which variant to keep, while
taking the company’s preferences into account.

Please feel free to reach out if you have any thoughts or suggestions.

[conversion-rate]: https://github.com/IvanUkhov/conversion-rate

[Chris Stucchio]: https://www.chrisstucchio.com/blog/2014/bayesian_ab_decision_rule.html
[David Robinson]: http://varianceexplained.org/r/bayesian-ab-testing/
[Evan Miller]: http://www.evanmiller.org/bayesian-ab-testing.html
