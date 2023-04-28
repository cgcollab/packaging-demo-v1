#!/bin/sh
##Skip if kappcontroller is installed
#kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.32.0/release.yml -y
#kubectl get all -n kapp-controller
#kubectl api-resources --api-group packaging.carvel.dev
#kubectl api-resources --api-group kappctrl.k14s.io
export PACKAGE_NAME=$APP_NAME.corp.com
export PACKAGE_REPO_NAME=$PROFILE-pkg-repo

#create package metadata and schema
imgpkg pull -b $MY_REG/$PROFILE-$APP_NAME-bundle:1.0.0 \
            -o temp/packages/$PROFILE/$APP_NAME/bundle
ytt -f temp/packages/$PROFILE/$APP_NAME/bundle/values/schema.yaml \
    --data-values-schema-inspect -o openapi-v3 > packages/$PROFILE/$APP_NAME/schema-openapi.yml
mv temp/packages/$PROFILE/$APP_NAME/bundle/.imgpkg/images.yml packages/$PROFILE/$APP_NAME/.imgpkg/images.yml
imgpkg push -b $MY_REG/$PACKAGE_NAME:1.0.0 -f packages/$PROFILE/$APP_NAME

#make the package repository
#mkdir -p pkg-repos/$PROFILE/.imgpkg pkg-repos/$PROFILE/packages/$PACKAGE_NAME
#touch pkg-repos/$PROFILE/.imgpkg/.gitkeep

imgpkg pull -b $MY_REG/$PACKAGE_NAME:v1.0.0 -o temp/pkg-repos/$PROFILE/packages/$PACKAGE_NAME/
ytt -f temp/pkg-repos/$PROFILE/packages/$PACKAGE_NAME/package-template.yml \
    --data-value-file openapi=temp/pkg-repos/$PROFILE/packages/$PACKAGE_NAME/schema-openapi.yml \
    -v version="v1.0.0" > pkg-repos/$PROFILE/packages/$PACKAGE_NAME/1.0.0.yml
kbld -f pkg-repos/$PROFILE/packages/$PACKAGE_NAME --imgpkg-lock-output pkg-repos/$PROFILE/.imgpkg/images.yml
imgpkg push -b gcr.io/pa-mbrodi/$PACKAGE_REPO_NAME:1.0.0 -f pkg-repos/$PROFILE


=============On the cluster:
kapp deploy -a repo -f pkg-repo-cr/$PROFILE/repo.yml -y
