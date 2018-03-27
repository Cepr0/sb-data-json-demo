package io.github.cepr0.demo.model;

import com.vladmihalcea.hibernate.type.array.StringArrayType;
import com.vladmihalcea.hibernate.type.json.JsonBinaryType;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Type;
import org.hibernate.annotations.TypeDef;
import org.hibernate.annotations.TypeDefs;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;
import java.io.Serializable;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

@Data
@NoArgsConstructor
@Entity
@Table(name = "parents")
@TypeDefs({
		@TypeDef(name = "string-array", typeClass = StringArrayType.class),
		@TypeDef(name = "jsonb", typeClass = JsonBinaryType.class)
})
public class Parent implements Serializable {

	private static final AtomicInteger COUNTER = new AtomicInteger();

	@Id
	private Integer id = COUNTER.incrementAndGet();

	@Column(nullable = false, columnDefinition = "text")
	private String name;

	@Type(type = "jsonb")
	@Column(columnDefinition = "jsonb")
	private List<Child> children;

	@Type(type = "jsonb")
	@Column(columnDefinition = "jsonb")
	private List<String> phones;

	public Parent(String name, List<Child> children, List<String> phones) {
		this.name = name;
		this.children = children;
		this.phones = phones;
	}
}
