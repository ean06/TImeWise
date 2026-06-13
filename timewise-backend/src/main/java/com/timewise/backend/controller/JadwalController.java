package com.timewise.backend.controller;

import com.timewise.backend.dto.TambahJadwalRequest;
import com.timewise.backend.entity.Akun;
import com.timewise.backend.entity.Jadwal;
import com.timewise.backend.entity.Kategori;
import com.timewise.backend.repository.AkunRepository;
import com.timewise.backend.repository.JadwalRepository;
import com.timewise.backend.repository.KategoriRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@CrossOrigin("*")
public class JadwalController {

    @Autowired private JadwalRepository jadwalRepository;
    @Autowired private AkunRepository akunRepository;
    @Autowired private KategoriRepository kategoriRepository;

    @PostMapping("/tambah-jadwal")
    public Map<String, Object> tambahJadwal(@RequestBody TambahJadwalRequest request) {
        Map<String, Object> response = new HashMap<>();

        List<Jadwal> existing = jadwalRepository.findByAkunIdAkunOrderByTanggalAscWaktuMulaiAsc(request.getIdAkun());
        for (Jadwal j : existing) {
            if (j.getTanggal() == null || request.getTanggal() == null) continue;
            if (!j.getTanggal().equals(request.getTanggal())) continue;
            if (j.getWaktuMulai() == null || request.getWaktuMulai() == null) continue;

            long selisih = Math.abs(j.getWaktuMulai().toSecondOfDay() - request.getWaktuMulai().toSecondOfDay()) / 60;
            if (selisih < 60) {
                int existingPrio = prioritasToInt(j.getPrioritas().name());
                int newPrio      = prioritasToInt(request.getPrioritas());

                if (newPrio < existingPrio) {
                    response.put("status", "conflict");
                    response.put("message", "Jadwal bertabrakan dengan '" + j.getNamaJadwal() + "' (prioritas lebih tinggi).");
                    return response;
                } else if (newPrio > existingPrio) {
                    response.put("displaced", j.getNamaJadwal());
                    hapusJadwal(j.getIdJadwal());
                }
            }
        }

        Akun akun = akunRepository.findById(request.getIdAkun()).orElse(null);
        if (akun == null) { response.put("status", "akun_not_found"); return response; }

        Jadwal jadwal = buildJadwal(new Jadwal(), request);
        jadwal.setAkun(akun);
        jadwalRepository.save(jadwal);

        response.put("status", "success");
        return response;
    }

    @GetMapping("/jadwal/{idAkun}")
    public List<Map<String, Object>> getJadwal(@PathVariable Integer idAkun) {
        List<Jadwal> jadwalList = jadwalRepository.findByAkunIdAkunOrderByTanggalAscWaktuMulaiAsc(idAkun);
        autoMarkTerlewat(jadwalList);
        return jadwalList.stream().map(this::toMap).collect(Collectors.toList());
    }

    @PutMapping("/jadwal/{idJadwal}")
    public Map<String, Object> editJadwal(@PathVariable Integer idJadwal, @RequestBody TambahJadwalRequest request) {
        Map<String, Object> response = new HashMap<>();

        Jadwal jadwal = jadwalRepository.findById(idJadwal).orElse(null);
        if (jadwal == null) { response.put("status", "not_found"); return response; }

        jadwalRepository.save(buildJadwal(jadwal, request));
        response.put("status", "success");
        return response;
    }

    @DeleteMapping("/jadwal/{idJadwal}")
    public Map<String, Object> hapusJadwalEndpoint(@PathVariable Integer idJadwal) {
        Map<String, Object> response = new HashMap<>();

        if (!jadwalRepository.existsById(idJadwal)) { response.put("status", "not_found"); return response; }

        hapusJadwal(idJadwal);
        response.put("status", "success");
        return response;
    }

    @GetMapping("/laporan/{idAkun}")
    public Map<String, Object> getLaporan(@PathVariable Integer idAkun) {
        List<Jadwal> semua  = jadwalRepository.findAllByAkunIdAkun(idAkun);
        LocalDate today     = LocalDate.now();
        LocalDate startMgg  = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        String[] namaHari   = { "Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min" };

        List<Map<String, Object>> harian = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            LocalDate hari = startMgg.plusDays(i);
            harian.add(Map.of("label", namaHari[i], "tanggal", hari.toString(),
                    "jumlah", semua.stream().filter(j -> hari.equals(j.getTanggal())).count()));
        }

        WeekFields wf       = WeekFields.of(DayOfWeek.MONDAY, 1);
        LocalDate startBln  = today.withDayOfMonth(1);
        LocalDate endBln    = today.with(TemporalAdjusters.lastDayOfMonth());
        List<Map<String, Object>> mingguan = new ArrayList<>();
        for (int w = startBln.get(wf.weekOfMonth()); w <= endBln.get(wf.weekOfMonth()); w++) {
            final int mgg = w;
            long jumlah = semua.stream().filter(j -> j.getTanggal() != null
                    && j.getTanggal().getMonth() == today.getMonth()
                    && j.getTanggal().getYear()  == today.getYear()
                    && j.getTanggal().get(wf.weekOfMonth()) == mgg).count();
            mingguan.add(Map.of("label", "Mgg " + w, "jumlah", jumlah));
        }

        List<Map<String, Object>> jamSibuk = semua.stream()
                .filter(j -> j.getWaktuMulai() != null)
                .collect(Collectors.groupingBy(j -> j.getWaktuMulai().getHour(), Collectors.counting()))
                .entrySet().stream()
                .sorted(Map.Entry.<Integer, Long>comparingByValue().reversed()).limit(5)
                .map(e -> Map.<String, Object>of("jam", String.format("%02d:00", e.getKey()), "jumlah", e.getValue()))
                .collect(Collectors.toList());

        return Map.of("harian", harian, "mingguan", mingguan, "jam_sibuk", jamSibuk, "total_jadwal", semua.size());
    }

    @GetMapping("/rekomendasi/{idAkun}")
    public Map<String, Object> getRekomendasi(@PathVariable Integer idAkun) {
        List<Jadwal> semua  = jadwalRepository.findAllByAkunIdAkun(idAkun);
        LocalDate today     = LocalDate.now();
        int[][] slots       = { {8,11}, {13,15}, {19,21} };
        String[] labelSlot  = { "Pagi (08:00 - 11:00)", "Siang (13:00 - 15:00)", "Malam (19:00 - 21:00)" };

        List<Map<String, Object>> rekomendasi = new ArrayList<>();
        for (int d = 0; d < 7 && rekomendasi.size() < 5; d++) {
            LocalDate tgl = today.plusDays(d);
            List<Integer> jamTerisi = semua.stream()
                    .filter(j -> tgl.equals(j.getTanggal()) && j.getWaktuMulai() != null)
                    .map(j -> j.getWaktuMulai().getHour()).collect(Collectors.toList());

            for (int s = 0; s < slots.length && rekomendasi.size() < 5; s++) {
                final int mulai = slots[s][0], akhir = slots[s][1];
                if (jamTerisi.stream().noneMatch(h -> h >= mulai && h < akhir))
                    rekomendasi.add(Map.of("tanggal", tgl.toString(), "slot", labelSlot[s],
                            "jam_mulai", String.format("%02d:00", mulai),
                            "jam_selesai", String.format("%02d:00", akhir)));
            }
        }

        return Map.of("rekomendasi", rekomendasi);
    }

    // ── Auto-mark terlewat ────────────────────────────────
    private void autoMarkTerlewat(List<Jadwal> jadwalList) {
        LocalDateTime now = LocalDateTime.now();
        List<Jadwal> toUpdate = new ArrayList<>();

        for (Jadwal j : jadwalList) {
            // Hanya proses jadwal yang masih pending
            if (j.getStatus() != Jadwal.Status.pending) continue;
            // Timeless tidak punya waktu selesai, skip
            if (j.getTimeless() == Jadwal.Timeless.y) continue;
            // Harus punya tanggal & waktu_selesai
            if (j.getTanggal() == null || j.getWaktuSelesai() == null) continue;

            LocalDateTime waktuSelesaiDt = LocalDateTime.of(j.getTanggal(), j.getWaktuSelesai());
            if (now.isAfter(waktuSelesaiDt)) {
                j.setStatus(Jadwal.Status.terlewat);
                toUpdate.add(j);
            }
        }

        if (!toUpdate.isEmpty()) {
            jadwalRepository.saveAll(toUpdate);
        }
    }

    // ── Helper ────────────────────────────────────────────

    private Jadwal buildJadwal(Jadwal jadwal, TambahJadwalRequest req) {
        if (req.getNamaJadwal()   != null) jadwal.setNamaJadwal(req.getNamaJadwal());
        if (req.getTanggal()      != null) jadwal.setTanggal(req.getTanggal());
        if (req.getWaktuMulai()   != null) jadwal.setWaktuMulai(req.getWaktuMulai());
        if (req.getWaktuSelesai() != null) jadwal.setWaktuSelesai(req.getWaktuSelesai());
        if (req.getDeadline()     != null) jadwal.setDeadline(req.getDeadline());
        if (req.getCatatan()      != null) jadwal.setCatatan(req.getCatatan());
        if (req.getTimeless()     != null) jadwal.setTimeless(Jadwal.Timeless.valueOf(req.getTimeless()));
        if (req.getPrioritas()    != null) jadwal.setPrioritas(Jadwal.Prioritas.valueOf(req.getPrioritas()));
        if (req.getStatus() != null) jadwal.setStatus(Jadwal.Status.valueOf(req.getStatus()));
        if (req.getIdKategori()   != null)
            jadwal.setKategori(kategoriRepository.findById(req.getIdKategori()).orElse(null));
        return jadwal;
    }

    private void hapusJadwal(Integer idJadwal) {
        jadwalRepository.deleteById(idJadwal);
    }

    private int prioritasToInt(String p) {
        if (p == null) return 1;
        return switch (p.toLowerCase()) {
            case "tinggi" -> 3;
            case "sedang" -> 2;
            default       -> 1;
        };
    }

    private Map<String, Object> toMap(Jadwal j) {
        Map<String, Object> m = new HashMap<>();
        m.put("id_jadwal",    j.getIdJadwal());
        m.put("nama_jadwal",  j.getNamaJadwal());
        m.put("tanggal",      j.getTanggal() != null ? j.getTanggal().toString() : null);
        m.put("waktu_mulai",  j.getWaktuMulai() != null ? j.getWaktuMulai().toString() : null);
        m.put("waktu_selesai",j.getWaktuSelesai() != null ? j.getWaktuSelesai().toString() : null);
        m.put("timeless",     j.getTimeless() != null ? j.getTimeless().name() : null);
        m.put("prioritas",    j.getPrioritas() != null ? j.getPrioritas().name() : null);
        m.put("status",       j.getStatus() != null ? j.getStatus().name() : null);
        m.put("deadline",     j.getDeadline() != null ? j.getDeadline().toString() : null);
        m.put("catatan",      j.getCatatan());
        if (j.getKategori() != null) {
            m.put("id_kategori",   j.getKategori().getIdKategori());
            m.put("nama_kategori", j.getKategori().getNama());
            m.put("warna_kategori",j.getKategori().getWarna());
        }
        return m;
    }
}