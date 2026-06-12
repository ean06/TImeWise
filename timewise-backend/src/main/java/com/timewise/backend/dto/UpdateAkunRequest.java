package com.timewise.backend.dto;

public class UpdateAkunRequest {

    // Untuk update setting notifikasi user
    private String statusNotif;   // "y" atau "n"
    private Integer waktuNotif; // menit sebelum deadline

    public String getStatusNotif() { return statusNotif; }
    public void setStatusNotif(String statusNotif) { this.statusNotif = statusNotif; }

    public Integer getWaktuNotif() { return waktuNotif; }
    public void setWaktuNotif(Integer waktuNotif) { this.waktuNotif = waktuNotif; }
}
