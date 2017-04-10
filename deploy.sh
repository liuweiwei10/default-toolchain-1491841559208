#!/bin/bash

echo "Create Guestbook"
IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep deployed | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

echo -e "Deleting previous version of wordpress if it exists"
kubectl delete --ignore-not-found=true -f local-volumes.yaml
kubectl delete --ignore-not-found=true -f mysql-deployment.yaml
kubectl delete --ignore-not-found=true -f wordpress-deployment.yaml

echo -e "Creating pods"
kubectl create -f local-volumes.yaml
echo 'password' > password.txt
tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt
kubectl create secret generic mysql-pass --from-file=password.txt
kubectl create -f mysql-deployment.yaml
kubectl create -f wordpress-deployment.yaml

PORT=$(kubectl get services | grep frontend | sed 's/.*://g' | sed 's/\/.*//g')

echo ""
echo "View the guestbook at http://$IP_ADDR:$PORT"
