# MLOps Demo: Application GitOps

This repo contains resources that are deployed and managed by the application team in a gitops environment. These resources are deployed to the namespaces created by the tenant-gitops repo utilizing the ArgoCD instance created by that repo.

## Creating Sealed Secret for SSH GitHub Authentication

Prerequisites:
- Kubectl CLI
- Install Kubeseal CLI (https://github.com/bitnami-labs/sealed-secrets/releases/download)
- Bootstrapped Openshift Cluster (see https://github.com/rh-intelligent-application-practice/mlops-demo-getting-started)

### Steps

1. Create the Kubernetes Secret with your SSH Private Key and save as _mlops-demo-application-gitops-github-ssh-key-secret.yaml_:

```
kind: Secret
apiVersion: v1
metadata:
  name: mlops-demo-application-gitops-github-ssh-key
  namespace: mlops-demo-pipelines
  annotations:
    tekton.dev/git-0: github.com
data:
  ssh-privatekey: >-
    <ENCODED_PRIVATE_KEY>
type: kubernetes.io/ssh-auth
```

2. Encrypt the Secret Using the Certificate from Step 1: 

```
kubeseal --controller-namespace=sealed-secrets --format=yaml < mlops-demo-application-gitops-github-ssh-key-secret.yaml > mlops-demo-application-gitops-github-ssh-key-sealed-secret.yaml
```

3. Apply the Sealed Secret to Your Cluster:
```
kubectl create -f mlops-demo-application-gitops-github-ssh-key-sealed-secret.yaml
```

4. Verify Creation of the Secret:
```
kubectl get secret mlops-demo-application-gitops-github-ssh-key -o jsonpath="{.data.ssh-privatekey}" | base64 --decode
```

5. The secret is now available in your namespace as specified in Step 2

## Custom Domain
The default custom domain for the cluster is `apps.<cluster-name>.....openshiftapps.com`. You can get this by executing `oc describe ingresscontroller default -n openshift-ingress-operator`
Before you run bootstrap for daybreak-application-gtops, you must update `environments/dev/3scale/overlay/default/patch-domain.yaml` with the correct domain name

## Running the Cluster Bootstrap
Before executing bootstrap.sh, you need to verify the following secrets are created successfully by daybreak-tenant-gitops bootstrap -
- redhat-guidehouse-github-secret in daybreak-gitops namespace
- zync-secret in daybreak-gitops namespace

Execute the bootstrap script to begin the installation process:

```sh
./scripts/bootstrap.sh
```

Additional ArgoCD Application objects will be created and synced in OpenShift GitOps. You can follow the progress of the sync using the ArgoCD URL that the script will provide. This sync operation should complete in a few seconds.

## Configure 3Scale and Keycloak
You will need to promote the configuration to staging and production. Go to 3scale, select seach product, then goto `integration` -> `configuration` section, then click `Promote to Staging` and `Promote to Production` button.

Login to keycloak admin console, go to `daybreak` realm, go to `Clients` list and select the application client id, make sure you turn off `client authentication`. Also configure `valid redirect URL` and `web origin` accordingly.

Last, you will need to update application helm chart, and update the referenced client id in `values.yaml` with the application's client id created by helm chart.
