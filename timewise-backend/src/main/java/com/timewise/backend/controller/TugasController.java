package com.timewise.backend.controller;

import com.timewise.backend.entity.*;
import com.timewise.backend.repository.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/tugas")
@RequiredArgsConstructor
public class TugasController {

    private final TugasRepository tugasRepo;
    private final ChecklistRepository checklistRepo;
    private final AkunRepository akunRepo;
    private final KategoriRepository kategoriRepo;


    @GetMapping
    public ResponseEntity<List<TugasResponse>> getAll(@RequestParam Integer idAkun) {
        return ResponseEntity.ok(
            tugasRepo.findByAkunIdAkun(idAkun)
                .stream().map(this::toResponse).collect(Collectors.toList())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<TugasResponse> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(toResponse(tugasRepo.findById(id).orElseThrow()));
    }

    @PostMapping
    public ResponseEntity<TugasResponse> create(
            @RequestParam Integer idAkun,
            @RequestBody TugasRequest req) {

        Akun akun = akunRepo.findById(idAkun).orElseThrow();
        Tugas t = new Tugas();
        t.setAkun(akun);
        if (req.getIdKategori() != null)
            t.setKategori(kategoriRepo.findById(req.getIdKategori()).orElse(null));
        t.setJudul(req.getJudul());
        t.setDeskripsi(req.getDeskripsi());
        t.setTanggalMulai(req.getTanggalMulai());
        t.setDeadline(req.getDeadline());
        t.setPrioritas(Tugas.Prioritas.valueOf(req.getPrioritas()));
        if (req.getPersentaseSelesai() != null) t.setPersentaseSelesai(req.getPersentaseSelesai());
        return ResponseEntity.ok(toResponse(tugasRepo.save(t)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<TugasResponse> update(
            @PathVariable Integer id,
            @RequestBody TugasRequest req) {

        Tugas t = tugasRepo.findById(id).orElseThrow();
        if (req.getJudul()             != null) t.setJudul(req.getJudul());
        if (req.getDeskripsi()         != null) t.setDeskripsi(req.getDeskripsi());
        if (req.getTanggalMulai()      != null) t.setTanggalMulai(req.getTanggalMulai());
        if (req.getDeadline()          != null) t.setDeadline(req.getDeadline());
        if (req.getPrioritas()         != null) t.setPrioritas(Tugas.Prioritas.valueOf(req.getPrioritas()));
        if (req.getStatus()            != null) t.setStatus(Tugas.Status.valueOf(req.getStatus()));
        if (req.getPersentaseSelesai() != null) t.setPersentaseSelesai(req.getPersentaseSelesai());
        if (req.getIdKategori()        != null)
            t.setKategori(kategoriRepo.findById(req.getIdKategori()).orElse(null));
        return ResponseEntity.ok(toResponse(tugasRepo.save(t)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        tugasRepo.deleteById(id);
        return ResponseEntity.noContent().build();
    }


    @GetMapping("/{idTugas}/checklist")
    public ResponseEntity<List<ChecklistResponse>> getChecklist(@PathVariable Integer idTugas) {
        return ResponseEntity.ok(
            checklistRepo.findByTugasIdTugas(idTugas)
                .stream().map(this::toChecklistResponse).collect(Collectors.toList())
        );
    }

    @PostMapping("/{idTugas}/checklist")
    public ResponseEntity<ChecklistResponse> addChecklist(
            @PathVariable Integer idTugas,
            @RequestBody ChecklistRequest req) {

        Tugas tugas = tugasRepo.findById(idTugas).orElseThrow();
        Checklist c = new Checklist();
        c.setTugas(tugas);
        c.setIsi(req.getIsi());
        return ResponseEntity.ok(toChecklistResponse(checklistRepo.save(c)));
    }

    @PutMapping("/checklist/{idChecklist}")
    public ResponseEntity<ChecklistResponse> updateChecklist(
            @PathVariable Integer idChecklist,
            @RequestBody ChecklistUpdateRequest req) {

        Checklist c = checklistRepo.findById(idChecklist).orElseThrow();
        Checklist.Selesai selesai = Checklist.Selesai.valueOf(req.getSelesai());
        c.setSelesai(selesai);

        LocalDateTime now = LocalDateTime.now();
        c.setWaktuSelesai(selesai == Checklist.Selesai.y ? now : null);
        c.setTglSelesai(selesai == Checklist.Selesai.y ? now.toLocalDate() : null);

        Tugas tugas = c.getTugas();
        List<Checklist> all = checklistRepo.findByTugasIdTugas(tugas.getIdTugas());
        checklistRepo.save(c); 
        long total = all.size();
        long done  = all.stream()
                .filter(item -> item.getIdChecklist().equals(c.getIdChecklist())
                        ? selesai == Checklist.Selesai.y
                        : item.getSelesai() == Checklist.Selesai.y)
                .count();
        if (total > 0) {
            tugas.setPersentaseSelesai((int) Math.round((done * 100.0) / total));
            tugasRepo.save(tugas);
        }

        return ResponseEntity.ok(toChecklistResponse(c));
    }

    @PutMapping("/checklist/{idChecklist}/isi")
    public ResponseEntity<ChecklistResponse> updateChecklistIsi(
            @PathVariable Integer idChecklist,
            @RequestBody ChecklistRequest req) {

        Checklist c = checklistRepo.findById(idChecklist).orElseThrow();
        c.setIsi(req.getIsi());
        return ResponseEntity.ok(toChecklistResponse(checklistRepo.save(c)));
    }

    @DeleteMapping("/checklist/{idChecklist}")
    public ResponseEntity<Void> deleteChecklist(@PathVariable Integer idChecklist) {
        checklistRepo.deleteById(idChecklist);
        return ResponseEntity.noContent().build();
    }


    private TugasResponse toResponse(Tugas t) {
        TugasResponse r = new TugasResponse();
        r.setIdTugas(t.getIdTugas());
        r.setJudul(t.getJudul());
        r.setDeskripsi(t.getDeskripsi());
        r.setTanggalMulai(t.getTanggalMulai());
        r.setDeadline(t.getDeadline());
        r.setPrioritas(t.getPrioritas().name());
        r.setStatus(t.getStatus().name());
        r.setPersentaseSelesai(t.getPersentaseSelesai());
        if (t.getKategori() != null) {
            r.setIdKategori(t.getKategori().getIdKategori());
            r.setNamaKategori(t.getKategori().getNama());
            r.setWarnaKategori(t.getKategori().getWarna());
        }
        return r;
    }

    private ChecklistResponse toChecklistResponse(Checklist c) {
        ChecklistResponse r = new ChecklistResponse();
        r.setIdChecklist(c.getIdChecklist());
        r.setIsi(c.getIsi());
        r.setSelesai(c.getSelesai().name());
        r.setWaktuSelesai(c.getWaktuSelesai() != null ? c.getWaktuSelesai().toString() : null);
        r.setTglSelesai(c.getTglSelesai() != null ? c.getTglSelesai().toString() : null);
        return r;
    }


    @Data static class TugasRequest {
        private Integer idKategori;
        private String judul, deskripsi, prioritas, status;
        private LocalDate tanggalMulai, deadline;
        private Integer persentaseSelesai;
    }

    @Data static class TugasResponse {
        private Integer idTugas;
        private String judul, deskripsi, prioritas, status;
        private LocalDate tanggalMulai, deadline;
        private Integer persentaseSelesai;
        private Integer idKategori;
        private String namaKategori, warnaKategori;
    }

    @Data static class ChecklistRequest  { private String isi; }
    @Data static class ChecklistUpdateRequest { private String selesai; }

    @Data static class ChecklistResponse {
        private Integer idChecklist;
        private String isi, selesai, waktuSelesai, tglSelesai;
    }
}