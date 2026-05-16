package com.timewise.backend.repository;

import com.timewise.backend.entity.Jadwal;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JadwalRepository extends JpaRepository<Jadwal, Integer> {

}