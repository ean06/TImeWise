package com.timewise.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "notifikasi")
public class Notifikasi {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_notifikasi")
    private Integer idNotifikasi;

    @Column(name = "status")
    private Boolean status;

    @Column(name = "reminder")
    private Integer reminder;

    @Column(name = "id_jadwal")
    private Integer idJadwal;

    public Integer getIdNotifikasi() { return idNotifikasi; }
    public void setIdNotifikasi(Integer idNotifikasi) { this.idNotifikasi = idNotifikasi; }

    public Boolean getStatus() { return status; }
    public void setStatus(Boolean status) { this.status = status; }

    public Integer getReminder() { return reminder; }
    public void setReminder(Integer reminder) { this.reminder = reminder; }

    public Integer getIdJadwal() { return idJadwal; }
    public void setIdJadwal(Integer idJadwal) { this.idJadwal = idJadwal; }
}
