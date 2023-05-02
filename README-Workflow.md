# gitops-config

```shell
source bin/set-app-env.sh hello-app lg ny
source bin/clean-app-env.sh
```
# ------- OR -------
```shell
source bin/set-app-env.sh giant-app lg ny
source bin/clean-app-env.sh
```

Skip if Kind installed and running or using a different cluster
```shell
mkdir $TEMP
curl https://kind.sigs.k8s.io/examples/kind-with-registry.sh -o $TEMP/kind-with-registry.sh \
  && chmod +x $TEMP/kind-with-registry.sh \
  && $TEMP/kind-with-registry.sh \
  && kubectl cluster-info --context kind-kind
```

Create a working directory and cd into it
Set the env var APP_HOME to point to the app directory
Set the env var APP_NAME to point to the app
Set all the var appropriately

```shell
#clear
#export MY_REG=localhost:5001/gitopscon
#export PROFILE=lg
#export DEPLOYMENT_HOME=deployments
#export DEPLOYMENT=ny
#export APP_HOME=apps
#export PROFILE_HOME=profiles
#export APP_NAME=hello-app
#export APP_REPO=git@github.com:GitOpsCon2023-gitops-edge-configuration/$APP_NAME.git
#export VERSION="1.0.0"
#export BUNDLE_NAME=$PROFILE-$APP_NAME-bundle
#export PACKAGE_NAME=$PROFILE-$APP_NAME.corp.com
#export PACKAGE_REPO_NAME=$PROFILE-pkg-repo
#export PACKAGE_HOME=packages
#export PKG_REPO_HOME=pkg-repos
#rm -rf $TEMP
#mkdir -p $TEMP/intermediate
#rm -rf $APP_HOME/$APP_NAME/base/config/vendir
#rm $APP_HOME/$APP_NAME/*lock*
#rm $APP_HOME/$APP_NAME/base/.imgpkg/images.yml
#rm $PACKAGE_HOME/$PROFILE/$APP_NAME/.imgpkg/images.yml
#rm $PACKAGE_HOME/$PROFILE/$APP_NAME/schema-openapi.yml
#rm $PKG_REPO_HOME/$PROFILE/.imgpkg/images.yml
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
rm -rf $TEMP/src/$APP_NAME
git clone $APP_REPO $TEMP/src/$APP_NAME
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
imgpkg push -b $MY_REG/$BUNDLE_NAME:$VERSION \
            -f $APP_HOME/$APP_NAME/base \
            -f $PROFILE_HOME/$PROFILE/$APP_NAME \
            --lock-output $APP_HOME/$APP_NAME/$PROFILE-bundle.$VERSION.lock.yml
#skopeo list-tags docker://$MY_REG/$BUNDLE_NAME
curl localhost:5001/v2/gitopscon/$BUNDLE_NAME/tags/list |jq
```
- then at the final location
- we get the image and apply the location specific config (deployment folder) that can be located anywhere
- (consider airgapped -> imgpkg copy/pull)
```shell
#mkdir -p $TEMP/deployable
#imgpkg pull -b $MY_REG/$BUNDLE_NAME:$VERSION \
#            -o $TEMP/$PROFILE-$APP_NAME/bundle/config
#            
#ytt -f $TEMP/$PROFILE-$APP_NAME/bundle/config \
#    -f $DEPLOYMENT_HOME/$PROFILE-$DEPLOYMENT/$APP_NAME \
#    | kbld -f- > $TEMP/deployable/$PROFILE-$DEPLOYMENT-$APP_NAME-config-flow2.yaml
```
SKIP to Packaging
Create package metadata and schema
```shell
imgpkg pull -b $MY_REG/$BUNDLE_NAME:$VERSION \
            -o $TEMP/app-bundles/$PROFILE/$APP_NAME/bundle
ytt -f $TEMP/app-bundles/$PROFILE/$APP_NAME/bundle/values/schema.yaml \
    --data-values-schema-inspect -o openapi-v3 > $PACKAGE_HOME/$PROFILE/$APP_NAME/schema-openapi.yml
#mv $TEMP/app-bundles/$PROFILE/$APP_NAME/bundle/.imgpkg/images.yml $PACKAGE_HOME/$PROFILE/$APP_NAME/.imgpkg/images.yml
#imgpkg push -b $MY_REG/$PACKAGE_NAME:$VERSION -f $PACKAGE_HOME/$PROFILE/$APP_NAME
#imgpkg pull -b $MY_REG/$PACKAGE_NAME:$VERSION -o $TEMP/pkg-repos/$PROFILE/packages/$PACKAGE_NAME/
ytt -f $PACKAGE_HOME/$PROFILE/$APP_NAME/package-template.yml \
    --data-value-file openapi=$PACKAGE_HOME/$PROFILE/$APP_NAME/schema-openapi.yml \
    -v version="$VERSION" > $PKG_REPO_HOME/$PROFILE/packages/$PACKAGE_NAME/$VERSION.yml
cp $PACKAGE_HOME/$PROFILE/$APP_NAME/metadata.yml $PKG_REPO_HOME/$PROFILE/packages/$PACKAGE_NAME/
kbld -f $PKG_REPO_HOME/$PROFILE/packages/$PACKAGE_NAME --imgpkg-lock-output $PKG_REPO_HOME/$PROFILE/.imgpkg/temp-images.yml
cat $PKG_REPO_HOME/$PROFILE/.imgpkg/temp-images.yml >> $PKG_REPO_HOME/$PROFILE/.imgpkg/images.yml
echo "" >> $PKG_REPO_HOME/$PROFILE/.imgpkg/images.yml
imgpkg push -b $MY_REG/$PACKAGE_REPO_NAME:0.0.1 -f $PKG_REPO_HOME/$PROFILE

#skopeo list-tags docker://$MY_REG/$PACKAGE_REPO_NAME
curl localhost:5001/v2/gitopscon/$PACKAGE_REPO_NAME/tags/list |jq

curl -X GET http://localhost:5001/v2/_catalog | jq

```


=============On the cluster:
This PackageRepository CR will allow kapp-controller to install any of the packages found within the repo
```shell
kapp deploy -a repo -f pkg-repo-cr/$PROFILE/repo.yml -y
kubectl get packagerepository -w
```
```shell
kubectl get pkgm
kubectl get packages 
kubectl get package $PACKAGE_NAME.$VERSION  -o yaml
```

Deploy kapp-controller if not there
```shell
kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/examples/rbac/default-ns.yml -y
```

```shell
#kapp delete -a lg-hello-app       
kapp deploy -a lg-hello-app -f pkg-repo-cr/$PROFILE/apps/$DEPLOYMENT/hello-app.yml -y
```