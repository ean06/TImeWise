package com.timewise.backend.dto;

public class UpdateAkunRequest {

    private String statusNotif;   
    private Integer waktuNotif; 

    public String getStatusNotif() { return statusNotif; }
    public void setStatusNotif(String statusNotif) { this.statusNotif = statusNotif; }

    public Integer getWaktuNotif() { return waktuNotif; }
    public void setWaktuNotif(Integer waktuNotif) { this.waktuNotif = waktuNotif; }
}
