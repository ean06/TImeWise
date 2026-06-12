package com.timewise.backend.dto;

public class ChecklistUpdateRequest {

    // "y" = sudah dicentang, "n" = di-uncentang
    // logika status tugas (selesai/terlambat) dihitung di frontend
    private String selesai;

    public String getSelesai() { return selesai; }
    public void setSelesai(String selesai) { this.selesai = selesai; }
}
