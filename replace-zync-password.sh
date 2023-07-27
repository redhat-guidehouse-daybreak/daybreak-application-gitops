#!/bin/bash
SECRET_VALUE=$(oc get secret zync-secret -n daybreak-gitops -o jsonpath="{.data.ZYNC_PASSWORD}" | base64 --decode)

# Replace the line in the file with the secret value
FILE_PATH="components/argocd/applications/base/fhir-server-charts-applicationset.yaml"

# Use sed to replace the line that starts with optional whitespace, followed by "zync_password:" and any characters
# with the new line containing the secret value
sed -i "s/zync_password:.*/zync_password: $SECRET_VALUE/" $FILE_PATH
