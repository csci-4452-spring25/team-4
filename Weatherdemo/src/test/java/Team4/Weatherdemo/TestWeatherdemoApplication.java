package Team4.Weatherdemo;

import org.springframework.boot.SpringApplication;

public class TestWeatherdemoApplication {

	public static void main(String[] args) {
		SpringApplication.from(WeatherdemoApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
