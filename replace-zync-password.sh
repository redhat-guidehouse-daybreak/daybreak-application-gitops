#!/bin/bash
read -p "Enter the zync secret for keycloak: " SECRET_VALUE

# Replace the line in the file with the secret value
FILE_PATH="components/argocd/applications/base/fhir-server-charts-applicationset.yaml"

# Use sed to replace the line that starts with optional whitespace, followed by "zync_password:" and any characters
# with the new line containing the secret value
sed -i "s/zync_password:.*/zync_password: $SECRET_VALUE/" $FILE_PATH
