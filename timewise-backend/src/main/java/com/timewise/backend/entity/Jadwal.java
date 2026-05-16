package com.timewise.backend.entity;

import java.time.LocalDate;
import java.time.LocalTime;

import jakarta.persistence.*;

@Entity
@Table(name = "jadwal")
public class Jadwal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_jadwal")
    private Integer idJadwal;

    @Column(name = "nama_jadwal")
    private String namaJadwal;

    @Column(name = "tanggal")
    private LocalDate tanggal;

    @Column(name = "waktu")
    private LocalTime waktu;

    @Column(name = "prioritas")
    private String prioritas;

    @Column(name = "deadline")
    private LocalDate deadline;

    @Column(name = "id_akun")
    private Integer idAkun;

    // Getter dan Setter

    public Integer getIdJadwal() {
        return idJadwal;
    }

    public void setIdJadwal(Integer idJadwal) {
        this.idJadwal = idJadwal;
    }

    public String getNamaJadwal() {
        return namaJadwal;
    }

    public void setNamaJadwal(String namaJadwal) {
        this.namaJadwal = namaJadwal;
    }

    public LocalDate getTanggal() {
        return tanggal;
    }

    public void setTanggal(LocalDate tanggal) {
        this.tanggal = tanggal;
    }

    public LocalTime getWaktu() {
        return waktu;
    }

    public void setWaktu(LocalTime waktu) {
        this.waktu = waktu;
    }

    public String getPrioritas() {
        return prioritas;
    }

    public void setPrioritas(String prioritas) {
        this.prioritas = prioritas;
    }

    public LocalDate getDeadline() {
        return deadline;
    }

    public void setDeadline(LocalDate deadline) {
        this.deadline = deadline;
    }

    public Integer getIdAkun() {
        return idAkun;
    }

    public void setIdAkun(Integer idAkun) {
        this.idAkun = idAkun;
    }
}