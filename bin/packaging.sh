#!/bin/sh
##Skip if kappcontroller is installed
#kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.32.0/release.yml -y
#kubectl get all -n kapp-controller
#kubectl api-resources --api-group packaging.carvel.dev
#kubectl api-resources --api-group kappctrl.k14s.io
export PACKAGE_NAME=$APP_NAME.corp.com

#create package metadata and schema
imgpkg pull -b $MY_REG/$PROFILE-$APP_NAME-bundle:v1.0.0 \
            -o packages/$PROFILE/$APP_NAME/bundle
ytt -f temp/$PROFILE-$APP_NAME/bundle/config/values/schema.yaml \
    --data-values-schema-inspect -o openapi-v3 > packages/$PROFILE/$APP_NAME/bundle/schema-openapi.yml
mv packages/$PROFILE/$APP_NAME/bundle/.imgpkg packages/$PROFILE/$APP_NAME/
rm -rf packages/$PROFILE/$APP_NAME/bundle
imgpkg push -b $MY_REG/$PACKAGE_NAME:v1.0.0 -f packages/$PROFILE/$APP_NAME

#make the package repository
mkdir -p pkg-repos/$PROFILE/.imgpkg pkg-repos/$PROFILE/packages/$PACKAGE_NAME
touch pkg-repos/$PROFILE/.imgpkg/.gitkeep
imgpkg pull -b $MY_REG/$PACKAGE_NAME:v1.0.0 -o pkg-repos/$PROFILE/packages/$PACKAGE_NAME/temp

ytt -f pkg-repos/$PROFILE/packages/$PACKAGE_NAME/temp/package-template.yml \
    --data-value-file openapi=pkg-repos/$PROFILE/packages/$PACKAGE_NAME/temp/schema-openapi.yml \
    -v version="v1.0.0" > pkg-repos/$PROFILE/packages/$PACKAGE_NAME/1.0.0.yml

kbld -f pkg-repos/$PROFILE/packages/$PACKAGE_NAME/temp --imgpkg-lock-output pkg-repos/$PROFILE/.imgpkg/images.yml


