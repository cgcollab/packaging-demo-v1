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
export APP_NAME=hello-app
export APP_REPO=git@github.com:GitOpsCon2023-gitops-edge-configuration/$APP_NAME.git
rm -rf temp
mkdir -p temp/generated
rm -rf $APP_HOME/$APP_NAME/base/config/temp
rm $APP_HOME/$APP_NAME/base/*lock*
rm $APP_HOME/$APP_NAME/base/config/.imgpkg/images.yml
```

Downloading and incorporating application's dependencies
``` shell
vendir sync --chdir $APP_HOME/$APP_NAME/base
```

Clone the application and build it so that we can seal the images SHA 
in the images file:  $APP_HOME/$APP_NAME/base/config/.imgpkg/images.yml
we are discarding the output as it's not resolved by ytt
```shell
rm -rf temp/src/$APP_NAME
git clone $APP_REPO temp/src/$APP_NAME
kbld -f $APP_HOME/$APP_NAME/base/kbld.yml \
    -f $APP_HOME/$APP_NAME/base/config \
    --imgpkg-lock-output $APP_HOME/$APP_NAME/base/config/.imgpkg/images.yml \
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
    -f $APP_HOME/$APP_NAME/base/config/.imgpkg/images.yml \
    | kbld -f- > temp/generated/$PROFILE-$DEPLOYMENT-$APP_NAME.yaml
```

Bundles FLOW 1 - Centralized approach
```shell
clear
imgpkg push -i $MY_REG/$PROFILE-$DEPLOYMENT-$APP_NAME-config:v1.0.0 \
        -f temp/generated/$PROFILE-$DEPLOYMENT-$APP_NAME.yaml
imgpkg pull -i $MY_REG/$PROFILE-$DEPLOYMENT-$APP_NAME-config:v1.0.0 \
            -o temp/$PROFILE-$DEPLOYMENT-$APP_NAME-config        
        
curl $MY_REG/v2/$PROFILE-$DEPLOYMENT-$APP_NAME-config/tags/list |jq
```


Bundles FLOW 2 - Decentralized approach 
- I can resolve at the edge specific config
```shell
clear

imgpkg push -b $MY_REG/$PROFILE-$APP_NAME-bundle:v1.0.0 \
            -f $APP_HOME/$APP_NAME/base/config \
            -f $PROFILE_HOME/$PROFILE/$APP_NAME \
            --lock-output $APP_HOME/$APP_NAME/base/bundle.lock.yml
imgpkg pull -b $MY_REG/$PROFILE-$APP_NAME-bundle:v1.0.0 \
            -o temp/$PROFILE-$APP_NAME-bundle
curl $MY_REG/v2/$PROFILE-$APP_NAME-bundle/tags/list |jq
```