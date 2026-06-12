package com.timewise.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "checklist")
public class Checklist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_checklist")
    private Integer idChecklist;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_tugas", nullable = false)
    private Tugas tugas;

    @Column(name = "isi", nullable = false, length = 200)
    private String isi;

    @Enumerated(EnumType.STRING)
    @Column(name = "selesai", columnDefinition = "ENUM('y','n') DEFAULT 'n'")
    private Selesai selesai = Selesai.n;

    @Column(name = "waktu_selesai")
    private LocalDateTime waktuSelesai;

    @Column(name = "tgl_selesai")
    private LocalDate tglSelesai;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum Selesai { y, n }
}