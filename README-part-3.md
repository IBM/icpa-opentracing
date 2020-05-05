This the 3rd part of a three-part tutorial, where you will move the customizations made to the microservices of parts 1 and 2 into an OpenShift cluster deployed as part of IBM Cloud Pak for Applications. 

The microservices will explore the OpenShift Service Mesh operator, which is heavily based on the Istio Service Mesh and offers a very similar application development experience, to the point where the applications will work without changes to the source code or deployment files.


## Prerequisites

* Complete the [first part of the "Distributed tracing for microservices" tutorial](https://developer.ibm.com/tutorials/distributed-tracing-for-microservices-1/) 

* Complete the [second part of the "Distributed tracing for microservices" tutorial](README-part-2.md) .

* Access to an installation of IBM Cloud Pak for Applications installation with the Accelerator for Teams option. This tutorial was verified on CP4A version 4.1.

* (Optional) Create a publicly accessible GitHub repository for each application completed in the second part of the tutorial and populate the repository with the final working version of the application content. The steps in this tutorial will reference baseline GitHub repositories to avoid eventual differences with your examples, but will call out where you can try using your repositories if you wish to customize the examples beyond the instructions in this series.

* [Docker](https://docs.docker.com/get-started/).
  If using Windows or macOS, Docker Desktop is probably the best choice. If using a Linux system, [minikube](https://github.com/kubernetes/minikube) and its internal Docker registry is an alternative.

* [Install the Appsody CLI](https://appsody.dev/docs/getting-started/installation).


## Estimated time

With the prerequisites in place, you should be able to complete this second part of the tutorial in 2 hours.



## Steps

In this tutorial, you will perform the following steps:

1. Setup the target namespace for the deployment
1. Validate the installation
1. Build and deploy applications
1. Using customized stacks to simplify the applications
1. Traffic rollout to new application versions
1. Simulate traffic delays and failures
1. Tear down the installation


### 1 Setup the target namespace for the deployment

As a good Kubernetes development practice, you will isolate the exercises in this tutorial from other deployments in the cluster, so that you avoid the risk of inadvertently modifying or erasing other critical configuration.

Note: If you do not have administrative permissions to create a new namespace, you may need to request an administrator to create the new namespace for you or adapt the instructions in this tutorial to reference a namespace you may already have access to. If that is the case, that initial optional prerequisite of having your GitHub repositories becomes mandatory because you will need to modify the target namespace in the `app-deploy.yaml` file due to .

Log in as a system admistrator via command-line interface, Logged in as a cluster administrator, create the new namespace 


### 2 Validate the installation


### 3 Build and deploy applications


### 4 Traffic rollout to new application versions


### 5 Simulate traffic delays and failures


### 6 Tear down the installation


## Next steps

- Explore other [Istio Telemetry Addons](https://istio.io/docs/tasks/observability/gateways/)

- Try other [traffic management](https://istio.io/docs/tasks/traffic-management/) capabilities in Istio, such as fault injection, traffic shifting, and circuit breaking.

- Try these hands-on [service mesh labs](https://learn.openshift.com/servicemesh/), which contains a good list of basic and advanced lessons.

- Read through a more [in-depth view of Red Hat OpenShift Service Mesh](https://docs.openshift.com/container-platform/latest/service_mesh/service_mesh_arch/understanding-ossm.html)

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
