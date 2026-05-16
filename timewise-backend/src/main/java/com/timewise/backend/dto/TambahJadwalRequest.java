package com.timewise.backend.dto;

import java.time.LocalDate;
import java.time.LocalTime;


public class TambahJadwalRequest {

    private String namaJadwal;
    private LocalDate tanggal;
    private LocalTime waktu;
    private String prioritas;
    private LocalDate deadline;
    private Integer idAkun;

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