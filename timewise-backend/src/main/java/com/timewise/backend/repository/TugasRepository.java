package com.timewise.backend.repository;

import com.timewise.backend.entity.Tugas;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;

public interface TugasRepository extends JpaRepository<Tugas, Integer> {

    List<Tugas> findByAkunIdAkun(Integer idAkun);

    List<Tugas> findByAkunIdAkunAndDeadline(Integer idAkun, LocalDate deadline);
}