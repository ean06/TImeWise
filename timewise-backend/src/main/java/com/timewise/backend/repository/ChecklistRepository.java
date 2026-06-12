package com.timewise.backend.repository;

import com.timewise.backend.entity.Checklist;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ChecklistRepository extends JpaRepository<Checklist, Integer> {
    List<Checklist> findByTugasIdTugas(Integer idTugas);
    void deleteByTugasIdTugas(Integer idTugas);
}