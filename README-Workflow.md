# gitops-config


```shell
source scripts/set-app-env.sh hello-app lg ny
```
------- OR -------
```shell
source scripts/set-app-env.sh giant-app lg ny
```
------- OR -------
```shell
source scripts/set-app-env.sh hello-app sm mtv
```
CLEAN UP CAREFULL
```shell
source scripts/clean-app-env.sh
```
Skip if Kind installed and running or using a different cluster
```shell
mkdir $TEMP
curl https://kind.sigs.k8s.io/examples/kind-with-registry.sh -o $TEMP/kind-with-registry.sh \
  && chmod +x $TEMP/kind-with-registry.sh \
  && $TEMP/kind-with-registry.sh \
  && kubectl cluster-info --context kind-kind
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

Bundles FLOW - Decentralized approach 
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
skopeo list-tags docker://$MY_REG/$BUNDLE_NAME
```

App Package
Create package metadata and schema per app
```shell
imgpkg pull -b $MY_REG/$BUNDLE_NAME:$VERSION \
            -o $TEMP/app-bundles/$PROFILE/$APP_NAME/bundle
ytt -f $TEMP/app-bundles/$PROFILE/$APP_NAME/bundle/config/schema.yaml \
    --data-values-schema-inspect -o openapi-v3 > $TEMP/app-bundles/$PROFILE/$APP_NAME/schema-openapi.yml
ytt -f $PKG_REPO_HOME/templates/package-template.yml \
    --data-value-file openapi=$TEMP/app-bundles/$PROFILE/$APP_NAME/schema-openapi.yml \
    -v version="$VERSION" -v packageName="$PACKAGE_NAME" \
    -v bundleName="$BUNDLE_NAME" -v registry="$MY_REG" \
    > $PKG_REPO_HOME/$PROFILE/$VERSION/packages/$PACKAGE_NAME/$VERSION.yml
ytt -f $PKG_REPO_HOME/templates/metadata-template.yml -v packageName="$PACKAGE_NAME" -v appName="$APP_NAME"\
    > $PKG_REPO_HOME/$PROFILE/$VERSION/packages/$PACKAGE_NAME/metadata.yml
```

Package Repo
After all apps have been packaged start packaging the repo
```shell
kbld -f $PKG_REPO_HOME/$PROFILE/$VERSION/packages/ --imgpkg-lock-output $PKG_REPO_HOME/$PROFILE/$VERSION/.imgpkg/images.yml
imgpkg push -b $MY_REG/$PACKAGE_REPO_NAME:$REPO_VERSION -f $PKG_REPO_HOME/$PROFILE/$VERSION

skopeo list-tags docker://$MY_REG/$PACKAGE_REPO_NAME
#curl localhost:5001/v2/gitopscon/$PACKAGE_REPO_NAME/tags/list |jq
#curl -X GET http://localhost:5001/v2/_catalog | jq

ytt -f $DEPLOYMENT_HOME/templates/repo-template.yml -v registry="$MY_REG" \
    -v profile="$PROFILE" -v packageRepoVersion="$REPO_VERSION" |
    kbld -f- --imgpkg-lock-output $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$VERSION/.imgpkg/images.yml > $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$VERSION/repo.yml
```


=============On the cluster:
Deploy kapp-controller if not there
```shell
kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
```

This PackageRepository CR will allow kapp-controller to install any of the packages found within the repo
```shell
tanzu package available list
tanzu package installed list
tanzu package installed delete lg-hello-app.corp.com -y
tanzu package installed delete lg-gaint-app.corp.com -y

kapp delete -a lg-ny-pkg-gitops -y
#kapp delete -a lg-hello-app   -y
#kapp delete -a lg-giant-app   -y
kapp delete -a repo -y
```

```shell
kubectl apply -f $DEPLOYMENT_HOME/ns-rbac-default.yml
kapp deploy -a repo -f $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$VERSION/repo.yml -y
kubectl get packagerepository -w
```
```shell
kubectl get pkgm
kubectl get packages 
kubectl get package $PACKAGE_NAME.$VERSION  -o yaml
```

```shell  
kapp deploy -a lg-hello-app -f $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$VERSIONpkg-installer/$DEPLOYMENT/hello-app.yml -y
kapp deploy -a lg-giant-app -f $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$VERSIONpkg-installer/$DEPLOYMENT/giant-app.yml -y
```
Try also with kapp
```shell
kubectl apply  -f $DEPLOYMENT_HOME/$PROFILE/gitops-controller/$DEPLOYMENT/pkg-gitops.yml
```
tanzu package available get lg-hello-app.corp.com/1.0.0 --values-schema
kubectl get package lg-hello-app.corp.com.1.0.0 -o yaml 