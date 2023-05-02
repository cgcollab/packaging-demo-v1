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
#curl gcr.io/pa-mbrodi/v2/gitopscon/$BUNDLE_NAME/tags/list |jq
```

Packaging
Create package metadata and schema
```shell
imgpkg pull -b $MY_REG/$BUNDLE_NAME:$VERSION \
            -o $TEMP/app-bundles/$PROFILE/$APP_NAME/bundle
ytt -f $TEMP/app-bundles/$PROFILE/$APP_NAME/bundle/values/schema.yaml \
    --data-values-schema-inspect -o openapi-v3 > $TEMP/app-bundles/$PROFILE/$APP_NAME/schema-openapi.yml
```

```shell
ytt -f $PKG_REPO_HOME/$PROFILE/packages/$PACKAGE_NAME/package-template.yml \
    --data-value-file openapi=$TEMP/app-bundles/$PROFILE/$APP_NAME/schema-openapi.yml \
    -v version="$VERSION" > $PKG_REPO_HOME/$PROFILE/packages/$PACKAGE_NAME/$VERSION.yml
kbld -f $PKG_REPO_HOME/$PROFILE/packages/$PACKAGE_NAME --imgpkg-lock-output $PKG_REPO_HOME/$PROFILE/.imgpkg/temp-images.yml
cat $PKG_REPO_HOME/$PROFILE/.imgpkg/temp-images.yml >> $PKG_REPO_HOME/$PROFILE/.imgpkg/images.yml
echo "" >> $PKG_REPO_HOME/$PROFILE/.imgpkg/images.yml
imgpkg push -b $MY_REG/$PACKAGE_REPO_NAME:0.0.1 -f $PKG_REPO_HOME/$PROFILE

skopeo list-tags docker://$MY_REG/$PACKAGE_REPO_NAME
#curl gcr.io/pa-mbrodi/v2/gitopscon/$PACKAGE_REPO_NAME/tags/list |jq

#curl -X GET http://gcr.io/pa-mbrodi/v2/_catalog | jq

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

kapp delete -a repo -y
kapp delete -a lg-hello-app   -y
```

```shell
kubectl apply -f pkg-repo-cr/ns-rbac-default.yml
kapp deploy -a repo -f pkg-repo-cr/$PROFILE/repo.yml -y
kubectl get packagerepository -w
```
```shell
kubectl get pkgm
kubectl get packages 
kubectl get package $PACKAGE_NAME.$VERSION  -o yaml
```

```shell  
kapp deploy -a lg-hello-app -f pkg-repo-cr/$PROFILE/apps/$DEPLOYMENT/hello-app.yml -y
```