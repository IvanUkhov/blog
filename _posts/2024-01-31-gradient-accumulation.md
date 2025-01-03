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

Long story short, assuming TensorFlow 2.17:

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
        self._gradients = None

    @property
    def iterations(self) -> int:
        """Return the number of iterations."""
        return tf.keras.ops.floor_divide(self._iterations, self.accumulation)

    def apply_gradients(
        self, gradients_variables: list[tuple[tf.Tensor, tf.Tensor]]
    ) -> tf.Tensor:
        """Apply the gradients according to the accumulation scheme."""
        # Split off the gradients from the trainable variables.
        gradients, variables = zip(*list(gradients_variables))
        # Perform the initialization if needed.
        if not self.built:
            with tf.init_scope():
                self.build(variables)
        first = self._iterations % self.accumulation == 0
        last = (self._iterations + 1) % self.accumulation == 0
        # Add the new gradients to the old ones with resetting if needed.
        for sum, delta in zip(self._gradients, gradients):
            if delta is not None:
                sum.assign(tf.cast(~first, tf.float32) * sum + delta)
        # Apply the average accumulated gradients to the trainable variables.
        gradients = [gradient / self.accumulation for gradient in self._gradients]
        return super().apply_gradients(zip(gradients, variables))

    def update_step(
        self,
        gradient: tf.Tensor,
        variable: tf.Tensor,
        learning_rate: any,
    ) -> None:
        """Update the trainable variable with the gradient."""
        update_step = super().update_step
        last = (self._iterations + 1) % self.accumulation == 0
        # Allow the update to happen only at the end of each cycle.
        true = lambda: update_step(gradient, variable, learning_rate)
        tf.cond(last, true, lambda: None)

    def build(self, variables: list[tf.Tensor]) -> None:
        """Initialize the internal state."""
        super().build(variables)
        # Allocate memory for accumulation.
        self._gradients = [
            self.add_variable_from_reference(
                reference_variable=variable,
                name="gradient",
            )
            for variable in variables
        ]
```

It is important to note that the learning rate keeps on changing (if variable)
and the weights keep on decaying (if enabled) during accumulation. Therefore,
one should account for this when configuring the optimizer at hand.

One should also note that TensorFlow does support gradient accumulation as of
version 2.16, which is controlled by the `gradient_accumulation_steps` option of
Keras optimizers. However, it does not play well with distributed training
strategies, which will hopefully be rectified in the future.

# Acknowledgments

I would like to thank [André Pedersen], [Axel Roebel], and [Tor-Arne Nordmo] for
their help with the implementation.

[André Pedersen]: https://github.com/andreped
[Axel Roebel]: https://github.com/roebel
[Tor-Arne Nordmo]: https://github.com/tno123
