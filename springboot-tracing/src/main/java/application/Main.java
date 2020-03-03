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