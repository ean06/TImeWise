package com.timewise.backend.controller;

import com.timewise.backend.dto.KategoriRequest;
import com.timewise.backend.entity.Akun;
import com.timewise.backend.entity.Kategori;
import com.timewise.backend.repository.AkunRepository;
import com.timewise.backend.repository.KategoriRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@CrossOrigin("*")
public class KategoriController {

    @Autowired
    private KategoriRepository kategoriRepository;

    @Autowired
    private AkunRepository akunRepository;

    @GetMapping("/kategori/{idAkun}")
    public List<Map<String, Object>> getKategori(@PathVariable Integer idAkun) {
        return kategoriRepository.findByAkunIdAkun(idAkun)
                .stream().map(this::toMap).collect(Collectors.toList());
    }

    @PostMapping("/kategori")
    public Map<String, Object> tambahKategori(@RequestBody KategoriRequest request) {
        Map<String, Object> response = new HashMap<>();

        Akun akun = akunRepository.findById(request.getIdAkun()).orElse(null);
        if (akun == null) {
            response.put("status", "akun_not_found");
            return response;
        }

        Kategori k = new Kategori();
        k.setAkun(akun);
        k.setNama(request.getNama());
        k.setWarna(request.getWarna() != null ? request.getWarna() : "#6C63FF");
        kategoriRepository.save(k);

        response.put("status", "success");
        return response;
    }

    @PutMapping("/kategori/{idKategori}")
    public Map<String, Object> editKategori(
            @PathVariable Integer idKategori,
            @RequestBody KategoriRequest request) {

        Map<String, Object> response = new HashMap<>();

        Kategori k = kategoriRepository.findById(idKategori).orElse(null);
        if (k == null) {
            response.put("status", "not_found");
            return response;
        }

        if (request.getNama()  != null) k.setNama(request.getNama());
        if (request.getWarna() != null) k.setWarna(request.getWarna());
        kategoriRepository.save(k);

        response.put("status", "success");
        return response;
    }

    @DeleteMapping("/kategori/{idKategori}")
    public Map<String, Object> hapusKategori(@PathVariable Integer idKategori) {
        Map<String, Object> response = new HashMap<>();

        if (!kategoriRepository.existsById(idKategori)) {
            response.put("status", "not_found");
            return response;
        }

        kategoriRepository.deleteById(idKategori);
        response.put("status", "success");
        return response;
    }

    private Map<String, Object> toMap(Kategori k) {
        Map<String, Object> m = new HashMap<>();
        m.put("id_kategori", k.getIdKategori());
        m.put("nama", k.getNama());
        m.put("warna", k.getWarna());
        return m;
    }
}