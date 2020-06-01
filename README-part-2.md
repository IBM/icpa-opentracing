---
# Related Review Board issue: https://github.ibm.com/IBMCode/IBMCodeContent/issues/3917

draft: true

completed_date: '2020-05-26'
last_updated: '2020-05-26'

title: "Distributed tracing for microservices, Part 2"
meta_title: "Distributed tracing for microservices, Part 2"
subtitle: "Enable your microservices in IBM Cloud Pak for Applications for greater visibility with modern observability techniques"

authors:
  - name: "Denilson Nastacio"
    email: "dnastaci@us.ibm.com"

abstract: "Making sense of Appsody microservice transactions with distributed tracing."
excerpt: "Making sense of Appsody microservice transactions with distributed tracing."
meta_description: "Making sense of Appsody microservice transactions with distributed tracing."

meta_keywords: "appsody, cloud pak for applications, kabanero, kubernetes, microservices, opentracing, jaeger"

primary_tag: "appsody"

tags:
  - "appsody"
  - "cloud"
  - "containers"
  - "microservices"

components:
  - "cloud-pak-for-applications"
  - "cloud-native"
  - "istio"
  - "kabanero"
  - "kubernetes"

related_content:
  - type: tutorials
    slug: distributed-tracing-for-microservices-1
  - type: blogs
    slug: app-modernization-ibm-cloud-pak-applications

related_links:
  - title: "Appsody.dev"
    url: "https://appsody.dev/"
  - title: "Kabanero.io"
    url: "https://kabanero.io"
  - title: "Learning Distributed Tracing 101"
    url: "https://ibm-cloud-architecture.github.io/learning-distributed-tracing-101/docs/index.html"
  - title: "OpenTracing specification"
    url: "https://opentracing.io/"

type: tutorial
---

This tutorial is the second part of a two-part tutorial series, where you deploy the microservices that are created in [Part 1](https://developer.ibm.com/tutorials/distributed-tracing-for-microservices-1/) behind a service mesh in a Kubernetes cluster. Then, you use popular traffic analysis tools to observe and inspect the internal state of the distributed service. This tutorial is meant for developers who are familiar with the concept of distributed tracing that uses [OpenTracing](https://opentracing.io/) APIs, as well as the [Istio service mesh](https://istio.io).

As mentioned in the [first part](https://developer.ibm.com/tutorials/distributed-tracing-for-microservices-1/) of this tutorial, [Appsody](https://appsody.dev/) is one of the upstream open source projects that are included in [IBM Cloud Pak for Applications](https://www.ibm.com/cloud/cloud-pak-for-applications). It is used through this tutorial series to expedite the creation and deployment of the microservices. In this tutorial, you instrument the existing microservices to work inside a Kubernetes cluster that is augmented with an Istio service mesh and generate some traffic through that microservices architecture. Then, you use tools like Grafana, Kiali, and Jaeger to progressively drill into the state of the overall system.

![Tutorial overview diagram](images/tutorial-overview-part-2.png)

A copy of the final application is available in [GitHub](https://github.com/IBM/icpa-opentracing), which you can use as a reference throughout the tutorial.

## A word about service meshes

The full potential of microservices relies on flexibility and resilience in the communications so that new services, or new versions of existing services, can be introduced and removed without negative impacts on the overall system. Service meshes such as [Istio](https://istio.io) are commonly paired with microservices to intermediate traffic among them, injecting functionality such as load balancing, security, and automatic generation of traffic metrics. If you are new to service meshes and want to learn more about them before proceeding, the [Red Hat microservices topic](https://www.redhat.com/en/topics/microservices/what-is-a-service-mesh) page is a good starting point, whereas the [Istio concepts](https://istio.io/docs/concepts/what-is-istio/) page expands those concepts into a more detailed view of Istio capabilities. If you want to dive even deeper into service meshes after you complete this tutorial, you can try the guided [Service Mesh labs](https://learn.openshift.com/servicemesh/), which have hands-on exercises that range from basic to advanced lessons.

## Prerequisites

* [Install Docker](https://docs.docker.com/get-started/). If you are using Windows or macOS, Docker Desktop is probably your best choice. If you are using a Linux system, [minikube](https://github.com/kubernetes/minikube) and its internal Docker registry are an alternative.
* [Install the Appsody CLI](https://appsody.dev/docs/getting-started/installation).
* Install Kubernetes locally if you do not have access to a Kubernetes or OpenShift cluster. [Minikube](https://github.com/kubernetes/minikube) works on most platforms, but if you are using Docker Desktop, the internal Kubernetes that is enabled from the Docker Desktop Preferences (macOS) or Settings panel (Windows) is a more convenient alternative.

## Estimated time

With the prerequisites in place, you should be able to complete this tutorial in an hour.

## Steps

The steps of this tutorial are split into two major groups: first building and instrumenting the basic microservice applications, and then progressing into a more complex deployment in an Istio service mesh. Using a service mesh reflects a more common deployment topology for production environments, especially when you use Appsody in combination with the other components of project [Kabanero](https://kabanero.io) (the upstream open source project for IBM Cloud Pak for Applications). Perform the following steps to complete this tutorial:

1. [Set up the local development environment](#1-set-up-the-local-development-environment)
1. [Deploy the service mesh](#2-deploy-the-service-mesh)
1. [Create the namespace for the microservices](#3-create-the-namespace-for-the-microservices)
1. [Create the Docker images for the microservices](#4-create-the-docker-images-for-the-microservices)
1. [Create the application configuration](#5-create-the-application-configuration)
1. [Configure the sidecar injection](#6-configure-the-sidecar-injection)
1. [Label the workload](#7-label-the-workload)
1. [Deploy the microservices](#8-deploy-the-microservices)
1. [Create the ingress routes for the application](#9-create-the-ingress-routes-for-the-application)
1. [Inspect the telemetry](#10-inspect-the-telemetry)
1. [Tear down the deployment](#11-tear-down-the-deployment)

### 1. Set up the local development environment

If you completed the [first part](https://developer.ibm.com/tutorials/distributed-tracing-for-microservices-1/) of this tutorial series, simply export the `tutorial_dir` environment variable:

```sh
export tutorial_dir=<same location where you started the first part of the series>
```

If you skipped the first part of the series, clone [this GitHub repository](https://github.com/IBM/icpa-opentracing.git) and export the `tutorial_dir` environment variable by entering the following command:

```sh
git clone https://github.com/IBM/icpa-opentracing.git
cd icpa-opentracing
export tutorial_dir=$(PWD)
```

### 2. Deploy the service mesh

This tutorial uses Istio as the service mesh for the microservices architecture completed in the previous steps.

Thanks to the _sidecar_ architecture pattern, which is also used in Istio, a new traffic intermediation container is added to each pod that is running a service, which means that microservices do not require alterations to benefit from the service mesh functionality.

The next steps assume that you are using the Istio _demo_ profile that is added on top of minikube or the Kubernetes cluster that is bundled with Docker Desktop. It is possible to use other providers, but the installation of everything present in the Istio demo profile can be quite involved and is outside the scope of this tutorial.

Assuming you are following the recommendation of using minikube or the Kubernetes cluster that is bundled with Docker Desktop, proceed with the [Istio installation instructions](https://istio.io/docs/setup/getting-started/), which are summarized below.

__Important:__ This [Appsody issue](https://github.com/appsody/appsody-operator/issues/227) currently blocks the usage of Istio 1.5 and higher, so do not update the `ISTIO_VERSION` in the following command until that issue is fixed:

```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.5.0 sh -
cd istio-1.5*
export PATH="$PATH:$(PWD)/bin"

istioctl verify-install

istioctl manifest apply \
  --set profile=demo \
  --set values.tracing.enabled=true \
  --set values.grafana.enabled=true \
  --set values.kiali.enabled=true
```

The output should look similar to the following text:

```
Detected that your cluster does not support third party JWT authentication. Falling back to less secure first party JWT. See https://istio.io/docs/ops/best-practices/security/#configure-third-party-service-account-tokens for details.
- Applying manifest for component Base...
✔ Finished applying manifest for component Base.
- Applying manifest for component Pilot...
✔ Finished applying manifest for component Pilot.
- Applying manifest for component EgressGateways...
- Applying manifest for component IngressGateways...
- Applying manifest for component AddonComponents...
✔ Finished applying manifest for component EgressGateways.
✔ Finished applying manifest for component IngressGateways.
✔ Finished applying manifest for component AddonComponents.

✔ Installation complete
```

### 3. Create the namespace for the microservices

This tutorial creates several resources in the target cluster and it is beneficial to keep that content separate from other resources that you might already have in the container. Create a new namespace called `tracing` for this tutorial by typing the following commands in a command-line terminal:

```sh
kubectl get namespace cloudlab || \
kubectl create namespace cloudlab
```

### 4. Create the Docker images for the microservices

Before you deploy the microservices, request the build of the Docker images for each of the microservices. For this step, you can reuse the command lines from the first part of this tutorial or create new ones.

Assuming the environment variable `tutorial_dir` was set to the directory where you first started the tutorial and created the `jaeger.properties` file, type the following commands in the command-line terminal:

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

After all of the image builds are complete, inspect the output of the following command:

```sh
docker images dev.local/*
```

You should see a result similar to this:

```
REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
dev.local/nodejs-tracing       latest              597adcbeb47e        3 minutes ago       192MB
dev.local/springboot-tracing   latest              c2ccb43475e1        4 minutes ago       412MB
dev.local/jee-tracing          latest              138f3c5276d6        4 minutes ago       708MB
```

Additionally, you should find a new `app-deploy.yaml` file at the root of each respective project. This deployment file contains an `AppsodyApplication` definition, which is documented in detail in the [Appsody Operator GitHub](https://github.com/appsody/appsody-operator/tree/master/doc) page.

This tutorial has some instructions for modifying the file, but you can refer to the [Appsody Operator User Guide](https://github.com/appsody/appsody-operator/blob/master/doc/user-guide.md) if you plan to further customize the deployment of your microservices.

### 5. Create the application configuration

[Create a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap) with the Jaeger configuration settings that are similar to the ones set in the `jaeger.properties` located in the first part of this tutorial:

```sh
cat <<EOF | kubectl apply -n cloudlab -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: jaeger-config
data:
  JAEGER_ENDPOINT: http://jaeger-collector.istio-system.svc.cluster.local:14268/api/traces
  JAEGER_PROPAGATION: b3
  JAEGER_REPORTER_LOG_SPANS: "true"
  JAEGER_SAMPLER_PARAM: "1"
  JAEGER_SAMPLER_TYPE: const
EOF

kubectl get configmap jaeger-config -n cloudlab -o yaml
```

Add the new `ConfigMap` to the application, inserting the `envFrom` snippet to the `spec` section of the `app-deploy.yaml` file for each application, as exemplified here:

```yaml
spec:
...
  envFrom:
  - configMapRef:
      name: jaeger-config
  ...
```

### 6. Configure the sidecar injection

An Istio sidecar is a proxy that is added by Istio throughout the environment to intercept the communication between microservices before it exercises the traffic management functions. You can read more about all the available possibilities in the [Istio sidecar configuration](https://istio.io/docs/reference/config/networking/sidecar/) page. This tutorial focuses on the proxy's ability to add tracing instrumentation to the applications in the pod.

There are two ways of injecting the Istio sidecar to an application:

1. Use the `istio kube-inject` command.
1. Enable automatic injection of sidecars to all applications added to a namespace.

The second option is more approachable for this tutorial since it requires fewer instructions to be typed on the terminal.

Enabling automatic injection is described in the [Installing the Sidecar](https://istio.io/docs/setup/additional-setup/sidecar-injection/) section of the Istio documentation. The essential takeaway from that documentation is that you need to add the label `istio-injection=enabled` annotation to the namespace where you want automatic injection Istio sidecars. Type the following instructions in the command line:

```sh
kubectl label namespace cloudlab istio-injection=enabled
```

You can verify the results by entering the following command:

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

Notice how you could set the `sidecar.istio.io/inject` annotation to `"false"` to turn off the injection for an individual application even when the automatic injection is enabled for the target namespace.

Optionally, replace the `service.type` value with `ClusterIP` in `app-deploy.yaml`. This change removes the external port for the microservice, which ensures no one accidentally bypasses the Istio traffic management.

### 7. Label the workload

Istio has a few labels that must be set in the deployment to instruct the service mesh about the name and version of the application.

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

The last required label is the [protocol selection](https://istio.io/docs/ops/configuration/traffic-management/protocol-selection/) field, classifying the traffic type as HTTP traffic:

```yaml
spec:
  service:
    ...
    portName: http

```

### 8. Deploy the microservices

To summarize up to this point, you made the following changes to your cluster and the deployment descriptor of each application:

* Created a namespace (`cloudlab`) for deploying the applications.
* Enabled that namespace for automatic injection of Istio sidecars.
* Created a `ConfigMap` resource that contains the Jaeger endpoint information.
* Added an `envFrom` entry to reference the `ConfigMap` resource in the `app-deploy.yaml` deployment descriptor for each application.
* Added a `sidecar.istio.io/inject` annotation to the `service` in the `app-deploy.yaml` deployment descriptor for each application.
* Added the `app` and `version` labels to the `metadata` section and `portName` field to the `service` section of the `app-deploy.yaml` deployment descriptor for each application.

With those changes in place and an assumption that the environment variable `tutorial_dir` is set to the directory where you first started the tutorial, type the following in the command-line terminal:

```sh
cd "${tutorial_dir}"
cd nodejs-tracing
appsody deploy --namespace cloudlab
```

```sh
cd "${tutorial_dir}"
cd springboot-tracing
appsody deploy --namespace cloudlab
```

```sh
cd "${tutorial_dir}"
cd jee-tracing
appsody deploy --namespace cloudlab
```

In concrete terms for the actual deployment, the _sidecar injection_ means that Istio adds a proxy container to each pod that is running the microservices. This is a good point in the tutorial to look at the running containers before the injection. Type the following instruction in the command-line terminal:

```sh
kubectl get pods -n cloudlab -l app.kubernetes.io/managed-by=appsody-operator
```

You should see output similar to the following text, with two containers inside each pod, which indicates the sidecar was added:

```
NAME                                  READY   STATUS    ...
jee-tracing-6cd5784b57-hm65c          2/2     Running   ...
nodejs-tracing-5cf9f655db-kl4gl       2/2     Running   ...
springboot-tracing-5f7b7fb74f-hzxl5   2/2     Running   ...
```

#### Note about sidecar injection at the application level

The previous sections enabled a sidecar injection for all deployments in a namespace. You might have good reasons to avoid introducing that default behavior and apply the instrumentation to individual applications. For your reference, you could instrument an Appsody-based application with an Istio sidecar after it is deployed:

```sh
application_name=<<name of your Appsody application, such as "nodejs-tracing" >>
kubectl get deployment ${application_name}  -o yaml | istioctl kube-inject -f - | kubectl apply -f -
```

Note that the `kube-inject` command modifies the deployment descriptor directly in the cluster, leaving the original `app-deploy.yaml` file unmodified. Future invocations of `appsody deploy` overwrite those modifications.

#### (Optional) Tail microservices logs

You can type the following commands in three separate terminal windows to follow the console output of each application as you progress towards the rest of the tutorial:

```sh
kubectl logs -n cloudlab -f -l app.kubernetes.io/name=nodejs-tracing --all-containers | grep -vi "live\|ready\|inbound\|metrics"
```

```sh
kubectl logs -n cloudlab -f -l app.kubernetes.io/name=springboot-tracing --all-containers | grep -vi "live\|ready\|inbound"
```

```sh
kubectl logs -n cloudlab -f -l app.kubernetes.io/name=jee-tracing --all-containers | grep -vi "live\|ready\|inbound"
```

### 9. Create the ingress routes for the application

The final step before you send transactions into the Node.js microservice is to configure the Istio `Gateway` and `VirtualService` resources to route traffic to the application:

```sh
cat <<EOF | kubectl apply -n cloudlab -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: tutorial-gateway
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
  name: tutorial-service
spec:
  hosts:
  - "*"
  gateways:
  - tutorial-gateway
  http:
  - match:
    - uri:
        prefix: "/quoteOrder"
    rewrite:
      uri: "/node-jee"
    route:
    - destination:
        host: nodejs-tracing
  - match:
    - uri:
        prefix: "/quoteItem"
    rewrite:
      uri: "/node-springboot"
    route:
    - destination:
        host: nodejs-tracing
EOF
```

Note the remapping of the `/node-springboot` and `/node-jee` virtual endpoints to `/quoteItem` and `/quoteOrder`in the `VirtualService`. This illustrates how you can recombine microservices endpoints independently of how they were named in the original application.

Now issue the following commands a few times:

```sh
curl localhost/node-springboot
curl localhost/node-jee
```

You can also leave the commands running continuously with:

```sh
while true; do
  curl -s localhost/quoteItem; sleep 2
  curl -s localhost/quoteOrder; sleep 2
done
```

### 10. Inspect the telemetry

You can verify the results of the trace data that is collected from the applications while servicing requests with any of the telemetry add-ons bundled with Istio.

#### View Istio dashboards with Grafana

[Grafana](https://grafana.com/) is one of the most prominent analytics and monitoring tools in the market and is bundled with Istio deployments. A Grafana dashboard is often the first line of observation for the data that is generated by an application. You can see some of the data that is generated in this tutorial by using a Grafana dashboard.

First, start the Grafana dashboard by typing the following instruction in the command line:

```sh
istioctl dashboard grafana &
```

After the new tab for the Grafana user interface (UI) shows up in your default browser, select __Explore__ on the navigation bar. Inspect some of the pre-packaged Istio dashboards by clicking the __Dashboards__ menu and selecting __Manage__.

In the resulting __Manage__ tab, click the __istio__ folder, and then select __Istio Service Dashboard__. After the dashboard completes rendering, select `nodejs-tracing.cloudlab.svc.cluster.local` in the __Service__ field and press Enter. Depending on the traffic still being generated from previous sections, you should see a screen similar to this:

![Screen capture of the traffic analysis in Istio Service Dashboard within Grafana](/images/grafana-istio-service-dashboard.png)

#### Explore metrics with Grafana

As an exercise of how you would reference Istio service mesh metrics to build your dashboard, click the __Explore__ menu and then type the following [PromQL query](https://prometheus.io/docs/prometheus/latest/querying/basics/) in the field marked `<Enter a PromQL query>`:

```
avg by (destination_service_name, destination_version, response_code)(rate(istio_requests_total{destination_service_namespace="cloudlab"}[5m]))
```

This tutorial is not a primer on PromQL, but the breakdown of the query can be read as follows: _average of the rate of requests in the Istio mesh for each service that is grouped in 5-minute intervals and then group them by service name, service version, and HTTP response code_.

The resulting visualization in the following picture is a simple and effective way of observing the volume of requests that are split between successful and unsuccessful responses.

![Screen capture of the average number of requests in the Istio service mesh, grouped by service and response code, in Grafana](/images/grafana-tracing-overview-light.png)

If you do not see some of the response errors in the chart, which is expected since the sequence of steps in the tutorial waited until all microservices were up and running, you can simulate a system crash where all pods get restarted simultaneously.

Assuming you left that `while` loop running in the background and sending requests to the Node.js application, simulate a system crash by using the Istio [Fault Injection](https://istio.io/docs/tasks/traffic-management/fault-injection/) support.

Inject the failure by creating an Istio `VirtualService` for the `jee-tracing` microservice:

```sh
cat <<EOF | kubectl apply -n cloudlab -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: jee-tracing
spec:
  hosts:
  - jee-tracing
  http:
  - fault:
      abort:
        httpStatus: 502
        percentage:
          value: 70
    route:
    - destination:
        host: jee-tracing
  - route:
    - destination:
        host: jee-tracing
EOF
```

The change takes place immediately, generating HTTP `502` gateway errors in 70 percent of the calls incoming from the Node.js application.

Click the manual refresh icon on the header and you should see some of the new errors appear in the graph.

#### (Optional) View import dashboard with Grafana

As a final exercise for the Grafana dashboard, you can import and study the dashboard that is contained in the [GitHub repository for this tutorial](https://github.com/IBM/icpa-opentracing/blob/master/grafana/GrafanaTutorialDashboard.json).

Select __Dashboards__ from the navigation menu again, click __Manage__, and then click __Import__. In the Import pane, paste the contents of the file in the form and click __Load__, which should display a dashboard that is similar to this screen capture:

![Screen capture of the Grafana dashboard for metrics generated in this tutorial](images/grafana-mesh-dashboard-light.png)

#### Use Kiali to view the microservices connections

The [Kiali](https://docs.openshift.com/container-platform/latest/service_mesh/service_mesh_arch/ossm-kiali.html) UI provides visibility by showing the microservices in your service mesh and how they are connected.

You could expose the Kiali UI to a fixed port in your localhost by using the [networking configuration instructions](https://istio.io/docs/tasks/observability/gateways/#option-2-insecure-access-http), but it is more convenient to use the `istioctl dashboard` command.

Type the following instruction on a command-line interface:

```sh
istioctl dashboard kiali
```

The dashboard opens as a tab in your default web browser. The default user and password is `admin:admin`.

After you are in the Kiali UI, explore the visualizations in the navigation pane. The focus of this tutorial is on the Graph view, where you can see the topology of the microservices you created in this tutorial.

Open that Graph view and select `tracing` in the __Namespace__ field, which matches the Kubernetes namespace used in this tutorial. You should see a view similar to this example:

![Screen capture of the application topology in Kiali](/images/kiali-ui-graph.png)

Note that the visualization is still missing some of the HTTP-specific numbers in the side pane due to an [Appsody issue](https://github.com/appsody/appsody-operator/issues/227). However, you can see the potential of the service mesh to help you understand the application topology, as well as the volume and reliability of the traffic distribution across various services.

#### Use Jaeger to visualize the additional spans

The Jaeger UI was already covered in the first part of this tutorial, so the focus of this section is narrowed to visualizing the additional [spans](https://opentracing.io/docs/overview/spans/) introduced by Istio into the overall distributed transaction.

Launch the Jaeger UI with the following command:

```sh
istioctl dashboard jaeger
```

Select `istio-mixer` in the Service menu, click __Find Traces__, and then click one of the traces, which should display a screen similar to this:

![Screen capture of a trace that starts from Istio Ingress in Jaeger](/images/jaeger-istio-ingress.png)

In this trace, you can see the points where Istio injected its traffic management into the business transactions, mediating inbound and inter-component traffic along the way.

As a last modification to the system, you can use Istio's fault injection support to introduce a delay on the responses from a microservice. This is useful for exploring the overall system tolerance to slow responses in a given component.

Inject the delays by creating an Istio `VirtualService` for the `springboot-tracing` microservice:

```sh
cat <<EOF | kubectl apply -n cloudlab -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: springboot-virtual-service
spec:
  hosts:
  - springboot-tracing
  http:
  - fault:
      delay:
        fixedDelay: 1s
        percentage:
          value: 50
    route:
    - destination:
        host: springboot-tracing
  - route:
    - destination:
        host: springboot-tracing
EOF
```

Search for the traces associated with the operation named `quoteItem` and notice how 50 percent of them are taking more than a second. Expand one of the traces and note the delay in the call from the service _A_ to service _B_ (implemented by the Spring Boot application):

![Screen capture of delayed calls from service A to service B in Jaeger](images/jaeger-trace-delayed-call.png)

Another type of fault injection is the simulation of failures in responses to requests to a service. This is also useful when you are trying to understand the system behavior during partial outages.

Inject the failures in the `jee-tracing` microservice by creating this other Istio `VirtualService` object in the namespace:

```sh
cat <<EOF | kubectl apply -n cloudlab -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: jee-virtual-service
spec:
  hosts:
  - jee-tracing
  http:
  - fault:
      abort:
        httpStatus: 502
        percentage:
          value: 80
    route:
    - destination:
        host: jee-tracing
  - route:
    - destination:
        host: jee-tracing
EOF
```

Search for the traces that are associated with the operation named `quoteOrder` and notice how 80 percent of them are now labeled with the Error tag. Expand one of the traces and note the presence of HTTP status code `"502"` in the result from calls to the `jee-tracing` application endpoint:

![Screen capture of failed calls associated with quoteOrder operation in Jaeger](images/jaeger-trace-failed-call.png)

These examples conclude the overview of using the Jaeger console to understand and troubleshoot communication among services.

### 11. Tear down the deployment

To delete everything created during this tutorial, type the following instruction from the directory that contains each application:

```sh
kubectl delete namespace cloudlab
```

If you deployed Istio as part of this tutorial, you can remove it from your cluster by typing the following instructions in a command-line terminal:

```sh
kubectl delete namespace istio-system
```

## Conclusion

You have built upon the distributed tracing example from the first part of this tutorial, inserting it into a service mesh running inside a Kubernetes cluster. 

Along the way, you also explored the core monitoring dashboards bundled with the Istio service mesh, using them to analyze the traffic sent to the distributed tracing database and the Prometheus telemetry database. 

This foundation will be leveraged in Part 3 of this tutorial, where the services are deployed to an OpenShift installation with minimal modifications, completing the entire development cycle for creating cloud-native microservices ready that are observable and ready for deployment in a real-world environment.


## Next steps

* Explore other [Istio Telemetry Addons](https://istio.io/docs/tasks/observability/gateways/).
* Try other [traffic management](https://istio.io/docs/tasks/traffic-management/) capabilities in Istio, such as fault injection, traffic shifting, and circuit breaking.
* Try [hands-on service mesh labs](https://learn.openshift.com/servicemesh/), which contain a good list of basic and advanced lessons.

## API references

* [Spans](https://opentracing.io/docs/overview/spans/)
* [The OpenTracing Semantic Specification](https://github.com/opentracing/specification/blob/master/specification.md)
* [NodeJS OpenTracing API doc](https://opentracing-javascript.surge.sh/)
* [OpenTracing API Javadoc](https://javadoc.io/doc/io.opentracing/opentracing-api/latest/index.html)
* [MicroProfile OpenTracing](https://github.com/eclipse/microprofile-opentracing)
* [Java Spring Jaeger](https://github.com/opentracing-contrib/java-spring-jaeger)

## Credits

Thanks to my colleague Carlos Santana, who wrote the excellent [Learning Distributed Tracing 101](https://ibm-cloud-architecture.github.io/learning-distributed-tracing-101/docs/index.html) tutorial, which was instrumental in helping me figure out the Node.js aspects of this tutorial.

Thanks to Yuri Shkuro (the father of Jaeger) and Junmin Liu for the excellent [Node.js chapter](https://github.com/yurishkuro/opentracing-tutorial/tree/master/nodejs) of the OpenTracing tutorial.
