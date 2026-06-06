package com.timewise.backend.repository;

import com.timewise.backend.entity.Notifikasi;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotifikasiRepository extends JpaRepository<Notifikasi, Integer> {

    List<Notifikasi> findByIdJadwal(Integer idJadwal);
}
