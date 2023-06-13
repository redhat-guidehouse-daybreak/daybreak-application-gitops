#!/bin/bash
set -e

BOOTSTRAP_DIR="bootstrap/overlays/default/"
COMPONENTS_DIR="components"
ARGO_NS=daybreak-gitops
HELM_CHARTS_REPO="https://github.com/redhat-guidehouse-daybreak/openshift-fhirserver-charts"

# check login
check_oc_login(){
  oc cluster-info | head -n1
  oc whoami || exit 1
  echo

  sleep 5
}
# check namespaces exist
download_helm_charts(){
    echo "Downloading helm charts from ${HELM_CHARTS_REPO}"
    git clone ${HELM_CHARTS_REPO} helm-charts
    echo "Helm charts downloaded"
    # copy the helm charts to the components directory
    cp -r helm-charts/charts/ ${COMPONENTS_DIR}/charts/
    # delete the helm charts directory
    rm -rf helm-charts
    
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
download_helm_charts
main