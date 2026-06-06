package com.timewise.backend.repository;

import com.timewise.backend.entity.Jadwal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface JadwalRepository extends JpaRepository<Jadwal, Integer> {

    List<Jadwal> findByIdAkunOrderByTanggalAscWaktuAsc(Integer idAkun);

    @Query("SELECT j FROM Jadwal j WHERE j.idAkun = :idAkun ORDER BY j.tanggal ASC, j.waktu ASC")
    List<Jadwal> findAllByIdAkun(@Param("idAkun") Integer idAkun);
}
