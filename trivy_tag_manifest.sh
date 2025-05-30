#!/bin/bash

set -e

tag_manifest() {
  # set this again for use in parallel
  set -e

  # get expected tag from first argument
  EXPECTED_TAG="${1}"

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
  AMD64_TAG_DIGEST="$(docker buildx imagetools inspect --raw "aquasec/trivy:${TRIMMED_TAG}" | jq -r '.manifests | .[] | select((.platform.architecture == "amd64") and (.platform.os == "linux")) | .digest')"
  ARM64_TAG_DIGEST="$(docker buildx imagetools inspect --raw "aquasec/trivy:${TRIMMED_TAG}" | jq -r '.manifests | .[] | select((.platform.architecture == "arm64") and (.platform.os == "linux")) | .digest')"

  # check to see if we got a tag digest
  if [ -z "${AMD64_TAG_DIGEST}" ] || [ -z "${ARM64_TAG_DIGEST}" ]
  then
    echo -e "error\nERROR: AMD64_TAG_DIGEST or ARM64_TAG_DIGEST not set!"
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

  # create the new manifest and push the manifest to docker hub
  echo -n "Create new manifest and push to Docker Hub..."
  docker buildx imagetools create --progress plain -t "mbentley/trivy:${MAJOR_MINOR_TAG}" "aquasec/trivy@${AMD64_TAG_DIGEST}" "aquasec/trivy@${ARM64_TAG_DIGEST}"
  if [ "${MAJOR_MINOR_TAG}" == "${LATEST_MAJOR_MINOR_TAG}" ]
  then
    # also tag this as latest
    docker buildx imagetools create --progress plain -t "mbentley/trivy:latest" "aquasec/trivy@${AMD64_TAG_DIGEST}" "aquasec/trivy@${ARM64_TAG_DIGEST}"
  fi

  echo -e "done\n"
}

# query for the github releases
GITHUB_TAGS="$(wget -q -O - "https://api.github.com/repos/aquasecurity/trivy/tags?per_page=50")"

# get the last five major.minor tags
EXPECTED_TAGS="$(echo "${GITHUB_TAGS}" | jq -r '.[]|.name' | awk -F 'v' '{print $2}' | awk -F '.' '{print $1 "." $2}' | sort --version-sort -ru | head -n 5)"

# get the latest tag
LATEST_MAJOR_MINOR_TAG="$(echo "${GITHUB_TAGS}" | jq -r '.[]|.name' | awk -F 'v' '{print $2}' | awk -F '.' '{print $1 "." $2}' | sort --version-sort -ru | head -n 1)"

# get full tag name, sorted by version so we can extract the latest major.minor.bugfix tag
TRIVY_RELEASES="$(echo "${GITHUB_TAGS}" | jq -r '.[]|.name' | sort --version-sort -r)"

# load env_parallel
. "$(command -v env_parallel.bash)"

# run multiple scans in parallel
env_parallel --env tag_manifest --env TRIVY_RELEASES --env LATEST_MAJOR_MINOR_TAG --halt soon,fail=1 -j 5 tag_manifest ::: "${EXPECTED_TAGS}"
