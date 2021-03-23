#!/bin/bash

set -e


echo "Checking up if cluster exists"
export cluster=$(kind get clusters | grep katya-cluster)
echo ${cluster}
if [ -z ${cluster} ];
then
    echo "Looks like cluster doesn't exist, creating..."
    kind create cluster --name=katya-cluster 
fi
kubectl config use-context kind-katya-cluster
kubectl get ns
#docker build -t katya-test -f  Dockerfile.dev .  
kubectl create secret -n default generic github-pat-secret --dry-run=client -o yaml \
  | yq w - type kubernetes.io/basic-auth \
  | yq w - stringData.username \
  | yq w - stringData.password \
  | kubectl apply -f -


kubectl annotate -n default secret github-pat-secret "tekton.dev/git-0=https://github.com"


kubectl get -n default secret github-pat-secret -o yaml

kubectl create sa -n default  github-bot  


## 1) Install the clone task
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/git/git-clone.yaml

kubectl apply -f testTask.yaml 

kubectl apply -f pipelineRun.yaml 

kubectl delete PipelineRun run-with-template-cat-branch-readme


tkn pipeline start secretworld-app-clone
tkn pipelinerun logs cat-branch-readme-run-76rp2 -f -n default




kubectl create secret -n default generic github-pat-secret --dry-run=client -o yaml \
  | yq w - type kubernetes.io/basic-auth \
  | yq w - stringData.username kguseva@ca.ibm.com \
  | yq w - stringData.password token \
  | kubectl apply -f -

kubectl annotate -n default secret github-pat-secret "tekton.dev/git-0=https://github.ibm.com"
kubectl get -n default secret github-pat-secret -o yaml
kubectl create sa -n default github-bot
kubectl patch serviceaccount github-bot -p '{"secrets": [{"name": "github-pat-secret"}]}'