#!/bin/bash
SECRET_VALUE=$(oc get secret zync-secret -n daybreak-gitops -o jsonpath="{.data.ZYNC_PASSWORD_$1}" | base64 --decode)

# Replace the line in the file with the secret value
FILE="components/argocd/applications/overlays/$1/patch-applicationset"

# Use sed to replace the line that starts with optional whitespace, followed by "zync_password:" and any characters
# with the new line containing the secret value
sed "s/zync_password:.*/zync_password: $SECRET_VALUE/" "$FILE.yaml" > "$FILE-with-secret.yaml"