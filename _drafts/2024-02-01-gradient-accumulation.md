---
layout: post
title: Gradient accumuation
date: 2024-02-01T08:00:00+01:00
math: true
wide: true
keywords:
  - adam
  - machine learning
  - optimization
---

She sells seashells by the seashore.

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
