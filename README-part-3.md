This the tentative 3rd part of what is currently a two-part tutorial, where you will move the customizations made to the microservices of parts 1 and 2 into custom application stacks, so that new microservices created using these stacks get the same kind of instrumentation without further customizations.

- [Distributed tracing for microservices, Part 1](https://developer.ibm.com/tutorials/distributed-tracing-for-microservices-1/)
- [Distributed tracing for microservices, Part 2 (draft)](README-part-2.md)


## Prerequisites

* [Install Docker](https://docs.docker.com/get-started/).
  If using Windows or macOS, Docker Desktop is probably the best choice. If using a Linux system, [minikube](https://github.com/kubernetes/minikube) and its internal Docker registry is an alternative.

* [Install the Appsody CLI](https://appsody.dev/docs/getting-started/installation).

* Access to an OpenShift cluster, whether hosted or local installation of Code Ready Containers.


## Estimated time

With the prerequisites in place, you should be able to complete this second part of the tutorial in 2 hours.



## Steps

...

### Step 1. Create custom stacks

```sh

```

## Step N. Tear down the deployment

...


## Next steps

- Explore other [Istio Telemetry Addons](https://istio.io/docs/tasks/observability/gateways/)

- Try other [traffic management](https://istio.io/docs/tasks/traffic-management/) capabilities in Istio, such as fault injection, traffic shifting, and circuit breaking.

- Try these hands-on [service mesh labs](https://learn.openshift.com/servicemesh/), which contains a good list of basic and advanced lessons.


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
