---
layout: post
title: >-
  A poor man’s orchestration of predictive models, or do it yourself
date: 2019-01-01
---

As a data scientist focusing on developing data products, you naturally want
your work to reach its target audience. Suppose, however, that your company does
not have a dedicated engineering team for productionazing data-science code. One
solution is to seek help in other teams, which are surely busy with their own
endeavors, and spend months waiting. Alternatively, you could take the
initiative and do it yourself. In this article, we take the initiative and
schedule the training and application phases of a predictive model using Apache
[Airflow], Google [Compute Engine], and [Docker].

Let us first set expectations for what is assumed to be given and what will be
attained by the end of the article. It is assumed that a predictive model for
supporting business decisions—such as a model for identifying potential churners
or a model for estimating the lifetime value of customers—has already been
developed. This means that the business question to be answered has already been
defined and translated into a target variable, the data needed for answering the
question have already been collected and translated into a set of explanatory
variables, and a modeling technique has already been adequately selected and
applied in order to answering the question by predicting the target variable
given the explanatory variables. We also assume that the company at hand has
chosen Google Cloud Platform as their primary platform, which makes a certain
suite of tools readily available. Our goal is then to schedule the model to run
in the cloud so that it is being periodically retrained (in order to account for
potential fluctuations in the data distribution) and periodically applied (in
order to actually make predictions). Predictions are to be delivered to the data
warehouse for further consumption by other parties. In our case, the destination
is a data set in BigQuery.

The data warehouse is certainly not the end of the journey. However, I will stop
there and save the discussion about visualization, dashboards, and acting upon
predictions for another time.

Lastly, the following two repositories contain the code discussed below:

* [example-prediction] and
* [example-prediction-service].

# Preparing the model

For concreteness, suppose the model has been written in Python. In that case,
the repository of the project might look as follows:

```
.
├── prediction
│   ├── __init__.py
│   ├── main.py
│   ├── model.py
│   └── task.py
├── README.md
└── requirements.txt
```

Here [`prediction`] is a Python package, and it is likely to contain many more
files than the ones listed. The [`main`] file is the entry point for
command-line invocation, the [`task`] module defines the actions that the
package is capable of performing, and the [`model`] module defines the model.

As alluded to above, the primary job of the `main` file is to parse command-line
arguments, read a configuration file, potentially set up logging and alike and
delegate the rest the `task` module. At a later stage, an invocation of an
action might look as follows:

```bash
python -m prediction.main --action training --config configs/training.json
```

Here we are passing two arguments: `--action` and `--config`. The former is to
specify the action of interest, and the latter is to supply additional options.
Collecting everything in a single configuration file scales much better than
passing each option as a separate argument.

The `task` module is conceptually as follows (see the repository for the exact
implementation):

```python
class Task:

    def training(self):
        # Read the training data
        # Train the model
        # Save the trained model

    def application(self):
        # Read the application data
        # Load the trained model
        # Make predictions
        # Save the predictions
```

In this example, there are two tasks: training and application. The training
task is responsible for fetching the training data, training the model, and
saving the result in a predefined location for future usage by the application
task. The application task is responsible for fetching the application data
(that is, the data the model is supposed to be applied to), loading the trained
model produced by the training task, making predictions, and saving them in a
predefined location to be picked up for the subsequent delivery to the data
warehouse.

Likewise, the `model` module can be simplified as follows:

```python
class Model:

    def fit(self, data):
        # Estimate the model’s parameters

    def predict(self, data):
        # Make predictions using the estimated parameters
```

Incidentally, this interface resembles the one used by the `scikit-learn`
package.

# Wrapping the model into a service

Now it is time to turn the model into a service. In the scope of this article, a
service is a piece of code that can be executed in the cloud upon request.

# Scheduling the service

Having wrapped the model into a cloud service, let us now make both the training
and application phases to be executed periodically, promptly delivering
predictions to the data warehouse.

# Conclusion

Although the presented workflow gets the job done, it has its own limitations
and weaknesses, which one has to be aware of.

This leads me to a request for feedback. If you have any suggestions regarding
improving the workflow, please leave a comment below. I am particularly curious
to see if there is an elegant, robust solution to communicating with Docker
containers running in virtual machines in Compute Engine.

Thank you!

[Airflow]: https://airflow.apache.org/
[Compute Engine]: https://cloud.google.com/compute/
[Docker]: https://www.docker.com/

[example-prediction]: https://github.com/IvanUkhov/example-prediction
[example-prediction-service]: https://github.com/IvanUkhov/example-prediction-service

[`main`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/main.py
[`model`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/model.py
[`prediction`]: https://github.com/IvanUkhov/example-prediction/tree/master/prediction
[`task`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/task.py
