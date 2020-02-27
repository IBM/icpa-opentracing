module.exports = (/*options*/) => {
  // Use options.server to access http.Server. Example with socket.io:
  //     const io = require('socket.io')(options.server)
  const app = require('express')()

  //
  // Tutorial begin: Remote requests to other applications
  //
  const request = require('request')
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
    // Use req.log (a `pino` instance) to log JSON:
    req.log.info({message: 'Hello from Appsody!'})
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

    const payload = { 'itemId': uuid(), 'count': Math.floor(1 + Math.random() * 10)}
    serviceTransaction(serviceCUrl, payload, span)
      .then(() => {
        const finishSpan = () => {
          span.log({'event': 'request_end'})
          span.finish()
        }

        res.on('finish', finishSpan)

        req.log.info({message: spanName})
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

    const payload = { 'order': uuid(), 'total': Math.floor(1 + Math.random() * 10000)}
    serviceTransaction(serviceCUrl, payload, span)
      .then(() => {
        const finishSpan = () => {
          span.log({'event': 'request_end'})
          span.finish()
        }

        res.on('finish', finishSpan)

        req.log.info({message: spanName})
        res.send(payload)
      })
  })
  // Tutorial end: Transaction A-C

  return app
}
