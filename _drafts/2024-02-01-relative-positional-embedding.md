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
present an efficient way of calculation this embedding in decoder blocks, in
which the self-attention is causal. In this article, the approach is generalized
to any attention mechanism, should it be self or cross or full or causal.

# References

* Huang et al., “[Music transformer: Generating music with long-term
  structure][Huang et al. (2018)],” Google Brain, 2018.
* Shaw et al., “[Self-attention with relative position representations][Shaw et
  al. (2018)],” Google Brain, 2018.

[Huang et al. (2018)]: https://arxiv.org/abs/1809.04281
[Shaw et al. (2018)]: https://arxiv.org/abs/1803.02155
