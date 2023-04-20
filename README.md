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
export MY_REG=localhost:5001
export PROFILE=lg
export DEPLOYMENT_HOME=deployments
export DEPLOYMENT=ny
export APP_HOME=apps
export PROFILE_HOME=profiles
export APP_NAME=hello-redis
export APP_REPO=git@github.com:GitOpsCon2023-gitops-edge-configuration/hello-redis.git
rm -rf temp
mkdir -p temp/generated
```

Downloading and incorporating application's dependencies
``` shell
vendir sync --chdir $APP_HOME/$APP_NAME/base
```

Clone the application and build it so that we can seal the images SHA 
in the images file:  $APP_HOME/$APP_NAME/base/config/.imgpkg/images.yml
we are discarding the output as it's not resolved by ytt
```shell
cat $APP_HOME/$APP_NAME/base/kbld.yml
cat $APP_HOME/$APP_NAME/base/.imgpkg/images.yml
rm -rf temp/src 
git clone $APP_REPO temp/src 
kbld -f $APP_HOME/$APP_NAME/base/kbld.yml \
    --imgpkg-lock-output $APP_HOME/$APP_NAME/base/.imgpkg/images.yml \
    > /dev/null
```

At this point we can generate the resolved yaml per each location using
the previously resolved images SHA
```shell
clear
echo  $DEPLOYMENT_HOME/$PROFILE-$DEPLOYMENT/$APP_NAME
ytt -f $APP_HOME/$APP_NAME/base/config \
    -f $PROFILE_HOME/$PROFILE/$APP_NAME \
    -f $DEPLOYMENT_HOME/$PROFILE-$DEPLOYMENT/$APP_NAME \
    -f $APP_HOME/$APP_NAME/base/.imgpkg/images.yml \
    | kbld -f- > temp/generated/$PROFILE-$DEPLOYMENT-$APP_NAME.yaml
```

Bundles --->>> Is this relly what we want to package????
```shell
clear
imgpkg push -b $MY_REG/hello-app-bundle:v1.0.0 \
            -f temp/generated/$PROFILE-$DEPLOYMENT-$APP_NAME.yaml \
            --lock-output $APP_HOME/$APP_NAME/base/bundle.lock.yml
            
curl $MY_REG/v2/hello-app-bundle/tags/list |jq

imgpkg pull -b $MY_REG/hello-app-bundle:v1.0.0 \
            -o temp/hello-app-bundle
```



--------------FLOW2??
```shell
ytt -f $APP_HOME/$APP_NAME/base/config \
    -f $PROFILE_HOME/$PROFILE/$APP_NAME > temp/generated/$APP_NAME-UNRESOLVED-generated.yml
```

If need to regenerate yaml with resolved SHA images
```shell
ytt -f $APP_HOME/$APP_NAME/base/config \
    -f $PROFILE_HOME/$PROFILE/$APP_NAME \
    -f $APP_HOME/$APP_NAME/base/config/.imgpkg/images.yml \
    | kbld -f-
    
```


Bundles --->>> Is this relly what we want to package????
```shell
imgpkg push -b $MY_REG/hello-app-bundle:v1.0.0 \
            -f $APP_HOME/$APP_NAME/base \
            -f $PROFILE_HOME/$PROFILE/$APP_NAME \
            --lock-output $APP_HOME/$APP_NAME/base/bundle.lock.yml
            
curl $MY_REG/v2/hello-app-bundle/tags/list |jq

imgpkg pull -b $MY_REG/hello-app-bundle:v1.0.0 \
            -o temp/hello-app-bundle
```
