module.exports = (/*options*/) => {
  // Use options.server to access http.Server. Example with socket.io:
  //     const io = require('socket.io')(options.server)
  const app = require('express')()

  // Tutorial begin: Remote requests to other applications
  const uuid = require('uuid-random');
  const serviceTransaction = require('./serviceBroker.js');
  
  const request = require('request');
  const { Tags, FORMAT_HTTP_HEADERS } = require('opentracing');
  // Tutorial end: Remote requests to other applications

  // Tutorial begin: OpenTracing initialization
  var initTracerFromEnv = require('jaeger-client').initTracerFromEnv;
  var config = { serviceName: 'app-a-nodejs' };
  var options = {};
  var tracer = initTracerFromEnv(config, options);
  // Tutorial end: OpenTracing initialization
  
  app.get('/', (req, res) => {
    // Tutorial begin: OpenTracing new span
    const span = tracer.startSpan('http_request');
    // Tutorial end: OpenTracing new span

    // Use req.log (a `pino` instance) to log JSON:
    req.log.info({message: 'Hello from Appsody!'});
    res.send('Hello from Appsody!');

    // Tutorial begin: Send span information to Jaeger
    span.log({'event': 'request_end'});
    span.finish();
    // Tutorial end: Send span information to Jaeger
  });

  // Tutorial begin: Transaction A-B 
  app.get('/node-springboot', (req, res) => {
    const baseUrl = 'http://springboot-tracing-dev:8080';
    const serviceCUrl = baseUrl + '/resource';
    const spanName = 'http_request_ab';
 
    const span = tracer.startSpan(spanName);

    const payload = { 'itemId': uuid(), 'count': Math.floor(1 + Math.random() * 10)};

    serviceTransaction(serviceCUrl, payload, span);

    req.log.info({message: 'Hello from Appsody!'});
    res.send(payload);

    span.log({'event': 'request_end'});
    span.finish();
  });
  // Tutorial end: Transaction A-B

  // Tutorial begin: Transaction A-C
  app.get('/node-jee', (req, res) => {
    const baseUrl = 'http://jee-tracing-dev:9080';
    const serviceCUrl = baseUrl + '/starter/service';
    const spanName = 'http_request_ac';

    const payload = { 'order': uuid(), 'total': Math.floor(1 + Math.random() * 10000)};
 
    const span = tracer.startSpan(spanName);

    serviceTransaction(serviceCUrl, payload, span);

    req.log.info({message: 'Hello from Appsody!'});
    res.send(payload);

    span.log({'event': 'request_end'});
    span.finish();
  });
  // Tutorial begin: Transaction A-C

  return app;
};
