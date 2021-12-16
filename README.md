# mbentley/trivy

docker image for Trivy; direct mirror of `aquasec/trivy` images

## Image Tags

### `mbentley/trivy`

* `0.21`, `0.20`, `0.19`, `0.18`, `0.17`

I've found that the Trivy images published in the [aquasec/trivy](https://hub.docker.com/r/aquasec/trivy/) repository on Docker Hub only has specific tags (e.g. - there are no `major.minor` tags) which makes it a pain to stay up to date on the latest bugfix versions.  [These scripts](https://github.com/mbentley/docker-trivy) will run daily to just create manifest tags for the `linux/amd64` images by querying for the latest tag from GitHub, parsing it, and writing manifests with the `major.minor` version only.

This allows for using the `major.minor` versions so that you'll always have the latest bugfix versions, such as:

* `mbentley/trivy:0.21` is a manifest pointing to `aquasec/trivy:0.21.2`

These manifests always use the same image digest as the newest bugfix versions available for each.
