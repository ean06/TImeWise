package com.timewise.backend.repository;

import com.timewise.backend.entity.Jadwal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public interface JadwalRepository extends JpaRepository<Jadwal, Integer> {

    List<Jadwal> findByAkunIdAkunOrderByTanggalAscWaktuMulaiAsc(Integer idAkun);

    List<Jadwal> findAllByAkunIdAkun(Integer idAkun);

    @Query("""
        SELECT j FROM Jadwal j
        JOIN j.akun a
        WHERE a.statusNotif = 'y'
            AND j.status = com.timewise.backend.entity.Jadwal.Status.pending
            AND j.timeless = com.timewise.backend.entity.Jadwal.Timeless.n
            AND j.tanggal = :today
            AND j.waktuMulai BETWEEN :dari AND :sampai
        """)
    List<Jadwal> findJadwalUntukNotif(
            @Param("today")  LocalDate today,
            @Param("sampai") LocalTime sampai,
            @Param("dari")   LocalTime dari
    );
}