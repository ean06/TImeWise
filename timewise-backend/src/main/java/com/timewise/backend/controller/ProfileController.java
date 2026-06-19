package com.timewise.backend.controller;

import com.timewise.backend.entity.Akun;
import com.timewise.backend.repository.AkunRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@CrossOrigin("*")
public class ProfileController {

    @Autowired
    private AkunRepository akunRepository;

    @GetMapping("/akun/{idAkun}")
    public Map<String, Object> getAkun(@PathVariable Integer idAkun) {
        Map<String, Object> response = new HashMap<>();

        Optional<Akun> optAkun = akunRepository.findById(idAkun);
        if (optAkun.isEmpty()) {
            response.put("status", "fail");
            response.put("message", "Akun tidak ditemukan");
            return response;
        }

        Akun akun = optAkun.get();
        response.put("status", "success");
        response.put("id_akun", akun.getIdAkun());
        response.put("username", akun.getUsername());
        response.put("status_notif", akun.getStatusNotif() != null ? akun.getStatusNotif().name() : "y");
        response.put("waktu_notif", akun.getWaktuNotif() != null ? akun.getWaktuNotif() : 30);
        return response;
    }

    @PutMapping("/akun/{idAkun}/profile")
    public Map<String, Object> updateProfile(
            @PathVariable Integer idAkun,
            @RequestBody Map<String, String> request) {

        Map<String, Object> response = new HashMap<>();

        Optional<Akun> optAkun = akunRepository.findById(idAkun);
        if (optAkun.isEmpty()) {
            response.put("status", "fail");
            response.put("message", "Akun tidak ditemukan");
            return response;
        }

        Akun akun = optAkun.get();

        String newUsername = request.get("username");

        if (newUsername != null && !newUsername.equals(akun.getUsername())) {
            Akun existing = akunRepository.findByUsername(newUsername);
            if (existing != null) {
                response.put("status", "username_taken");
                response.put("message", "Username sudah dipakai");
                return response;
            }
            akun.setUsername(newUsername);
        }

        akunRepository.save(akun);

        response.put("status", "success");
        response.put("id_akun", akun.getIdAkun());
        response.put("username", akun.getUsername());
        return response;
    }

    @PutMapping("/akun/{idAkun}/change-password")
    public Map<String, Object> changePassword(
            @PathVariable Integer idAkun,
            @RequestBody Map<String, String> request) {

        Map<String, Object> response = new HashMap<>();

        Optional<Akun> optAkun = akunRepository.findById(idAkun);
        if (optAkun.isEmpty()) {
            response.put("status", "fail");
            response.put("message", "Akun tidak ditemukan");
            return response;
        }

        Akun akun = optAkun.get();
        String oldPassword = request.get("oldPassword");
        String newPassword = request.get("newPassword");

        if (oldPassword == null || !oldPassword.equals(akun.getPassword())) {
            response.put("status", "fail");
            response.put("message", "Password saat ini salah");
            return response;
        }

        if (newPassword == null || newPassword.length() < 6) {
            response.put("status", "fail");
            response.put("message", "Password baru minimal 6 karakter");
            return response;
        }

        akun.setPassword(newPassword);
        akunRepository.save(akun);

        response.put("status", "success");
        return response;
    }

    @PutMapping("/akun/{idAkun}/notification")
    public Map<String, Object> updateNotification(
            @PathVariable Integer idAkun,
            @RequestBody Map<String, Object> request) {

        Map<String, Object> response = new HashMap<>();

        Optional<Akun> optAkun = akunRepository.findById(idAkun);
        if (optAkun.isEmpty()) {
            response.put("status", "fail");
            response.put("message", "Akun tidak ditemukan");
            return response;
        }

        Akun akun = optAkun.get();

        if (request.containsKey("statusNotif")) {
            Boolean active = (Boolean) request.get("statusNotif");
            akun.setStatusNotif(active ? Akun.StatusNotif.y : Akun.StatusNotif.n);
        }

        if (request.containsKey("waktuNotif")) {
            Number waktu = (Number) request.get("waktuNotif");
            akun.setWaktuNotif(waktu != null ? waktu.intValue() : null);
        }

        akunRepository.save(akun);

        response.put("status", "success");
        return response;
    }
}
