#!/bin/sh
RELEASE_NAME=mlflow
NAMESPACE_NAME=mlflow

# k8s namespace mlflow 확인 및 등록
HAS_NS=$(kubectl get namespaces $NAMESPACE_NAME > /dev/null 2>&1 && echo true || echo false)

if [ $HAS_NS != "true" ]; then
    kubectl create namespace $NAMESPACE_NAME
fi

# minio 설치
helm upgrade --install -f values-minio.yaml minio bitnami/minio --namespace $NAME_SPACE

# postgresql 설치
helm upgrade --install -f values-postgresql.yaml postgresql bitnami/postgresql -n $NAMESPACE

# mlflow 설치
