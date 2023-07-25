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

Execute the bootstrap script to begin the installation process:

```sh
./scripts/bootstrap.sh
```

Additional ArgoCD Application objects will be created and synced in OpenShift GitOps. You can follow the progress of the sync using the ArgoCD URL that the script will provide. This sync operation should complete in a few seconds.

## Configure 3Scale and Keycloak
For each application that needs to be integration with 3scale, we will add 3scale backdend and product custom resource as part of helm chart. ArgoCD currently does not support helm chart lookup for existing secret value in kubernets cluster. For security reason, we can't put secret values in helm chart repo. After 3sacle product with keycloak integration is created, we will need to manually configure the keycloak service account secret. To do this, login to 3scale, select the product to be configured, go to `integration` -> `settings`, then go to `OPENID CONNECT (OIDC) BASICS` -> `OpenID Connect Issuer` section, change the url `https://daybreak:changeit@keycloak-keycloak.apps.mission-db.bf3l.p1.openshiftapps.com/realms/daybreak`, change literal string `changeit` to be the actual secret for the service account `daybreak`. You can retrieve the service account password from keycloak admin console, go to realm `daybreak`, then go to Clients list and find `daybreak` client and retrieve its credential.

After the setting is changed, you will need to promote the changes to staging and production. Go to 3scale `integration` -> `configuration` section, then click `Promote to Staging` and `Promote to Production` button.

Current 3scle operator version does not support 3scale application CRD. Therefore, we will need to create application manually. To this, go to 3scale admin console, select the product, then go to `Applications` -> `Listing`, then click `Create Application` button. Select `daybreak` account, and `daybreak-basic` application plan, then provide an application name. Once the application is created, it will automatically generate a client id and client secret. This client id and secret will be automatically syn'ed to keycloak daybreak realm. 

Login to keycloak admin console, go to `daybreak` realm, go to `Clients` list and select the newly created application client id, make sure you turn off `client authentication`. Also configure `valid redirect URL` and `web origin` accordingly.

Last, you will need to update application helm chart, and update the referenced client id in `values.yaml` with the new client id just created.
