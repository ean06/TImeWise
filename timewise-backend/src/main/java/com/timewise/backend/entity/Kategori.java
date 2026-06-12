package com.timewise.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "kategori")
public class Kategori {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_kategori")
    private Integer idKategori;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_akun", nullable = false)
    private Akun akun;

    @Column(name = "nama", nullable = false, length = 50)
    private String nama;

    @Column(name = "warna", nullable = false, length = 7)
    private String warna = "#6C63FF";

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}