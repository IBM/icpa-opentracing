
# step 1

stack_hub_url=https://github.com/kabanero-io/kabanero-stack-hub/releases/latest/download/kabanero-stack-hub-index.yaml
appsody list kabanero 2> /dev/null || appsody repo add kabanero ${stack_hub_url}

docker network create opentrace_network

docker run --name jaeger-collector \
  --detach \
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

docker logs jaeger-collector

cd ~
tutorial_dir=~/workspace/opentracing-tutorial-part1
rm -rf "${tutorial_dir}"
mkdir -p "${tutorial_dir}"
cd "${tutorial_dir}"


cat > jaeger.properties << EOF
JAEGER_ENDPOINT=http://jaeger-collector:14268/api/traces
JAEGER_REPORTER_LOG_SPANS=true
JAEGER_SAMPLER_TYPE=const
JAEGER_SAMPLER_PARAM=1
JAEGER_PROPAGATION=b3
EOF

# step 2 - new window

cd "${tutorial_dir}"
mkdir nodejs-tracing
cd nodejs-tracing
appsody init kabanero/nodejs-express

sed -i bak 's|"name": "nodejs-express-simple",|"name": "app-a-nodejs",|' package.json
sed -i bak $'/devDependencies/  i\
\\  "dependencies": { \
\\    "jaeger-client": "^3.17.1" \
\\  },\\\n' package.json

cat<<EOF > app.js
const app = require('express')()

//
// Tutorial begin: Global initialization block
//
var initTracerFromEnv = require('jaeger-client').initTracerFromEnv;
var config = {
  serviceName: 'app-a-nodejs',
};
var options = {
};
var tracer = initTracerFromEnv(config, options);
//
// Tutorial end: Global initialization block
//

app.get('/', (req, res) => {
  //
  // Tutorial begin: OpenTracing new span
  //
  const span = tracer.startSpan('http_request');
  //
  // Tutorial end: OpenTracing new span
  //

  // Use req.log (a pino instance) to log JSON:
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

module.exports.app = app;
EOF


appsody run \
  --name "nodejs-tracing" \
  --publish "8081:8080" \
  --docker-options="--env-file ../jaeger.properties" \
  --network opentrace_network 


# step 3 - new window

tutorial_dir=~/workspace/opentracing-tutorial-part1
cd "${tutorial_dir}"
mkdir springboot-tracing
cd springboot-tracing
appsody init kabanero/java-spring-boot2

sed -i bak 's|<artifactId>default-application</artifactId>|<artifactId>app-b-springboot</artifactId>|' pom.xml

cat<< EOF > ./src/main/java/application/Main.java
package application;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

//
// Tutorial: Begin import statements for Jaeger and OpenTracing
//
import org.springframework.context.annotation.Bean;
import io.jaegertracing.Configuration;
import io.opentracing.Tracer;
//
// Tutorial: End import statements for Jaeger and OpenTracing
//

@SpringBootApplication
public class Main {

        //
        // Tutorial: Begin initialization of OpenTracing tracer
        //
        @Bean
        public Tracer initTracer() {
          return Configuration.fromEnv("app-b-springboot").getTracer();
        }
        //
        // Tutorial: End initialization of OpenTracing tracer
        //

        public static void main(String[] args) {
                SpringApplication.run(Main.class, args);
        }

}
EOF

appsody run \
  --name springboot-tracing \
  --docker-options="--env-file ../jaeger.properties" \
  --network opentrace_network

# step 4 - new window

tutorial_dir=~/workspace/opentracing-tutorial-part1
cd "${tutorial_dir}"
mkdir jee-tracing
cd jee-tracing
appsody init kabanero/java-openliberty

sed -i bak 's|<artifactId>starter-app</artifactId>|<artifactId>app-c-jee</artifactId>|' pom.xml
sed -i bak $'/\<\/dependencies\>/  i\
\\\n \
\\        \<dependency\> \
\\            \<groupId\>io.jaegertracing\<\/groupId\> \
\\            \<artifactId\>jaeger-client\<\/artifactId\> \
\\            \<version\>0.34.0\<\/version\> \
\\        \<\/dependency\>\\\n\\\n' pom.xml

sed -i bak $'/\<\/featureManager\>/  i\
\\        \<feature\>mpOpenTracing-1.3\<\/feature\>\\\n' src/main/liberty/config/server.xml

sed -i bak '/webApplication/d' src/main/liberty/config/server.xml

sed -i bak $'/\<\/server\>/  i\
\\    \<webApplication location="app-c-jee.war" contextRoot="\/" \> \
\\        \<classloader apiTypeVisibility="+third-party" \/\> \
\\    \<\/webApplication\>\\\n\\\n' src/main/liberty/config/server.xml


appsody run \
  --name jee-tracing \
  --publish "9444:9443" \
  --docker-options="--env-file ../jaeger.properties" \
  --network opentrace_network 


# step 5

tutorial_dir=~/workspace/opentracing-tutorial-part1
cd "${tutorial_dir}"
cd jee-tracing

cat<<EOF > src/main/java/dev/appsody/starter/ServiceResource.java
package dev.appsody.starter;

import javax.inject.Inject;
import javax.json.Json;
import javax.json.JsonObject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;

import io.opentracing.Scope;
import io.opentracing.Tracer;
import io.opentracing.tag.Tags;

@Path("/service")
public class ServiceResource {

    @Inject
    Tracer tracer;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response completeOrder(JsonObject orderPayload, @Context HttpHeaders httpHeaders) {
        try (Scope childScope = tracer.buildSpan("phase_1").startActive(true)) {
            MultivaluedMap<String, String> requestHeaders = httpHeaders.getRequestHeaders();
            requestHeaders.forEach((k, v) -> System.out.println(k + ":" + v.toString()));
            System.out.println(orderPayload);
            System.out.println("baggage item: " + tracer.activeSpan().getBaggageItem("baggage"));
        }

        try (Scope childScope = tracer.buildSpan("phase_2").startActive(true)) {
            double orderTotal = orderPayload.getJsonNumber("total").doubleValue();
            if (orderTotal > 6000) {
                childScope.span().setTag(Tags.ERROR.getKey(), true);
                childScope.span().log("Order value " + orderTotal + " is too high");
            }
            // Simulation of long stretch of work
            Thread.sleep(60);
        } catch (InterruptedException e) {
            // no-op
        }

        JsonObject response = Json.createObjectBuilder().add("status", "completed")
                .add("order", orderPayload.getString("order")).build();
        return Response.ok(response).build();
    }
}
EOF


tutorial_dir=~/workspace/opentracing-tutorial-part1
cd "${tutorial_dir}"
cd springboot-tracing

cat<<EOF > src/main/java/application/ServiceResource.java
package application;

import java.util.Map;
import java.util.Random;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import io.opentracing.Span;
import io.opentracing.Tracer;
import io.opentracing.tag.Tags;

@RestController
public class ServiceResource {

    @Autowired
    private Tracer tracer;

    @GetMapping(value = "/resource", consumes = "application/json", produces = "application/json")
    public ResponseEntity<Object> quoteItem(@RequestBody Map<String, Object> quotePayload,
        @RequestHeader HttpHeaders  httpHeaders) {

        Span parentSpan = tracer.scopeManager().activeSpan();
        Span spanPhase1 = tracer.buildSpan("phase_1").asChildOf(parentSpan).start();
        try {
            httpHeaders.forEach((k, v) -> System.out.println(k + ":" + v.toString()));
            quotePayload.forEach((k, v) -> System.out.println(k + ":" + v.toString()));
            System.out.println("baggage:" + parentSpan.getBaggageItem("baggage"));
        } finally {
            spanPhase1.finish();
        }

        Span spanPhase2 = tracer.buildSpan("phase_2").asChildOf(parentSpan).start();
        try {
            int orderTotal = (Integer) quotePayload.getOrDefault("count", 0);
            if (orderTotal > 7) {
                spanPhase2.setTag(Tags.ERROR.getKey(), true);
                spanPhase2.log("Out of stock for item " + quotePayload.get("itemId"));
            }
            try {
                // Simulate long stretch of work
                Thread.sleep(60);
            } catch (InterruptedException e) {
                // no-op
            }
        } finally {
            spanPhase2.finish();
        }

        return ResponseEntity
          .ok().contentType(MediaType.APPLICATION_JSON)
          .body("{ \"quote\", " + new Random().nextFloat() + " }");
    }
}
EOF


tutorial_dir=~/workspace/opentracing-tutorial-part1
cd "${tutorial_dir}"
cd nodejs-tracing


sed -i bak 's|"jaeger-client": "^3.17.1"|"jaeger-client": "^3.17.1",|' package.json
sed -i bak $'/jaeger-client/  a\
\\    "opentracing": "latest", \
\\    "request-promise": "^4.2.0", \
\\    "uuid-random": "latest"\\\n' package.json
cat package.json

appsody stop --name nodejs-tracing
appsody run \
  --name "nodejs-tracing" \
  --publish "8081:8080" \
  --docker-options="--env-file ../jaeger.properties" \
  --network opentrace_network

cat<<EOF > serviceBroker.js
// serviceBroker.js
// ================

const request = require('request-promise');
const { Tags, FORMAT_HTTP_HEADERS } = require('opentracing');

var serviceTransaction = function(serviceCUrl, servicePayload, parentSpan) {
    const tracer = parentSpan.tracer();
    const span = tracer.startSpan("service", {childOf: parentSpan.context()});
    var callResult = callService(serviceCUrl, servicePayload, span)
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
    return callResult;
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
    span.setBaggageItem("baggage", true);
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
        span.setTag(Tags.ERROR, true)
        span.finish();
        throw e;
    }

}

module.exports = serviceTransaction;
EOF


cat <<EOF > app.js
const app = require('express')()

//
// Tutorial begin: Remote requests to other applications
//
const uuid = require('uuid-random')
const serviceTransaction = require('./serviceBroker.js')
//
// Tutorial end: Remote requests to other applications
//

//
// Tutorial begin: OpenTracing initialization
//
const opentracing = require('opentracing')
var initTracerFromEnv = require('jaeger-client').initTracerFromEnv
var config = { serviceName: 'app-a-nodejs' }
var options = {}
var tracer = initTracerFromEnv(config, options)

// This block is required for compatibility with the service meshes
// using B3 headers for header propagation
// https://github.com/openzipkin/b3-propagation
const ZipkinB3TextMapCodec = require('jaeger-client').ZipkinB3TextMapCodec
let codec = new ZipkinB3TextMapCodec({ urlEncoding: true });
tracer.registerInjector(opentracing.FORMAT_HTTP_HEADERS, codec);
tracer.registerExtractor(opentracing.FORMAT_HTTP_HEADERS, codec);

opentracing.initGlobalTracer(tracer)
//
// Tutorial end: OpenTracing initialization
//

app.get('/', (req, res) => {
  res.send('Hello from Appsody!')
})

// Tutorial begin: Transaction A-B
app.get('/node-springboot', (req, res) => {
  const baseUrl = 'http://springboot-tracing:8080'
  const serviceCUrl = baseUrl + '/resource'
  const spanName = 'http_request_ab'

  // https://opentracing-javascript.surge.sh/classes/tracer.html#extract
  const wireCtx = tracer.extract(opentracing.FORMAT_HTTP_HEADERS, req.headers)
  const span = tracer.startSpan(spanName, { childOf: wireCtx })
  span.log({ event: 'request_received' })

  const payload = { itemId: uuid(),
                    count: Math.floor(1 + Math.random() * 10)}
  serviceTransaction(serviceCUrl, payload, span)
    .then(() => {
      const finishSpan = () => {
        span.log({ event : 'request_end'})
        span.finish()
      }

      res.on('finish', finishSpan)

      res.send(payload)
    })
})
// Tutorial end: Transaction A-B

// Tutorial begin: Transaction A-C
app.get('/node-jee', (req, res) => {
  const baseUrl = 'http://jee-tracing:9080'
  const serviceCUrl = baseUrl + '/starter/service'
  const spanName = 'http_request_ac'

  const wireCtx = tracer.extract(opentracing.FORMAT_HTTP_HEADERS, req.headers)
  const span = tracer.startSpan(spanName, { childOf: wireCtx })
  span.log({ event: 'request_received' })

  const payload = { order: uuid(),
                    total: Math.floor(1 + Math.random() * 10000)}
  serviceTransaction(serviceCUrl, payload, span)
    .then(() => {
      const finishSpan = () => {
        span.log({ event : 'request_end'})
        span.finish()
      }

      res.on('finish', finishSpan)

      res.send(payload)
    })
})
// Tutorial end: Transaction A-C

module.exports.app = app;
EOF


# step 6
for i in {1..50}
do
  curl -s http://localhost:3000/node-jee
  sleep 1
  curl -s http://localhost:3000/node-springboot
  sleep 1
done


# step 7
appsody stop --name nodejs-tracing
appsody stop --name springboot-tracing
appsody stop --name jee-tracing
docker stop jaeger-collector
docker network rm opentrace_network
