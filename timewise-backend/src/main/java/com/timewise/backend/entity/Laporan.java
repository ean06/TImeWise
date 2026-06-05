package com.timewise.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "laporan")
public class Laporan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_laporan")
    private Integer idLaporan;

    @Column(name = "jenis")
    private String jenis;

    @Column(name = "id_jadwal")
    private Integer idJadwal;

    public Integer getIdLaporan() { return idLaporan; }
    public void setIdLaporan(Integer idLaporan) { this.idLaporan = idLaporan; }

    public String getJenis() { return jenis; }
    public void setJenis(String jenis) { this.jenis = jenis; }

    public Integer getIdJadwal() { return idJadwal; }
    public void setIdJadwal(Integer idJadwal) { this.idJadwal = idJadwal; }
}
