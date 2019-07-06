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

Before we proceed, this article is largely inspired by a series of excellent
blog posts by [Evan Miller], [Chris Stucchio], and [David Robinson].

Suppose, as a business, you send communications to your customers in order to
increase their engagement with the product. Furthermore, suppose you suspect
that a certain change to the usual way of working might increase the uplift.
In order to test your hypothesis, you set up an A/B test. The only decision you
care about is whether or not you should switch from A to B. The twist is that
each variant comes with its own utility, if it is the winner, and its own loss,
if it is the loser, from the perspective of the business, and you would like to
incorporate this information in your decision.

Let $$A$$ and $$B$$ be two random variable modeling the conversion rates of two
groups, group A and group B. Group A is considered to be the baseline.
Furthermore, let $$f$$ be the density function of the joint distribution of
$$A$$ and $$B$$. In what follows, concrete values assumed by the variables are
denoted by $$a$$ and $$b$$, respectively.

Define the utility function as

$$
U(a, b) = G(a, b) I(a < b) + L(a, b) I(a > b)
$$

where $$G$$ and $$L$$ are referred to as the gain and loss functions,
respectively. The gain function takes effect when group B has a higher
conversion rate than the one of group A, and the loss function takes effect when
group A is better than group B, which is what is enforced by the two indicator
functions. The expected utility is then as follows:

$$
\begin{align}
E(U(A, B))
&= \int_0^1 \int_0^1 U(a, b) f(a, b) \, db \, da \\
&=
\int_0^1 \int_a^1 G(a, b) f(a, b) \, db \, da +
\int_0^1 \int_0^a L(a, b) f(a, b) \, db \, da.
\end{align}
$$

Suppose the gain and loss are linear:

$$
\begin{align}
& G(a, b) = w_g (b - a) \text{ and} \\
& L(a, b) = w_l (b - a).
\end{align}
$$

In the above, $$w_g$$ and $$w_l$$ are two non-negative scaling factors. Then we
have that

$$
\begin{align}
E(U(A, B)) =
&
w_g \int_0^1 \int_a^1 b \, f(a, b) \, db \, da -
w_g \int_0^1 \int_a^1 a \, f(a, b) \, db \, da + {} \\
&
w_l \int_0^1 \int_0^a b \, f(a, b) \, db \, da -
w_l \int_0^1 \int_0^a a \, f(a, b) \, db \, da.
\end{align}
$$

For convenience, denote the four integrals by $$G_1$$, $$G_2$$, $$L_1$$, and
$$L_2$$, respectively, in which case we have that

$$
E(U(A, B)) = w_g \, G_1 - w_g \, G_2 + w_l \, L_1 - w_l \, L_2.
$$

Now, assume $$A$$ has a beta distribution with parameters $$\alpha_a$$ and
$$\beta_a$$; similarly, let $$B$$ has a beta distribution with parameters
$$\alpha_b$$ and $$\beta_b$$. Assume further that, given the parameters, the
variables are independent. In this case,

$$
f(a, b) =
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

where

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

Similarly,

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

Similarly,

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

It is worth noting that, in the case of this linear model, we have the following
relationship between $$G$$ and $$L$$:

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
\Delta - (L_1 - L_2).
\end{align}
$$

Therefore,

$$
\begin{align}
E(U(A, B))
&= w_g (G_1 - G_2) + w_l (L_1 - L_2) \\
&= w_g (G_1 - G_2) + w_l (\Delta - (G_1 - G_2)) \\
&= (w_g - w_l) (G_1 - G_2) + w_l \, \Delta.
\end{align}
$$

[Chris Stucchio]: https://www.chrisstucchio.com/blog/2014/bayesian_ab_decision_rule.html
[David Robinson]: http://varianceexplained.org/r/bayesian-ab-testing/
[Evan Miller]: http://www.evanmiller.org/bayesian-ab-testing.html
