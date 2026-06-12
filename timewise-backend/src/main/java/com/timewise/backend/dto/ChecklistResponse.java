package com.timewise.backend.dto;

public class ChecklistResponse {

    private Integer idChecklist;
    private String isi;
    private String selesai;
    private String waktuSelesai;
    private String tglSelesai;

    public Integer getIdChecklist() { return idChecklist; }
    public void setIdChecklist(Integer idChecklist) { this.idChecklist = idChecklist; }

    public String getIsi() { return isi; }
    public void setIsi(String isi) { this.isi = isi; }

    public String getSelesai() { return selesai; }
    public void setSelesai(String selesai) { this.selesai = selesai; }

    public String getWaktuSelesai() { return waktuSelesai; }
    public void setWaktuSelesai(String waktuSelesai) { this.waktuSelesai = waktuSelesai; }

    public String getTglSelesai() { return tglSelesai; }
    public void setTglSelesai(String tglSelesai) { this.tglSelesai = tglSelesai; }
}