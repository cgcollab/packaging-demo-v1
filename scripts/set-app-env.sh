#!/usr/bin/env bash

HOME_DIR=$( pwd )
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


if [ $# -lt 3 ]
  then
    echo "Please call '$0 <app-name> <profile-name> <deployment-name>' to run this command"
fi

export APP_NAME=$1
export VERSION="1.0.0"
export PROFILE=$2
export DEPLOYMENT=$3
export MY_REG=gcr.io/pa-mbrodi/gitopscon
export APP_REPO=git@github.com:GitOpsCon2023-gitops-edge-configuration/$APP_NAME.git

export TEMP=$HOME_DIR/temp
export APP_HOME=$HOME_DIR/apps
export PROFILE_HOME=$HOME_DIR/profiles
export DEPLOYMENT_HOME=$HOME_DIR/deployments
export PKG_REPO_HOME=$HOME_DIR/pkg-repos

export BUNDLE_NAME=$PROFILE-$APP_NAME-bundle
export PACKAGE_NAME=$PROFILE-$APP_NAME.corp.com
export PACKAGE_REPO_NAME=$PROFILE-pkg-repo

mkdir -p $APP_HOME/$APP_NAME/base/.imgpkg/.gitkeep
mkdir -p $DEPLOYMENT_HOME/$PROFILE-$DEPLOYMENT/$APP_NAME/overlays/.gitkeep
mkdir -p $PKG_REPO_HOME/$PROFILE/packages/$PACKAGE_NAME/.gitkeep



