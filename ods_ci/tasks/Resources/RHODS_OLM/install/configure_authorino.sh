#!/bin/bash

echo ">> Waiting for Authorino service to be created by Kuadrant operator"

# Wait for the Authorino service to exist (max 5 minutes)
timeout=300
elapsed=0
while [[ $elapsed -lt $timeout ]]; do
    if oc get svc/authorino-authorino-authorization -n kuadrant-system &>/dev/null; then
        echo ">> Authorino service found"
        break
    fi
    echo ">> Waiting for Authorino service... ($elapsed seconds elapsed)"
    sleep 10
    elapsed=$((elapsed + 10))
done

# Check if service exists
if ! oc get svc/authorino-authorino-authorization -n kuadrant-system &>/dev/null; then
    echo ">> ERROR: Authorino service not found after $timeout seconds" >&2
    exit 1
fi

# Annotate the service for SSL certificate
echo ">> Annotating Authorino service for SSL certificate"
oc annotate svc/authorino-authorino-authorization service.beta.openshift.io/serving-cert-secret-name=authorino-server-cert -n kuadrant-system --overwrite

if [[ $? -eq 0 ]]; then
    echo ">> Authorino service annotated successfully"
else
    echo ">> Failed to annotate Authorino service" >&2
    exit 1
fi

# Wait for the TLS secret to be created by OpenShift's serving cert controller
echo ">> Waiting for TLS secret to be created..."
timeout=120
elapsed=0
while [[ $elapsed -lt $timeout ]]; do
    if oc get secret/authorino-server-cert -n kuadrant-system &>/dev/null; then
        echo ">> TLS secret created successfully"
        exit 0
    fi
    echo ">> Waiting for TLS secret... ($elapsed seconds elapsed)"
    sleep 5
    elapsed=$((elapsed + 5))
done

# Check if secret exists
if ! oc get secret/authorino-server-cert -n kuadrant-system &>/dev/null; then
    echo ">> ERROR: TLS secret not found after $timeout seconds" >&2
    exit 1
fi
