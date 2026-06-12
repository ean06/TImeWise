package com.timewise.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "tugas")
public class Tugas {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_tugas")
    private Integer idTugas;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_akun", nullable = false)
    private Akun akun;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_kategori")
    private Kategori kategori;

    @Column(name = "judul", nullable = false, length = 150)
    private String judul;

    @Column(name = "deskripsi", columnDefinition = "TEXT")
    private String deskripsi;

    @Column(name = "tanggal_mulai", nullable = false)
    private LocalDate tanggalMulai;

    @Column(name = "deadline", nullable = false)
    private LocalDate deadline;

    @Enumerated(EnumType.STRING)
    @Column(name = "prioritas", columnDefinition = "ENUM('rendah','sedang','tinggi') DEFAULT 'sedang'")
    private Prioritas prioritas = Prioritas.sedang;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", columnDefinition = "ENUM('pending','selesai','terlambat') DEFAULT 'pending'")
    private Status status = Status.pending;

    @Column(name = "persentase_selesai")
    private Integer persentaseSelesai = 0;

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

    public enum Prioritas { rendah, sedang, tinggi }
    public enum Status    { pending, selesai, terlambat }
}