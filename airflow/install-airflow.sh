#!/bin/sh
RELEASE_NAME=airflow
NAMESPACE_NAME=airflow
AIRFLOW_TGZ=airflow-14.0.16.tgz

# k8s namespace mlflow 확인 및 등록
HAS_NS=$(kubectl get namespaces $NAMESPACE_NAME > /dev/null 2>&1 && echo true || echo false)

if [ $HAS_NS != "true" ]; then
    kubectl create namespace $NAMESPACE_NAME
fi

# airflow 설치
helm upgrade --install -f config-airflow.yaml airflow ./$AIRFLOW_TGZ -n $NAMESPACE_NAME
