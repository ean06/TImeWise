package com.timewise.backend.dto;

import java.time.LocalDate;
import java.time.LocalTime;

public class TambahJadwalRequest {

    private Integer idAkun;
    private Integer idKategori;
    private String namaJadwal;
    private LocalDate tanggal;
    private LocalTime waktuMulai;
    private LocalTime waktuSelesai;
    private String timeless;
    private String prioritas;  
    private String status;
    private LocalDate deadline;
    private String catatan;

    public Integer getIdAkun() { return idAkun; }
    public void setIdAkun(Integer idAkun) { this.idAkun = idAkun; }

    public Integer getIdKategori() { return idKategori; }
    public void setIdKategori(Integer idKategori) { this.idKategori = idKategori; }

    public String getNamaJadwal() { return namaJadwal; }
    public void setNamaJadwal(String namaJadwal) { this.namaJadwal = namaJadwal; }

    public LocalDate getTanggal() { return tanggal; }
    public void setTanggal(LocalDate tanggal) { this.tanggal = tanggal; }

    public LocalTime getWaktuMulai() { return waktuMulai; }
    public void setWaktuMulai(LocalTime waktuMulai) { this.waktuMulai = waktuMulai; }

    public LocalTime getWaktuSelesai() { return waktuSelesai; }
    public void setWaktuSelesai(LocalTime waktuSelesai) { this.waktuSelesai = waktuSelesai; }

    public String getTimeless() { return timeless; }
    public void setTimeless(String timeless) { this.timeless = timeless; }

    public String getPrioritas() { return prioritas; }
    public void setPrioritas(String prioritas) { this.prioritas = prioritas; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDate getDeadline() { return deadline; }
    public void setDeadline(LocalDate deadline) { this.deadline = deadline; }

    public String getCatatan() { return catatan; }
    public void setCatatan(String catatan) { this.catatan = catatan; }
}
