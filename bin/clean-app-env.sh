#!/usr/bin/env bash

#SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p $TEMP
rm -rf $TEMP/app-bundles/$PROFILE/$APP_NAME
rm -rf $TEMP/src/$APP_NAME

rm -rf $APP_HOME/$APP_NAME/base/config/vendir
rm $APP_HOME/$APP_NAME/*lock*
rm $APP_HOME/$APP_NAME/base/.imgpkg/images.yml

rm $PACKAGE_HOME/$PROFILE_HOME/$APP_NAME/.imgpkg/images.yml
rm $PACKAGE_HOME/$PROFILE_HOME/$APP_NAME/schema-openapi.yml

rm $PKG_REPO_HOME/$PROFILE/.imgpkg/images.yml

