#!/bin/sh

# Wait for the Vault pod to be in Running state
for _ in $(seq 1 30); do
	POD_STATUS=$(kubectl get pod vault-0 --namespace=vault -o jsonpath='{.status.phase}')
	if [ "$POD_STATUS" = "Running" ]; then
		echo "vault-0 pod is running (even if not fully ready)"
		break
	else
		echo "vault-0 pod not running yet (status: $POD_STATUS), retrying in 10 seconds..."
		sleep 10
	fi
done

if [ "$POD_STATUS" != "Running" ]; then
	echo "vault-0 pod not running after retries, exiting."
	exit 1
fi

# Check if Vault is already initialized
if kubectl exec vault-0 --namespace=vault -- vault status | grep -q 'Initialized.*true'; then
	echo "Vault is already initialized."
else
	# Initialize Vault and store the unseal key and root token in Kubernetes secrets
	kubectl exec vault-0 --namespace=vault -- vault operator init -key-shares=1 -key-threshold=1 |
		tee /tmp/vault-init-output.txt |
		awk '/Unseal Key 1/ {print $4}' |
		xargs -I {} kubectl create secret generic vault-unseal-secret --namespace=vault --from-literal=unseal-key={} --dry-run=client -o yaml | kubectl apply -f -

	# Extract the root token and store it in a secret
	awk '/Initial Root Token/ {print $4}' </tmp/vault-init-output.txt |
		xargs -I {} kubectl create secret generic vault-root-token --namespace=vault --from-literal=root-token={} --dry-run=client -o yaml | kubectl apply -f -
fi

# Print out the root token every time
ROOT_TOKEN=$(kubectl get secret vault-root-token --namespace=vault -o jsonpath='{.data.root-token}' | base64 --decode)
echo "Vault root token: $ROOT_TOKEN"

# Wait for the unseal secret to be created if it doesn't exist
while ! kubectl get secret vault-unseal-secret --namespace=vault --no-headers; do
	echo "Waiting for unseal secret to be created..."
	sleep 5
done

# Check if Vault is already unsealed
if kubectl exec vault-0 --namespace=vault -- vault status | grep -q 'Sealed.*false'; then
	echo "Vault is already unsealed."
else
	# Unseal Vault
	kubectl exec vault-0 --namespace=vault -- vault operator unseal "$(kubectl get secret vault-unseal-secret --namespace=vault -o jsonpath='{.data.unseal-key}' | base64 --decode)"
fi
