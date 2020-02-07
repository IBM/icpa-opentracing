package application;

import io.jaegertracing.Configuration;
import io.jaegertracing.Configuration.ReporterConfiguration;
import io.jaegertracing.Configuration.SamplerConfiguration;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Main {

	@Bean
	public io.opentracing.Tracer initTracer() {
	  SamplerConfiguration samplerConfig = new SamplerConfiguration().withType("const").withParam(1);
	  ReporterConfiguration reporterConfig = ReporterConfiguration.fromEnv().withLogSpans(true);
	  return Configuration.fromEnv("app-b-springboot").withSampler(samplerConfig).withReporter(reporterConfig).getTracer();
	}

	public static void main(String[] args) {
		SpringApplication.run(Main.class, args);
	}

}
