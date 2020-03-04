---
# Related publishing issue: https://github.ibm.com/IBMCode/IBMCodeContent/issues/3797

authors:
  - name: "Denilson Nastacio"
    email: "dnastaci@us.ibm.com"

# cities:        # Required=false For a full list of options see https://github.ibm.com/IBMCode/Definitions/blob/master/cities.yml. Use the slug value found at the referenced link to include it in this content.

# collection:        # Required=false 

completed_date: '2020-03-03'
last_updated: '2020-03-03'

components:        # Required=false For a full list of options see https://github.ibm.com/IBMCode/Definitions/blob/master/components.yml
  - "cloud-pak-for-applications"
  - "cloud-native"
  - "microprofile"
  - "open-liberty"
  - "istio"
  - "kabanero"
  - "kubernetes"
  - "zipkin"

draft: true

meta_description: "Making sense of Appsody microservice transactions with distributed tracing."
abstract: "Making sense of Appsody microservice transactions with distributed tracing."
excerpt: "Making sense of Appsody microservice transactions with distributed tracing."

meta_keywords:        # Required=true This is a comma separated list of keywords used for SEO purposes.
  - "appsody"
  - "icpa"
  - "kabanero"
  - "kubernetes"
  - "microservices"
  - "opentracing"
  - "jaeger"

primary_tag: appsody

pta: "cloud, container, and infrastructure"

pwg:        # Required=true Note: can be one or many. For a full list of options see https://github.ibm.com/IBMCode/Definitions/blob/master/portfolio-working-group.yml. Use the slug value found at the referenced link to include it in this content.
  - containers

related_content:        # Required=false Note: zero or more related content
  - type: "blogs"
    slug: "app-modernization-ibm-cloud-pak-applications/"

related_links:
  - title: "Appsody website"
    url: "https://appsody.dev/"
    # description:
  - title: "Kabanero.io website"
    url: "https://kabanero.io"
    # description:
  - title: "IBM Cloud Pak for Applications"
    url: "https://developer.ibm.com/components/cloud-pak-for-applications/"
    description: "A hybrid, multicloud foundation for modernizing existing applications and developing new cloud-native apps"
  - title: "Learning Distributed Tracing 101"
    url: "https://ibm-cloud-architecture.github.io/learning-distributed-tracing-101/docs/index.html"
  - title: https://opentracing.io/
    url: "https://opentracing.io/"
    description: "Vendor-neutral APIs and instrumentation for distributed tracing"


title: "Distributed tracing for Appsody microservices: Part 2"
meta_title: "Distributed tracing for Appsody microservices: Part 2"
subtitle: "Make sense of Appsody microservice transactions with distributed tracing"

tags:
  - "appsody"
  - "cloud"
  - "containers"
  - "microservices"

type: tutorial
---

This the second part of a two-part tutorial, where you will deploy the microservices created in part 1 behind a service mesh in a a Kubernetes cluster and then use popular traffic analysis tools to observe and inspect the internal state of the distributed service

This tutorial is meant for developers who are somewhat familiar with the concept of distributed tracing using [OpenTracing](https://opentracing.io/) APIs as well as the [Istio service mesh](https://istio.io)

As mentioned in part 1, Appsody  is one of the upstream open source projects included in [IBM Cloud Pak for Applications] (https://www.ibm.com/cloud/cloud-pak-for-applications) and is used through this series to expedite the creation and deployment of the microservices.

At the end of the tutorial, you will have instrumented the existing microservices to work inside a Kubernetes cluster augmented with an Istio service mesh, generated some traffic through that microservices architecture, and used tools like Kiali and Jaeger to progressively drill into the state of the overall system:

![Tutorial overview](images/tutorial-overview-part-2.png)

This [GitHub repository](https://github.com/IBM/icpa-opentracing) contains a copy of the final application after completion of all steps, which you can use as a reference throughout the 
tutorial.


### A word about service meshes

The full potential of microservices relies on flexibility and resilience in the communications, so that new services or new versions of existing services can be introduced and removed without negative impacts to the overall system.

Service meshes such as [Istio](https://istio.io) are commonly paired with microservices to intermediate traffic amongst them, injecting functionality such as load balancing, security, and automatic generation of traffic metrics.

If you are new to service meshes and want to learn more about them before proceeding, [this overview](https://www.redhat.com/en/topics/microservices/what-is-a-service-mesh) is a good starting point, whereas the [Istio Concepts](https://istio.io/docs/concepts/what-is-istio/) page expands those concepts into a more detailed view of Istio capabilities. If you want to dive even deeper into service meshes after you complete this tutorial, you can try these guided [Service Mesh labs](https://learn.openshift.com/servicemesh/), with hands-on exercises ranging from basic to advanced lessons.



## Prerequisites

* [Install Docker](https://docs.docker.com/get-started/).
  If using Windows or macOS, Docker Desktop is probably the best choice. If using a Linux system, [minikube](https://github.com/kubernetes/minikube) and its internal Docker registry is an alternative.

* [Install the Appsody CLI](https://appsody.dev/docs/getting-started/installation).

* Install Kubernetes. [minikube](https://github.com/kubernetes/minikube) will work on most platforms, but if using Docker Desktop, the internal Kubernetes enabled from the Docker Desktop Preferences (macOS) or Settings (Windows) panel is a more convenient alternative.



## Estimated time

With the prerequisites in place, you should be able to complete this second part of the tutorial in 1 hour.



## Steps

Following along to this tutorial, you will perform the following steps:

1. Setup development environment
1. Create the Node.js application
1. Create the JEE application
1. Create the Spring boot application
1. Create the microservice dependencies
1. Examining tracing results
1. Istio service mesh
1. Tear down

These steps can be split into two major groups, first building and instrumenting the basic microservice applications, then progressing into a more complex deployment into an Istio service mesh.

Using a service mesh reflects a more common deployment topology for production environments, specially when using Appsody in combination with the other components of project Kabanero (the upstream open source project for IBM Cloud Pak for Applications).



## Step 1. Setup local development environment


### Jaeger tracing options

The first part of the tutorial defined a `jaeger.properties` file, following the properties documented in the [Client Library Features](https://www.jaegertracing.io/docs/latest/client-features/) page of the Jaeger website and you will need to define a few of those properties.

The difference in this portion of the tutorial is the usage of the full hostname of the  `jaeger-collector` service in `JAEGER_ENDPOINT`, since the microservices will be running in a different Kubernetes namespace than the Jaeger server.

Create a file for the Jaeger client properties, named `jaeger.properties`:

```properties
cat > jaeger.properties << EOF
JAEGER_ENDPOINT=http://jaeger-collector.istio-system.svc.cluster.local:14268/api/traces
JAEGER_REPORTER_LOG_SPANS=true
JAEGER_SAMPLER_TYPE=const
JAEGER_SAMPLER_PARAM=1
JAEGER_PROPAGATION=b3
EOF
```

The first part had a few special n are a few special notes about the contents of this configuration file:

- If you read through the [Jaeger architecture](https://www.jaegertracing.io/docs/latest/architecture/) page, the `JAEGER_ENDPOINT` variable instructs the client library to send span data directly to the Jaeger collector process instead of sending it to the intermediary agent process. This is an arbitrary decision for the purposes for this tutorial and has no impact on the final outcome in the Jaeger database. In a real production environment, there may be reasons to aggregate traffic through a Jaeger agent, but that discussion is outside the scope of this tutorial. 

- The combination of the `JAEGER_SAMPLER_TYPE` and `JAEGER_SAMPLER_PARAM` values is instructing the Jaeger client library to send every span to the Jaeger backend. This approach is appropriate for a tutorial where we want to inspect each request, but it may negatively affect the performance of the system in a real production environment. Refer to the Jaeger documentation on [sampling](https://www.jaegertracing.io/docs/sampling/) to make an informed decision about the ideal sampling settings for your environment.


## Step 2. Deploy the service mesh

This tutorial uses Istio as the service mesh for the microservices architecture completed in the previous steps.

Thanks to the "side-car" architecture pattern, also used in Istio, a new traffic intermediation container is added to each pod running a service, which means microservices do not require alterations to benefit from the service mesh functionality.

The next steps assume the usage of the Istio "Demo" profile added on top of minikube or the Kubernetes cluster bundled with Docker Desktop . It is possible to use other providers, but installation of everything present in the Istio "Demo" profile may be quite involved and are outside the scope of thius tutorial.

Assuming you will follow the recommendation of using minikube or the Kubernetes cluster bundled with Docker Desktop, proceed with the [Istio installation instructions](https://istio.io/docs/setup/getting-started/) , which are summarized below:


```
curl -L https://istio.io/downloadIstio | sh -

export PATH="$PATH:$(PWD)/istio-1.4.4/bin"

istioctl verify-install

istioctl manifest apply  --set profile=demo --set values.tracing.enabled=true --set values.kiali.enabled=true
```

The output shoud look similar to the one below

```
- Applying manifest for component Base...
✔ Finished applying manifest for component Base.
- Applying manifest for component Tracing...
- Applying manifest for component Citadel...
- Applying manifest for component Policy...
- Applying manifest for component Prometheus...
- Applying manifest for component Kiali...
- Applying manifest for component EgressGateway...
- Applying manifest for component IngressGateway...
- Applying manifest for component Pilot...
- Applying manifest for component Galley...
- Applying manifest for component Telemetry...
- Applying manifest for component Injector...
- Applying manifest for component Grafana...
✔ Finished applying manifest for component Citadel.
✔ Finished applying manifest for component Prometheus.
✔ Finished applying manifest for component Kiali.
✔ Finished applying manifest for component Galley.
✔ Finished applying manifest for component Tracing.
✔ Finished applying manifest for component Injector.
✔ Finished applying manifest for component Policy.
✔ Finished applying manifest for component Pilot.
✔ Finished applying manifest for component EgressGateway.
✔ Finished applying manifest for component IngressGateway.
✔ Finished applying manifest for component Grafana.
✔ Finished applying manifest for component Telemetry.
```



## Step 3. Create the namespace for the microservices

The tutorial will create a number of resources in the target cluster and it is beneficial to keep that content separate from other resources you may already have in the container.

You will create a new namespace for this tutorial, named `tracing`, typing the following commands in a command-line terminal:

```sh
kubectl get namespace tracing || \
kubectl create namespace tracing
```



## Step 4. Making the Jaeger collector reachable across namespaces

Once the installation is complete, you should be able to see all content created by Istio installation by typing the following command into a terminal:

```sh
kubectl get all -n istio-system
```

The output of that command shows all Deployments, ReplicaSets, Pods, and Services supporting Istio. Note this particular `Service` entry in the output:

```
service/jaeger-collector         ClusterIP   ...
```

The instructions in this tutorial place the microservices on the `default` namespace, which is different than the `istio-system` namespace where `jaeger-collector` resides. Therefore, we want Kubernetes to map any references to `jaeger-collector` in the `default` namespace towards the actual service running in the `istio-system` namespace.

Following the [Kubernetes DNS naming resolution scheme](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/), you can realize the resulting hostname for the Jaeger collector to be `jaeger-collector.istio-system.svc.cluster.local`. Hardcoding that hostname in the configuration of all microservices is not a good idea since it would introduce a hard dependency on the service mesh architecture and topology, so the better approach is to create a `Service` instance with the type [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) .

Type the following commands on a command-line terminal in order to create that `Service` instance:

```sh
cat <<EOF | kubectl apply -n tracing -f -
kind: Service
apiVersion: v1
metadata:
  name: jaeger-collector
spec:
  type: ExternalName
  externalName: jaeger-collector.istio-system.svc.cluster.local
  ports:
  - port: 14268
EOF
```


## Step 5. Create the Docker images for the microservices

As a first step prior to deployment of the microservices, you will request the build of the Docker images for each of the microservices. For this step, you can reuse the command-line terminals from the first part of this tutorial or create new ones. 

Assuming the environment variable `tutorial_dir` was set to the directory where you first started the tutorial and created the `jaeger.properties` file, type the following commands from the command-line terminal:

```sh
cd "${tutorial_dir}"
cd nodejs-tracing
appsody build
```

```sh
cd "${tutorial_dir}"
cd springboot-tracing
appsody build
```

```sh
cd "${tutorial_dir}"
cd jee-tracing
appsody build
```

Once all image builds are complete, inspect the output of the following command:

```sh
docker images dev.local/*
```

This command should result in an output similar to this:

```
REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
dev.local/nodejs-tracing       latest              597adcbeb47e        3 minutes ago       192MB
dev.local/springboot-tracing   latest              c2ccb43475e1        4 minutes ago       412MB
dev.local/jee-tracing          latest              138f3c5276d6        4 minutes ago       708MB
```

Additionally, you will also find a new `app-deploy.yaml` file at the root of each respective project.
This deployment file contains an `AppsodyApplication` definition, which is documented in detail in the [Appsody Operator GitHub page](https://github.com/appsody/appsody-operator/tree/master/doc).

This tutorial will have small and instructions for modifications to the file, but you can refer to the [Appsody Operator User Guide](https://github.com/appsody/appsody-operator/blob/master/doc/user-guide.md) if you plan on further customizing the deployment of the microservices.



## Step 6. Create application configuration

[Create a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap) with the Jaeger configuration settings added to `jaeger.properties` earlier in this tutorial:

```sh
cd "${tutorial_dir}"
kubectl create configmap jaeger-config -n tracing --from-env-file=jaeger.properties

kubectl get configmap jaeger-config -n tracing -o yaml
```

Add the new ConfigMap to the application, inserting the `envFrom` snippet to the `spec` section of the `app-deploy.yaml` file for each application, as exemplified below:

```yaml
spec:
...
  envFrom:
  - configMapRef:
      name: jaeger-config
  ...
```


## Step 7. Configure sidecar injection

An Istio sidecar is a proxy added by Istio throughout the environment, with the purpose of intercepting the communication betweeen microservices before exercising its traffic management functions. You can read more about all the available possibilities in the [Istio sidecar configuration](https://istio.io/docs/reference/config/networking/sidecar/) page, but for the purposes of this tutorial, you are interested in the proxy's ability to add tracing instrumentation to the applications in the pod.

There are two ways of injecting the Istio sidecar to an application:

1. Using the `istio kube-inject` command
2. Enabling automatic injection of sidecars to all applications added to a namespace

The second alternative is more approachable for this tutorial, since it requires less instructions to be typed on the terminal. 

Enabling automatic injection is described in the [Installing the Sidecar](https://istio.io/docs/setup/additional-setup/sidecar-injection/) section of the Istio documentation. The essential takeaway from that documentation is that you need to add the label `istio-injection=enabled` annotation to the namespace where you want automatic injection of the sidecar, so type the following instructions in the command-line:

```sh
kubectl label namespace tracing istio-injection=enabled
```

You can verify the results of this 
```sh
kubectl get namespace -L istio-injection
```

Add the `sidecar.istio.io/inject` annotation to the `metadata.annotations` section of the `app-deploy.yaml` file for each application. 

```yaml
metadata:
  annotations:
    ...
    sidecar.istio.io/inject: "true"
    ...
  ...
...
```

Notice how you could set the `sidecar.istio.io/inject` annotation to `"false"` to turn off the injection for an individual application even when automatic injection is enabled for the target namespace.

Optionally, replace the `service.type` value from `NodePort` to `ClusterIP` in `app-deploy.yaml`. This will remove the external port for the microservice, which ensures no one accidentally bypasses the Istio traffic management.



## Step 8. Labeling the workload

Istio has a number of optional labels that can be quite useful to further categorize metrics, specially when visualizing the data from the Kiali console.

These labels are defined in the [Pods and Services](https://istio.io/docs/ops/deployment/requirements/) page of the Istio documentation. Add the following labels to the `app-deploy.yaml` file for the `nodejs-tracing` application:

```yaml
metadata:
  ...
  labels:
     app: nodejs-tracing
     version: v1
     ...
...
```


## Step 9. Deploy the microservices

As a summary up to this point, you have made the following changes to your cluster and to the deployment descriptor of each application:

- Created a namespace (`tracing`) for deploying the applications

- Enabled that namespace for automatic Istio sidecar injection

- Created a `ConfigMap` resource containing the Jaeger endpoint information

- Added an `envFrom` entry to reference the `ConfigMap` resource in the `app-deploy.yaml` deployment descriptor for each application 

- Added a `sidecar.istio.io/inject` annotation to the `service` in the `app-deploy.yaml` deployment descriptor for each application

With all those changes in place, and ssuming the environment variable `tutorial_dir` is set to the directory where you first started the tutorial, type the following commands from the command-line terminal:

```sh
cd "${tutorial_dir}"
cd nodejs-tracing
appsody deploy --namespace tracing
```

```sh
cd "${tutorial_dir}"
cd springboot-tracing
appsody deploy --namespace tracing
```

```sh
cd "${tutorial_dir}"
cd jee-tracing
appsody deploy --namespace tracing
```

In concrete terms for the actual deployment, the "sidecar injection" means Istio adds a proxy container to the each pod running the microservices. This is a good point in the tutorial to take a look at the running containers before the injection. Type the following instruction in the command-line terminal:

```sh
kubectl get pods -n tracing -l app.kubernetes.io/managed-by=appsody-operator
```

You should see output similar to the one below, with a two containers inside each pod, which indicates the sidecar has been added:

```
NAME                                  READY   STATUS    ...
jee-tracing-6cd5784b57-hm65c          2/2     Running   ...
nodejs-tracing-5cf9f655db-kl4gl       2/2     Running   ...
springboot-tracing-5f7b7fb74f-hzxl5   2/2     Running   ...
```


### Note about sidecar injection at the application level

The previous sections enabled sidecar injection for all deployments in a namespace. There may be good reasons to avoid introducing that default behavior and apply instrumentation of individual applications. Just in the way of a reference, this is how you would instrument an Appsody-based application with an Istio sidecar after it has been deployed:

```sh
application_name=<<name of your Appsody application, such as "nodejs-tracing" >>
kubectl get deployment ${application_name}  -o yaml | istioctl kube-inject -f - | kubectl apply -f -
```

Note that `kube-inject` command modifies the deployment descriptor directly in the cluster, leaving the original `app-deploy.yaml` file unmodified. Future invocations of `appsody deploy` will overwrite those modifications.


### (Optional) Tail microservices logs

You can type the following commands in three separate terminal windows to follow the console output of each application as you progress towards the rest of the tutorial:

```sh
kubectl logs -n tracing -f -l app.kubernetes.io/name=nodejs-tracing --all-containers | grep -vi "live\|ready\|inbound\|metrics"
```

```sh
kubectl logs -n tracing -f -l app.kubernetes.io/name=springboot-tracing --all-containers | grep -vi "live\|ready\|inbound"
```

```sh
kubectl logs -n tracing -f -l app.kubernetes.io/name=jee-tracing --all-containers | grep -vi "live\|ready\|inbound"
```


## Step 10. Create ingress routes for the top-level application

As the final step before sending transactions into the Node.js microservice, you need to configure Istio Gateway and VirtualService resources to route traffic to the application:


```sh
cat <<EOF | kubectl apply -n tracing -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: tracing-tutorial-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tracing-tutorialinfo
spec:
  hosts:
  - "*"
  gateways:
  - tracing-tutorial-gateway
  http:
  - match:
    - uri:
        exact: /node-springboot
    - uri:
        exact: /node-jee
    route:
    - destination:
        host: nodejs-tracing
        port:
          number: 3000
EOF
```

Note the presence of the `/node-springboot` and `/node-jee` virtual endpoints in the `VirtualService`, which map to the respective endpoints in the Node.js application.

Now issue the following commands a few times:

```sh
curl localhost/node-springboot
curl localhost/node-jee
```


## Step 11. Inspect telemetry

Istio bundles several popular tools for analyzing different facets. This tutorial will focus on Kiali and Jaeger. 

### Kiali

The [Kiali UI](https://docs.openshift.com/container-platform/latest/service_mesh/service_mesh_arch/ossm-kiali.html) provides visibility into your service mesh by showing you the microservices in your service mesh, and how they are connected.

You could expose the Kiali UI to a fixed port in your localhost using the instructions in https://istio.io/docs/tasks/observability/gateways/#option-2-insecure-access-http, but it is more convenient to use the `istioctl dashboard` command. 

Type the following instruction on a command-line interface:

```sh
istioctl dashboard kiali
```

The default user and password will be `admin:admin`

See status of application

![Application status](/images/kiali-ui-overview.png)


![Application topology](/images/kiali-ui-graph.png)

![Application overview](/images/kiali-ui-applications.png)

![Workloads](/images/kiali-ui-workloads.png)

![Services](/images/kiali-ui-services.png)

[Need support for named ports for service meshes](https://github.com/appsody/appsody-operator/issues/227)

[Istio "version" label is not supported to allow multiple versions of app in the same cluster](https://github.com/appsody/appsody-operator/issues/228)


### Jaeger UI

```sh
istioctl dashboard jaeger
```


## Step 12. Tear down the deployment

Remove all applications from the cluster by typing the following instruction from the directory containing each application:

```sh
cd "${tutorial_dir}"
cd nodejs-tracing ;     appsody deploy delete
cd springboot-tracing ; appsody deploy delete
cd jee-tracing ;        appsody deploy delete
```

Alternatively, you can also remove the Appsody-based microservices by using the `kubectl` command to delete the `AppsodyApplication` for that microservie, typing the following instructions on a command-line terminal:

```sh
kubectl delete AppsodyApplication nodejs-tracing
kubectl delete AppsodyApplication springboot-tracing
kubectl delete AppsodyApplication jee-tracing
```

If you deployed Istio as part of this tutorial, you can remove it from your cluster by typing the following instructions on a command-line terminal:

```sh
kubectl delete namespace istio-system
kubectl delete namespace tracing

```


## Next steps

- Further explore other [Istio Telemetry Addons](https://istio.io/docs/tasks/observability/gateways/)

- You can try these hands-on [service mesh labs](https://learn.openshift.com/servicemesh/), which contains a good list of basic and advanced lessons.


## API references 

- [Spans](https://opentracing.io/docs/overview/spans/)
- [The OpenTracing Semantic Specification](https://github.com/opentracing/specification/blob/master/specification.md)
- [NodeJS OpenTracing API doc](https://opentracing-javascript.surge.sh/)
- [OpenTracing API Javadoc](https://javadoc.io/doc/io.opentracing/opentracing-api/latest/index.html)
- [MicroProfile OpenTracing](https://github.com/eclipse/microprofile-opentracing)
- [Java Spring Jaeger](https://github.com/opentracing-contrib/java-spring-jaeger)


## Credits

- Thanks to my colleague Carlos Santana, who wrote the excellent ["Learning Distributed Tracing 101" tutorial](https://ibm-cloud-architecture.github.io/learning-distributed-tracing-101/docs/index.html), which was instrumental in helping me figure out the Node.js aspects of this tutorial.

- Thanks to Yuri Shkuro (the father of Jaeger) and Junmin Liu for the excellent [Node.js chapter of the OpenTracing tutorial](https://github.com/yurishkuro/opentracing-tutorial/tree/master/nodejs).
