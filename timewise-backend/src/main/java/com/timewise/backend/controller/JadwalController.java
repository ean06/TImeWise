package com.timewise.backend.controller;

import com.timewise.backend.dto.TambahJadwalRequest;
import com.timewise.backend.entity.Jadwal;
import com.timewise.backend.repository.JadwalRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@CrossOrigin("*")
public class JadwalController {

    @Autowired
    private JadwalRepository jadwalRepository;

    @PostMapping("/tambah-jadwal")
    public Map<String, String> tambahJadwal(
            @RequestBody TambahJadwalRequest request
    ) {

        Jadwal jadwal = new Jadwal();

        jadwal.setNamaJadwal(request.getNamaJadwal());
        jadwal.setTanggal(request.getTanggal());
        jadwal.setWaktu(request.getWaktu());
        jadwal.setPrioritas(request.getPrioritas());
        jadwal.setDeadline(request.getDeadline());
        jadwal.setIdAkun(request.getIdAkun());

        jadwalRepository.save(jadwal);

        Map<String, String> response = new HashMap<>();

        response.put("status", "success");

        return response;
    }
}