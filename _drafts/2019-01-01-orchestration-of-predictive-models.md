---
layout: post
title: >-
  A poor man’s orchestration of predictive models via Airflow, Compute Engine,
  and Docker
date: 2019-01-01
---

As a data scientist focusing on developing predictive models, you naturally want
your work to reach its target audience. However, your company might not be
mature enough in this regard and, therefore, have no dedicated engineering team
for productionazing your data-science code. What do you do? One solution is to
seek help in other teams, which are surely busy with their own endeavors, and
potentially spend months waiting. Another solution is to take the initiative and
do it yourself. In this post, we take the initiative and schedule training and
application of a predictive model using Apache Airflow, Google Compute Engine,
and Docker.

Suppose you have a predictive model for identifying potential churners.
