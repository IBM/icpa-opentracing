// Requires statements and code for non-production mode usage
if (!process.env.NODE_ENV || !process.env.NODE_ENV === 'production') {
  require('appmetrics-dash').attach();
}
const express = require('express');
const health = require('@cloudnative/health-connect');
const fs = require('fs');

require('appmetrics-prometheus').attach();

const app = express();

const basePath = __dirname + '/user-app/';

function getEntryPoint() {
    let rawPackage = fs.readFileSync(basePath + 'package.json');
    let package = JSON.parse(rawPackage);
    if (!package.main) {
        console.error("Please define a primary entrypoint of your application by agdding 'main: <entrypoint>' to package.json.")
        process.exit(1)
    }
    return package.main;
}

//
// OpenTracing instrumentation: begin
//
const opentracing = require('opentracing')
var initTracerFromEnv = require('jaeger-client').initTracerFromEnv
const jaegerEndpoint = process.env.JAEGER_ENDPOINT || "http://jaeger-collector:14268/api/traces";
const jaegerReporterLogSpans = process.env.JAEGER_REPORTER_LOG_SPANS || true;
const jaegerSamplerType = process.env.JAEGER_SAMPLER_TYPE || "const";
const jaegerSamplerParam = process.env.JAEGER_SAMPLER_PARAM || 1;

var userAppJson = require(basePath + '/package.json');
var config = { 
  serviceName: userAppJson.name
}
config.sampler = { 
  type: jaegerSamplerType, param: jaegerSamplerParam
}
config.reporter = { 
  logSpans: jaegerReporterLogSpans,
  collectorEndpoint: jaegerEndpoint 
};
var options = {}
var tracer = initTracerFromEnv(config, options)

if (jaegerEndpoint.includes("cluster")) {
  // This block is required for compatibility with the service meshes
  // using B3 headers for header propagation
  // https://github.com/openzipkin/b3-propagation
  const ZipkinB3TextMapCodec = require('jaeger-client').ZipkinB3TextMapCodec
  let codec = new ZipkinB3TextMapCodec({ urlEncoding: true });
  tracer.registerInjector(opentracing.FORMAT_HTTP_HEADERS, codec);
  tracer.registerExtractor(opentracing.FORMAT_HTTP_HEADERS, codec);
}

opentracing.initGlobalTracer(tracer)

// From: https://ibm-cloud-architecture.github.io/learning-distributed-tracing-101/docs/lab-jaeger-nodejs.html
function tracingMiddleWare(req, res, next) {

  const tracer = opentracing.globalTracer();

  const wireCtx = tracer.extract(opentracing.FORMAT_HTTP_HEADERS, req.headers)
  const span = tracer.startSpan(req.method + "-" + req.path, { childOf: wireCtx })
  span.log({ event: 'request_received' })

  // Use the setTag api to capture standard span tags for http traces
  span.setTag(opentracing.Tags.HTTP_METHOD, req.method)
  span.setTag(opentracing.Tags.SPAN_KIND, opentracing.Tags.SPAN_KIND_RPC_SERVER)
  span.setTag(opentracing.Tags.HTTP_URL, req.path)

  // include trace ID in headers so that we can debug slow requests we see in
  // the browser by looking up the trace ID found in response headers
  const responseHeaders = {}
  tracer.inject(span, opentracing.FORMAT_HTTP_HEADERS, responseHeaders)
  res.set(responseHeaders)

  // add the span to the request object for any other handler to use the span
  Object.assign(req, { span })

  // finalize the span when the response is completed
  const finishSpan = () => {
    if (res.statusCode >= 500) {
      // Force the span to be collected for http errors
      span.setTag(opentracing.Tags.SAMPLING_PRIORITY, 1)
      // If error then set the span to error
      span.setTag(opentracing.Tags.ERROR, true)

      // Response should have meaning info to futher troubleshooting
      span.log({ event: 'error', message: res.statusMessage })
    }
    // Capture the status code
    span.setTag(opentracing.Tags.HTTP_STATUS_CODE, res.statusCode)
    span.log({ event: 'request_end' })
    span.finish()
  }
  res.on('finish', finishSpan)
  next()
}
app.use(tracingMiddleWare)
//
// OpenTracing instrumentation: end
//

// Register the users app. As this is before the health/live/ready routes,
// those can be overridden by the user
const userApp = require(basePath + getEntryPoint()).app;
app.use('/', userApp);

const healthcheck = new health.HealthChecker();
app.use('/live', health.LivenessEndpoint(healthcheck));
app.use('/ready', health.ReadinessEndpoint(healthcheck));
app.use('/health', health.HealthEndpoint(healthcheck));

app.get('*', (req, res) => {
  res.status(404).send("Not Found");
});


const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(`App started on PORT ${PORT}`);
});

// Export server for testing purposes
module.exports.server = server;
module.exports.PORT = PORT;