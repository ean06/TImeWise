package com.timewise.backend.controller;

import com.timewise.backend.dto.LoginRequest;
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
    public Map<String, String> login(@RequestBody LoginRequest request) {

        Akun akun = akunRepository.findByUsernameAndPassword(
                request.getUsername(),
                request.getPassword()
        );

        Map<String, String> response = new HashMap<>();

        if (akun != null) {
            response.put("status", "success");
        } else {
            response.put("status", "fail");
        }

        return response;
    }
}