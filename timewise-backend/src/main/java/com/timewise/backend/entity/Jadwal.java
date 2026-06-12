package com.timewise.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;

@Entity
@Table(name = "jadwal")
public class Jadwal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_jadwal")
    private Integer idJadwal;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_akun", nullable = false)
    private Akun akun;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_kategori")
    private Kategori kategori;

    @Column(name = "nama_jadwal", nullable = false, length = 100)
    private String namaJadwal;

    @Column(name = "waktu_mulai")
    private LocalTime waktuMulai;

    @Column(name = "waktu_selesai")
    private LocalTime waktuSelesai;

    @Column(name = "tanggal")
    private LocalDate tanggal;

    @Enumerated(EnumType.STRING)
    @Column(name = "timeless", columnDefinition = "ENUM('y','n') DEFAULT 'n'")
    private Timeless timeless = Timeless.n;

    @Enumerated(EnumType.STRING)
    @Column(name = "prioritas", columnDefinition = "ENUM('rendah','sedang','tinggi') DEFAULT 'sedang'")
    private Prioritas prioritas = Prioritas.sedang;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", columnDefinition = "ENUM('pending','selesai','terlewat') DEFAULT 'pending'")
    private Status status = Status.pending;

    @Column(name = "deadline")
    private LocalDate deadline;

    @Column(name = "catatan", columnDefinition = "TEXT")
    private String catatan;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum Timeless  { y, n }
    public enum Prioritas { rendah, sedang, tinggi }
    public enum Status    { pending, selesai, terlewat }

    // Getters & Setters
    public Integer getIdJadwal() { return idJadwal; }
    public void setIdJadwal(Integer idJadwal) { this.idJadwal = idJadwal; }

    public Akun getAkun() { return akun; }
    public void setAkun(Akun akun) { this.akun = akun; }

    public Kategori getKategori() { return kategori; }
    public void setKategori(Kategori kategori) { this.kategori = kategori; }

    public String getNamaJadwal() { return namaJadwal; }
    public void setNamaJadwal(String namaJadwal) { this.namaJadwal = namaJadwal; }

    public LocalTime getWaktuMulai() { return waktuMulai; }
    public void setWaktuMulai(LocalTime waktuMulai) { this.waktuMulai = waktuMulai; }

    public LocalTime getWaktuSelesai() { return waktuSelesai; }
    public void setWaktuSelesai(LocalTime waktuSelesai) { this.waktuSelesai = waktuSelesai; }

    public LocalDate getTanggal() { return tanggal; }
    public void setTanggal(LocalDate tanggal) { this.tanggal = tanggal; }

    public Timeless getTimeless() { return timeless; }
    public void setTimeless(Timeless timeless) { this.timeless = timeless; }

    public Prioritas getPrioritas() { return prioritas; }
    public void setPrioritas(Prioritas prioritas) { this.prioritas = prioritas; }

    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }

    public LocalDate getDeadline() { return deadline; }
    public void setDeadline(LocalDate deadline) { this.deadline = deadline; }

    public String getCatatan() { return catatan; }
    public void setCatatan(String catatan) { this.catatan = catatan; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}