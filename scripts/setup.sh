#!/usr/bin/env bash
set -eu
# MinIO settings and credentials
export MINIO_IMAGE="${MINIO_IMAGE:-quay.io/minio/minio:RELEASE.2024-09-13T20-26-02Z}"
export MINIO_EU_ROOT_USER="${MINIO_EU_ROOT_USER:-cnpg-eu}"
export MINIO_EU_ROOT_PASSWORD="${MINIO_EU_ROOT_PASSWORD:-postgres5432-eu}"
export MINIO_US_ROOT_USER="${MINIO_US_ROOT_USER:-cnpg-us}"
export MINIO_US_ROOT_PASSWORD="${MINIO_US_ROOT_PASSWORD:-postgres5432-us}"
# Look for a supported container provider and use it throughout
export containerproviders="docker"
for containerProvider in `which $containerproviders`; do
export CONTAINER_PROVIDER=$containerProvider
    break
done
export git_repo_root=$(git rev-parse --show-toplevel)
export kube_config_path=${git_repo_root}/k8s/kube-config.yaml
export kind_config_path=${git_repo_root}/k8s/kind-cluster.yaml
cd "${git_repo_root}"
export KUBECONFIG=${kube_config_path}
mkdir -p minio-eu
$CONTAINER_PROVIDER run \
   --name minio-eu \
	 -d \
   -v "${git_repo_root}/minio-eu:/data" \
   -e "MINIO_ROOT_USER=$MINIO_EU_ROOT_USER" \
   -e "MINIO_ROOT_PASSWORD=$MINIO_EU_ROOT_PASSWORD" \
   -u $(id -u):$(id -g) \
   ${MINIO_IMAGE} server /data --console-address ":9001"
mkdir -p minio-us
$CONTAINER_PROVIDER run \
   --name minio-us \
	 -d \
   -v "${git_repo_root}/minio-us:/data" \
   -e "MINIO_ROOT_USER=$MINIO_US_ROOT_USER" \
   -e "MINIO_ROOT_PASSWORD=$MINIO_US_ROOT_PASSWORD" \
   -u $(id -u):$(id -g) \
   ${MINIO_IMAGE} server /data --console-address ":9001"
# Setup the EU Kind Cluster
kind create cluster --config ${kind_config_path} --name k8s-eu
# The `node-role.kubernetes.io` label must be set after the node have been created
kubectl label node -l postgres.node.kubernetes.io node-role.kubernetes.io/postgres=
kubectl label node -l infra.node.kubernetes.io node-role.kubernetes.io/infra=
kubectl label node -l app.node.kubernetes.io node-role.kubernetes.io/app=

# Setup the US Kind Cluster
kind create cluster --config ${kind_config_path} --name k8s-us
# The `node-role.kubernetes.io` label must be set after the node have been created
kubectl label node -l postgres.node.kubernetes.io node-role.kubernetes.io/postgres=
kubectl label node -l infra.node.kubernetes.io node-role.kubernetes.io/infra=
kubectl label node -l app.node.kubernetes.io node-role.kubernetes.io/app=

$CONTAINER_PROVIDER network connect kind minio-eu
$CONTAINER_PROVIDER network connect kind minio-us

# Create the secrets for MinIO
for region in eu us; do
   kubectl create secret generic minio-eu \
      --context kind-k8s-${region} \
      --from-literal=ACCESS_KEY_ID="$MINIO_EU_ROOT_USER" \
      --from-literal=ACCESS_SECRET_KEY="$MINIO_EU_ROOT_PASSWORD"

   kubectl create secret generic minio-us \
      --context kind-k8s-${region} \
      --from-literal=ACCESS_KEY_ID="$MINIO_US_ROOT_USER" \
      --from-literal=ACCESS_SECRET_KEY="$MINIO_US_ROOT_PASSWORD"
done

./scripts/info.sh
