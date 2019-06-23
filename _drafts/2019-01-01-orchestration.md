---
layout: post
title: >-
  A poor man’s orchestration of predictive models via Airflow, Compute Engine,
  and Docker
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
attained at the end of the article. We assume that there has already been
developed a predictive model for supporting business decisions of some kind,
such as a model for identifying potential churners or estimating the lifetime
value of customers. The explanatory variables, modeling technique, and
hyperparameters have already been decided upon. We also assume that the company
in question has chosen Google Cloud Platform as their primary platform, which
makes a certain suite of tools available to us. Our goal is then to schedule the
model to run in the cloud so that it is being periodically retrained (in order
to account for potential fluctuations in the data distribution) and periodically
applied (in order to actually make predictions). Predictions are to be delivered
to the data warehouse for further consumption by other parties. In our case, the
destination is a data set in BigQuery.

The data warehouse is certainly not the end of the journey. However, I will stop
there and save the discussion about visualization, dashboards, and acting upon
predictions for another time.

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

Here `prediction` is a Python package, and it is likely to contain many more
files than the ones listed. The `main` module is the entry point for
command-line invocation.

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
