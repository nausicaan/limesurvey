### Table of Contents

<!-- TOC depthTo:2 -->

- [GDX LimeSurvey](#gdx-limesurvey)
  - [Prerequisites](#prerequisites)
  - [Build](#build)
    - [Image Creation](#image-creation)
  - [Deploy](#deploy)
    - [Database Deployment](#database-deployment)
    - [Application Deployment](#application-deployment)
      - [LimeSurvey installation](#limesurvey-installation)
    - [Log into the LimeSurvey app](#log-into-the-limesurvey-app)
  - [Example Deployment](#example-deployment)
    - [Example Database Deployment](#example-database-deployment)
    - [Example Application Deployment](#example-application-deployment)
    - [Log into the LimeSurvey app](#log-into-the-limesurvey-app-1)
  - [Using Environmental variables to deploy](#using-environmental-variables-to-deploy)
    - [Set the environment variables](#set-the-environment-variables)
    - [Database Deployment](#database-deployment-1)
    - [App Deployment](#app-deployment)
    - [Log into the LimeSurvey app](#log-into-the-limesurvey-app-2)
  - [FAQ](#faq)

<!-- /TOC -->

# GDX LimeSurvey

This repository contains OpenShift templates outlining an instance of [LimeSurvey](https://github.com/LimeSurvey/LimeSurvey) created for Government Digital Experience (GDX). [LimeSurvey](https://www.limesurvey.org/) is an open-source PHP application with a [PostgreSQL](https://www.postgresql.org/) relational database for persistent data. All work is based on [Gary Wong's](https://github.com/garywong-bc) incredible [nrm-survey](https://github.com/garywong-bc/nrm-survey) repo. 

## Prerequisites

For appropriate security on deployed pods:

- Kubernetes Network Policies should be in place, see the [Network Policy QuickStart](https://github.com/bcgov/how-to-workshops/tree/master/labs/netpol-quickstart)

For build:

- Administrator access to an [Openshift](https://console.apps.silver.devops.gov.bc.ca/k8s/cluster/projects) Project `*-tools` namespace
- the [oc](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html) CLI tool, installed on your local workstation
- access to this public [GitHub Repo](./)
- docker-pull-passthru secret referencing [artifactory credentials](https://developer.gov.bc.ca/Developer-Tools/Artifact-Repositories-(Artifactory))
```console
oc -n <tools-namespace> create secret docker-registry docker-pull-passthru \
--docker-server=docker-remote.artifacts.developer.gov.bc.ca \
--docker-username=default-<namespace>-<random> \
--docker-password=<random> \
--docker-email=<git username>@<tools-namespace>.local
```

Once built, this image may be deployed to a separate `*-dev`, `*-test`, or `*-prod` namespace with the appropriate `system:image-puller` role.

For deployment:

- Administrator access to an [Openshift](https://console.apps.silver.devops.gov.bc.ca/k8s/cluster/projects) Project namespace
- the [oc](https://docs.openshift.com/container-platform/3.11/cli_reference/get_started_cli.html) CLI tool, installed on your local workstation
- access to this public [GitHub Repo](./)

Once deployed, any visitors to the site will require a modern browser (e.g. Edge, FF, Chrome, Opera etc.) with activated JavaScript (see official LimeSurvey [docs](https://manual.limesurvey.org/Installation_-_LimeSurvey_CE#Make_sure_you_can_use_LimeSurvey_on_your_website))

## Build

### Image Creation

For a brand new build/image/imagestream/imagestreamtag in your new namespace, you would first create an image stream using this (forked) code (replace `<tools-namespace>` with your `*-tools` project namespace).

```console
oc -n <tools-namespace> create istag limesurvey-gdx:latest
oc -n <tools-namespace> process -f openshift/limesurvey-bc.yaml | oc -n <tools-namespace> apply -f -
oc -n <tools-namespace> start-build limesurvey-gdx
```

Tag the built image stream with the correct release version, matching the `major.minor` release tag at the source [repo](https://github.com/LimeSurvey/LimeSurvey). For example, this v5.4.15 was tagged via:

```console
oc -n <tools-namespace> tag limesurvey-gdx:latest limesurvey-gdx:5.4.15
```

NOTE: To update our LimeSurvey image, we would update or override the Dockerfile ARG, and run the [Build](./openshift/limesurvey.bc.yaml). For example, this v5.4.15 was built with:

```
ARG GITHUB_TAG=5.4.15+221212
```

## Deploy

### Database Deployment

Deploy the DB using the correct SURVEY_NAME parameter (e.g. an acronym that will be automatically prefixed to `limesurvey`):

```console
oc -n <project> new-app --file=./openshift/postgresql-dc.yaml -p SURVEY_NAME=<survey>
```

All DB deployments are based on the out-of-the-box [OpenShift Database Image](https://docs.openshift.com/container-platform/3.11/using_images/db_images/postgresql.html), and DB deployed objects (e.g. deployment configs, secrets, services, etc) have a naming convention of `<survey>-limesurvey-postgresql` in the Openshift console.

### Application Deployment

Deploy the Application specifying:

- the survey-specific parameter (i.e. `<survey>`)
- your project `*-tools` namespace that contains the image, and
- a `@gov.bc.ca` email account that will be used with the `apps.smtp.gov.bc.ca` SMTP Email Server:

```console
oc -n <project> new-app --file=./openshift/limesurvey-dc.yaml -p SURVEY_NAME=<survey> -p IS_NAMESPACE=<tools> -p ADMIN_EMAIL=<Email.Address>@gov.bc.ca
```

NOTE: The ADMIN_EMAIL is required, and you may also override the default ADMIN_USER and ADMIN_NAME. The ADMIN_PASSWORD is automatically generated by the template; be sure to __note the generated password__ (shown in the log output of this command on your screen).

Application deployed objects (e.g. deployment configs, secrets, services, etc) have a naming convention of `<survey>-limesurvey-app` in the Openshift console.

#### LimeSurvey installation

The application is automatically done as part of the `docker-entrypoint.sh`, which calls `gdx-check-install.php` returning either:

- `NOINSTALL` (Database Connection is valid but LimeSurvey has not yet been installed), or
- `INSTALL` (LimeSurvey tables exist in the database)

If `NOINSTALL` is returned, then the script automatically runs:

```console
php application/commands/console.php install "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_NAME" "$ADMIN_EMAIL" verbose
```

</details>

### Log into the LimeSurvey app

Once the application has finished the initial install you may log in as the admin user (using the generated password). Use the correct Survey acronym in the URL:
`https://<survey>-limesurvey.apps.silver.devops.gov.bc.ca/index.php/admin`

NOTE: The password is also stored as a secret in the OCP Console (`<survey>-limesurvey-app.admin-password`), or can be echoed in the shell of deployed app terminal:

```console
echo ${ADMIN_PASSWORD}
```

## Example Deployment

As a concrete example of a survey with the acronym `theta`, deployed in the project namespace `c329bd-tools`, here are the steps:

<details><summary>Deployment Steps</summary>

### Example Database Deployment

```console
❯ oc whoami
nausicaan@github

❯ oc -n c329bd-tools new-app --file=./openshift/postgresql-dc.yaml -p SURVEY_NAME=theta

--> Deploying template "c329bd-tools/limesurvey-gdx-postgresql-dc" for "./openshift/postgresql-dc.yaml" to project c329bd-tools

     * With parameters:
        * Survey Name=theta
        * Memory Limit=512Mi
        * PostgreSQL Connection Password=fSCMvcVj3MeAXwxL # generated
        * Database Volume Capacity=1Gi

--> Creating resources ...
    secret "theta-limesurvey-postgresql" created
    persistentvolumeclaim "theta-limesurvey-postgresql" created
    deploymentconfig.apps.openshift.io "theta-limesurvey-postgresql" created
    service "theta-limesurvey-postgresql" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose service/theta-limesurvey-postgresql'
    Run 'oc status' to view your app.
```

### Example Application Deployment

After thirty seconds, the database pod should be up.

```console
> oc -n c329bd-tools new-app --file=./openshift/limesurvey-dc.yaml -p IS_NAMESPACE=c329bd-tools -p SURVEY_NAME=theta -p ADMIN_EMAIL=first.last@gov.bc.ca

--> Deploying template "c329bd-tools/limesurvey-gdx-app-dc" for "./openshift/limesurvey-dc.yaml" to project c329bd-tools

     * With parameters:
        * Namespace=c329bd-tools
        * Image Stream=limesurvey-gdx
        * Version of LimeSurvey=5.4.15
        * LimeSurvey Acronym=theta-
        * Upload Folder size=1Gi
        * Administrator Account Name=admin
        * Administrator Display Name=Administrator
        * Administrator Password=AhgMnt84y2vOXi3I # generated
        * Administrator Email Address=King.Kong@gov.bc.ca
        * Database Type=pgsql
        * CPU_LIMIT=200m
        * MEMORY_LIMIT=512Mi
        * CPU_REQUEST=50m
        * MEMORY_REQUEST=200Mi
        * REPLICA_MIN=2
        * REPLICA_MAX=3

--> Creating resources ...
    secret "theta-limesurvey-app" created
    persistentvolumeclaim "theta-limesurvey-app-upload" created
    persistentvolumeclaim "theta-limesurvey-app-config" created
    persistentvolumeclaim "theta-limesurvey-app-plugins" created
    deploymentconfig.apps.openshift.io "theta-limesurvey-app" created
    horizontalpodautoscaler.autoscaling "theta-limesurvey-app" created
    service "theta-limesurvey-app" created
    route.route.openshift.io "theta-limesurvey-app" created
--> Success
    Access your application via route 'theta-limesurvey.apps.silver.devops.gov.bc.ca'
    Run 'oc status' to view your app.
```

### Log into the LimeSurvey app

The Administrative interface is at:
https://theta-limesurvey.apps.silver.devops.gov.bc.ca/index.php/admin/

and brings to you a screen like:
![Admin Logon](images/AdminLogin.png)

Once logged as an Admin, you'll be brought to the Welcome page:
![Welcome Page](images/WelcomePage.png)

</details>

## Using Environmental variables to deploy

As this is a template deployment, it may be easier to set environment variable for the deployment, so using the same PROJECT `c329bd-tools` and SURVEY `mass-test`:

<details><summary>Deployment Steps</summary>

### Set the environment variables

On a workstation logged into the OpenShift Console:

```console
export TOOLS=c329bd-tools
export PROJECT=c329bd-tools
export SURVEY=mass-test
```

### Database Deployment

```console
> oc -n ${PROJECT} new-app --file=./openshift/postgresql-dc.yaml -p SURVEY_NAME=${SURVEY}

--> Deploying template "c329bd-tools/limesurvey-gdx-postgresql-dc" for "./openshift/postgresql-dc.yaml" to project c329bd-tools

     * With parameters:
        * Survey Name=mass-test
        * Memory Limit=512Mi
        * PostgreSQL Connection Password=c7fTOXpikaMCWfK3 # generated
        * Database Volume Capacity=1Gi

--> Creating resources ...
    secret "mass-testlimesurvey-postgresql" created
    persistentvolumeclaim "mass-testlimesurvey-postgresql" created
    deploymentconfig.apps.openshift.io "mass-testlimesurvey-postgresql" created
    service "mass-testlimesurvey-postgresql" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose service/mass-testlimesurvey-postgresql'
    Run 'oc status' to view your app.
```

### App Deployment

Wait about 30 seconds, and/or confirm via the GUI that the DB is up:

```console
> oc -n ${PROJECT} new-app --file=./openshift/limesurvey-dc.yaml -p SURVEY_NAME=${SURVEY} -p IS_NAMESPACE=${TOOLS} -p ADMIN_EMAIL=Joe.Smith@gov.bc.ca -p ADMIN_NAME="MASS LimeSurvey Administrator"

--> Deploying template "c329bd-tools/limesurvey-gdx-app-dc" for "./openshift/limesurvey-dc.yaml" to project c329bd-tools

     * With parameters:
        * Namespace=c329bd-tools
        * Image Stream=limesurvey-gdx
        * Version of LimeSurvey=5.4.15
        * LimeSurvey Acronym=mass-test
        * Upload Folder size=1Gi
        * Administrator Account Name=admin
        * Administrator Display Name=MASS LimeSurvey Administrator
        * Administrator Password=dV0x1DuaBYjNhjCG # generated
        * Administrator Email Address=Joe.Smith@gov.bc.ca
        * Database Type=pgsql
        * CPU_LIMIT=200m
        * MEMORY_LIMIT=512Mi
        * CPU_REQUEST=50m
        * MEMORY_REQUEST=200Mi
        * REPLICA_MIN=2
        * REPLICA_MAX=3

--> Creating resources ...
    secret "mass-testlimesurvey-app" created
    persistentvolumeclaim "mass-testlimesurvey-app-upload" created
    persistentvolumeclaim "mass-testlimesurvey-app-config" created
    persistentvolumeclaim "mass-testlimesurvey-app-plugins" created
    deploymentconfig.apps.openshift.io "mass-testlimesurvey-app" created
    horizontalpodautoscaler.autoscaling "mass-testlimesurvey-app" created
    service "mass-testlimesurvey-app" created
    route.route.openshift.io "mass-testlimesurvey-app" created
--> Success
    Access your application via route 'mass-testlimesurvey.apps.silver.devops.gov.bc.ca'
    Run 'oc status' to view your app.
```

### Log into the LimeSurvey app

The Administrative interface is at https://${SURVEY}.apps.silver.devops.gov.bc.ca/index.php/admin/ which is this example is https://mass-testlimesurvey.apps.silver.devops.gov.bc.ca/ .

and brings to you a screen like:
![Admin Logon](./docs/images/AdminLogin.png)

Once logged as an Admin, you'll be brought to the Welcome page:
![Welcome Page](./docs/images/WelcomePage.png)

</details>

## FAQ

- to login the database, open the DB pod terminal (via OpenShift Console or `oc rsh`) and enter:

  `psql -U ${POSTGREQL_USER} ${POSTGRESQL_DATABASE}`

- to clean-up database deployments:

   `oc -n <project> delete secret/<survey>-limesurvey-postgresql dc/<survey>-limesurvey-postgresql svc/<survey>-limesurvey-postgresql`

  NOTE: The Database Volume will be left as-is in case there is critical business data, so to delete:

  `oc -n <project> delete pvc/<survey>-limesurvey-postgresql`

  or if using environment variables:

  ```console
  oc -n ${PROJECT} delete secret/${SURVEY}-limesurvey-postgresql dc/${SURVEY}-limesurvey-postgresql svc/${SURVEY}-limesurvey-postgresql
  oc -n ${PROJECT} delete pvc/${SURVEY}-limesurvey-postgresql
  ```

- to clean-up application deployments:

  ```console
  oc -n <project> delete secret/<survey>-limesurvey-app dc/<survey>-limesurvey-app svc/<survey>-limesurvey-app route/<survey>-limesurvey-app hpa/<survey>-limesurvey-app`
  ```

  NOTE: The Configuration, Upload, and Plugins Volumes are left intact in case there are customized assets; if not (i.e. it's a brand-new survey):  

  ```console
  oc -n <project> delete pvc/<survey>-limesurvey-app-config pvc/<survey>-limesurvey-app-upload pvc/<survey>-limesurvey-app-plugins`
  ```

  or if using environment variables:

  ```console
  oc -n ${PROJECT} delete secret/${SURVEY}-limesurvey-app dc/${SURVEY}-limesurvey-app svc/${SURVEY}-limesurvey-app route/${SURVEY}-limesurvey-app hpa/${SURVEY}-limesurvey-app pvc/${SURVEY}-limesurvey-app-config pvc/${SURVEY}-limesurvey-app-upload pvc/${SURVEY}-limesurvey-app-plugins
  ```

- to reset _all_ deployed objects (this will destroy all data and persistent volumes). Only do this on a botched initial install or if you have the DB backed up and ready to restore into the new wiped database.

  `oc -n <project> delete all,secret,pvc -l app=<survey>-limesurvey`

  or if using environment variables:

  ```console
  oc -n ${PROJECT} delete all,secret,pvc,hpa -l app=${SURVEY}-limesurvey
  ```

- to dynamically get the pod name of the running pods, this is helpful:

  `oc -n <project> get pods | grep <survey>-limesurvey-app- | grep -v deploy | grep Running | awk '{print \$1}'`

- to customize the deployment with higher/lower resources, using environment variables, use  these examples:

  ```console
  oc -n ${PROJECT} new-app --file=./openshift/postgresql-dc.yaml -p SURVEY_NAME=${SURVEY} -p MEMORY_LIMIT=768Mi -p DB_VOLUME_CAPACITY=1280M
  
  oc -n ${PROJECT} new-app --file=./openshift/limesurvey-dc.yaml -p SURVEY_NAME=${SURVEY} -p ADMIN_EMAIL=John.Doe@gov.bc.ca -p ADMIN_NAME="IITD LimeSurvey Administrator" -p REPLICA_MIN=2
  ```