---
layout: post
title: Out of memory, or gradient accumulation for larger models
date: 2024-02-01T08:00:00+01:00
math: true
wide: true
keywords:
  - adam
  - distributed systems
  - gradient
  - machine learning
  - optimization
---

When the model grows large and does not fit on a single device, the common
mitigation strategy is to reduce the batch size, thereby allowing more space for
the model at the expense of the data. However, smaller batches lead to noisier
weight updates, which is undesirable. One solution is gradient accumulation
where the weights are updated only after evaluating the gradients for several
batches. In this article, we show how it can be implemented in TensorFlow.

```python
class CumulativeAdam(tf.keras.optimizers.Adam):
    def __init__(self, accumulation: int = 1, **options) -> None:
        super().__init__(**options)
        self.accumulation = accumulation
        self._gradients = None

    def build(self, variables: list[tf.Tensor]) -> None:
        super().build(variables)
        if self._gradients is None:
            self._gradients = [
                tf.Variable(tf.zeros_like(variable), trainable=False)
                for variable in variables
            ]

    def apply_gradients(self, pairs: list[tuple[tf.Tensor, tf.Tensor]]) -> tf.Tensor:
        gradients, variables = zip(*list(pairs))
        self.build(variables)
        scale = 1 - tf.cast(self.iterations % self.accumulation == 0, tf.float32)
        for gradient, addition in zip(self._gradients, gradients):
            gradient.assign(scale * gradient + addition)
        scale = tf.cast((self.iterations + 1) % self.accumulation == 0, tf.float32)
        gradients = [scale * gradient for gradient in self._gradients]
        return super().apply_gradients(zip(gradients, variables))
```
