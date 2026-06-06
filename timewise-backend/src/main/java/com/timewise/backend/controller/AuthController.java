package com.timewise.backend.controller;

import com.timewise.backend.dto.LoginRequest;
import com.timewise.backend.dto.RegisterRequest;
import com.timewise.backend.entity.Akun;
import com.timewise.backend.repository.AkunRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@CrossOrigin("*")
public class AuthController {

    @Autowired
    private AkunRepository akunRepository;

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody LoginRequest request) {
        Akun akun = akunRepository.findByUsernameAndPassword(
                request.getUsername(),
                request.getPassword()
        );

        Map<String, Object> response = new HashMap<>();

        if (akun != null) {
            response.put("status", "success");
            response.put("id_akun", akun.getIdAkun());
            response.put("username", akun.getUsername());
        } else {
            response.put("status", "fail");
        }

        return response;
    }

    @PostMapping("/register")
    public Map<String, Object> register(@RequestBody RegisterRequest request) {
        Map<String, Object> response = new HashMap<>();

        Akun existing = akunRepository.findByUsername(request.getUsername());
        if (existing != null) {
            response.put("status", "username_taken");
            return response;
        }

        Akun akun = new Akun();
        akun.setUsername(request.getUsername());
        akun.setPassword(request.getPassword());
        akunRepository.save(akun);

        response.put("status", "registered");
        return response;
    }
}
