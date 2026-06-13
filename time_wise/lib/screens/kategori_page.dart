import 'package:flutter/material.dart';
import 'package:time_wise/services/session_service.dart';
import 'package:time_wise/services/api_service.dart';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  int _idAkun = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _kategoriList = [];

  // Daftar warna pilihan untuk picker
  final List<String> _warnaOptions = const [
    '#6C63FF',
    '#2EAD65',
    '#FF9800',
    '#E91E63',
    '#2196F3',
    '#9C27B0',
    '#00BCD4',
    '#FFC107',
    '#795548',
    '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _idAkun = await SessionService.getIdAkun();
    await _fetchKategori();
  }

  Future<void> _fetchKategori() async {
    if (_idAkun == 0) return;
    setState(() => _isLoading = true);

    final data = await ApiService.getKategori(_idAkun);

    if (mounted) {
      setState(() {
        _kategoriList = data;
        _isLoading = false;
      });
    }
  }

  Color _hexToColor(String hex) {
    String h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  int _idKategori(Map<String, dynamic> item) {
    final raw = item['id_kategori'] ?? item['idKategori'] ?? 0;
    return raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
  }

  // ── Tambah / Edit Dialog ───────────────────────────────────────────
  void _showFormDialog({Map<String, dynamic>? existing}) {
    final localContext = context;

    final namaController =
        TextEditingController(text: existing?['nama']?.toString() ?? '');

    String selectedWarna = existing?['warna']?.toString() ?? _warnaOptions.first;

    // Jika warna existing tidak ada di list, tambahkan agar tetap muncul
    final List<String> warnaOptions = List.from(_warnaOptions);
    if (!warnaOptions.contains(selectedWarna)) {
      warnaOptions.insert(0, selectedWarna);
    }

    final isEdit = existing != null;

    showModalBottomSheet(
      context: localContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isEdit ? 'Edit Kategori' : 'Tambah Kategori',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Nama ──
                const Text(
                  'Nama Kategori',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInput(
                  controller: namaController,
                  hint: 'Contoh: Kuliah, Pribadi, Olahraga',
                  icon: Icons.label_outline,
                ),

                const SizedBox(height: 20),

                // ── Pilih Warna ──
                const Text(
                  'Pilih Warna',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: warnaOptions.map((hex) {
                    final color = _hexToColor(hex);
                    final isSelected = selectedWarna == hex;
                    return GestureDetector(
                      onTap: () => setModal(() => selectedWarna = hex),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.black87
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // ── Tombol Simpan ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nama = namaController.text.trim();

                      if (nama.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nama kategori tidak boleh kosong'),
                            backgroundColor: Color(0xFFE91E63),
                          ),
                        );
                        return;
                      }

                      final body = {
                        'idAkun': _idAkun,
                        'nama': nama,
                        'warna': selectedWarna,
                      };

                      bool success;
                      if (isEdit) {
                        success = await ApiService.updateKategori(
                          _idKategori(existing!),
                          body,
                        );
                      } else {
                        success = await ApiService.tambahKategori(body);
                      }

                      if (!context.mounted) return;
                      Navigator.pop(context);

                      if (success) {
                        _fetchKategori();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit
                                ? 'Kategori berhasil diperbarui'
                                : 'Kategori berhasil ditambahkan'),
                            backgroundColor: const Color(0xFF2EAD65),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal menyimpan kategori'),
                            backgroundColor: Color(0xFFE91E63),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EAD65),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? 'Simpan Perubahan' : 'Tambah Kategori',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hapus Kategori ──────────────────────────────────────────────────
  Future<void> _deleteKategori(int idKategori, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus kategori "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Color(0xFFE91E63)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.hapusKategori(idKategori);

    if (!mounted) return;

    if (success) {
      _fetchKategori();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus'),
          backgroundColor: Color(0xFF2EAD65),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus kategori'),
          backgroundColor: Color(0xFFE91E63),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: const Text(
          'Kategori',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2EAD65),
        onRefresh: _fetchKategori,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2EAD65),
                  strokeWidth: 2.5,
                ),
              )
            : _kategoriList.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.label_off_outlined,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada kategori',
                              style: TextStyle(
                                  color: Colors.black38, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tekan tombol + untuk menambahkan',
                              style: TextStyle(
                                  color: Colors.black26, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: _kategoriList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = _kategoriList[i];
                      final nama = (item['nama'] ?? '').toString();
                      final warna = (item['warna'] ?? '#6C63FF').toString();
                      final color = _hexToColor(warna);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: color.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _showFormDialog(existing: item),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: Colors.black38),
                            ),
                            IconButton(
                              onPressed: () => _deleteKategori(
                                  _idKategori(item), nama),
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFF2EAD65),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}