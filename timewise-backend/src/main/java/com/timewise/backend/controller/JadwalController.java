package com.timewise.backend.controller;

import com.timewise.backend.dto.TambahJadwalRequest;
import com.timewise.backend.entity.Jadwal;
import com.timewise.backend.repository.JadwalRepository;
import com.timewise.backend.repository.LaporanRepository;
import com.timewise.backend.repository.NotifikasiRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@CrossOrigin("*")
public class JadwalController {

    @Autowired private JadwalRepository jadwalRepository;
    @Autowired private LaporanRepository laporanRepository;
    @Autowired private NotifikasiRepository notifikasiRepository;

    @PostMapping("/tambah-jadwal")
    public Map<String, Object> tambahJadwal(@RequestBody TambahJadwalRequest request) {
        Map<String, Object> response = new HashMap<>();

        List<Jadwal> existing = jadwalRepository.findByIdAkunOrderByTanggalAscWaktuAsc(request.getIdAkun());

        for (Jadwal j : existing) {
            if (j.getTanggal() == null || request.getTanggal() == null) continue;
            if (!j.getTanggal().equals(request.getTanggal())) continue;
            if (j.getWaktu() == null || request.getWaktu() == null) continue;

            long selisihMenit = Math.abs(
                j.getWaktu().toSecondOfDay() - request.getWaktu().toSecondOfDay()
            ) / 60;

            if (selisihMenit < 60) {
                int existingPrio = prioritasToInt(j.getPrioritas());
                int newPrio      = prioritasToInt(request.getPrioritas());

                if (newPrio < existingPrio) {
                    response.put("status", "conflict");
                    response.put("message",
                        "Jadwal bertabrakan dengan '" + j.getNamaJadwal() +
                        "' (prioritas lebih tinggi). Jadwal tidak disimpan.");
                    return response;
                } else if (newPrio > existingPrio) {
                    response.put("displaced", j.getNamaJadwal());
                    hapusJadwalDanRelasinya(j.getIdJadwal());
                }
            }
        }

        Jadwal jadwal = new Jadwal();
        jadwal.setNamaJadwal(request.getNamaJadwal());
        jadwal.setTanggal(request.getTanggal());
        jadwal.setWaktu(request.getWaktu());
        jadwal.setPrioritas(request.getPrioritas());
        jadwal.setDeadline(request.getDeadline());
        jadwal.setIdAkun(request.getIdAkun());
        jadwalRepository.save(jadwal);

        response.put("status", "success");
        return response;
    }

    @GetMapping("/jadwal/{idAkun}")
    public List<Map<String, Object>> getJadwalByUser(@PathVariable Integer idAkun) {
        return jadwalRepository
                .findByIdAkunOrderByTanggalAscWaktuAsc(idAkun)
                .stream()
                .map(this::toMap)
                .collect(Collectors.toList());
    }

    @PutMapping("/jadwal/{idJadwal}")
    public Map<String, String> editJadwal(
            @PathVariable Integer idJadwal,
            @RequestBody TambahJadwalRequest request) {

        Map<String, String> response = new HashMap<>();
        Optional<Jadwal> opt = jadwalRepository.findById(idJadwal);

        if (opt.isEmpty()) {
            response.put("status", "not_found");
            return response;
        }

        Jadwal jadwal = opt.get();
        jadwal.setNamaJadwal(request.getNamaJadwal());
        jadwal.setTanggal(request.getTanggal());
        jadwal.setWaktu(request.getWaktu());
        jadwal.setPrioritas(request.getPrioritas());
        jadwal.setDeadline(request.getDeadline());
        jadwalRepository.save(jadwal);

        response.put("status", "success");
        return response;
    }

    @DeleteMapping("/jadwal/{idJadwal}")
    public Map<String, String> hapusJadwal(@PathVariable Integer idJadwal) {
        Map<String, String> response = new HashMap<>();

        if (!jadwalRepository.existsById(idJadwal)) {
            response.put("status", "not_found");
            return response;
        }

        hapusJadwalDanRelasinya(idJadwal);
        response.put("status", "success");
        return response;
    }

    @GetMapping("/laporan/{idAkun}")
    public Map<String, Object> getLaporan(@PathVariable Integer idAkun) {
        List<Jadwal> semua = jadwalRepository.findAllByIdAkun(idAkun);
        LocalDate today = LocalDate.now();

        LocalDate startMinggu = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        String[] namaHari = {"Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"};
        List<Map<String, Object>> harian = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            LocalDate hari = startMinggu.plusDays(i);
            long jumlah = semua.stream()
                    .filter(j -> hari.equals(j.getTanggal()))
                    .count();
            Map<String, Object> m = new HashMap<>();
            m.put("label", namaHari[i]);
            m.put("tanggal", hari.toString());
            m.put("jumlah", jumlah);
            harian.add(m);
        }

        LocalDate startBulan = today.withDayOfMonth(1);
        LocalDate endBulan   = today.with(TemporalAdjusters.lastDayOfMonth());
        WeekFields wf = WeekFields.of(DayOfWeek.MONDAY, 1);
        int mingguAwal  = startBulan.get(wf.weekOfMonth());
        int mingguAkhir = endBulan.get(wf.weekOfMonth());

        List<Map<String, Object>> mingguan = new ArrayList<>();
        for (int w = mingguAwal; w <= mingguAkhir; w++) {
            final int mgg = w;
            long jumlah = semua.stream()
                    .filter(j -> j.getTanggal() != null
                            && j.getTanggal().getMonth() == today.getMonth()
                            && j.getTanggal().getYear() == today.getYear()
                            && j.getTanggal().get(wf.weekOfMonth()) == mgg)
                    .count();
            Map<String, Object> m = new HashMap<>();
            m.put("label", "Mgg " + w);
            m.put("jumlah", jumlah);
            mingguan.add(m);
        }

        Map<Integer, Long> perJam = semua.stream()
                .filter(j -> j.getWaktu() != null)
                .collect(Collectors.groupingBy(
                        j -> j.getWaktu().getHour(),
                        Collectors.counting()
                ));

        List<Map<String, Object>> jamSibuk = perJam.entrySet().stream()
                .sorted(Map.Entry.<Integer, Long>comparingByValue().reversed())
                .limit(5)
                .map(e -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("jam", String.format("%02d:00", e.getKey()));
                    m.put("jumlah", e.getValue());
                    return m;
                })
                .collect(Collectors.toList());

        Map<String, Object> result = new HashMap<>();
        result.put("harian", harian);
        result.put("mingguan", mingguan);
        result.put("jam_sibuk", jamSibuk);
        result.put("total_jadwal", semua.size());
        return result;
    }

    @GetMapping("/rekomendasi/{idAkun}")
    public Map<String, Object> getRekomendasi(@PathVariable Integer idAkun) {
        List<Jadwal> semua = jadwalRepository.findAllByIdAkun(idAkun);
        LocalDate today = LocalDate.now();

        int[][] slots = {{8, 11}, {13, 15}, {19, 21}};
        String[] labelSlot = {
            "Pagi (08:00 - 11:00)",
            "Siang (13:00 - 15:00)",
            "Malam (19:00 - 21:00)"
        };

        List<Map<String, Object>> rekomendasi = new ArrayList<>();

        for (int d = 0; d < 7 && rekomendasi.size() < 5; d++) {
            LocalDate tgl = today.plusDays(d);

            List<Integer> jamTerisi = semua.stream()
                    .filter(j -> tgl.equals(j.getTanggal()) && j.getWaktu() != null)
                    .map(j -> j.getWaktu().getHour())
                    .collect(Collectors.toList());

            for (int s = 0; s < slots.length && rekomendasi.size() < 5; s++) {
                int jamMulai = slots[s][0];
                int jamAkhir = slots[s][1];

                boolean adaTabrakan = jamTerisi.stream()
                        .anyMatch(h -> h >= jamMulai && h < jamAkhir);

                if (!adaTabrakan) {
                    Map<String, Object> r = new HashMap<>();
                    r.put("tanggal", tgl.toString());
                    r.put("slot", labelSlot[s]);
                    r.put("jam_mulai", String.format("%02d:00", jamMulai));
                    r.put("jam_selesai", String.format("%02d:00", jamAkhir));
                    rekomendasi.add(r);
                }
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("rekomendasi", rekomendasi);
        return response;
    }

    private void hapusJadwalDanRelasinya(Integer idJadwal) {
        laporanRepository.deleteAll(laporanRepository.findByIdJadwal(idJadwal));
        notifikasiRepository.deleteAll(notifikasiRepository.findByIdJadwal(idJadwal));
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
        m.put("id_jadwal",   j.getIdJadwal());
        m.put("nama_jadwal", j.getNamaJadwal());
        m.put("tanggal",     j.getTanggal()  != null ? j.getTanggal().toString()  : null);
        m.put("waktu",       j.getWaktu()    != null ? j.getWaktu().toString()    : null);
        m.put("prioritas",   j.getPrioritas());
        m.put("deadline",    j.getDeadline() != null ? j.getDeadline().toString() : null);
        m.put("id_akun",     j.getIdAkun());
        return m;
    }
}
