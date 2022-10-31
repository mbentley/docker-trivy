# mbentley/trivy

docker image for Trivy; direct mirror of `aquasec/trivy` images

## Image Tags

For an up to date list of tags, please refer to the [Docker Hub tags list](https://hub.docker.com/r/mbentley/trivy/tags) as I only manually update this README occasionally and the script will always pull from the GitHub tags API. Other older tags may be available but this script only updates the last five. I'm not sure of the support lifecycle for each version of Trivy but they don't seem to release patches for older versions for very long.

### `mbentley/trivy`

#### Current Tags

* `latest`, `0.34`
* `0.33`
* `0.32`
* `0.31`
* `0.30`

### Previous Tags

* `0.17`, `0.18`, `0.19`, `0.20`, `0.21`, `0.22`, `0.23`, `0.24`, `0.25`, `0.26`, `0.27`, `0.28`, `0.29`

**Note**: The `latest` tag will always be the same as the newest `major.minor` tag.

## Why

I've found that the Trivy images published in the [aquasec/trivy](https://hub.docker.com/r/aquasec/trivy/) repository on Docker Hub only has specific tags (e.g. - there are no `major.minor` tags) which makes it a pain to stay up to date on the latest bugfix versions. [These scripts](https://github.com/mbentley/docker-trivy) will run daily to just create manifest tags for the `linux/amd64` images by querying for the latest tag from GitHub, parsing it, and writing manifests with the `major.minor` version only.

This allows for using the `major.minor` versions so that you'll always have the latest bugfix versions, such as:

* `mbentley/trivy:0.21` is a manifest pointing to `aquasec/trivy:0.21.2`

If a `0.21.3` would be released, the `0.21` tag will be updated to point to the new reference. These manifests always use the same image digest as the newest bugfix versions available for each.
