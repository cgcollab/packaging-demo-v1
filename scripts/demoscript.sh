# To execute, run:
# ./scripts/demorunner.sh scripts/demoscript.sh

# To clean beforehand, run:
# source scripts/clean-app-env.sh

###### Pre-requisites:
## 1. Authenticate docker to the image registry you want to use (see Kind option below)
## 2. Set kube context to the Kubernetes cluster you want to use (see Kind option below)
## 3. Install kapp-controller to the cluster (see kapp-controller instruction below)
## 4. Install Carvel CLIs

# Kind with registry installation:
#mkdir $TEMP
#curl https://kind.sigs.k8s.io/examples/kind-with-registry.sh -o $TEMP/kind-with-registry.sh \
#  && chmod +x $TEMP/kind-with-registry.sh \
#  && $TEMP/kind-with-registry.sh \
#  && kubectl cluster-info --context kind-kind
# export MY_REG=localhost:5001/gitopscon

# kapp-controller installation:
#kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml

#_ECHO_OFF

DEMO_HOME=$( pwd )

echo
echo "Setting env vars"
# unset APP_NAME VERSION PROFILE DEPLOYMENT REPO_VERSION MY_REG
# To override, export env vars with desired values and re-run demo script
source $DEMO_HOME/scripts/set-app-env.sh "${APP_NAME:=hello-app}" "${PROFILE:=lg}" "${DEPLOYMENT:=ny}" "${VERSION:=1.0.0}" "${REPO_VERSION:=0.0.1}" "${MY_REG:=localhost:5001/gitopscon}"

# TO-DO: Update registry and REPO_VERSION in files. Do this in set env actually

echo "Cloning source code"
mkdir -p $TEMP/src/$APP_NAME && rm -rf $TEMP/src/$APP_NAME && git clone $APP_REPO $TEMP/src/$APP_NAME

clear
#_ECHO_ON
#_ECHO_# Let's package an app for distribution & deployment using Project Carvel!

#_ECHO_# To start, we'll need our app source code and k8s config files
tree $TEMP/src/$APP_NAME $APP_HOME/$APP_NAME

#_ECHO_# Next, we need the k8s config for 3rd party dependencies. Carvel vendir can help us get it!
if [ -f $APP_HOME/$APP_NAME/vendir.yml ]; then cat $APP_HOME/$APP_NAME/vendir.yml; fi
if [ -f $APP_HOME/$APP_NAME/vendir.yml ]; then vendir sync --chdir $APP_HOME/$APP_NAME; tree $APP_HOME/$APP_NAME; fi

#_ECHO_# Finally, we need the k8s config values and overlays for this specific profile
tree $PROFILE_HOME/$PROFILE/$APP_NAME

#_ECHO_# That's a lot of YAML! Carvel kbld can tell us all the images referenced...
kbld inspect -f $APP_HOME/$APP_NAME/base -f $PROFILE_HOME/$PROFILE/$APP_NAME --column image

# TO-DO: What is kbld flag --unresolved-inspect

#_ECHO_# Looks like we still need to build our app into an image and replace all tags with SHAs. kbld can help here too!
cat $APP_HOME/$APP_NAME/kbld.yml

# TO-DO: In $APP_HOME/$APP_NAME/base/config, create values and overlay sibling dirs

# Note: Here we use kbld to build app, resolve tags, and generate images.yml.
#       However, we discard the stdout YAML output as we have not yet processed the input with ytt.
#       WAIT WHAT? WE WEREN'T APPLYING YTT BEFORE BUNDLING THE APP ANYWAY!?
#       MAYBE WE JUST DISCARD THE OUTPUT SO WE CAN BUNDLE THE FILES WITH THE ORIGINAL DIR STRUCTURE
#       BUT THEN WE DEF NEED TO INCLUDE THE IMAGES.YML FILE!!! OTHERWISE WHAT WAS THE POINT OF RESOLVING NOW, OTHER THAN BUILDING THE APP?
kbld -f $APP_HOME/$APP_NAME/kbld.yml -f $APP_HOME/$APP_NAME/base/config -f $PROFILE_HOME/$PROFILE/$APP_NAME --imgpkg-lock-output $APP_HOME/$APP_NAME/base/.imgpkg/images.yml > /dev/null

#_ECHO_# We now have a Bill of Materials that we can use to lock down these SHAs for our images!
cat $APP_HOME/$APP_NAME/base/.imgpkg/images.yml

clear
#_ECHO_# Let's bundle all of the config PLUS the new Bill of Materials file...
imgpkg push -b $MY_REG/$BUNDLE_NAME:$VERSION -f $APP_HOME/$APP_NAME/base -f $PROFILE_HOME/$PROFILE/$APP_NAME --lock-output $APP_HOME/$APP_NAME/$PROFILE-bundle.$VERSION.lock.yml
skopeo list-tags docker://$MY_REG/$BUNDLE_NAME #OR: curl localhost:5001/v2/gitopscon/$BUNDLE_NAME/tags/list |jq

#_ECHO_# What exactly is in the bundle we created? Let's take a look... imgpkg makes it easy to move or share our app bundle
imgpkg pull -b $MY_REG/$BUNDLE_NAME:$VERSION -o $TEMP/app-bundles/$PROFILE/$APP_NAME/$VERSION/bundle
tree $TEMP/app-bundles/$PROFILE/$APP_NAME/$VERSION/bundle

#_ECHO_# One nifty thing in this bundle is the app's values schema file. We can use it to understand all configurable values:
ytt -f $TEMP/app-bundles/$PROFILE/$APP_NAME/$VERSION/bundle/config/schema.yaml --data-values-schema-inspect -o openapi-v3 > $TEMP/app-bundles/$PROFILE/$APP_NAME/schema-openapi.yml
yq $TEMP/app-bundles/$PROFILE/$APP_NAME/schema-openapi.yml

#_ECHO_# At this point, we could use Carvel ytt to render a deployable version of the YAML
#_ECHO_# But we want Kubernetes to do this declaratively, not imperatively! Carvel has some K8s CRDs that can do this!
# TO-DO: Consider: maybe this should be the first profile-specific artifact? One app, one package per profile?
#_ECHO_# Let's start with PackageMetadata, a way to provide some metadata to Kubernetes
#_ECHO_OFF
ytt -f $PKG_REPO_HOME/metadata.yml -v packageName="$PACKAGE_NAME" -v appName="$APP_NAME" > $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/packages/$PACKAGE_NAME/metadata.yml
#_ECHO_ON
cat $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/packages/$PACKAGE_NAME/metadata.yml

#_ECHO_# For each release of the app bundle, we'll also need a Package CRD
#_ECHO_OFF
ytt -f $PKG_REPO_HOME/templates/package-template.yml --data-value-file openapi=$TEMP/app-bundles/$PROFILE/$APP_NAME/schema-openapi.yml -v version="$VERSION" -v packageName="$PACKAGE_NAME" -v bundleName="$BUNDLE_NAME" -v registry="$MY_REG" > $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/packages/$PACKAGE_NAME/$VERSION.yml
#_ECHO_ON
cat $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/packages/$PACKAGE_NAME/$VERSION.yml

clear
#_ECHO_# Most likely you have many apps, so you'll have many Packages, and you'll need to send all of them to many target locations.
tree $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/packages/
#_ECHO_# How can you bundle and distribute these easily for deployment at many target locations? Remember our friend imgpkg?
kbld -f $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/packages/ --imgpkg-lock-output $PKG_REPO_HOME/$PROFILE/$REPO_VERSION/.imgpkg/images.yml
imgpkg push -b $MY_REG/$PACKAGE_REPO_NAME:$REPO_VERSION -f $PKG_REPO_HOME/$PROFILE/$REPO_VERSION
skopeo list-tags docker://$MY_REG/$PACKAGE_REPO_NAME  #OR curl localhost:5001/v2/gitopscon/$PACKAGE_REPO_NAME/tags/list |jq
#curl -X GET http://localhost:5001/v2/_catalog | jq

clear
#_ECHO_# Let's consider the perspective of the target deployment location. How do we get the PackageRepo into our cluster?
#_ECHO_# Carvel provides a Kubernetes Controller called kapp-controller that can help automate pulling and installing packages
#_ECHO_OFF
# TO-DO - SHould this repo.$REPO_VERSION.yml file be versioned or put under a different hierarchy?
ytt -f $DEPLOYMENT_HOME/templates/repo-template.yml -v registry="$MY_REG" -v profile="$PROFILE" -v packageRepoVersion="$REPO_VERSION" | kbld -f- --imgpkg-lock-output $DEPLOYMENT_HOME/$PROFILE/.imgpkg/images.yml > $DEPLOYMENT_HOME/$PROFILE/repo.$REPO_VERSION.yml
#_ECHO_ON
cat $DEPLOYMENT_HOME/$PROFILE/repo.$REPO_VERSION.yml

#_ECHO_# Let's apply this to the cluster!
kubectl apply -f $DEPLOYMENT_HOME/ns-rbac-default.yml
# TODO: This step fails if the pkg-repo image is on kind. Just move this one to gcr and all is good
kapp deploy -a repo -f $DEPLOYMENT_HOME/$PROFILE/repo.$REPO_VERSION.yml -y

#_ECHO_# We can now list all of the available Packages in the PackageRepository
# kubectl get packagerepository
# kubectl get packagemetadatas
kubectl get packages
kubectl get package $PACKAGE_NAME.$VERSION  -o yaml

#_ECHO_# At this point, you could imperatively install each of these Packages and apply the location-specific values...
# e.g. kapp deploy -a $PROFILE-$APP_NAME -f $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$DEPLOYMENT/$APP_NAME.yml -y

#_ECHO_# But we'd rather define this declaratively!
cat $DEPLOYMENT_HOME/$PROFILE/pkg-installer/$VERSION/$DEPLOYMENT/$APP_NAME.yml

#_ECHO_# And even better... we want to use GitOps to continuously apply this configuration. kapp-controller has our backs!
#_ECHO_OFF
ytt -f $DEPLOYMENT_HOME/templates/pkg-gitops-template.yml -v profile="$PROFILE" -v packageRepoVersion="$REPO_VERSION" -v deployment="$DEPLOYMENT" | kbld -f- --imgpkg-lock-output $DEPLOYMENT_HOME/$PROFILE/gitops-controller/.imgpkg/images.yml > $DEPLOYMENT_HOME/$PROFILE/gitops-controller/$DEPLOYMENT/pkg-gitops.$REPO_VERSION.yml
#_ECHO_ON
cat $DEPLOYMENT_HOME/$PROFILE/gitops-controller/$DEPLOYMENT/pkg-gitops.$REPO_VERSION.yml
open https://github.com/GitOpsCon2023-gitops-edge-configuration/gitops-config/tree/main/deployments/$PROFILE/pkg-installer/$REPO_VERSION/$DEPLOYMENT/$APP_NAME.yml
kubectl apply  -f $DEPLOYMENT_HOME/$PROFILE/gitops-controller/$DEPLOYMENT/pkg-gitops.$REPO_VERSION.yml  # Try also with kapp

#_ECHO_# Now every time a location wants to upgrade a package or change local vales, they just need to make a git commit!

# DEMO - Change local values


# DEMO - Upgrade Package version



#This PackageRepository CR will allow kapp-controller to install any of the packages found within the repo
tanzu package available list
tanzu package installed list
tanzu package installed delete lg-hello-app.corp.com -y
tanzu package installed delete lg-gaint-app.corp.com -y
kapp delete -a repo -y
kapp delete -a lg-ny-pkg-gitops -y
kapp delete -a lg-hello-app   -y
kapp delete -a lg-giant-app   -y

tanzu package available get lg-hello-app.corp.com/1.0.0 --values-schema
kubectl get package lg-hello-app.corp.com.1.0.0 -o yaml
