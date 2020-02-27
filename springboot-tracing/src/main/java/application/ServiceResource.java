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