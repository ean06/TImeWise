package com.timewise.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "notifikasi")
public class Notifikasi {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_notifikasi")
    private Integer idNotifikasi;

    @Column(name = "jenis")
    private String jenis;

    @Column(name = "id_jadwal")
    private Integer idJadwal;

    public Integer getIdNotifikasi() { return idNotifikasi; }
    public void setIdNotifikasi(Integer idNotifikasi) { this.idNotifikasi = idNotifikasi; }

    public String getJenis() { return jenis; }
    public void setJenis(String jenis) { this.jenis = jenis; }

    public Integer getIdJadwal() { return idJadwal; }
    public void setIdJadwal(Integer idJadwal) { this.idJadwal = idJadwal; }
}
