package com.timewise.backend.repository;

import com.timewise.backend.entity.Laporan;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LaporanRepository extends JpaRepository<Laporan, Integer> {

    List<Laporan> findByIdJadwal(Integer idJadwal);
}
