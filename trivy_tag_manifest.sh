#!/bin/bash

set -e

# set expected major.minor tags
EXPECTED_TAGS="0.21 0.20 0.19 0.18 0.17"

# get last 100 release tags from GitHub
TRIVY_RELEASES="$(wget -q -O - "https://api.github.com/repos/aquasecurity/trivy/tags?per_page=100" | jq -r '.[] | .name' | sort --version-sort -r)"

# loop through each tag
for EXPECTED_TAG in ${EXPECTED_TAGS}
do
  # get latest full version from GitHub releases
  echo -n "Getting full version for ${EXPECTED_TAG} from GitHub releases..."
  TRIVY_VERSION="$(echo "${TRIVY_RELEASES}" | grep "^v${EXPECTED_TAG}\." | head -n 1)"

  # check to see if we received a trivy version from github tags
  if [ -z "${TRIVY_VERSION}" ]
  then
    echo -e "error\nERROR: unable to retrieve the Trivy version from GitHub"
    exit 1
  fi

  echo "${TRIVY_VERSION}"

  # check to see if this is a non-GA version
  if [ -n "$(echo "${TRIVY_VERSION}" | awk -F '-' '{print $2}')" ]
  then
    echo "ERROR: non-GA version ${TRIVY_VERSION} found!"
    exit 1
  fi

  # trim the tag for checking
  TRIMMED_TAG="$(echo "${TRIVY_VERSION}" | awk -F 'v' '{print $2}')"

  # check to see if we got a trimmed tag
  if [ -z "${TRIMMED_TAG}" ]
  then
    echo "ERROR: TRIMMED_TAG not set!"
    exit 1
  fi

  # get digest for image
  echo -n "Getting digest for aquasec/trivy:${TRIMMED_TAG} from Docker Hub..."
  TAG_DIGEST="$(docker manifest inspect "aquasec/trivy:${TRIMMED_TAG}" | jq -r '.manifests | .[] | select((.platform.architecture == "amd64") and (.platform.os == "linux")) | .digest')"

  # check to see if we got a tag digest
  if [ -z "${TAG_DIGEST}" ]
  then
    echo -e "error\nERROR: TAG_DIGEST not set!"
    exit 1
  fi

  echo "done"

  # get the target tag we want to use
  MAJOR_MINOR_TAG="$(echo "${TRIVY_VERSION}" | awk -F 'v' '{print $2}' | awk -F '.' '{print $1"."$2}')"

  # check to see if we got a tag digest
  if [ -z "${MAJOR_MINOR_TAG}" ]
  then
    echo "ERROR: MAJOR_MINOR_TAG not set!"
    exit 1
  fi

  # check to see if the major.minor tag is no longer the value of EXPECTED_TAG
  if [ "${MAJOR_MINOR_TAG}" != "${EXPECTED_TAG}" ]
  then
    echo "ERROR: the major.minor tag is no longer ${EXPECTED_TAG}; we found ${TRIMMED_TAG}!"
    exit 1
  fi

  # clear any existing manifests, create the new manifest, and push the manifest
  echo "Clearing existing manifests, create new manifest and push to Docker Hub..."
  docker manifest rm "mbentley/trivy:${MAJOR_MINOR_TAG}" || true
  docker manifest create "mbentley/trivy:${MAJOR_MINOR_TAG}" --amend "aquasec/trivy@${TAG_DIGEST}"
  docker manifest push --purge "mbentley/trivy:${MAJOR_MINOR_TAG}"

  echo -e "done\n"
done
