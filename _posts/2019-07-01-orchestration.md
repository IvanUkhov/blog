---
layout: post
title: A poor man’s orchestration of predictive models, or do it yourself
date: 2019-07-01
---

As a data scientist focusing on developing data products, you naturally want
your work to reach its target audience. Suppose, however, that your company does
not have a dedicated engineering team for productizing data-science code. One
solution is to seek help in other teams, which are surely busy with their own
endeavors, and spend months waiting. Alternatively, you could take the
initiative and do it yourself. In this article, we take the initiative and
schedule the training and application phases of a predictive model using Apache
[Airflow], Google [Compute Engine], and [Docker].

Let us first set expectations for what is assumed to be given and what will be
attained by the end of this article. It is assumed that a predictive model for
supporting business decisions—such as a model for identifying potential churners
or a model for estimating the lifetime value of customers—has already been
developed. This means that a business problem has already been identified and
translated into a concrete question, the data needed for answering the question
have already been collected and transformed into a target variable and a set of
explanatory variables, and a modeling technique has already been selected and
calibrated in order to answer the question by predicting the target variable
given the explanatory variables. For the sake of concreteness, the model is
assumed to be written in Python. We also assume that the company at hand has
chosen Google Cloud Platform as its primary platform, which makes a certain
suite of tools readily available.

Our goal is then to schedule the model to run in the cloud via Airflow, Compute
Engine, and Docker so that it is periodically retrained (in order to take into
account potential fluctuations in the data distribution) and periodically
applied (in order to actually make predictions), delivering predictions to the
data warehouse in the form of [BigQuery] for further consumption by other
parties.

It is important to note that this article is not a tutorial on any of the
aforementioned technologies. The reader is assumed to be familiar with Google
Cloud Platform and to have an understanding of Airflow and Docker, as well as to
be comfortable with finding out missing details on their own.

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
arguments, read a configuration file, potentially set up logging and alike, and
delegate the rest to the `task` module. At a later stage, an invocation of an
action might look as follows:

```bash
python -m prediction.main --action training --config configs/training.json
```

Here we are passing two arguments: `--action` and `--config`. The former is to
specify the desired action, and the latter is to supply additional configuration
parameters, such as the location of the training data and the values of the
model’s hyperparameters. Keeping all parameters in a separate file, as opposed
to hard-coding them, makes the code reusable, and passing them all at once as a
single file scales much better than passing each parameter as a separate
argument.

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

It can be seen that the structure presented above makes very few assumptions
about the model, which makes it generally applicable. It can also be easily
extended to accommodate other actions. For instance, one could have a separate
action for testing the model on unseen data.

Having structured the model as shown above, it can now be productized, which we
discuss next.

# Wrapping the model into a service

Now it is time to turn the model into a service. In the scope of this article, a
service is a self-sufficient piece of code that can be executed in the cloud
upon request. To this end, another repository is created, adhering to the
separation-of-concerns design principle. Specifically, by doing so, we avoid
mixing the modeling code with the code specific to a particular environment
where the model happens to be deployed. The suggested structure of the
repository is as follows:

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
│   ├── application.py         # a symbolic link to graph.py
│   ├── graph.py
│   └── training.py            # a symbolic link to graph.py
├── Makefile
└── README.md
```

The [`container/`] folder contains files for building a Docker image for the
service. The [`service/`] folder is the service itself, meaning that these files
will be present in the container and eventually executed. Lastly, the
[`scheduler/`] folder contains files for scheduling the service using Airflow.
The last one will be covered in the next section; here we focus on the first
two.

Let us start with `service/`. The first repository (the one discussed in the
previous section) is added to this second repository as a Git submodule living
in `service/source/`. This means that the model will essentially be embedded in
the service but will conveniently remain an independent entity. At all times,
the service contains a reference to a particular state (a particular commit,
potentially on a dedicated release branch) of the model, guaranteeing that the
desired version of the model is in production. However, when invoking the model
from the service, we might want to use a different set of configuration files
than the ones present in the first repository. To this end, a service-specific
version of the configuration files is created in `service/configs/`. We might
also want to install additional Python dependencies; hence, there is a separate
file with requirements.

Now it is time to containerize the service code by building a Docker image. The
relevant files are gathered in `container/`. The image is defined in
[`container/Dockerfile`] and is as follows:

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

As mentioned earlier, `service/` gets copied as is (including `service/source`
with the model), and it will be the working directory inside the container. We
also copy [`container/run.sh`], which becomes the entry point of the container;
this script is executed whenever a container is launched. Let us take a look at
the content of the script (as before, some parts omitted for clarity):

```sh
#!/bin/bash

function process_training() {
  # Invoke training
  python -m prediction.main \
    --action ${ACTION} \
    --config configs/${ACTION}.json
  # Set the output location in Cloud Storage
  local output=gs://${NAME}/${VERSION}/${ACTION}/${timestamp}
  # Copy the trained model from the output directory to Cloud Storage
  save output ${output}
}

function process_application() {
  # Find the latest trained model in Cloud Storage
  # Copy the trained model from Cloud Storage to the output directory
  load ${input} output
  # Invoke application
  python -m prediction.main \
    --action ${ACTION} \
    --config configs/${ACTION}.json
  # Set the output location in Cloud Storage
  local output=gs://${NAME}/${VERSION}/${ACTION}/${timestamp}
  # Copy the predictions from the output directory to Cloud Storage
  save output ${output}
  # Set the input file in Cloud Storage
  # Set the output data set and table in BigQuery
  # Ingest the predictions from Cloud Storage into BigQuery
  ingest ${input} ${output} player_id:STRING,label:BOOL
}

function delete() {
  # Delete a Compute Engine instance called "${NAME}-${VERSION}-${ACTION}"
}

function ingest() {
  # Ingest a file from Cloud Storage into a table in BigQuery
}

function load() {
  # Sync the content of a location in Cloud Storage with a local directory
}

function save() {
  # Sync the content of a local directory with a location in Cloud Storage
}

function send() {
  # Write into a Stackdriver log called "${NAME}-${VERSION}-${ACTION}"
}

# Invoke the delete function when the script exits regardless of the reason
trap delete EXIT

# Report a successful start to Stackdriver
send 'Running the action...'
# Invoke the function specified by the ACTION environment variable
process_${ACTION}
# Report a successful completion to Stackdriver
send 'Well done.'
```

The script expects a number of environment variables to be set upon each
container launch, which will be discussed shortly. The primary ones are `NAME`,
`VERSION`, and `ACTION`, indicating the name of the service, version of the
service, and action to be executed by the service, respectively.

As we shall see below, the above script interacts with several different
products on Google Cloud Platform. It might then be surprising that there is
only a handful of variables passed to the script. The explanation is that the
convention-over-configuration design paradigm is followed to a great extent
here, meaning that other necessary variables can be derived (save sensible
default values) from the ones given, since there are certain naming conventions
used throughout the project.

The `process_training` and `process_application` are responsible for training
and application, respectively. It can be seen that they leverage the
command-line interface by invoking the `main` file, which was discussed in the
previous section. Since containers are stateless, all artifacts are stored in an
external storage, which is a bucket in [Cloud Storage] in our case, and this job
is delegated to the `load` and `save` functions used in both `process_training`
and `process_application`. In addition, the result of the application action
(that is, the predictions) is ingested into a table in BigQuery using [Cloud
SDK], which can be seen in the `ingest` function in [`container/run.sh`].

The container communicates with the outside world using [Stackdriver] via the
`send` function, which writes messages to a log dedicated to the current service
run. The most important message is the one indicating a successful completion,
which is sent at the very end; we use “Well done” for this purpose. This is the
message that will be looked for in order to determine the overall outcome of a
service run.

Note also that, upon successful or unsuccessful completion, the container
deletes its hosting virtual machine, which is achieved by setting a handler
(`delete`) for the `EXIT` event.

Lastly, let us discuss the commands used for building the image and launching
the actions. This entails a few lengthy invocations of Cloud SDK, which can be
neatly organized in a [`Makefile`]:

```make
# The name of the service
name ?= example-prediction-service
# The version of the service
version ?= 2019-00-00

# The name of the project on Google Cloud Platform
project ?= example-cloud-project
# The zone for operations in Compute Engine
zone ?= europe-west1-b
# The address of Container Registry
registry ?= eu.gcr.io

# The name of the Docker image
image := ${name}
# The name of the instance excluding the action
instance := ${name}-${version}

build:
	docker rmi ${image} 2> /dev/null || true
	docker build --file container/Dockerfile --tag ${image} .
	docker tag ${image} ${registry}/${project}/${image}:${version}
	docker push ${registry}/${project}/${image}:${version}

training-start:
	gcloud compute instances create-with-container ${instance}-training \
		--container-image ${registry}/${project}/${image}:${version} \
		--container-env NAME=${name} \
		--container-env VERSION=${version} \
		--container-env ACTION=training \
		--container-env ZONE=${zone} \
		--container-restart-policy never \
		--no-restart-on-failure \
		--machine-type n1-standard-1 \
		--scopes default,bigquery,compute-rw,storage-rw
		--zone ${zone}

training-wait:
	container/wait.sh instance ${instance}-training ${zone}

training-check:
	container/wait.sh success ${instance}-training

# Similar for application
```

Here we define one command for building images, namely `build`, and three
commands per action, namely `start`, `wait`, and `check`. In this section, we
discuss `build` and `start` and leave the last two for the next section, as they
are needed specifically for scheduling.

The `build` command is invoked as follows:

```sh
make build
```

It has to be used each time a new version of the service is to be deployed. The
command creates a local Docker image according to the recipe in
`container/Dockerfile` and uploads it to [Container Registry], which is Google’s
storage for Docker images. For the last operation to succeed, your local Docker
has to be configured appropriately, which boils down to the following lines:

```sh
gcloud auth login # General authentication for Cloud SDK
gcloud auth configure-docker
```

Once `build` has finished successfully, one should be able to see the newly
created image in [Cloud Console] by navigating to Container Registry in the menu
to the left. All future versions of the service will be neatly grouped in a
separate folder in the registry.

Given that the image is in the cloud, we can start to create virtual machines
running containers with this particular image, which is what the `start` command
is for:

```sh
make training-start # Similar for application
```

Internally, it relies on `gcloud compute instances create-with-container`, which
can be seen in `Makefile` listed above. There are a few aspects to note about
this command. Apart from selecting the right image and version
(`--container-image`), one has to make sure to set the environment variables
mentioned earlier, as they control what the container will be doing once
launched. This is achieved by passing a number of `--container-env` options to
`create-with-container`. Here one can also easily scale up and down the host
virtual machine via the `--machine-type` option. Lastly, it is important to set
the `--scopes` option correctly in order to empower the container to work with
BigQuery, Compute Engine, and Cloud Storage.

At this point, we have a few handy commands for working with the service. It is
time for scheduling.

# Scheduling the service

The goal now is to make both training and application be executed periodically,
promptly delivering predictions to the data warehouse. Technically, one could
just keep invoking `make training-start` and `make application-start` on their
local machine, but of course, this is neither convenient nor reliable. Instead,
we would like to have an autonomous scheduler running in the cloud that would,
apart from its primary task of dispatching jobs, manage temporal dependencies
between jobs, keep record of all past and upcoming jobs, and preferably provide
a web-based dashboard for monitoring. One such tool is Airflow, and it is the
one used in this article.

In Airflow, the work to be performed is expressed as a directed acyclic graph
defined using Python. Our job is to create two such graphs. One is for training,
and one is for application, each with its own periodicity. At this point, it
might seem that each graph should contain only one node calling the `start`
command, which was introduced earlier. However, a more comprehensive solution is
to not only start the service but also wait for its termination and check that
it successfully executed the corresponding logic. It will give us great
visibility on the life cycle of the service in terms of various statistics (for
instance, the duration and outcome of all runs) directly in Airflow.

The above is the reason we have defined two additional commands in `Makefile`:
`wait` and `check`. The `wait` command ensures that the virtual machine reached
a terminal state (regardless of the outcome), and the `check` command ensures
that the terminal state was the one expected. This functionality can be
implemented in different ways. The approach that we use can be seen in
[`container/wait.sh`], which is invoked by both operations from `Makefile`:

```sh
#!/bin/bash

function process_instance() {
  echo 'Waiting for the instance to finish...'
  while true; do
    # Try to read some information about the instance
    # Exit successfully when there is no such instance
    wait
  done
}

function process_success() {
  echo 'Waiting for the success to be reported...'
  while true; do
    # Check if the last entry in Stackdriver contains “Well done”
    # Exit successfully if the phrase is present
    wait
  done
}

function wait() {
  echo 'Waiting...'
  sleep 10
}

# Invoke the function specified by the first command-line argument and forward
# the rest of the arguments to this function
process_${1} ${@:2:10}
```

The script has two main functions. The `process_instance` function waits for the
virtual machine to finish, and it is currently based on trying to fetch some
information about the machine in question using Cloud SDK. Whenever this
fetching fails, it is an indication of the machine being shut down and
destroyed, which is exactly what is needed in this case. The `process_success`
function waits for the key phrase “Well done” to appear in Stackdriver. However,
this message might never appear, and this is the reason `process_success` has a
timeout, unlike `process_instance`.

All right, there are now three commands to schedule in sequence: `start`,
`wait`, and `check`. For instance, for training, the exact command sequence is
the following:

```sh
make training-start
make training-wait
make training-check
```

We need to create two separate Python files defining two separate Airflow
graphs; however, the graphs will be almost identical except for the triggering
interval and the prefix of the `start`, `wait`, and `check` commands. It then
makes sense to keep the varying parts in separate configuration files and use
the exact same code for constructing the graphs, adhering to the
do-not-repeat-yourself design principle. The [`scheduler/configs/`] folder
contains the configuration files suggested, and [`scheduler/graph.py`] is the
Python script creating a graph:

```python
from airflow import DAG
from airflow.operators.bash_operator import BashOperator


def configure():
    # Extract the directory containing the current file
    path = os.path.dirname(__file__)
    # Extract the name of the current file without its extension
    name = os.path.splitext(os.path.basename(__file__))[0]
    # Load the configuration file corresponding to the extracted name
    config = os.path.join(path, 'configs', name + '.json')
    config = json.loads(open(config).read())
    return config


def construct(config):

    def _construct_graph(default_args, start_date, **options):
        start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d')
        return DAG(default_args=default_args, start_date=start_date, **options)

    def _construct_task(graph, name, code):
        return BashOperator(task_id=name, bash_command=code, dag=graph)

    # Construct an empty graph
    graph = _construct_graph(**config['graph'])
    # Construct the specified tasks
    tasks = [_construct_task(graph, **task) for task in config['tasks']]
    tasks = dict([(task.task_id, task) for task in tasks])
    # Enforce the specified dependencies between the tasks
    for child, parent in config['dependencies']:
        tasks[parent].set_downstream(tasks[child])
    return graph


try:
    # Load an appropriate configuration file and construct a graph accordingly
    graph = construct(configure())
except FileNotFoundError:
    # Exit without errors in case the current file has no configuration file
    pass
```

The script receives no arguments and instead tries to find a suitable
configuration file based on its own name, which can be seen in the `configure`
function. Then `scheduler/training.py` and `scheduler/application.py` can simply
be symbolic links to `scheduler/graph.py`, avoiding any code repetition. When
they are read by Airflow, each one will have its own name, and it will load its
own configuration if there is one in `scheduler/configs/`.

For instance, for training, [`scheduler/configs/training.json`] is as follows:

```json
{
  "graph": {
    "dag_id": "example-prediction-service-training",
    "schedule_interval": "0 0 1 * *",
    "start_date": "2019-07-01"
  },
  "tasks": [
    {
      "name": "start",
      "code": "make -C '${ROOT}/..' training-start"
    },
    {
      "name": "wait",
      "code": "make -C '${ROOT}/..' training-wait"
    },
    {
      "name": "check",
      "code": "make -C '${ROOT}/..' training-check"
    }
  ],
  "dependencies": [
    ["wait", "start"],
    ["check", "wait"]
  ]
}
```

Each configuration file contains three main sections: `graph`, `tasks`, and
`dependencies`. The first section prescribes the desired start date,
periodicity, and other parameters specific to the graph itself. In this example,
the graph is triggered on the first day of every month at midnight (`0 0 1 *
*`), which might be a reasonable frequency for retraining the model. The second
section defines what commands should be executed. It can be seen that there is
one task for each of the three actions. The `-C '${ROOT}/..'` part is needed in
order to ensure that the right `Makefile` is used, which is taken care of in
`scheduler/graph.py`. Lastly, the third section dictates the order of execution
by enforcing dependencies. In this case, we are saying that `wait` depends on
(should be executed after) `start`, and that `check` depends on `wait`, forming
a chain of tasks.

At this point, the graphs are considered to be complete. In order to make
Airflow aware of them, the repository can be simply cloned into the `dags`
directory of Airflow.

Lastly, Airflow itself can live on a separate instance in Compute Engine.
Alternatively, [Cloud Composer] provided by Google Cloud Platform can be
utilized for this purpose.

# Conclusion

Having reached this point, our predictive model is up and running in the cloud
in an autonomous fashion, delivering predictions to the data warehouse to act
upon. The data warehouse is certainly not the end of the journey, but we stop
here and save the discussion for another time.

Although the presented workflow gets the job done, it has its own limitations
and weaknesses, which one has to be aware of. The most prominent one is the
communication between a Docker container running inside a virtual machine and
the scheduler, Airflow. Busy waiting for a virtual machine in Compute Engine to
shut down and for Stackdriver to deliver a certain message is arguably not the
most reliable solution. There is also a certain overhead associated with
starting a virtual machine in Compute Engine, downloading an image from
Container Registry, and launching a container. Furthermore, this approach is not
suitable for online prediction, as the service does not expose any API for other
services to integrate with---its job is making periodically batch predictions.

If you have any suggestions regarding improving the workflow or simply would
like to share your thoughts, please leave a comment below or send an e-mail.
Feel also free to [create an issue] or [open a pull request] on GitHub. Any
feedback is very much appreciated!


Thank you!

[Airflow]: https://airflow.apache.org/
[BigQuery]: https://cloud.google.com/bigquery/
[Cloud Composer]: https://cloud.google.com/composer/
[Cloud Console]: https://console.cloud.google.com
[Cloud SDK]: https://cloud.google.com/sdk/
[Cloud Storage]: https://cloud.google.com/storage/
[Compute Engine]: https://cloud.google.com/compute/
[Container Registry]: https://cloud.google.com/container-registry/
[Docker]: https://www.docker.com/
[Stackdriver]: https://cloud.google.com/stackdriver/

[example-prediction]: https://github.com/IvanUkhov/example-prediction
[example-prediction-service]: https://github.com/IvanUkhov/example-prediction-service

[create an issue]: https://github.com/IvanUkhov/example-prediction-service/issues
[open a pull request]: https://github.com/IvanUkhov/example-prediction-service/pulls

[`Makefile`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/Makefile
[`container/Dockerfile`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/container/Dockerfile
[`container/`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/container
[`container/run.sh`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/container/run.sh
[`container/wait.sh`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/container/wait.sh
[`main`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/main.py
[`model`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/model.py
[`prediction/`]: https://github.com/IvanUkhov/example-prediction/tree/master/prediction
[`scheduler/`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/scheduler
[`scheduler/configs/`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/scheduler/configs
[`scheduler/configs/training.json`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/scheduler/configs/training.json
[`scheduler/graph.py`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/scheduler/graph.py
[`service/`]: https://github.com/IvanUkhov/example-prediction-service/tree/master/service
[`task`]: https://github.com/IvanUkhov/example-prediction/blob/master/prediction/task.py
