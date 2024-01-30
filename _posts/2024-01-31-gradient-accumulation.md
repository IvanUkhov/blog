---
layout: post
title: Out of memory, or gradient accumulation for larger models
date: 2024-01-31T08:00:00+01:00
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

Long story short:

```python
class CumulativeAdam(tf.keras.optimizers.Adam):
    """Optimizer that implement the Adam algorithm with gradient accumulation."""

    def __init__(self, accumulation: int = 1, **options) -> None:
        """Create an instance.

        Arguments:
          accumulation: The number of iteration to accumulate over. If it is
          set to one, no accumulation is performed, and the gradients are
          applied as soon as they are computed. If it is set to a value greater
          than one, the gradients will be accumulated for the specified number
          of iteration and only then applied, starting a new cycle.

        All other arguments are passed to `tf.keras.optimizers.Adam`.
        """
        super().__init__(**options)
        self.accumulation = accumulation
        self._gradients = None

    def apply_gradients(self, pairs: list[tuple[tf.Tensor, tf.Tensor]]) -> tf.Tensor:
        """Apply the gradients according to the accumulation scheme."""
        # Split off the gradients from the trainable variables.
        gradients, variables = zip(*list(pairs))
        # Perform the initialization if needed.
        self.build(variables)
        # Compute a scaling factor that will reset the accumulated gradients at
        # the beginning of each cycle and do nothing otherwise.
        scale = 1 - tf.cast(self.iterations % self.accumulation == 0, tf.float32)
        # Add the new gradients to the old ones after scaling.
        for gradient, addition in zip(self._gradients, gradients):
            gradient.assign(scale * gradient + addition)
        # Compute a scaling factor that will prevent the weights from updating
        # until the end of each cycle and do nothing otherwise.
        scale = tf.cast((self.iterations + 1) % self.accumulation == 0, tf.float32)
        # Apply the gradients to the trainable variables after scaling.
        gradients = [scale * gradient for gradient in self._gradients]
        return super().apply_gradients(zip(gradients, variables))

    def build(self, variables: list[tf.Tensor]) -> None:
        """Initialize the internal state for the given trainable variables."""
        super().build(variables)
        if self._gradients is None:
            # Allocate memory for accumulation.
            self._gradients = [
                tf.Variable(tf.zeros_like(variable), trainable=False)
                for variable in variables
            ]
```
