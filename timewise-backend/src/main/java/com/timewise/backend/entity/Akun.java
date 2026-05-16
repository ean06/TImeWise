package com.timewise.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "akun")
public class Akun {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)

    @Column(name = "id_akun")
    private Integer idAkun;

    @Column(name = "username")
    private String username;

    @Column(name = "password")
    private String password;

    public Integer getIdAkun() {
        return idAkun;
    }

    public void setIdAkun(Integer idAkun) {
        this.idAkun = idAkun;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}