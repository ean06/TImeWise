package com.timewise.backend.dto;

import java.time.LocalTime;

public class UpdateAkunRequest {

    // Untuk update setting notifikasi user
    private String statusNotif;   // "y" atau "n"
    private LocalTime waktuNotif; // jam berapa notif dikirim

    public String getStatusNotif() { return statusNotif; }
    public void setStatusNotif(String statusNotif) { this.statusNotif = statusNotif; }

    public LocalTime getWaktuNotif() { return waktuNotif; }
    public void setWaktuNotif(LocalTime waktuNotif) { this.waktuNotif = waktuNotif; }
}
