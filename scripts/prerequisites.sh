#!/bin/bash
###### Pre-requisites:
## 1. Authenticate docker to the image registry you want to use (see Kind option below)
## 2. Set kube context to the Kubernetes cluster you want to use (see Kind option below)
## 3. Install kapp-controller to the cluster (see kapp-controller instruction below)
## 4. Install Carvel CLIs

# Kind with registry installation:
curl https://kind.sigs.k8s.io/examples/kind-with-registry.sh -o kind-with-registry.sh \
  && chmod +x kind-with-registry.sh \
  && ./kind-with-registry.sh \
  && kubectl cluster-info --context kind-kind \
  && rm kind-with-registry.sh
 export MY_REG=localhost:5001/gitopscon

# kapp-controller installation and RBAC configuration:
kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
kubectl apply -f deployments/ns-rbac-default.yml