#!/bin/sh
NAMESPACE_NAME=yatai-image-builder
CERT_MANAGER_NAMESPACE_NAME=cert-manager

IMAGE_REGISTRY_RELEASE_NAME=docker-registry
YATAI_IMAGE_BUILDER_CRDS_RELEASE_NAME=yatai-image-builder-crds
YATAI_IMAGE_BUILDER_RELEASE_NAME=yatai-image-builder

IMAGE_REGISTRY_TGZ=docker-registry-2.2.2.tgz
YATAI_IMAGE_BUILDER_CRDS_TGZ=yatai-image-builder-crds-1.1.3.tgz
YATAI_IMAGE_BUILDER_TGZ=yatai-image-builder-1.1.3.tgz

# k8s namespace yatai-image-builder 확인 및 등록
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
    kubectl apply -f ./values-cert-manager.yaml
fi

cmready=""
while [ "$cmready" != "true" ]; do
	cmready=$(kubectl -n $CERT_MANAGER_NAMESPACE_NAME get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep cert-manager-webhook | awk '{print $2}')
	sleep 1
done

echo "cert-manager is running !"

## yatai-image-builder 설치
## 1. install image-registry
helm upgrade --install $IMAGE_REGISTRY_RELEASE_NAME -n $NAMESPACE_NAME ./$IMAGE_REGISTRY_TGZ -f ./values-docker-registry.yaml

drready=""
while [ "$drready" != "true" ]; do
	drready=$(kubectl -n $NAMESPACE_NAME get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep docker-registry | awk '{print $2}')
	sleep 1
done

echo "image-registry is running !"


## 2. install yatai-image-builder-crds
helm upgrade --install $YATAI_IMAGE_BUILDER_CRDS_RELEASE_NAME -n $NAMESPACE_NAME ./$YATAI_IMAGE_BUILDER_CRDS_TGZ

echo $(kubectl wait --for condition=established --timeout=120s crd/bentorequests.resources.yatai.ai)
echo $(kubectl wait --for condition=established --timeout=120s crd/bentoes.resources.yatai.ai)

echo "yatai-image-builder-crds are running !"

helm upgrade --install $YATAI_IMAGE_BUILDER_RELEASE_NAME -n $NAMESPACE_NAME ./$YATAI_IMAGE_BUILDER_TGZ -f ./values-yatai-image-builder.yaml

ibready=""

## 3. install yatai-image-builder
while [ "$ibready" != "true" ]; do
	ibready=$(kubectl -n $NAMESPACE_NAME get pods -o custom-columns=POD:metadata.name,READY-true:status.containerStatuses[*].ready | grep true | grep yatai-image-builder | awk '{print $2}')
	sleep 1
done
echo "yatai-image-builder is running !"