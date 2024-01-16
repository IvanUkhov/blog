---
layout: post
title: Relative positional embedding for any attention mechanism
date: 2024-02-01T08:00:00+01:00
math: true
keywords:
  - large language models
  - machine learning
  - positional embedding
  - transformers
---

In [Shaw et al. (2018)], the authors introduce relative positional embedding for
self-attention in transformer models, and in [Huang et al. (2018)], the authors
present a memory efficient approach to calculating this embedding in decoder
blocks, in which the self-attention is causal. In this article, the approach is
generalized to any attention mechanism, should it be self or cross or full or
causal.

The classical attention is formalized as follows:

$$
A = \text{softmax}\left( \frac{QK^{T}}{\sqrt{d_h}} \right) V
$$

where $$K$$, $$V$$, and $$Q$$ are the keys, values, and queries, respectively.
The keys and values are of shape $$n_s \times n_h \times n_{t_1} \times d_h$$
where $$n_s$$ is the batch size (_s_ for space), $$n_h$$ is the number of
attention heads, $$n_{t_1}$$ is the window size (_t_ for time) of the _input_
sequence, and $$d_h$$ is the head size. The queries are of shape $$n_s \times
n_h \times n_{t_2} \times d_h$$ where $$n_{t_2}$$ is the window size of the
_output_ sequence.

The relative attention obtains one additional term in the numerator:

$$
A = \text{softmax}\left( \frac{QK^T + S}{\sqrt{d_h}} \right) V.
$$

In the above, $$S$$ is of shape $$n_s \times n_h \times n_{t_2} \times n_{t_1}$$
and calculated based on $$Q$$ and a matrix $$E$$ of shape $$d_h \times n_{t_3}$$
containing relative positional embeddings. The typical context is causal
self-attention, in which $$n_{t_3}$$ is thought of as the maximum allowed
relative distance between the keys and queries and set to $$n_{t_1}$$, with the
interpretation that the embeddings are running from position $$-n_{t_1} + 1$$
(the farthest past) up to $$0$$ (the present moment). Then $$S$$ is a specific
arrangement of the inner products between the queries in $$Q$$ and the
embeddings in $$E$$ so as to respect the arrangement in $$QK^T$$.

The direct and more memory efficient ways of calculating $$S$$ in the case of
causal attention, are compared in the illustration below, which is taken from
Huang et al. (2018).

![](/assets/images/2024-02-01-relative-position/huang.jpeg)

The matrix to the very right shows how $$S$$ is arranged. Since it is for the
case of causal attention, the upper triangle above the main diagonal (gray
circles) is irrelevant and can contain arbitrary values, which it does in the
algorithm proposed in Huang et al. (2018). The main diagonal (green circles)
contains the inner products of the queries and the embedding corresponding to
position $$0$$. The first subdiagonal (pink circles) contains the inner products
of the queries except for the first one as it has no past, and the embedding
corresponding to position $$-1$$. And it continues in this way down to
$$-n_{t_1} + 1$$, in which case it is only the last query that is involved,
since it comes last in the input sequence and has the longest past.

# References

* Huang et al., “[Music transformer: Generating music with long-term
  structure][Huang et al. (2018)],” Google Brain, 2018.
* Shaw et al., “[Self-attention with relative position representations][Shaw et
  al. (2018)],” Google Brain, 2018.

[Huang et al. (2018)]: https://arxiv.org/abs/1809.04281
[Shaw et al. (2018)]: https://arxiv.org/abs/1803.02155
