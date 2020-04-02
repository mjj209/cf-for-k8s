TODO: 
- Why do we have so many cert variables? How might a user generate a cert per component?
- We should remove the documentation for `-g` gcr option. For users, we ask them to manaully configure the registry. 
  The docs become very easy to follow.


---
# Deploying CF for K8s

- [Prerequisites](#prerequisites)
  * [Required Tools](#required-tools)
  * [Kubernetes Cluster Requirements](#kubernetes-cluster-requirements)
  * [IaaS Requirements](#iaas-requirements)
  * [Requirements for Cloud Native Buildpacks Support](#requirements-for-cloud-native-buildpacks-support)
- [Steps to deploy](#steps-to-deploy)
    + [Option A - Use the included hack-script to generate the install values](#option-a---use-the-included-hack-script-to-generate-the-install-values)
    + [Option B - Create the install values by hand](#option-b---create-the-install-values-by-hand)
- [Validate the deployment using a source-based app](#optional-validate-the-deployment-using-a-source-based-app)
- [Delete CF4K8s install](#delete-cf4k8s-install)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## Prerequisites

### Required Tools

You need the following CLIs on your system to be able to run the script:

* [`kapp`](https://k14s.io/#install)
* [`ytt`](https://k14s.io/#install) (v0.26.0+)

In addition, you will also probably want [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for your own debugging and inspection of the system.

Make sure that your Kubernetes config (e.g, `~/.kube/config`) is pointing to the cluster you intend to deploy CF for K8s to.

### Kubernetes Cluster Requirements
:exclamation::exclamation::exclamation: This is a highly experimental project and resource requirements are subject to change in the future. :exclamation::exclamation::exclamation:

To deploy cf-for-k8s as is, the cluster should:
* be running version 1.14.x, 1.15.x, or 1.16.x
* have a minimum of 5 nodes
* have a minimum of 3 CPU, 7.5GB memory per node

### IaaS Requirements

* support LoadBalancer services
  * requires a workaround on Minikube and Kind, for example
* define a default StorageClass
  * requires [additional config on vSphere](https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/storageclass.html), for example

### Requirements for pushing source-based apps to Cloud Foundry

To be able to push source-based apps to your CF for K8s installation, you will need to add OCI compliant registry (e.g. dockerhub.com) to the configuration. 

> Under the hood, CF for K8s uses Cloud Native buildpacks to detect and build the app source code into an oci compliant image and pushes the app image to the given registry. Currently, CF for K8s has only been tested with Google Container Registry (GCR) and Dockerhub.com. Ideally, it should work for any external OCI compliant registry.

To deploy cf-for-k8s with the Cloud Native Buildpacks feature, you additionally need to:
  1. create a GCP Service Account with `Storage/Storage Admin` role
      * (optionally) if you want to limit the permissions this service account has, see https://cloud.google.com/container-registry/docs/access-control for the minimum permission set
  1. create a Service Key JSON and download it to the machine from which you will install cf-for-k8s (referred to, below, as `path-to-kpack-gcr-service-account`)

## Steps to deploy

1. Clone and initialize this git repository:
   ```console
   $ git clone https://github.com/cloudfoundry/cf-for-k8s.git
   $ cd cf-for-k8s
   ```

1. Set your current `kubectl` context to your desired Kubernetes cluster

1. Create a "CF Installation Values" file and configure it:

   You can either: a) auto-generate the installation values or b) create the values by yourself.

   #### Option A - Use the included hack-script to generate the install values
   > **NOTE:** The script requires the [BOSH CLI](https://bosh.io/docs/cli-v2-install/#install) in installed on your machine. The BOSH CLI has a handy tool to generate self signed certs and passwords.
   
   ```console
   $ ./hack/generate-values.sh -d <cf-domain> > /tmp/cf-values.yml
   ```
   Replace `<cf-domain>` with _your_ registered DNS domain name.

   #### Option B - Create the install values by hand
   1. Clone file `sample-cf-install-values.yml` in this directory as a starting point
   ```console
   $ copy sample-cf-install-values.yml /tmp/cf-values.yml
   ```
   2. Open the `cf-values.yml` file and follow the instructions to update the configuration. At minimum you should provide 3 required configuration values.

   | Field  |  Details |
   | ------------- | ------------- |
   | `system_domain`  | Update to your desired domain address  |
   | `app_domain`  | Update to your desired domain address |
   | `system_certificate` | Generate certificates for the above domains and paste them in `crt`, `key`, `ca` values. Certificates and keys should be base64 encoded and valid for your *.<cf-domain>.  |

      > **Important** Your certificates must include a subject alternative name entry for the internal `*.cf-system.svc.cluster.local` domain in addition to your chosen external domain.


1. To enable Cloud Native Buildpacks feature, configure access to an external registry in `cf-values.yml`:
   1. To configure Dockerhub.com
      Uncomment dockerhub configuration in `cf-values.yml` and comment Google container registry registry configuration
      ```console
      app_registry:
         hostname: https://index.docker.io/v1/
         repository: "<my_username>"
         username: "<my_username>"
         password: "<my_password>"
      ```
      1. Update `<my_username>` with your docker username
      1. Update `<my_username>` with your docker password

   1. Configure Google Container Registry
      ```console
      app_registry:
         hostname: gcr.io
         repository: gcr.io/<gcp_project_id>/cf-workloads
         username: _json_key
         password: |
            <contents_of_service_account_json>
      ```
      1. Update the `gcp_project_id` portion to your GCP Project Id. 
      1. Change `contents_of_service_account_json` to be the entire contents of your GCP Service Account JSON

   > If you do NOT wish to enable Cloud Native Buildpacks support, then remove the `app_registry` block from your `cf-values.yml`

1. Run the install script with your "CF Install Values" file
   ```console
   $ ./bin/install-cf.sh /tmp/cf-values.yml
   ```

1. Configure DNS on your IaaS provider to point the wildcard subdomain of your
   system domain and the wildcard subdomain of all apps domains to point to external IP
   of the Istio Ingress Gateway service. You can retrieve the external IP of this service by running
   `kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].ip}'`
   1. If you used the `./hack/generate-values.sh` script then you should only
      configure a single DNS record for the domain you passed as input to the
      script and have it resolve to the Ingress Gateway's external IP

      e.g.
      ```
      # sample A record in Google cloud DNS. The IP address below is the address of Ingress gateway's external IP
      Domain         Record Type  TTL  IP Address
      *.<cf-domain>  A            30   35.111.111.111
      ```

## Validate the deployment

Assuming you have enabled support for Cloud Native Buildpacks:

1. Target your CF CLI to point to the new CF instance

```console
$ cf api --skip-ssl-validation https://api.<cf-domain>
```

1. Login using the admin credentials for key `cf_admin_password` in `/tmp/cf-values.yml` 
```console
$ cf auth admin <cf-values.yml.cf-admin_password>
```

1. Create an org and space in the new CF instance
```console
$ cf create-org <org-name> && cf target -o <org-name> && cf create-space <space-name> && cf target -o <org-name> <space-name>
```

1. Enable `diego_docker feature flag

> This is a temporary hack to enable cf push in CF for K8s. The team has plans to remove this requirement soon.

```console
$ cf enable-feature-flag diego_docker
```

1. Deploy a source-based app:
```console
   $ cf push test-node-app -p tests/smoke/assets/test-node-app
   Pushing app test-node-app to org test-org / space test-space as admin...
   Getting app info...
   Creating app with these attributes...
   + name:       test-node-app
     path: /Users/pivotal/workspace/cf-for-k8s/tests/smoke/assets/test-node-app
     routes:
   +   test-node-app.cf.example.com

   Creating app test-node-app...
   Mapping routes...
   Comparing local files to remote cache...
   Packaging files to upload...
   Uploading files...
    498 B / 498 B [==================================================================================================================================================================================================================================================================================================] 100.00% 1s

   Waiting for API to complete processing files...

   Staging app and tracing logs...
   Failed to retrieve logs from Log Cache: Get /api/v1/info: unsupported protocol scheme ""

   Failed to retrieve logs from Log Cache: Get /api/v1/info: unsupported protocol scheme ""

   Failed to retrieve logs from Log Cache: Get /api/v1/info: unsupported protocol scheme ""

   Failed to retrieve logs from Log Cache: Get /api/v1/info: unsupported protocol scheme ""

   Failed to retrieve logs from Log Cache: Get /api/v1/info: unsupported protocol scheme ""
   

   Waiting for app to start...

   name:                test-node-app
   requested state:     started
   isolation segment:   placeholder
   routes:              test-node-app.cf.example.com
   last uploaded:       Tue 17 Mar 19:24:21 PDT 2020
   stack:
   buildpacks:

   type:           web
   instances:      1/1
   memory usage:   1024M
        state     since                  cpu    memory    disk      details
   #0   running   2020-03-18T02:24:51Z   0.0%   0 of 1G   0 of 1G
```

1. Validate that the app is reachable
   ```console
   $ curl http://test-node-app.<cf-domain>
   Hello World
   ```

## Delete CF4K8s install
You can delete CF4K8s deployment by running the following command.
```console
# Assuming that you ran `bin/install.sh...`
$ kapp delete -a cf
```
