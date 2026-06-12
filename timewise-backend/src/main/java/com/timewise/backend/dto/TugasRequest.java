package com.timewise.backend.dto;

import java.time.LocalDate;

public class TugasRequest {

    private Integer idAkun;
    private Integer idKategori;
    private String judul;
    private String deskripsi;
    private LocalDate tanggalMulai;
    private LocalDate deadline;
    private String prioritas;
    private String status;
    private Integer persentaseSelesai;

    public Integer getIdAkun() { return idAkun; }
    public void setIdAkun(Integer idAkun) { this.idAkun = idAkun; }

    public Integer getIdKategori() { return idKategori; }
    public void setIdKategori(Integer idKategori) { this.idKategori = idKategori; }

    public String getJudul() { return judul; }
    public void setJudul(String judul) { this.judul = judul; }

    public String getDeskripsi() { return deskripsi; }
    public void setDeskripsi(String deskripsi) { this.deskripsi = deskripsi; }

    public LocalDate getTanggalMulai() { return tanggalMulai; }
    public void setTanggalMulai(LocalDate tanggalMulai) { this.tanggalMulai = tanggalMulai; }

    public LocalDate getDeadline() { return deadline; }
    public void setDeadline(LocalDate deadline) { this.deadline = deadline; }

    public String getPrioritas() { return prioritas; }
    public void setPrioritas(String prioritas) { this.prioritas = prioritas; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getPersentaseSelesai() { return persentaseSelesai; }
    public void setPersentaseSelesai(Integer persentaseSelesai) { this.persentaseSelesai = persentaseSelesai; }
}