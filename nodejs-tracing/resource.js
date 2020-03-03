// resource.js
// ===========

const request = require('request-promise');
const { Tags, FORMAT_HTTP_HEADERS } = require('opentracing');

var transaction1 = function(tracer, root_span) {

    const span = tracer.startSpan('t1');
    span.setTag('sometag', 'x');

    const helloTo = 'a';
    format_string(tracer, helloTo, span)
        .then( data => {
            return print_hello(tracer, data, span);
        })
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

function format_string(tracer, input, root_span) {
    const url = `http://jee-tracing-dev:9080/starter/resource`;
    const fn = 'format';

    const span = tracer.startSpan(fn, {childOf: root_span.context()});
    span.log({
        'event': 'format-string',
        'value': input
    });

    return http_get(tracer, url, span); 
}  

function print_hello(tracer, input, root_span) {
    const url = `http://jee-tracing-dev:9080/starter/resource`;
    const fn = 'publish';

    const span = tracer.startSpan(fn, {childOf: root_span.context()});
    span.log({
        'event': 'print-string',
        'value': input
    });
    return http_get(tracer, url, span);
}

function http_get(tracer, url, span) {
    const method = 'GET';
    const headers = {};
    
    span.setTag(Tags.HTTP_URL, url);
    span.setTag(Tags.HTTP_METHOD, method);
    span.setTag(Tags.SPAN_KIND, Tags.SPAN_KIND_RPC_CLIENT);
    // Send span context via request headers (parent id etc.)
    tracer.inject(span, FORMAT_HTTP_HEADERS, headers);

    return request({url, method, headers})
        .then( data => {
            span.finish();
            return data;
        }, e => {
            span.finish();
            throw e;
        });

}

module.exports = transaction1;
