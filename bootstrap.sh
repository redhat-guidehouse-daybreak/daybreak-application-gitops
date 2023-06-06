#!/bin/bash
set -e

BOOTSTRAP_DIR="bootstrap/overlays/default/"
ARGO_NS=daybreak-gitops

# check login
check_oc_login(){
  oc cluster-info | head -n1
  oc whoami || exit 1
  echo

  sleep 5
}
# check namespaces exist
ensure_namespaces_exist(){
  if ! oc get namespace ${ARGO_NS} > /dev/null 2>&1; then
    echo "Creating namespace: ${ARGO_NS}"
    oc create namespace ${ARGO_NS}
    echo "Waiting for namespace to provision: ${ARGO_NS}"
    sleep 5
  fi
}

main(){
    echo "Applying overlay: ${BOOTSTRAP_DIR}"
    kustomize build ${BOOTSTRAP_DIR} | oc apply -f -

    echo ""
    echo "Deploying application components.  Check the status of the sync here:
    "
    route=$(oc get route argocd-server -o=jsonpath='{.spec.host}' -n ${ARGO_NS})

    echo "https://${route}"
}

check_oc_login
ensure_namespaces_exist
main