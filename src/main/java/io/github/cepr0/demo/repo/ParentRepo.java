package io.github.cepr0.demo.repo;

import io.github.cepr0.demo.model.Parent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

import java.util.List;

@RepositoryRestResource
public interface ParentRepo extends JpaRepository<Parent, Integer> {
	@Query(value = "select p.* from parents p where p.phones @> cast(?#{@parentRepo.toArray(#phone)} as text[])", nativeQuery = true)
	List<Parent> findByPhone(@Param("phone") String phone);

	@Query(value = "select p.* from parents p where p.children @> cast(?#{@parentRepo.nameToJson(#name)} as jsonb)", nativeQuery = true)
	List<Parent> findByChildName(@Param("name") String name);

	default String toArray(String phone) {
		return "{+" + phone + "}";
	}

	default String nameToArray(String name) {
		return "{" + name + "}";
	}

	default String nameToJson(String name) {
		return "[{\"name\":\"" + name + "\"}]";
	}

}
