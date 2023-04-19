# gitops-config

Create a working directory and cd into it
Set the env var APP_HOME to point to the app directory
Set the env var APP_NAME to point to the app

```shell
export MY_REG=localhost:5001
export PROFILE=lg
export DEPLOYMENT=ny
export APP_HOME=apps
export PROFILE_HOME=profiles
export APP_NAME=hello-redis
export APP_REPO=git@github.com:GitOpsCon2023-gitops-edge-configuration/hello-redis.git
```

``` shell
vendir sync --chdir $APP_HOME/$APP_NAME/base
```

```shell
mkdir -p $PROFILE_HOME/lg/$APP_NAME/temp
ytt -f $APP_HOME/$APP_NAME/base/config -f $PROFILE_HOME/lg/$APP_NAME >  $PROFILE_HOME/lg/$APP_NAME/temp/generated.yml
```

```shell
mkdir temp
curl https://kind.sigs.k8s.io/examples/kind-with-registry.sh -o temp/kind-with-registry.sh \
  && chmod +x temp/kind-with-registry.sh \
  && ./temp/kind-with-registry.sh \
  && kubectl cluster-info --context kind-kind
```

```shell
rm -rf temp/src
mkdir temp/src
git clone $APP_REPO temp/src
mkdir $APP_HOME/$APP_NAME/.imgpkg     
kbld  -f $APP_HOME/$APP_NAME/base/kbld.yml \
      -f $APP_HOME/$APP_NAME/base/config \
      -f $PROFILE_HOME/lg/$APP_NAME \
      --imgpkg-lock-output $APP_HOME/$APP_NAME/base/.imgpkg/images.yml \
      > /dev/null     
```

If need to regenerate yaml with resolved SHA images
```shell
ytt -f $APP_HOME/$APP_NAME/base/config \
    -f $PROFILE_HOME/lg/$APP_NAME \
    -f $APP_HOME/$APP_NAME/base/config/.imgpkg/images.yml \
    | kbld -f-
    
```

Bundles --->>> Is this relly what we want to package????
```shell
imgpkg push -b $MY_REG/hello-app-bundle:v1.0.0 \
            -f $APP_HOME/$APP_NAME/base \
            -f $PROFILE_HOME/lg/$APP_NAME \
            --lock-output $APP_HOME/$APP_NAME/base/bundle.lock.yml
```


