#!/bin/bash

set -e

###
### Variables
###

## Your Organization
CLUSTER_NAME="mycluster"

## Consul
CONSUL_SERVER="172.17.8.50"
CONSUL_ROOT="consul"
CONSUL_DATACENTER="dc1"

## etcd
ETCD3_CONSUL_SERVICE_NAME="etcd3"
ETCD3_CONSUL_SERVICE="${CLUSTER_NAME}.${ETCD3_CONSUL_SERVICE_NAME}.service.${CONSUL_DATACENTER}.${CONSUL_ROOT}"
ETCD3_INITIAL_CLUSTER_TOKEN="etcd-cluster-1"

## Kubelet
CLUSTER_DNS="10.3.0.10"
CLUSTER_DOMAIN="${CLUSTER}.ingress.service.${CONSUL_DATACENTER}.${CONSUL_ROOT}."

## Files
SCRIPT_ROOT="$PWD/$(dirname $0)"
echo "SCRIPT_ROOT: ${SCRIPT_ROOT}"
# Service
KUBELET_FILE="${SCRIPT_ROOT}/units/kubelet.service"
SOCAT_SERVICE_FILE="${SCRIPT_ROOT}/units/socat.service"
ETCD3_REGISTER_FILE="${SCRIPT_ROOT}/units/etcd3-register.service"
ETCD3_DNS_CHECK_THEN_ACTIVATE_FILE="${SCRIPT_ROOT}/units/etcd3-dns-check-then-activate.service"
# Pods
CONSUL_SERVER_POD_FILE="${SCRIPT_ROOT}/pods/consul-server.yaml"
CONSUL_AGENT_POD_FILE="${SCRIPT_ROOT}/pods/consul-agent.yaml"
ETCD3_POD_FILE="${SCRIPT_ROOT}/pods/etcd3.yaml"
# Cloud Config
CONSUL_CLOUD_CONFIG_FILE="${SCRIPT_ROOT}/consul-cloud-config.yaml"
ETCD3_CLOUD_CONFIG_FILE="${SCRIPT_ROOT}/etcd-cloud-config.yaml"
# Kubeconfig
KUBECONFIG_FILE="${SCRIPT_ROOT}/assets/auth/kubeconfig"

###
### Generate Assets
###

## Generate Assets
if [ -d "${SCRIPT_ROOT}/assets" ]; then
  rm -rf "${SCRIPT_ROOT}/assets"
fi
docker run -it \
  -v "${SCRIPT_ROOT}:/tmp/mount" \
  quay.io/coreos/bootkube:v0.3.7 \
  /bootkube render \
  --asset-dir /tmp/mount/assets \
  --api-servers "https://${CLUSTER_NAME}.apiserver.service.${CONSUL_DATACENTER}.${CONSUL_ROOT}:443"

###
### Templating
###

KUBELET_SERVICE_TEMPLATED=$(cat "${KUBELET_FILE}" \
  | sed -e "s!CLUSTER_DOMAIN!${CLUSTER_DOMAIN}!g" \
  | sed -e "s!CLUSTER_DNS!${CLUSTER_DNS}!g" \
  | gzip | base64 )
ETCD3_REGISTER_SERVER_SERVICE_TEMPLATED=$(cat "${ETCD3_REGISTER_FILE}" \
  | sed -e "s!CLUSTER_NAME!${CLUSTER_NAME}!g" \
  | sed -e "s!ETCD3_CONSUL_SERVICE_NAME!${ETCD3_CONSUL_SERVICE_NAME}!g" \
  | sed -e "s!TAG_TYPE!server!g" \
  | sed -e "s!TARGET_PORT!2380!g" \
  | gzip | base64 )
ETCD3_REGISTER_CLIENT_SERVICE_TEMPLATED=$(cat "${ETCD3_REGISTER_FILE}" \
  | sed -e "s!CLUSTER_NAME!${CLUSTER_NAME}!g" \
  | sed -e "s!ETCD3_CONSUL_SERVICE_NAME!${ETCD3_CONSUL_SERVICE_NAME}!g" \
  | sed -e "s!TAG_TYPE!client!g" \
  | sed -e "s!TARGET_PORT!2379!g" \
  | gzip | base64 )
ETCD3_DNS_CHECK_THEN_ACTIVATE_TEMPLATED=$(cat "${ETCD3_DNS_CHECK_THEN_ACTIVATE_FILE}" \
  | sed -e "s!ETCD3_CONSUL_SERVICE!${ETCD3_CONSUL_SERVICE}!g" \
  | gzip | base64 )
SOCAT_SERVICE_TEMPLATED=$(cat "${SOCAT_SERVICE_FILE}" \
  | gzip | base64 )
CONSUL_SERVER_TEMPLATED=$(cat "${CONSUL_SERVER_POD_FILE}" \
  | gzip | base64 )
CONSUL_AGENT_TEMPLATED=$(cat "${CONSUL_AGENT_POD_FILE}" \
  | sed -e "s!CONSUL_SERVER!${CONSUL_SERVER}!g" \
  | gzip | base64 )
KUBECONFIG_TEMPLATED=$(cat "${KUBECONFIG_FILE}" \
  | gzip | base64 )

CONSUL_CLOUD_CONFIG_TEMPLATED=$(cat "${CONSUL_CLOUD_CONFIG_FILE}" \
  | sed -e "s!KUBELET_SERVICE_TEMPLATED!${KUBELET_SERVICE_TEMPLATED}!g" \
  | sed -e "s!SOCAT_SERVICE_TEMPLATED!${SOCAT_SERVICE_TEMPLATED}!g" \
  | sed -e "s!KUBECONFIG_TEMPLATED!${KUBECONFIG_TEMPLATED}!g" \
  | sed -e "s!CONSUL_DATACENTER!${CONSUL_DATACENTER}!g" \
  | sed -e "s!CONSUL_SERVER_TEMPLATED!${CONSUL_SERVER_TEMPLATED}!g" )

ETCD3_CLOUD_CONFIG_TEMPLATED=$(cat "${ETCD3_CLOUD_CONFIG_FILE}" \
  | sed -e "s!KUBELET_SERVICE_TEMPLATED!${KUBELET_SERVICE_TEMPLATED}!g" \
  | sed -e "s!ETCD3_REGISTER_SERVICE_TEMPLATED!${ETCD3_REGISTER_SERVICE_TEMPLATED}!g" \
  | sed -e "s!ETCD3_REGISTER_SERVER_SERVICE_TEMPLATED!${ETCD3_REGISTER_SERVER_SERVICE_TEMPLATED}!g" \
  | sed -e "s!ETCD3_REGISTER_CLIENT_SERVICE_TEMPLATED!${ETCD3_REGISTER_CLIENT_SERVICE_TEMPLATED}!g" \
  | sed -e "s!ETCD3_DNS_CHECK_THEN_ACTIVATE_TEMPLATED!${ETCD3_DNS_CHECK_THEN_ACTIVATE_TEMPLATED}!g" \
  | sed -e "s!ETCD3_CONSUL_SERVICE!${ETCD3_CONSUL_SERVICE}!g" \
  | sed -e "s!ETCD3_INITIAL_CLUSTER_TOKEN!${ETCD3_INITIAL_CLUSTER_TOKEN}!g" \
  | sed -e "s!KUBECONFIG_TEMPLATED!${KUBECONFIG_TEMPLATED}!g" \
  | sed -e "s!CONSUL_SERVER!${CONSUL_SERVER}!g" \
  | sed -e "s!CONSUL_AGENT_TEMPLATED!${CONSUL_AGENT_TEMPLATED}!g" )

echo "${CONSUL_CLOUD_CONFIG_TEMPLATED}" > "${SCRIPT_ROOT}/generated/consul-cloud-config.yaml"
echo "${ETCD3_CLOUD_CONFIG_TEMPLATED}" > "${SCRIPT_ROOT}/generated/etcd3-cloud-config.yaml"
