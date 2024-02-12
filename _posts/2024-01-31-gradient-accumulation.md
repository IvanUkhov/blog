---
layout: post
title: Out of memory, or gradient accumulation for larger models
date: 2024-01-31T08:00:00+01:00
math: true
wide: true
keywords:
  - Adam
  - TensorFlow
  - distributed systems
  - gradient
  - machine learning
  - optimization
---

When the model grows large and does not fit on a single device, and there are no
more devices to spare, the common mitigation strategy is to reduce the batch
size, thereby allowing more space for the model at the expense of the data.
However, smaller batches lead to noisier weight updates, which is undesirable.
One solution is gradient accumulation where the weights are updated after
evaluating the gradients for several batches at a time. In this article, we show
how it can be implemented in practice.

# Solution

Long story short:

```python
# Inherit from any optimizer of choice, such as Adam.
class Optimizer(tf.keras.optimizers.Adam):
    """Optimizer that implements gradient accumulation."""

    def __init__(self, accumulation: int = 1, **options) -> None:
        """Create an instance.

        Arguments:
          accumulation: The number of iterations to accumulate gradients over.
          If it is set to one, no accumulation is performed, and the gradients
          are applied as soon as they are computed. If it is set to a value
          greater than one, the gradients will be accumulated for the specified
          number of iterations and only then applied, starting a new cycle.

        All other arguments are passed to the base optimizer.
        """
        super().__init__(**options)
        self.accumulation = accumulation
        self._accumulation = None
        self._gradients = None

    def apply_gradients(
        self, gradients_variables: list[tuple[tf.Tensor, tf.Tensor]]
    ) -> tf.Tensor:
        """Apply the gradients according to the accumulation scheme."""
        # Split off the gradients from the trainable variables.
        gradients, variables = zip(*list(gradients_variables))
        # Perform the initialization if needed.
        with tf.init_scope():
            self.build(variables)
        first = self._accumulation % self.accumulation == 0
        last = (self._accumulation + 1) % self.accumulation == 0
        # Add the new gradients to the old ones with resetting if needed.
        for gradient, increment in zip(self._gradients, gradients):
            gradient.assign(tf.cast(~first, tf.float32) * gradient + increment)
        # Apply the average accumulated gradients to the trainable variables.
        gradients = [gradient / self.accumulation for gradient in self._gradients]
        super().apply_gradients(zip(gradients, variables))
        # Decrement the base counter incremented by the application if needed.
        self.iterations.assign_sub(tf.cast(~last, tf.int64))
        # Increment the accumulation counter.
        self._accumulation.assign_add(1)
        return self.iterations

    def update_step(self, gradient: tf.Tensor, variable: tf.Tensor) -> None:
        """Update the trainable variable with the gradient."""
        update_step = super().update_step
        # Allow the update to happen only at the end of each cycle.
        tf.cond(
            (self._accumulation + 1) % self.accumulation == 0,
            lambda: update_step(gradient, variable),
            lambda: None,
        )

    def build(self, variables: list[tf.Tensor]) -> None:
        """Initialize the internal state."""
        super().build(variables)
        if self._gradients is None:
            # Create a counter for tracking accumulation.
            self._accumulation = self.add_variable(shape=(), dtype=tf.int64)
            # Allocate memory for accumulation.
            self._gradients = [
                self.add_variable_from_reference(
                    model_variable=variable,
                    variable_name="gradient",
                )
                for variable in variables
            ]
```

It is important to note that the learning rate is _not_ held constant during
accumulation. However, since it is not expected to change much from one
iteration to another, it is an adequate simplification.

# Acknowledgments

I would like to thank [André Pedersen], [Axel Roebel], and [Tor-Arne Nordmo] for
their help with the implementation.

[André Pedersen]: https://github.com/andreped
[Axel Roebel]: https://github.com/roebel
[Tor-Arne Nordmo]: https://github.com/tno123
