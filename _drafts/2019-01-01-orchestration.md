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
given the explanatory variables. For the sake of concreteness, the model is
assumed to be written in Python. We also assume that the company at hand has
chosen Google Cloud Platform as their primary platform, which makes a certain
suite of tools readily available.

Our goal is then to schedule the model to run in the cloud so that it is being
periodically retrained (in order to account for potential fluctuations in the
data distribution) and periodically applied (in order to actually make
predictions). Predictions are to be delivered to the data warehouse for further
consumption by other parties. In our case, the destination is a data set in
BigQuery.

The data warehouse is certainly not the end of the journey. However, I will stop
there and save the discussion about visualization, dashboards, and acting upon
predictions for another time.

Lastly, the following two repositories contain the code discussed below:

* [example-prediction] and
* [example-prediction-service].

# Preparing the model

The suggested structure of the repository hosting the model is as follows:

```
.
├── configs/
│   ├── application.json
│   └── training.json
├── prediction/
│   ├── __init__.py
│   ├── main.py
│   ├── model.py
│   └── task.py
├── README.md
└── requirements.txt
```

Here [`prediction/`] is a Python package, and it is likely to contain many more
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
specify the action of interest, and the latter is to supply additional
configuration parameters, such as the location of the training data and the
values of the model’s hyperparameters. Keeping all parameters in a separate
file, as opposed to hard-coding them, makes the code reusable, and passing them
all at once as a single file scales much better than passing each parameter as a
separate argument.

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

It can be seen that the structure presented above makes very few assumptions
about the model, which makes it generally applicable. It can also be easily
extended to accommodate other actions. For instance, one could have a separate
action for testing the model on unseen data.

Having structured the model as shown above, it can now be productionized, which
we discuss next.

# Wrapping the model into a service

Now it is time to turn the model into a service. In the scope of this article, a
service is a self-sufficient piece of code that can be executed in the cloud
upon request. To this end, another repository is created in order to keep
concerns separated. Specifically, the modeling code should not be mixed with the
code specific to a particular environment where the model happens to be
deployed. By convention, the name of the new repository is the same as the one
for the model except for the addition of the `-service` suffix. The suggested
structure of the repository is as follows:

```
.
├── container/
│   ├── Dockerfile
│   ├── run.sh
│   └── wait.sh
├── service/
│   ├── configs/
│   │   ├── application.json
│   │   └── training.json
│   ├── source/                # the first repository as a submodule
│   └── requirements.txt
├── scheduler/
│   ├── configs/
│   │   ├── application.json
│   │   └── training.json
│   ├── application.py         # a symlink to graph.py
│   ├── graph.py
│   └── training.py            # a symlink to graph.py
├── Makefile
└── README.md
```

The [`container/`] folder contains files for building a Docker image for the
service. The [`service/`] folder is the service itself, meaning that these files
will be present in the container and eventually executed. Lastly, the
[`scheduler/`] folder contain files for scheduling the service using Airflow.
The last one will be covered in the next section; here we focus on the first
two.

Let us start with `service/`. The first repository (the one discussed in the
previous section) is added to this second repository as a Git submodule living
in `service/source/`. This means that the model will essentially be embedded
into the service but will conveniently remain an independent entity. At all
times, the service contains a reference to a particular state (a particular
commit, potentially on a dedicated release branch) of the model, guaranteeing
that the desired version of the model is in production. However, when invoking
the model from the service, we might want to use a different set of
configuration files than the ones present in the first repository. To this end,
a service-specific version of the configuration files is created in
`service/configs/`. We might also want to install additional Python
dependencies; hence, there is a separate file with requirements.

Now it is time to containerize the service code by building a Docker image. The
relevant files are gathered in `container/`. The image build defined in
[`container/Dockerfile`] is as follows:

```docker
# Use a minimal Python image
FROM python:3.7-slim

# Install Google Cloud SDK as described in
# https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu

# Copy the service directory to the image
COPY service /service
# Copy the run script to the image
COPY container/run.sh /run.sh

# Install Python dependencies specific to the predictive model
RUN pip install --upgrade --requirement /service/source/requirements.txt
# Install Python dependencies specific to the service
RUN pip install --upgrade --requirement /service/requirements.txt

# Set the working directory to be the service directory
WORKDIR /service

# Set the entry point to be the run script
ENTRYPOINT /run.sh
```

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

[`container/`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/container
[`container/Dockerfile`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/container/Dockerfile
[`main`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/main.py
[`model`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/model.py
[`prediction/`]: https://github.com/IvanUkhov/example-prediction/tree/master/prediction
[`scheduler/`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/scheduler
[`service/`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/service
[`task`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/task.py
