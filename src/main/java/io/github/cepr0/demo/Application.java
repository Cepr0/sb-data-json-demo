package io.github.cepr0.demo;

import com.github.javafaker.Faker;
import io.github.cepr0.demo.model.Child;
import io.github.cepr0.demo.model.Gender;
import io.github.cepr0.demo.model.Parent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@SpringBootApplication
public class Application {

	@PersistenceContext
	private EntityManager em;

	@Value("${spring.jpa.properties.hibernate.jdbc.batch_size:100}")
	private int batchSize;

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

	@Transactional
	@EventListener
	public void onReady(ApplicationReadyEvent e) {
		em.createQuery("delete from Parent").executeUpdate();
		log.info("Data is cleaned.");

		Faker faker = new Faker();

		for (int i = 0; i < 1_000_000; i++) {

			int childrenCount = 1 + faker.random().nextInt(5);
			List<Child> children = new ArrayList<>(childrenCount);
			for (int j = 0; j < childrenCount; j++) {
				children.add(
						new Child(
								faker.name().firstName(),
								new Date(faker.date().birthday(1, 18).getTime()).toLocalDate(),
								Gender.valueOf(faker.demographic().sex().toUpperCase())
						)
				);
			}

			int phonesCount = 1 + faker.random().nextInt(3);
			List<String> phones = new ArrayList<>(phonesCount);
			for (int j = 0; j < phonesCount; j++) {
				phones.add(faker.phoneNumber().cellPhone());
			}

			Parent parent = new Parent(faker.name().name(), children, phones);

			em.persist(parent);
			if (i != 0 && i % batchSize == 0) {
				em.flush();
				em.clear();
			}

			if (i != 0 && i % 10_000 == 0) {
				log.info("Inserted records: {}", i);
			}
		}
	}
}
