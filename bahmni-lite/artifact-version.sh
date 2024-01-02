#!/bin/bash
set -e

verifyReleaseVersion(){
  version=$1
  tagCount=$(curl -s https://api.github.com/repos/$GITHUB_REPOSITORY/tags | jq --arg tagName "$version"  '[.[] | select( .name == $tagName)] | length')
  if [ $tagCount -gt 0 ]; then
    echo "Error: Version $version already released. Please update your version in package/.appversion"
    exit 1
  fi
}

setArtifactVersion(){
  version=$1
  echo "Setting version $version"
  echo "ARTIFACT_VERSION=$version" >> $GITHUB_ENV
}

case $GITHUB_REF in
  refs/tags/*)
      echo "Current action is for tag.."
      setArtifactVersion "$GITHUB_REF_NAME"
      ;;
  refs/heads/release-*)
      echo "Current action is for release branch.."
      version=$(echo $GITHUB_REF_NAME | cut -d '-' -f 2)
      verifyReleaseVersion "$version"
      setArtifactVersion "$version"-rc
      ;;
  *)
      echo "Current action is neither tag nor release branch.."
      version=$(cat package/.appversion)
      verifyReleaseVersion "$version"
      setArtifactVersion "$version-$GITHUB_RUN_NUMBER"
      ;;
esac