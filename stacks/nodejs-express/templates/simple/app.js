const app = require('express')()

const opentracing = require('opentracing')

const router=require('express').Router();
//
// OpenTracing instrumentation: begin
//
// app.use((req, res, next) => {

//   console.log("D")
//   req.tracer = opentracing.globalTracer();
//   const span = req.tracer.startSpan(req.method + "-" + req.url);
//   span.log({'event': 'request_start'});
//   req.span = span;

//   res.on('finish', () => {
//     span.log({'event': 'request_end'});
//     span.finish();
//   });

//   next();
// })


app.get('/', (req, res) => {
  //
  // Tutorial begin: If you need access to the parent tracer or span
  //
  const tracer = req.tracer.startSpan('some_span');
  const span = req.span
  //
  // Tutorial end: OpenTracing new span
  //

  // Use req.log (a pino instance) to log JSON:
  res.send('Hello from Appsody 2!');

});
 
module.exports.app = app;
