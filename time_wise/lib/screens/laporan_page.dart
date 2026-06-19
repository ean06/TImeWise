import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'jadwal_page.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Harian', 'Mingguan', 'Bulanan'];
  List<Map<String, dynamic>> _allJadwal = [];
  List<Map<String, dynamic>> _allTugas = [];
  bool _isLoading = false;
  bool _isExporting = false;
  int _idAkun = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _idAkun = await SessionService.getIdAkun();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final jadwal = await ApiService.getJadwal(_idAkun);
    final tugas = await ApiService.getTugas(_idAkun);
    setState(() {
      _allJadwal = jadwal;
      _allTugas = tugas;
      _isLoading = false;
    });
  }

  String _tanggalKey(Map<String, dynamic> item) {
    final raw = item['tanggal'] ?? '';
    final s = raw.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  List<Map<String, dynamic>> get _harianData {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      final key = date.toString().substring(0, 10);
      final count =
          _allJadwal.where((j) => _tanggalKey(j) == key).length;
      final dayNames = [
        'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'
      ];
      return {
        'label': dayNames[date.weekday % 7],
        'sublabel': '${date.day}/${date.month}',
        'count': count,
        'isToday': key == today.toString().substring(0, 10),
        'date': date,
      };
    });
  }

  List<Map<String, dynamic>> get _mingguanData {
    final today = DateTime.now();
    return List.generate(4, (i) {
      final weekStart = today
          .subtract(Duration(days: today.weekday - 1 + (3 - i) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final count = _allJadwal.where((j) {
        final key = _tanggalKey(j);
        if (key.isEmpty) return false;
        try {
          final d = DateTime.parse(key);
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        } catch (_) {
          return false;
        }
      }).length;
      return {
        'label': 'Mgg ${i + 1}',
        'sublabel': '${weekStart.day}/${weekStart.month}',
        'count': count,
        'isToday': false,
        'date': null,
      };
    });
  }

  List<Map<String, dynamic>> get _bulananData {
    final today = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return List.generate(6, (i) {
      final month =
          DateTime(today.year, today.month - (5 - i), 1);
      final count = _allJadwal.where((j) {
        final key = _tanggalKey(j);
        if (key.isEmpty) return false;
        try {
          final d = DateTime.parse(key);
          return d.year == month.year && d.month == month.month;
        } catch (_) {
          return false;
        }
      }).length;
      return {
        'label': monthNames[month.month - 1],
        'sublabel': '${month.year}',
        'count': count,
        'isToday':
            month.year == today.year && month.month == today.month,
        'date': null,
      };
    });
  }

  List<Map<String, dynamic>> get _currentData {
    switch (_selectedTab) {
      case 0:
        return _harianData;
      case 1:
        return _mingguanData;
      case 2:
        return _bulananData;
      default:
        return _harianData;
    }
  }

  int get _totalJadwal => _allJadwal.length;

  int get _maxCount {
    final counts =
        _currentData.map((e) => e['count'] as int).toList();
    if (counts.isEmpty) return 1;
    final max = counts.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 1 : max;
  }

  // Warna tema untuk PDF
  static final PdfColor _pdfPrimary = PdfColor.fromInt(0xFF2EAD65);
  static final PdfColor _pdfPrimaryLight = PdfColor.fromInt(0xFFE8F8EF);
  static final PdfColor _pdfGrey = PdfColor.fromInt(0xFF6B7280);
  static final PdfColor _pdfRed = PdfColor.fromInt(0xFFE5484D);
  static final PdfColor _pdfBorder = PdfColor.fromInt(0xFFE2E8F0);

  /// Menentukan status jadwal: Selesai, Terlewat, atau Mendatang.
  String _statusJadwal(Map<String, dynamic> item) {
    final rawStatus = (item['status'] ?? '').toString().toLowerCase();
    final isDoneFlag = item['is_done'] == true ||
        item['selesai'] == true ||
        rawStatus == 'selesai' ||
        rawStatus == 'done' ||
        rawStatus == 'completed';

    if (isDoneFlag) return 'Selesai';
    if (rawStatus == 'terlewat' || rawStatus == 'overdue') return 'Terlewat';

    try {
      final tanggalStr = _tanggalKey(item);
      if (tanggalStr.isEmpty) return 'Mendatang';

      DateTime? waktuJadwal;
      final jamSelesai = item['jam_selesai'] ?? item['jam_akhir'];
      final jamMulai = item['jam_mulai'] ?? item['jam'];
      final jamStr = (jamSelesai ?? jamMulai)?.toString();

      if (jamStr != null && jamStr.isNotEmpty) {
        waktuJadwal = DateTime.tryParse('${tanggalStr}T$jamStr');
      }
      waktuJadwal ??= DateTime.tryParse(tanggalStr);
      if (waktuJadwal == null) return 'Mendatang';

      return waktuJadwal.isBefore(DateTime.now()) ? 'Terlewat' : 'Mendatang';
    } catch (_) {
      return 'Mendatang';
    }
  }

  PdfColor _statusColor(String status) {
    switch (status) {
      case 'Selesai':
        return _pdfPrimary;
      case 'Terlewat':
      case 'Terlambat':
        return _pdfRed;
      default:
        return _pdfGrey;
    }
  }

  /// Label status tugas dari backend (pending/selesai/terlambat) -> tampilan
  String _statusTugasLabel(Map<String, dynamic> item) {
    final s = (item['status'] ?? 'pending').toString().toLowerCase();
    switch (s) {
      case 'selesai':
        return 'Selesai';
      case 'terlambat':
        return 'Terlambat';
      default:
        return 'Pending';
    }
  }

  String _prioritasLabel(Map<String, dynamic> item) {
    final p = (item['prioritas'] ?? 'sedang').toString();
    return p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase();
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final laporan = await ApiService.getLaporan(_idAkun);
      final username = await SessionService.getUsername();

      final currentData = _currentData;
      final totalPeriode =
          currentData.fold<int>(0, (s, e) => s + (e['count'] as int));
      final avg = currentData.isEmpty
          ? '0'
          : (totalPeriode / currentData.length).toStringAsFixed(1);

      final harian = (laporan['harian'] as List?) ?? [];
      final mingguan = (laporan['mingguan'] as List?) ?? [];
      final jamSibuk = (laporan['jam_sibuk'] as List?) ?? [];
      final totalJadwalServer = laporan['total_jadwal'] ?? _totalJadwal;

      // ── Hitung status per jadwal (selesai / terlewat / mendatang) ──
      final List<Map<String, dynamic>> daftarJadwal = _allJadwal
          .map((e) => {...e, '_status': _statusJadwal(e)})
          .toList();

      daftarJadwal.sort((a, b) => _tanggalKey(b).compareTo(_tanggalKey(a)));

      final totalJadwalCount = daftarJadwal.length;
      final jumlahSelesai =
          daftarJadwal.where((e) => e['_status'] == 'Selesai').length;
      final jumlahTerlewat =
          daftarJadwal.where((e) => e['_status'] == 'Terlewat').length;
      final jumlahMendatang =
          totalJadwalCount - jumlahSelesai - jumlahTerlewat;

      final persenSelesai = totalJadwalCount == 0
          ? 0.0
          : (jumlahSelesai / totalJadwalCount) * 100;
      final persenTerlewat = totalJadwalCount == 0
          ? 0.0
          : (jumlahTerlewat / totalJadwalCount) * 100;

      // ── Ringkasan Tugas ──
      final daftarTugas = List<Map<String, dynamic>>.from(_allTugas);
      daftarTugas.sort((a, b) =>
          (b['deadline'] ?? '').toString().compareTo((a['deadline'] ?? '').toString()));

      final totalTugas = daftarTugas.length;
      final tugasSelesai = daftarTugas
          .where((t) => (t['status'] ?? '') == 'selesai')
          .length;
      final tugasTerlambat = daftarTugas
          .where((t) => (t['status'] ?? '') == 'terlambat')
          .length;
      final tugasPending = totalTugas - tugasSelesai - tugasTerlambat;
      final persenTugasSelesai = totalTugas == 0
          ? 0.0
          : (tugasSelesai / totalTugas) * 100;

      final doc = pw.Document();
      final now = DateTime.now();
      final tanggalCetak =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      pw.Widget sectionTitle(String text) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6, top: 4),
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.75),
              ),
            ),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _pdfPrimary,
              ),
            ),
          );

      pw.Widget statTile(String label, String value, {PdfColor? color}) {
        return pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 3),
            padding:
                const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: _pdfPrimaryLight,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(value,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: color ?? _pdfPrimary,
                    )),
                pw.SizedBox(height: 2),
                pw.Text(label,
                    style: pw.TextStyle(fontSize: 8, color: _pdfGrey)),
              ],
            ),
          ),
        );
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) {
            if (context.pageNumber == 1) return pw.SizedBox();
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text('Laporan TimeWise',
                  style: pw.TextStyle(fontSize: 9, color: _pdfGrey)),
            );
          },
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _pdfGrey),
            ),
          ),
          build: (context) => [
            // ── Header utama ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan TimeWise',
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: _pdfPrimary)),
                    pw.SizedBox(height: 4),
                    pw.Text('Tab: ${_tabs[_selectedTab]}',
                        style: pw.TextStyle(fontSize: 10, color: _pdfGrey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Pengguna: $username',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text('Dicetak: $tanggalCetak',
                        style: pw.TextStyle(fontSize: 9, color: _pdfGrey)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // ── Ringkasan ──
            sectionTitle('Ringkasan'),
            pw.Row(
              children: [
                statTile('Total Jadwal', '$totalJadwalServer'),
                statTile('Selesai', '$jumlahSelesai', color: _pdfPrimary),
                statTile('Terlewat', '$jumlahTerlewat', color: _pdfRed),
                statTile('Mendatang', '$jumlahMendatang'),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                statTile('% Selesai', '${persenSelesai.toStringAsFixed(1)}%',
                    color: _pdfPrimary),
                statTile('% Terlewat',
                    '${persenTerlewat.toStringAsFixed(1)}%',
                    color: _pdfRed),
                statTile('Rata-rata (${_tabs[_selectedTab]})',
                    '$avg / periode'),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Ringkasan Tugas ──
            sectionTitle('Ringkasan Tugas'),
            pw.Row(
              children: [
                statTile('Total Tugas', '$totalTugas'),
                statTile('Selesai', '$tugasSelesai', color: _pdfPrimary),
                statTile('Terlambat', '$tugasTerlambat', color: _pdfRed),
                statTile('Pending', '$tugasPending'),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                statTile('% Tugas Selesai',
                    '${persenTugasSelesai.toStringAsFixed(1)}%',
                    color: _pdfPrimary),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Statistik periode ──
            sectionTitle('Statistik ${_tabs[_selectedTab]}'),
            pw.Table.fromTextArray(
              headers: ['Periode', 'Tanggal/Keterangan', 'Jumlah Jadwal'],
              data: currentData
                  .map((e) => [
                        e['label'].toString(),
                        e['sublabel'].toString(),
                        e['count'].toString(),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(color: _pdfBorder, width: 0.5),
              cellPadding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            ),
            pw.SizedBox(height: 16),

            // ── Daftar Jadwal & Tugas ──
            sectionTitle('Daftar Jadwal & Tugas (${daftarJadwal.length})'),
            if (daftarJadwal.isEmpty)
              pw.Text('Belum ada data jadwal.',
                  style: pw.TextStyle(fontSize: 10, color: _pdfGrey))
            else
              pw.Table(
                border: pw.TableBorder.all(color: _pdfBorder, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(1.4),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _pdfPrimary),
                    children: [
                      'Nama Jadwal/Tugas',
                      'Tanggal',
                      'Jam',
                      'Status',
                    ]
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 6),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.white)),
                            ))
                        .toList(),
                  ),
                  ...daftarJadwal.map((item) {
                    final nama = (item['nama'] ??
                            item['nama_jadwal'] ??
                            item['judul'] ??
                            item['title'] ??
                            item['kegiatan'] ??
                            '-')
                        .toString();
                    final tanggal = _tanggalKey(item);
                    final jam =
                        (item['jam_mulai'] ?? item['jam'] ?? '-').toString();
                    final status = item['_status'] as String;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(nama,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(tanggal,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(jam,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(
                            status,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 16),

            // ── Daftar Tugas ──
            sectionTitle('Daftar Tugas ($totalTugas)'),
            if (daftarTugas.isEmpty)
              pw.Text('Belum ada data tugas.',
                  style: pw.TextStyle(fontSize: 10, color: _pdfGrey))
            else
              pw.Table(
                border: pw.TableBorder.all(color: _pdfBorder, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.6),
                  1: pw.FlexColumnWidth(1.1),
                  2: pw.FlexColumnWidth(1.3),
                  3: pw.FlexColumnWidth(1.3),
                  4: pw.FlexColumnWidth(1.1),
                  5: pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _pdfPrimary),
                    children: [
                      'Judul Tugas',
                      'Prioritas',
                      'Mulai',
                      'Deadline',
                      'Progress',
                      'Status',
                    ]
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 6),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.white)),
                            ))
                        .toList(),
                  ),
                  ...daftarTugas.map((item) {
                    final judul = (item['judul'] ?? '-').toString();
                    final prioritas = _prioritasLabel(item);
                    final mulaiRaw = (item['tanggalMulai'] ?? '').toString();
                    final mulai =
                        mulaiRaw.length >= 10 ? mulaiRaw.substring(0, 10) : mulaiRaw;
                    final deadlineRaw = (item['deadline'] ?? '').toString();
                    final deadline = deadlineRaw.length >= 10
                        ? deadlineRaw.substring(0, 10)
                        : deadlineRaw;
                    final persen = (item['persentaseSelesai'] ?? 0);
                    final status = _statusTugasLabel(item);

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(judul,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(prioritas,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(mulai,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(deadline,
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text('$persen%',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _pdfPrimary)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 6),
                          child: pw.Text(
                            status,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 16),

            if (harian.isNotEmpty) ...[
              sectionTitle('Jadwal Harian (Minggu Ini)'),
              pw.Table.fromTextArray(
                headers: ['Hari', 'Tanggal', 'Jumlah'],
                data: harian
                    .map((e) => [
                          e['label'].toString(),
                          e['tanggal'].toString(),
                          e['jumlah'].toString(),
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(color: _pdfBorder, width: 0.5),
                cellPadding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              ),
              pw.SizedBox(height: 16),
            ],

            if (mingguan.isNotEmpty) ...[
              sectionTitle('Jadwal Mingguan (Bulan Ini)'),
              pw.Table.fromTextArray(
                headers: ['Minggu', 'Jumlah'],
                data: mingguan
                    .map((e) => [
                          e['label'].toString(),
                          e['jumlah'].toString(),
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(color: _pdfBorder, width: 0.5),
                cellPadding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              ),
              pw.SizedBox(height: 16),
            ],

            if (jamSibuk.isNotEmpty) ...[
              sectionTitle('Jam Tersibuk'),
              pw.Table.fromTextArray(
                headers: ['Jam', 'Jumlah Jadwal'],
                data: jamSibuk
                    .map((e) => [
                          e['jam'].toString(),
                          e['jumlah'].toString(),
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(color: _pdfBorder, width: 0.5),
                cellPadding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              ),
            ],
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'laporan_timewise_${now.millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _currentData;
    final total =
        currentData.fold<int>(0, (s, e) => s + (e['count'] as int));
    final avg = currentData.isEmpty
        ? '0'
        : (total / currentData.length).toStringAsFixed(1);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5EE09A), Color(0xFF2EAD65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Laporan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _isExporting ? null : _exportPdf,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: _isExporting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined,
                                    color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _fetchData,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.refresh,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Rangkuman Cards ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Jadwal',
                            '$_totalJadwal',
                            Icons.calendar_month_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Rata-rata',
                            '$avg / periode',
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Tugas',
                            '${_allTugas.length}',
                            Icons.task_alt_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Tugas Selesai',
                            '${_allTugas.where((t) => (t['status'] ?? '') == 'selesai').length}',
                            Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Chart Area ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children:
                              List.generate(_tabs.length, (i) {
                            final isActive = _selectedTab == i;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedTab = i),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(26),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _tabs[i],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: isActive
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Chart label ──
                      Row(
                        children: [
                          Text(
                            _selectedTab == 0
                                ? '7 Hari Terakhir'
                                : _selectedTab == 1
                                    ? '4 Minggu Terakhir'
                                    : '6 Bulan Terakhir',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                          if (_selectedTab == 0) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.touch_app_outlined,
                              size: 12,
                              color: Colors.black26,
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'Tap bar untuk lihat detail',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black26,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Bar Chart ──
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF2EAD65)))
                            : currentData.every(
                                    (e) => (e['count'] as int) == 0)
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            Icons
                                                .bar_chart_outlined,
                                            size: 52,
                                            color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Belum ada data jadwal',
                                          style: TextStyle(
                                              color: Colors.black38,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: currentData
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final item = entry.value;
                                      final date =
                                          item['date'] as DateTime?;

                                      return _buildBar(
                                        label: item['label'],
                                        sublabel: item['sublabel'],
                                        count: item['count'],
                                        isHighlight: item['isToday'],
                                        onTap: _selectedTab == 0 &&
                                                date != null
                                            ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        JadwalPage(
                                                      initialDate:
                                                          date,
                                                    ),
                                                  ),
                                                );
                                              }
                                            : null,
                                      );
                                    }).toList(),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required String sublabel,
    required int count,
    required bool isHighlight,
    VoidCallback? onTap,
  }) {
    const double maxBarHeight = 160;
    final double barHeight =
        count == 0 ? 8 : (count / _maxCount) * maxBarHeight;
    final bool tappable = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              count > 0 ? '$count' : '',
              key: ValueKey('$label$count'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isHighlight
                    ? const Color(0xFF2EAD65)
                    : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 4),

          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: 36,
            height: barHeight,
            decoration: BoxDecoration(
              gradient: isHighlight
                  ? const LinearGradient(
                      colors: [Color(0xFF5EE09A), Color(0xFF2EAD65)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : LinearGradient(
                      colors: [
                        const Color(0xFF2EAD65).withOpacity(0.25),
                        const Color(0xFF2EAD65).withOpacity(0.15),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: tappable
                  ? Border.all(
                      color: const Color(0xFF2EAD65).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isHighlight
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: isHighlight
                  ? const Color(0xFF2EAD65)
                  : Colors.black45,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
                fontSize: 9, color: Colors.black26),
          ),
        ],
      ),
    );
  }
}