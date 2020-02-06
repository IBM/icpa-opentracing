var initTracerFromEnv = require('jaeger-client').initTracerFromEnv;
var config = {
  serviceName: 'app-C-nodejs',
};
var options = {
  tags: {
    'my-awesome-service.version': '1.1.2',
  }
};
var tracer = initTracerFromEnv(config, options);

module.exports = (/*options*/) => {
  // Use options.server to access http.Server. Example with socket.io:
  //     const io = require('socket.io')(options.server)
  const app = require('express')()

  app.get('/', (req, res) => {
    const span = tracer.startSpan('http_request');

    // Use req.log (a `pino` instance) to log JSON:
    req.log.info({message: 'Hello from Appsody!'});
    res.send('Hello from Appsody!');

    span.log({'event': 'request_end'});
    span.finish();
  });

  return app;
};
