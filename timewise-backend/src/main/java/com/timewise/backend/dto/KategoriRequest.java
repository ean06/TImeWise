package com.timewise.backend.dto;

public class KategoriRequest {

    private Integer idAkun;
    private String nama;
    private String warna;

    public Integer getIdAkun() { return idAkun; }
    public void setIdAkun(Integer idAkun) { this.idAkun = idAkun; }

    public String getNama() { return nama; }
    public void setNama(String nama) { this.nama = nama; }

    public String getWarna() { return warna; }
    public void setWarna(String warna) { this.warna = warna; }
}
