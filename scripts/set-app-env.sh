#!/usr/bin/env bash

HOME_DIR=$( pwd )
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

HOME_DIR="."
SCRIPT_DIR="./scripts"

if [[ $1 == "--help" ]] || [[ $1 == "-h" ]] || [[ $1 == "help" ]]; then
    echo
    echo "USAGE EXAMPLES:"
    echo "To accept all default values, run:      $0"
    echo "To override initial arg defaults, run:  $0 <app-name> <profile-name> <deployment-name>"
    echo "To override all default values, run:    $0 <app-name> <profile-name> <deployment-name> <app-version> <repo-version> <registry>"
    echo
else
  export APP_NAME=${1:-hello-app}
  export PROFILE=${2:-lg}
  export DEPLOYMENT=${3:-ny}
  export VERSION=${4:-1.0.0}
  export REPO_VERSION=${5:-0.0.1}
  export MY_REG=${6:-localhost:5001/gitopscon}
  export EDGE_REG=${EDGE_REG:-localhost:5001/gitopscon-edge}

  echo "-----> PLEASE REVIEW THE FOLLOWING VALUES:"
  echo "APP_NAME=$APP_NAME"
  echo "PROFILE=$PROFILE"
  echo "DEPLOYMENT=$DEPLOYMENT"
  echo "VERSION=$VERSION"
  echo "REPO_VERSION=$REPO_VERSION"
  echo "MY_REG=$MY_REG"
  echo "EDGE_REG=$EDGE_REG"
  echo

  echo "-----> LOOK OK? ENTER ANY KEY TO CONTINUE."
  read -p "-----> OTHERWISE QUIT NOW AND CHECK USAGE INSTRUCTIONS: $0 --help" CONTINUE

  export APP_REPO=git@github.com:GitOpsCon2023-gitops-edge-configuration/$APP_NAME.git

  export TEMP=$HOME_DIR/temp
  export APP_HOME=$HOME_DIR/apps
  export PROFILE_HOME=$HOME_DIR/profiles
  export DEPLOYMENT_HOME=$HOME_DIR/deployments
  export PKG_REPO_HOME=$HOME_DIR/pkg-repos

  export BUNDLE_NAME=$PROFILE-$APP_NAME-bundle
  export PACKAGE_NAME=$PROFILE-$APP_NAME.corp.com
  export PACKAGE_REPO_NAME=$PROFILE-pkg-repo

  mkdir -p $APP_HOME/$APP_NAME/base/.imgpkg
  touch $APP_HOME/$APP_NAME/base/.imgpkg/.gitkeep
  mkdir -p $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/packages/$PACKAGE_NAME
  touch $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/packages/$PACKAGE_NAME/.gitkeep
  mkdir -p $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/.imgpkg
  touch $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/.imgpkg/.gitkeep
  mkdir -p $DEPLOYMENT_HOME/$PROFILE/.imgpkg/
  touch $DEPLOYMENT_HOME/$PROFILE/.imgpkg/.gitkeep
  mkdir $DEPLOYMENT_HOME/$PROFILE/gitops-controller/.imgpkg
  touch $DEPLOYMENT_HOME/$PROFILE/gitops-controller/.imgpkg/.gitkeep
#  mkdir -p $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$REPO_VERSION/.imgpkg
#  touch $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$REPO_VERSION/.imgpkg/.gitkeep
#  mkdir -p $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$REPO_VERSION/$DEPLOYMENT
fi

