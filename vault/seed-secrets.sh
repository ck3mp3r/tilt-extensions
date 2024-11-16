#!/bin/sh
# Wait for the Vault pod to be ready before seeding secrets
for _ in $(seq 1 30); do
	POD_READY=$(kubectl get pod vault-0 --namespace=vault -o jsonpath='{.status.containerStatuses[0].ready}')
	if [ "$POD_READY" = "true" ]; then
		echo "Vault is ready. Seeding secrets into cubbyhole..."
		break
	else
		echo "Vault not ready yet (status: $POD_READY), retrying in 10 seconds..."
		sleep 10
	fi
done

# Execute all commands in one shell session
VAULT_TOKEN=$(kubectl get secret vault-root-token --namespace=vault -o jsonpath='{.data.root-token}' | base64 --decode)
kubectl exec vault-0 --namespace=vault -- /bin/sh -c "
export VAULT_TOKEN=$VAULT_TOKEN
__SEED_CMDS__"
