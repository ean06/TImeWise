package com.timewise.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalTime;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "akun")
public class Akun {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_akun")
    private Integer idAkun;

    @Column(name = "username", nullable = false, unique = true, length = 50)
    private String username;

    @Column(name = "password", nullable = false, length = 255)
    private String password;

    @Enumerated(EnumType.STRING)
    @Column(name = "status_notif", columnDefinition = "ENUM('y','n') DEFAULT 'y'")
    private StatusNotif statusNotif = StatusNotif.y;

    @Column(name = "waktu_notif")
    private Integer waktuNotif;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "last_active_at")
    private LocalDateTime lastActiveAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum StatusNotif { y, n }
}