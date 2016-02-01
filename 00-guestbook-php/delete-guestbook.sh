#!/bin/bash

kubectl delete -f 7-ingress.yaml
kubectl delete -f 6-nginx-ingress-controller.yaml

export K8S_INGRESS_NODE=$(kubectl get no | sort -t $'\t' -k4,4 | awk 'NR==1{print $1}')
kubectl label no $K8S_INGRESS_NODE role-

kubectl delete -f 5-frontend-service.yaml
kubectl delete -f 4-frontend-controller.yaml
kubectl delete -f 3-redis-slave-service.yaml
kubectl delete -f 2-redis-slave-controller.yaml
kubectl delete -f 1-redis-master-service.yaml
kubectl delete -f 0-redis-master-controller.yaml
