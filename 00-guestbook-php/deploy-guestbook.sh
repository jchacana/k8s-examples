#!/bin/bash

kubectl create -f 0-redis-master-controller.yaml
kubectl create -f 1-redis-master-service.yaml
kubectl create -f 2-redis-slave-controller.yaml
kubectl create -f 3-redis-slave-service.yaml
kubectl create -f 4-frontend-controller.yaml
kubectl create -f 5-frontend-service.yaml

export K8S_INGRESS_NODE=$(kubectl get no | sort -t $'\t' -k4,4 | awk 'NR==1{print $1}')
kubectl label no $K8S_INGRESS_NODE role=ingress-node

kubectl create -f 6-nginx-ingress-controller.yaml
kubectl create -f 7-ingress.yaml

