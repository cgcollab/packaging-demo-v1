# gitops-config

Create a working directory and cd into it
Set the env var APP_HOME to point to the app directory
Set the env var APP_NAME to point to the app 

```shell
export APP_HOME=/Users/mbrodi/git/conference/Cd-Vancouver/gitops-config/apps
export APP_NAME=hello-redis
```

``` shell
vendir sync --chdir $APP_HOME/base/$APP_NAME
```

```shell
ytt -f $APP_HOME/$APP_NAME/base/config -f $APP_HOME/$APP_NAME/values
```