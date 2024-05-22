# LimeSurvey Instance

Create a functional, but reproducible (simple) instance of LimeSurvey in OpenShift. Complete with an NGINX proxy server and a MariaDB backend.

![Stack](ls.webp)
 
## Prerequisites

Applications needed will be:

- Docker Hub or Podman Desktop
- Docker CLI ( or Podman CLI )
- Visual Studio Code or equivilent code editor
- A Docker or Quay.io ( RedHat ) account to create repositories.

## Build

Individually, the images can be built tagged, and pushed to a repo for easy access.

1. docker build -f Dockerfile -t [name] .
2. docker image tag [name]:latest [repo]/[name]:[version]
3. docker push [repo]/[name]:[version]

### Extras

MariaDB requires a .env file with the following values:

```bash
DB_NAME=''
DB_USER=''
DB_PASSWORD=''
DB_ROOT_PASSWORD=''