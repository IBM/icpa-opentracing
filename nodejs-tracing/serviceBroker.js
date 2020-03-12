// serviceBroker.js
// ================

const request = require('request-promise')
const { Tags, FORMAT_HTTP_HEADERS } = require('opentracing')

var serviceTransaction = function(serviceCUrl, servicePayload, parentSpan) {
    const tracer = parentSpan.tracer()
    const span = tracer.startSpan("service", {childOf: parentSpan.context()})
    var callResult = callService(serviceCUrl, servicePayload, span)
        .then( data => {
            span.setTag(Tags.HTTP_STATUS_CODE, 200)
            span.finish()
        })
        .catch( err => {
            console.log(err)
            span.setTag(Tags.ERROR, true)
            span.setTag(Tags.HTTP_STATUS_CODE, err.statusCode || 500)
            span.finish()
        })
    return callResult
}

async function callService(serviceCUrl, servicePayload, parentSpan) {
    const tracer = parentSpan.tracer()
    const url = serviceCUrl
    const body = servicePayload

    const span = parentSpan
    const method = 'GET'
    const headers = {}
    span.setTag(Tags.HTTP_URL, serviceCUrl)
    span.setTag(Tags.SPAN_KIND, Tags.SPAN_KIND_RPC_CLIENT)
    span.setBaggageItem("baggage", true)
    tracer.inject(span, FORMAT_HTTP_HEADERS, headers)

    var serviceCallOptions = {
        uri: url,
        json: true,
        headers: headers,
        body: servicePayload
    }
    try {
        const data = await request(serviceCallOptions)
        span.finish()
        return data
    }
    catch (e) {
        console.log(e)
        span.setTag(Tags.ERROR, true)
        span.finish()
        throw e
    }

}

module.exports = serviceTransaction
