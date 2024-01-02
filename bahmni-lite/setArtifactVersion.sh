#!/bin/bash
set -e

setArtifactVersion(){
  version=$1
  echo "Setting version $version"
  echo "ARTIFACT_VERSION=$version" >> $GITHUB_ENV
}

case $GITHUB_REF in
  refs/tags/*)
      echo "Current action is for tag.."
      echo "tag====$GITHUB_REF_NAME"
      setArtifactVersion "$(cat package/.appversion)-$GITHUB_REF_NAME"
      ;;
  *)
      echo "Current action is not for tag.."
      version=$(cat package/.appversion)
      setArtifactVersion "$version-$GITHUB_RUN_NUMBER"
      ;;
esac