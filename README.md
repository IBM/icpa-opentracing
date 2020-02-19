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

draft: true

meta_description: "Create a highly-scalable database client with the Appsody Eclipse MicroProfile collection."
abstract: "Create a highly-scalable database client with the Appsody Eclipse MicroProfile collection."
excerpt: "Create a highly-scalable database client with the Appsody Eclipse MicroProfile collection."

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
  - title: "Codewind website"
    url: "https://www.eclipse.org/codewind/"
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


title: "[title]"
meta_title: "[title]"
subtitle: "Using JPA and JDBC connection pools inside the Appsody java-microprofile collection"

tags:
  - "appsody"
  - "cloud"
  - "containers"
  - "microservices"

type: tutorial
---

Observability with service meshes and Open Tracing

In this tutorial, ...

![Tutorial progress](images/tutorial-overview.png)


https://opentracing.io/

https://opentelemetry.io/


https://opentracing.io/docs/overview/spans/

[The OpenTracing Semantic Specification](https://github.com/opentracing/specification/blob/master/specification.md)

### Node.js

[OpenTracing API doc](https://opentracing-javascript.surge.sh/)

### Java


[Eclipse MicroProfile](https://microprofile.io/)

[MicroProfile OpenTracing](https://github.com/eclipse/microprofile-opentracing)

[OpenTracing API Javadoc](https://javadoc.io/doc/io.opentracing/opentracing-api/latest/index.html)

### SpringBoot

[Java Spring Jaeger](https://github.com/opentracing-contrib/java-spring-jaeger)

## Prerequisites

[[[ Whole section is copy-paste placeholder ]]]


* [Install Docker](https://docs.docker.com/get-started/).
  If using Windows or macOS, Docker Desktop is probably the best choice. If using a Linux system, [minikube](https://github.com/kubernetes/minikube) and its internal Docker registry is an alternative.

* [Install the Appsody CLI](https://appsody.dev/docs/getting-started/installation).

* Install Kubernetes. [minikube](https://github.com/kubernetes/minikube) will work on most platforms, but if using Docker Desktop, the internal Kubernetes enabled from the Docker Desktop Preferences (macOS) or Settings (Windows) panel is a more convenient alternative.




## Estimated time

With the prerequisites in place, you should be able to complete this tutorial in 1 hour.



## Steps

Following along to this tutorial, you will perform the following steps:

1. Setup local development 
1. Create the Node.js application
1. Create the JEE application
1. Create the Spring boot application
1. Create distributed transactions through application dependencies
1. Examining tracing results (OpenShift playground)
1. Tear down



## Step 1. Setup local development 

You will need a local [all-in-one Jaeger server](https://www.jaegertracing.io/docs/1.6/getting-started/) running throughout the as you progress through the steps in this tutorial. 

This all-in-one server acts both as the backend for receiving the telemetry data from the various servers participating in a distributed transaction, as well as the host for the Jaeger console from where you can inspect the results of each transaction.

### Create a custom Docker network

This tutorial has many applications that need to locate each other via name lookups, which is easier when using a custom Docker network instead of the default bridge network.

Execute the following command from a command-line terminal:

```sh
docker network create opentrace_network
```

### Start a local Jaeger server

The instructions in the tutorial expect the all-in-one server to be named "jaeger", which needs to be specified as a parameter when creating the container.

Type the following starting command from a command-line terminal, observing the presence of the `network` parameter cross-referencing the Docker network you just created:

```sh
docker run --name jaeger \
  --rm \
  -e COLLECTOR_ZIPKIN_HTTP_PORT=9411 \
  -p 5775:5775/udp \
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 14268:14268 \
  -p 9411:9411 \
  --network opentrace_network \
  jaegertracing/all-in-one:latest
```

### Jaeger tracing options

Create a file for the [Jaeger client properties](https://www.jaegertracing.io/docs/latest/client-features/) , named `jaeger.properties`:


`jaeger.properties`
```properties
cat > jaeger.properties << EOF
JAEGER_AGENT_HOST=jaeger-agent
JAEGER_AGENT_PORT=6832
JAEGER_REPORTER_LOG_SPANS=true
JAEGER_SAMPLER_TYPE=const
JAEGER_SAMPLER_PARAM=1
EOF
```

Noting that the JAEGER_AGENT_HOST references the jaeger agent in the istio-system, but you could try this:

https://stackoverflow.com/questions/37221483/service-located-in-another-namespace
https://kubernetes.io/docs/concepts/services-networking/service/#externalname

```yaml
kind: Service
apiVersion: v1
metadata:
  name: jaeger-agent
  namespace: default
spec:
  type: ExternalName
  externalName: jaeger-agent.istio-system.svc.cluster.local
  ports:
  - port: 6832
```

## Step 2. Create the Node.js application

It is now time to create the Node.js application, once again using the Appsody command-line interface. Appsody supports both [Express](https://expressjs.com/) and [LoopBack](https://loopback.io/) frameworks and for this tutorial you will use the Express framework.

Type the following command in the command-line interface:

```sh
mkdir nodejs-tracing
cd nodejs-tracing
appsody init incubator/nodejs-express
```

Take a moment to inspect the structure of the template application created by Appsody:

```
nodejs-tracing
├── app.js
├── package-lock.json
├── package.json
└── test
    └── test.js

```


### Assign a name to the application

Since you want to easily identify this application while inspecting a tracing span, the first modification to the application is to change the application name inside the newly generated `package.json` file.

Modify the line containing `"name": "nodejs-express-simple",` in `package.json` to this line instead:

```json
    "name": "app-a-nodejs",
```

### Enable OpenTracing using Jaeger client

For this section, you will follow the instructions outlined in the [Jaeger documentation](https://github.com/jaegertracing/jaeger-client-node).

Following the code sample in the instructions in that page, the first change is to include the `jaeger-client` package in your application.

First include the [package dependency](https://www.npmjs.com/package/jaeger-client) in the `package.json` file, 

```json
  "dependencies": {
    "jaeger-client": "^3.17.1"
  },
```

Node.js does not automatically instrument RESTful calls for tracing, so you need to make a few changes to the `app.js` file:
1. Insert a global initialization block for an OpenTracing tracer object
2. Initiate a tracing span at the beginning of the request
3.  and the tracing statements inside the handler for the RESTful request being traced.



```js
module.exports = (/*options*/) => {
  // Use options.server to access http.Server. Example with socket.io:
  //     const io = require('socket.io')(options.server)
  const app = require('express')()

  //
  // Tutorial begin: OpenTracing initialization
  //
  var initTracerFromEnv = require('jaeger-client').initTracerFromEnv;
  var config = {
    serviceName: 'app-a-nodejs',
  };
  var options = {
  };
  var tracer = initTracerFromEnv(config, options);
  //
  // Tutorial end: OpenTracing initialization
  //
  
  app.get('/', (req, res) => {
    //
    // Tutorial begin: OpenTracing new span
    //
    const span = tracer.startSpan('http_request');
    //
    // Tutorial end: OpenTracing new span
    //

    // Use req.log (a `pino` instance) to log JSON:
    req.log.info({message: 'Hello from Appsody!'});
    res.send('Hello from Appsody!');

    //
    // Tutorial begin: Send span information to Jaeger
    //
    span.log({'event': 'request_end'});
    span.finish();
    //
    // Tutorial end: Send span information to Jaeger
    //
  });

  return app;
};
```

You can find more information about the `tracer` interface at the [OpenTracing API page](https://github.com/opentracing/opentracing-javascript/).


### Launch the application

With all modifications in places, it is time for you to launch the application and validate that it is instrumented for tracing distributed transactions.

Type the following command on a separate command-line window:

```sh
appsody run \
   --docker-options="--env JAEGER_AGENT_HOST=jaeger --env JAEGER_AGENT_PORT=6832 --env JAEGER_REPORTER_LOG_SPANS=true --env JAEGER_SAMPLER_TYPE=const --env JAEGER_SAMPLER_PARAM=1" \
    --network opentrace_network 
```

Once again, notice the `JAEGER_AGENT_HOST` parameter matching the name of the Jaeger all-in-one server launched in previous steps, as well as the usage of the `network` parameter to place the container in the same custom Docker network created at the beginning of the tutorial.

You should see a message such as the one below indicating that the server is ready to accept requests:

`[Container] App started on PORT 3000`

Once you see the message, you should issue a few requests to the sample resource created along with the application.

```
curl http://localhost:3000
```

You can then launch the Jaeger UI in your browser of choice, by opening this URL:
http://localhost:16686

Choose the `app-a-nodejs` application in the Service menu and then click on the "Find Traces" button, which should display the transactions you initiated from the command-line:

![Node.js traces in Jaeger UI](images/jaeger-app-nodejs.png)



## Step 2. Create the Spring Boot application

It is now time to create the Spring Boot application, once again using the Appsody command-line interface. Type the following command in the command-line interface:

```sh
mkdir springboot-tracing
cd springboot-tracing
appsody init incubator/java-spring-boot2
```

Before starting making modifications to the application, take a moment to inspect the template application created by Appsody:

```
springboot-tracing
├── mvnw
├── mvnw.cmd
├── pom.xml
└── src
    ├── main
    │   ├── java
    │   │   └── application
    │   │       ├── LivenessEndpoint.java
    │   │       └── Main.java
    │   └── resources
    │       ├── application.properties
    │       └── public
    │           └── index.html
    └── test
        └── java
            └── application
                └── MainTests.java
```


### Assign a name to the application

Since you want to easily identify this application while inspecting a tracing span, the first modification to the application is to change the application name inside the newly generated `pom.xml` file.

Modify the line containing `<artifactId>default-application</artifactId>` in `pom.xml` to this line instead:

```xml
    <artifactId>app-b-springboot</artifactId>
```

### Enable OpenTracing using Jaeger client

For this section, you will follow the instructions outlined in the [https://github.com/opentracing-contrib/java-spring-jaeger
The next modification is to enable OpenTracing within the Spring Boot runtime, which requires a couple of localized changes to the`pom.xml` file

Insert the [Maven opentracing-spring-jaeger-cloud-starter dependency](https://mvnrepository.com/artifact/io.opentracing.contrib/opentracing-spring-jaeger-cloud-starter) inside the `<dependencies>` element of the `pom.xml` file:

```xml
    <dependency>
        <groupId>io.opentracing.contrib</groupId>
        <artifactId>opentracing-spring-cloud-starter</artifactId>
        <version>0.4.0</version>
    </dependency>

    <dependency>
        <groupId>io.opentracing</groupId>
        <artifactId>opentracing-api</artifactId>
        <version>0.33.0</version>
    </dependency>

    <dependency>
        <groupId>io.jaegertracing</groupId>
        <artifactId>jaeger-client</artifactId>
        <version>1.1.0</version>
    </dependency>
```


### Enable OpenTracing in the Spring Boot application

```java
import io.jaegertracing.Configuration;
import io.jaegertracing.Configuration.ReporterConfiguration;
import io.jaegertracing.Configuration.SamplerConfiguration;

import org.springframework.context.annotation.Bean;
```

```java
@Bean
	public io.opentracing.Tracer initTracer() {
	  SamplerConfiguration samplerConfig = new SamplerConfiguration().withType("const").withParam(1);
	  ReporterConfiguration reporterConfig = ReporterConfiguration.fromEnv().withLogSpans(true);
	  return Configuration.fromEnv("app-b-springboot").withSampler(samplerConfig).withReporter(reporterConfig).getTracer();
	}
```

### Launch the application

With the modification in place, it is time to launch the application and validate that it is instrumented for tracing distributed transactions.

Type the following command on a separate command-line window:

```sh
appsody run \
   --docker-options="--env JAEGER_AGENT_HOST=jaeger --env JAEGER_REPORTER_LOG_SPANS=true --env JAEGER_SAMPLER_TYPE=const --env JAEGER_SAMPLER_PARAM=1" \
    --network opentrace_network 
```

Note the `JAEGER_AGENT_HOST` parameter matching the name of the Jaeger all-in-one server launched in previous steps, as well as the usage of the `network` parameter to place the container in the same custom Docker network created at the beginning of the tutorial.

You should see a message such as the one below indicating that the server is ready to accept requests:

`[Container] [INFO] [AUDIT   ] CWWKF0011I: The defaultServer server is ready to run a smarter planet.`

Once you see the message, you should issue a few requests to the sample resource created along with the application. Any URL will be sufficient for now as the goal is to validate that the enablement is working before we move on to creating new endpoints.

Enter the following command in a command-line terminal and repeat it a few times.

```
curl http://localhost:8080/actuator
```

Now return to Jaeger UI (hosted at http://localhost:16686) in your browser. You will need to refresh the browser screen to see the new service entry for the application (`app-b-springboot`).

Choose the `app-b-springboot` application in the Service menu and then click on the "Find Traces" button again, which will display the transactions you initiated from the command-line:

![Spring Boot traces in Jaeger UI](images/jaeger-app-springboot.png)



## Step 4. Create the JEE application

As mentioned in the steps section, you will create a JEE application and instrument it with tracing capabilities.

Using the Appsody command-line interface makes the creation step quite simple, requiring a single command to create a working skeleton of a JEE application using the Open Liberty server:

```sh
mkdir jee-tracing
cd jee-tracing
appsody init incubator/java-openliberty
```

Before starting making modifications to the application, take a moment to inspect the template application created by Appsody:

```
java-openliberty
├── pom.xml
└── src
    ├── main
    │   ├── java
    │   │   └── dev
    │   │       └── appsody
    │   │           └── starter
    │   │               ├── StarterApplication.java
    │   │               ├── StarterResource.java
    │   │               └── health
    │   │                   ├── StarterLivenessCheck.java
    │   │                   └── StarterReadinessCheck.java
    │   ├── liberty
    │   │   └── config
    │   │       └── server.xml
    │   └── webapp
    │       ├── WEB-INF
    │       │   └── beans.xml
    │       └── index.html
    └── test
        └── java
            └── it
                └── dev
                    └── appsody
                        └── starter
                            └── HealthEndpointTest.java
```


### Assign a name to the application

Since you want to easily identify this application while inspecting a tracing span, the first modification to the application is to change the application name inside the newly generated `pom.xml` file.

Modify the line containing `<artifactId>starter-app</artifactId>` in `pom.xml` to this line instead:

```xml
    <artifactId>app-c-jee</artifactId>
```

### Enable OpenTracing using Jaeger client

The next modification is to enable OpenTracing within the Open Liberty runtime, which requires a couple of localized changes to both the `pom.xml` and `src/main/liberty/config/server.xml` files.

The nature of these changes is explained in a bit more in the [Open Liberty blog entry announcing the support of Jaeger as a tracing backend](https://openliberty.io/blog/2019/12/06/microprofile-32-health-metrics-190012.html#jmo).

The first change is to include the [Jaeger Java client library](https://github.com/jaegertracing/jaeger-client-java) dependency in the final application. If you look at the Open Liberty documentation it will instruct you to create a new shared library available to all applications running inside the container, but that level of complexity is unnecessary in a microservice where there will be a single application inside that server.

Insert the [Maven jaeger-client dependency](https://mvnrepository.com/artifact/io.jaegertracing/jaeger-client) XML element inside the `<dependencies>` element of the `pom.xml` file:

```xml
        <dependency>
            <groupId>io.jaegertracing</groupId>
            <artifactId>jaeger-client</artifactId>
            <version>0.34.0</version>
        </dependency>
```

Note that this version of the Jaeger client, while not the latest, it is the version tested with the version of Open Liberty bundled in the Appsody `java-openliberty` stack at the time this tutorial was written. See notes in section [xxxx] about common problems while attempting to use different versions.

The next step is to add the OpenTracing feature to the Open Liberty server. Add the following element inside the `featureManager` section of the `src/main/liberty/config/server.xml` file:

```xml
        <feature>mpOpenTracing-1.3</feature>
```

Replace the `webApplication` element in the `src/main/liberty/config/server.xml` file with this snippet:

```xml
    <webApplication location="app-c-jee.war" contextRoot="/" >
        <classloader apiTypeVisibility="+third-party" />
    </webApplication>
```


### Launch the application

With the modification in place, it is time to launch the application and validate that it is instrumented for tracing distributed transactions.

Type the following command on a separate command-line window:


```sh
appsody run \
   --docker-options="--env JAEGER_AGENT_HOST=jaeger --env JAEGER_REPORTER_LOG_SPANS=true --env JAEGER_SAMPLER_TYPE=const --env JAEGER_SAMPLER_PARAM=1" \
    --network opentrace_network 
```

Notice the `JAEGER_AGENT_HOST` parameter matching the name of the Jaeger all-in-one server launched in previous steps, as well as the usage of the `network` parameter to place the container in the same custom Docker network created at the beginning of the tutorial. You can inspect the other Jaeger configuration parameters at https://github.com/jaegertracing/jaeger-client-java/blob/master/jaeger-core/README.md


You should see a message such as the one below indicating that the server is ready to accept requests:

`[Container] [INFO] [AUDIT   ] CWWKF0011I: The defaultServer server is ready to run a smarter planet.`

Once you see the message, you should issue a few requests to the sample resource created along with the application.

```
curl http://localhost:9080/starter/resource
```

Now return to Jaeger UI (hosted at http://localhost:16686) in your browser. You will need to refresh the browser screen to see the new service entry for the application (`app-c-jee`).

Choose the `app-c-jee` application in the Service menu and then click on the "Find Traces" button again, which should display the transactions you initiated from the command-line:

![Open Liberty application traces in Jaeger UI](images/jaeger-app-jee.png)



## Create distributed transactions through application dependencies

At this point in the tutorial you have the 3 applications running and enabled for sending their tracing information to the Jaeger all-in-one server, so it is time to make modifications to each of the applications to implement the topology depicted at the beginning of the tutorial.


### Service endpoint in the Open Liberty application

The default template for the Open Liberty application created by Appsody already contains a REST endpoint that can be used without modification, defined in the `./src/main/java/dev/appsody/starter/StarterResource.java` Java class:

```java
package dev.appsody.starter;

import javax.ws.rs.GET;
import javax.ws.rs.Path;

@Path("/resource")
public class StarterResource {

    @GET
    public String getRequest() {
        return "StarterResource response";
    }
}
```


### Create service endpoint in the Sprint Boot application

Create a new Java class named `StarterResource.java` in the `./src/main/java/application` folder of the Spring Boot application:

```java
package application;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class StarterResource {

    @RequestMapping("/resource")
    public String getRequest() {
        return "StarterResource response";
    }
}
```

### Create the top-level service endpoint in the Node.js application

Add the `request` package inside the `package.json` file:

```json
  "dependencies": {
    "jaeger-client": "^3.17.1",
    "opentracing": "latest",
    "request-promise": "^4.2.0",
    "uuid-random": "latest"
  },
```

https://github.com/yurishkuro/opentracing-tutorial

```js
// serviceBroker.js
// ================

const request = require('request-promise');
const { Tags, FORMAT_HTTP_HEADERS } = require('opentracing');

var serviceTransaction = function(serviceCUrl, servicePayload, parentSpan) {
    const tracer = parentSpan.tracer();
    const span = tracer.startSpan("service", {childOf: parentSpan.context()});
    callService(serviceCUrl, servicePayload, span)
        .then( data => {
            span.setTag(Tags.HTTP_STATUS_CODE, 200)
            span.finish();
        })
        .catch( err => {
            console.log(err);
            span.setTag(Tags.ERROR, true)
            span.setTag(Tags.HTTP_STATUS_CODE, err.statusCode || 500);
            span.finish();
        });

}

async function callService(serviceCUrl, servicePayload, parentSpan) {
    const tracer = parentSpan.tracer();
    const url = serviceCUrl;
    const body = servicePayload

    const span = parentSpan;
    const method = 'GET';
    const headers = {};
    span.setTag(Tags.HTTP_URL, serviceCUrl);
    span.setTag(Tags.SPAN_KIND, Tags.SPAN_KIND_RPC_CLIENT);
    tracer.inject(span, FORMAT_HTTP_HEADERS, headers);

    var serviceCallOptions = {
        uri: url,
        json: true,
        headers: headers,
        body: servicePayload
    };
    try {
        const data = await request(serviceCallOptions);
        span.finish();
        return data;
    }
    catch (e) {
        span.finish();
        throw e;
    }

}

module.exports = serviceTransaction;
```

### Jaeger queries

![](/images/jaeger-ui-trace-query.png)


![](/images/jaeger-ui-ab-request.png)


## All in Cluster

[Install Istio](https://istio.io/docs/setup/getting-started/)

```
mkdir icpa-opentracing
cd icpa-opentracing
curl -L https://istio.io/downloadIstio | sh -
export PATH="$PATH:/Users/nastacio/workspace/icpa-opentracing/istio-1.4.4/bin"
istioctl verify-install 
cd is*
istioctl manifest apply --set profile=demo
```

```
istioctl manifest apply --set profile=demo
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

[Add Jaeger to Cluster](https://www.jaegertracing.io/docs/latest/operator/)

```sh
cat <<EOF | kubectl apply -f -
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: simplest
EOF
```

```
kubectl get deployment nodejs-tracing  -o yaml | ./istioctl kube-inject -f - | kubectl apply -f -
```

Expose the JaegerUI for local access:
```
kubectl expose service simplest-query --type=LoadBalancer  --name=jaeger-ui
```

```
http://localhost:16686
```

Expose Jager 
```
cd nodejs-tracing 
appsody deploy
```

[Create a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap) with the Jaeger configuration settings added to `jaeger.properties` earier in this tutorial:


```sh
kubectl create configmap jaeger-config --from-env-file=../jaeger.properties
kubectl get configmap jaeger-config -o yaml
```

```
kubectl label namespace default istio-injection=enabled
kubectl get namespace -L istio-injection
```

```
cat <<EOF | kubectl apply -f -
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
        prefix: /node-jee
    route:
    - destination:
        host: nodejs-tracing
        port:
          number: 3000
EOF
```

```sh
default
[Error] Failed to get deployment hostname and port: Failed to find deployed service IP and Port: kubectl get failed: exit status 1: Error from server (NotFound): services "nodejs-tracing" not found
[Error] Failed to find deployed service IP and Port: Failed to find deployed service IP and Port: kubectl get failed: exit status 1: Error from server (NotFound): services "nodejs-tracing" not found
```





## Tear down the environment


1. Press Ctrl+C on each terminal running Appsody.
2. Stop the Jaeger all-in-one server and delete the custom Docker network:
   ```sh
   docker stop jaeger
   docker network delete opentrace_network
    ```



## Troubleshooting

### Choosing different Jaeger client for java-openliberty stack

The Jaeger client depends on the OpenTracing libraries bundled with Open Liberty, which in turn is the core of the Appsody java-openliberty stack. At the time of the writing for this tutorial, the [recommended version](https://openliberty.io/blog/2019/12/06/microprofile-32-health-metrics-190012.html#jmo) is 0.34.0.

As the application code evolves, it is a good development practice to pick later versions of dependency libraries, but beware of these common problems when the Jaeger client version has conflicts with the OpenTracing libraries bundled with Open Liberty.

For instance, version 0.35.0 of the Jaeger client is incompatible with Open Liberty 19.0.0.12. The symptom are failed RESTful requests accompanied from this message.

`Error 500: java.lang.NoSuchMethodError: io/opentracing/ScopeManager.activeSpan&#40;&#41;Lio/opentracing/Span&#59; &#40;loaded from file:/opt/ol/wlp/lib/../dev/api/third-party/com.ibm.websphere.appserver.thirdparty.opentracing.0.31.0_1.0.35.jar by org.eclipse.osgi.internal.loader.EquinoxClassLoader@377a1965[com.ibm.websphere.appserver.thirdparty.opentracing.0.31.0:1.0.35.cl191220191120-0300&#40;id=216&#41;]&#41; called from class io.jaegertracing.internal.JaegerTracer$SpanBuilder &#40;loaded from file:/mvn/repository/io/jaegertracing/jaeger-core/0.35.0/jaeger-core-0.35.0.jar by com.ibm.ws.classloading.internal.AppClassLoader@bb1ae24d&#41;.`

If you attempt the version 1.1.0, the RESTful request also fail, but this time with a more cryptic error message about classloading violations:

`java.lang.LinkageError: loading constraint violation: loader "org/eclipse/osgi/internal/loader/EquinoxClassLoader@233ffde8" previously initiated loading for a different type with name "io/opentracing/Tracer" defined by loader "com/ibm/ws/classloading/internal/AppClassLoader@ef963440"`

In summary, be on the lookout for these types of error messages as you attempt to use more recent versions of the Jaeger client in your application.

