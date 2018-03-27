package io.github.cepr0.demo.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.Period;

import static com.fasterxml.jackson.annotation.JsonFormat.Shape.STRING;

@Data
@NoArgsConstructor
public class Child implements Serializable {
	private String name;
	@JsonFormat(shape = STRING)
	private LocalDate birthDate;
	private Gender gender;
	private Integer age;

	public Child(String name, LocalDate birthDate, Gender gender) {
		this.name = name;
		this.birthDate = birthDate;
		this.gender = gender;
		this.age = Period.between(birthDate, LocalDate.now()).getYears();
	}
}
