#!/bin/sh
NAMESPACE_NAME=yatai-deployment
CERT_MANAGER_NAMESPACE_NAME=cert-manager

METRICS_SERVER_RELEASE_NAME=metrics-server
YATAI_DEPLOYMENT_CRDS_RELEASE_NAME=yatai-deployment-crds
YATAI_DEPLOYMENT_RELEASE_NAME=yatai-deployment

METRICS_SERVER_TGZ=metrics-server-3.8.3.tgz
YATAI_DEPLOYMENT_CRDS_TGZ=yatai-deployment-crds-1.1.8.tgz
YATAI_DEPLOYMENT_TGZ=yatai-deployment-1.1.8.tgz


# k8s namespace yatai-deployment 확인 및 등록
HAS_NS=$(kubectl get namespaces $NAMESPACE_NAME > /dev/null 2>&1 && echo true || echo false)
if [ $HAS_NS != "true" ]; then
	kubectl create namespace $NAMESPACE_NAME
fi

# k8s namespace cert-manager 확인 및 등록
HAS_NS=$(kubectl get namespaces $CERT_MANAGER_NAMESPACE_NAME > /dev/null 2>&1 && echo true || echo false)
if [ $HAS_NS != "true" ]; then
	kubectl create namespace $CERT_MANAGER_NAMESPACE_NAME
fi


# cert-manager 확인 및 설치
cmready=$(kubectl -n $CERT_MANAGER_NAMESPACE_NAME get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep cert-manager-webhook | awk '{print $2}')
if [ "$cmready" != "true" ]; then
	echo "cert-manager is not installed. install cert-manager."
    kubectl apply -f ./values-cert-manager.yaml
fi

while [ "$cmready" != "true" ]; do
	cmready=$(kubectl -n $CERT_MANAGER_NAMESPACE_NAME get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep cert-manager-webhook | awk '{print $2}')
	sleep 1
done

echo "cert-manager installation is completed !"

# metrcis-server 확인 및 설치
# metrics-server
mmready=$(kubectl get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep metrics-server | awk '{print $2}')
if [ "$mmready" != "true" ]; then
	echo "$METRICS_SERVER_RELEASE_NAME is not installed. install $METRICS_SERVER_RELEASE_NAME."
	helm upgrade --install $METRICS_SERVER_RELEASE_NAME ./$METRICS_SERVER_TGZ -f ./values-metrics-server.yaml
fi

while [ "$mmready" != "true" ]; do
	mmready=$(kubectl get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep metrics-server | awk '{print $2}')
	sleep 1
done
echo "$METRICS_SERVER_RELEASE_NAME installation is completed !"

## 1. yatai-deployment-crds 설치
helm upgrade --install $YATAI_DEPLOYMENT_CRDS_RELEASE_NAME -n $NAMESPACE_NAME ./$YATAI_DEPLOYMENT_CRDS_TGZ
echo "yatai-deployment-crds installation is completed !"


## 2. install yatai-deployment 설치
ydready=$(kubectl -n $NAMESPACE_NAME get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep yatai-deployment | awk '{print $2}')
if [ "$ydready" != "true" ]; then
	echo "$YATAI_DEPLOYMENT_RELEASE_NAME is not installed. install $YATAI_DEPLOYMENT_RELEASE_NAME."
    helm upgrade --install $YATAI_DEPLOYMENT_RELEASE_NAME -n $NAMESPACE_NAME ./$YATAI_DEPLOYMENT_TGZ -f ./values-yatai-deployment.yaml
fi

ydready=""
while [ "$ydready" != "true" ]; do
	ydready=$(kubectl -n $NAMESPACE_NAME get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep yatai-deployment | awk '{print $2}')
	sleep 1
done

echo "yatai-deployment installation is completed !"