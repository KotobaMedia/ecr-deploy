# ecr-deploy

Simple script to help with AWS ECR deploys.

## Usage Overview

0. Set up services and JSON task definition configuration in S3
1. Install `ecr-deploy`: `gem install ecr-deploy`
2. Set up configuration file (see `configuration.yml`)
3. Run `ecr-deploy`:

    ```
    $ ecr-deploy path_to_configuration.yml $ENVIRONMENT_NAME $IMAGE_TAG
    ```

## About

`ecr-deploy` makes a few assumptions about your ECR setup:

You have multiple **environments** of tasks and services. The name of a service
is formatted `ENVIRONMENT-NAME`. So, for example, the "web" service in a
production environment would have the service name of `production-web`.

Shared environment variables and ECS task definition files live in a S3 bucket.
Shared environment variables are environment-specific, and are contained in a
JSON file of the name `ENVIRONMENT-env.json`. Service and task configuration
templates are contained in JSON files with the name `ENVIRONMENT-NAME.json`
(where `NAME` is the service / task name specified in configuration.yml).

A quick overview of the steps `ecr-deploy` will take when you run it with
`$ ecr-deploy config.yml production 0abcdef`, when `config.yml` has a single
"web" service in the "production" environemnt:

1. Download the `production-env.json`
2. Download `production-web.json`
    1. Replace `[ENVIRONMENT]` with the environment loaded from `production-env.json`
    2. Replace `[CURRENT_IMAGE_TAG]` with `0abcdef`
3. Register the task definition using the contents of the previous step
4. Update the `production-web` service to use the new task definition registered in the previous step
5. Wait for the `production-web` to reach a stable state (will throw an error after 10 minutes)

## Task Definition templates

`ecr-deploy` uses the AWS SDK for Ruby which uses a slightly different format
of the task definition JSON (under_scored instead of camelCased).

```json
{
  "container_definitions": [
    {
      "volumes_from": [],
      "port_mappings": [
        {
          "host_port": 80,
          "container_port": 8000
        }
      ],
      "command": [
        "run_server"
      ],
      "environment": [
        [ENVIRONMENT]
      ],
      "essential": true,
      "entry_point": [],
      "links": [],
      "mount_points": [],
      "memory": 500,
      "name": "production-web",
      "cpu": 256,
      "image": "XXX.dkr.ecr.us-east-1.amazonaws.com/REPO_NAME:[CURRENT_IMAGE_TAG]"
    }
  ],
  "volumes": [],
  "family": "production-web"
}
```

Notice `[ENVIRONMENT]` and `[CURRENT_IMAGE_TAG]` -- these tokens will be replaced
on deploy.

## `configuration.yml`

```yaml
---
base_config:
  # The S3 bucket that contains the task definition templates and environment
  # files.
  template_bucket: km-t01-config
  # The prefix for template object file names. Used for disambiguation if you
  # deploy multiple apps from the same bucket.
  template_bucket_prefix: ecr-deploy-

  # The name of the ECS cluster
  cluster: default

production:
  # Services that will be updated
  services:
    - web

  # Tasks that will be run as part of the deploy process (good for automatic
  # migrations, etc)
  run_tasks:
    - migrator

  # Tasks that will only be registered, not run. Good for on-demand workers.
  register_tasks:
    - worker
```
