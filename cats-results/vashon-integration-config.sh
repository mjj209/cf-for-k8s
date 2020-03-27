#!/bin/bash

set -e

cat <<EOF
{
  "api": "api.vashon.k8s-dev.relint.rocks",
  "admin_user": "admin",
  "admin_password": "$(cat /tmp/vashon-password)",
  "apps_domain": "vashon.k8s-dev.relint.rocks",
  "artifacts_directory": "logs",
  "skip_ssl_validation": true,
  "use_http": true,
  "timeout_scale": 1,
  "include_apps": true,
  "include_backend_compatibility": false,
  "include_deployments": false,
  "include_capi_no_bridge": false,
  "include_container_networking": false,
  "include_detect": false,
  "include_docker": false,
  "include_ssh": false,
  "include_internet_dependent": false,
  "include_isolation_segments": false,
  "include_private_docker_registry": false,
  "include_route_services": false,
  "include_routing": false,
  "include_routing_isolation_segments": false,
  "include_security_groups": false,
  "include_services": false,
  "include_sso": false,
  "include_tasks": false,
  "include_tcp_routing": false,
  "include_v3": false,
  "include_zipkin": false
}
EOF
