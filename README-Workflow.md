# gitops-config

Skip if Kind installed and running or using a different cluster
```shell
mkdir temp
curl https://kind.sigs.k8s.io/examples/kind-with-registry.sh -o temp/kind-with-registry.sh \
  && chmod +x temp/kind-with-registry.sh \
  && ./temp/kind-with-registry.sh \
  && kubectl cluster-info --context kind-kind
```

Create a working directory and cd into it
Set the env var APP_HOME to point to the app directory
Set the env var APP_NAME to point to the app
Set all the var appropriately

```shell
clear
export MY_REG=gcr.io/pa-mbrodi/gitopscon
export PROFILE=lg
export DEPLOYMENT_HOME=deployments
export DEPLOYMENT=ny
export APP_HOME=apps
export PROFILE_HOME=profiles
export APP_NAME=hello-app
export APP_REPO=git@github.com:GitOpsCon2023-gitops-edge-configuration/$APP_NAME.git
export VERSION="1.0.0"
export BUNDLE_NAME=$PROFILE-$APP_NAME-bundle
export PACKAGE_NAME=$PROFILE-$APP_NAME.corp.com
export PACKAGE_REPO_NAME=$PROFILE-pkg-repo
rm -rf temp
mkdir -p temp/intermediate
rm -rf $APP_HOME/$APP_NAME/base/config/temp
rm $APP_HOME/$APP_NAME/*lock*
rm $APP_HOME/$APP_NAME/base/.imgpkg/images.yml
rm packages/lg/$APP_NAME/.imgpkg/images.yml
rm packages/lg/$APP_NAME/schema-openapi.yml
rm pkg-repos/$PROFILE/.imgpkg/images.yml
```

Downloading and incorporating application's dependencies
``` shell
if [ -f $APP_HOME/$APP_NAME/vendir.yml ] 
then
    vendir sync --chdir $APP_HOME/$APP_NAME
fi
```

Clone the application and build it so that we can seal the images SHA 
in the images file:  $APP_HOME/$APP_NAME/base/config/.imgpkg/images.yml
we are discarding the output as it's not resolved by ytt
```shell
rm -rf temp/src/$APP_NAME
git clone $APP_REPO temp/src/$APP_NAME
```

Bundles FLOW 2 - Decentralized approach 
- I can resolve at the edge specific config
- first we package
```shell
clear
kbld -f $APP_HOME/$APP_NAME/kbld.yml \
    -f $APP_HOME/$APP_NAME/base/config \
    -f $PROFILE_HOME/$PROFILE/$APP_NAME \
    --imgpkg-lock-output $APP_HOME/$APP_NAME/base/.imgpkg/images.yml \
    > /dev/null
imgpkg push -b $MY_REG/$BUNDLE_NAME:1.0.0 \
            -f $APP_HOME/$APP_NAME/base \
            -f $PROFILE_HOME/$PROFILE/$APP_NAME \
            --lock-output $APP_HOME/$APP_NAME/bundle.lock.yml
#curl $MY_REG/v2/$PROFILE-$APP_NAME/tags/list |jq
skopeo list-tags docker://$MY_REG/$BUNDLE_NAME
```
- then at the final location
- we get the image and apply the location specific config (deployment folder) that can be located anywhere
- (consider airgapped -> imgpkg copy/pull)
```shell
#mkdir -p temp/deployable
#imgpkg pull -b $MY_REG/$BUNDLE_NAME:1.0.0 \
#            -o temp/$PROFILE-$APP_NAME/bundle/config
#            
#ytt -f temp/$PROFILE-$APP_NAME/bundle/config \
#    -f $DEPLOYMENT_HOME/$PROFILE-$DEPLOYMENT/$APP_NAME \
#    | kbld -f- > temp/deployable/$PROFILE-$DEPLOYMENT-$APP_NAME-config-flow2.yaml
```
SKIP to Packaging
Create package metadata and schema
```shell
imgpkg pull -b $MY_REG/$BUNDLE_NAME:1.0.0 \
            -o temp/packages/$PROFILE/$APP_NAME/bundle
ytt -f temp/packages/$PROFILE/$APP_NAME/bundle/values/schema.yaml \
    --data-values-schema-inspect -o openapi-v3 > packages/$PROFILE/$APP_NAME/schema-openapi.yml
mv temp/packages/$PROFILE/$APP_NAME/bundle/.imgpkg/images.yml packages/$PROFILE/$APP_NAME/.imgpkg/images.yml
imgpkg push -b $MY_REG/$PACKAGE_NAME:1.0.0 -f packages/$PROFILE/$APP_NAME

```

```shell
imgpkg pull -b $MY_REG/$PACKAGE_NAME:1.0.0 -o temp/pkg-repos/$PROFILE/packages/$PACKAGE_NAME/
ytt -f temp/pkg-repos/$PROFILE/packages/$PACKAGE_NAME/package-template.yml \
    --data-value-file openapi=temp/pkg-repos/$PROFILE/packages/$PACKAGE_NAME/schema-openapi.yml \
    -v version="1.0.0" > pkg-repos/$PROFILE/packages/$PACKAGE_NAME/1.0.0.yml
kbld -f pkg-repos/$PROFILE/packages/$PACKAGE_NAME --imgpkg-lock-output pkg-repos/$PROFILE/.imgpkg/images.yml
imgpkg push -b $MY_REG/$PACKAGE_REPO_NAME:1.0.0 -f pkg-repos/$PROFILE
```


=============On the cluster:
```shell
kapp deploy -a repo -f pkg-repo-cr/$PROFILE/repo.yml -y
```

