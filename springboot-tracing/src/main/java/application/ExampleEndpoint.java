package application;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ExampleEndpoint {

    @RequestMapping("/example")
    public String example() {
        return "This is an example";
    }
}