import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChecklistPage extends StatefulWidget {
  final Map<String, dynamic> tugas;

  const ChecklistPage({super.key, required this.tugas});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  late Map<String, dynamic> _tugas;
  List<Map<String, dynamic>> _checklists = [];
  bool _isLoading = false;
  final TextEditingController _checklistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tugas = Map<String, dynamic>.from(widget.tugas);
    _fetchChecklist();
  }

  @override
  void dispose() {
    _checklistController.dispose();
    super.dispose();
  }

  int get _idTugas => _tugas['idTugas'] ?? 0;

  Future<void> _fetchChecklist() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getChecklist(_idTugas);
    setState(() {
      _checklists = data;
      _isLoading = false;
    });
  }

  Future<void> _refreshTugas() async {
    final updated = await ApiService.getTugasById(_idTugas);
    if (updated != null) {
      setState(() => _tugas = updated);
    }
  }

  // ── Tambah checklist ──────────────────────────────────────────────────
  Future<void> _tambahChecklist() async {
    final isi = _checklistController.text.trim();
    if (isi.isEmpty) return;
    _checklistController.clear();

    final result = await ApiService.tambahChecklist(_idTugas, isi);
    if (result != null) {
      await _fetchChecklist();
      await _refreshTugas();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambahkan checklist'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Toggle selesai checklist ────────────────────────────────────────
  Future<void> _toggleChecklist(Map<String, dynamic> item) async {
    final currentSelesai = item['selesai'] ?? 'n';
    final newSelesai = currentSelesai == 'y' ? 'n' : 'y';

    final result =
        await ApiService.updateChecklist(item['idChecklist'], newSelesai);
    if (result != null) {
      await _fetchChecklist();
      await _refreshTugas();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui checklist'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Edit isi checklist ───────────────────────────────────────────────
  void _editChecklist(Map<String, dynamic> item) {
    final editController =
        TextEditingController(text: item['isi'] ?? '');
    String? formError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Edit Checklist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: TextField(
                  controller: editController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Isi checklist',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon:
                        Icon(Icons.edit_note, color: Colors.grey[400], size: 18),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Pesan error inline (tidak akan tertutup modal) ──
              if (formError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    setModal(() => formError = null);

                    final newIsi = editController.text.trim();
                    if (newIsi.isEmpty) {
                      setModal(() =>
                          formError = 'Isi checklist tidak boleh kosong');
                      return;
                    }
                    final result = await ApiService.updateChecklistIsi(
                        item['idChecklist'], newIsi);
                    if (!ctx.mounted) return;
                    if (result != null) {
                      Navigator.pop(ctx);
                      await _fetchChecklist();
                    } else {
                      setModal(() => formError = 'Gagal mengubah checklist');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EAD65),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text('Simpan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hapus checklist ──────────────────────────────────────────────────
  Future<void> _deleteChecklist(int idChecklist) async {
    final success = await ApiService.deleteChecklist(idChecklist);
    if (success) {
      await _fetchChecklist();
      await _refreshTugas();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus checklist'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Color _priorityColor(String p) {
    switch (_capitalize(p)) {
      case 'Tinggi':
        return const Color(0xFFE91E63);
      case 'Sedang':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF2EAD65);
    }
  }

  @override
  Widget build(BuildContext context) {
    final judul = _tugas['judul'] ?? '';
    final prioritas =
        _capitalize((_tugas['prioritas'] ?? 'sedang').toString());
    final deadline = (_tugas['deadline'] ?? '').toString();
    final persen = (_tugas['persentaseSelesai'] ?? 0) as num;
    final done = _checklists.where((c) => c['selesai'] == 'y').length;
    final total = _checklists.length;
    final color = _priorityColor(prioritas);

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
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white),
                    ),
                    Expanded(
                      child: Text(judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _fetchChecklist();
                        await _refreshTugas();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.refresh,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // ── Info tugas: prioritas + deadline ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(prioritas,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (deadline.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.flag_outlined,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                          deadline.length >= 10
                              ? deadline.substring(0, 10)
                              : deadline,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Progress bar persentase checklist ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progress Checklist',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text('$done/$total selesai (${persen.toInt()}%)',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: persen / 100.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── List checklist ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF2EAD65)))
                      : _checklists.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.checklist_rounded,
                                      size: 56, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('Belum ada checklist',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('Tambahkan sub-tugas di bawah',
                                      style: TextStyle(
                                          color: Colors.grey[350],
                                          fontSize: 12)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: _checklists.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  _buildChecklistItem(_checklists[i], color),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: TextField(
                  controller: _checklistController,
                  decoration: InputDecoration(
                    hintText: 'Tambah item checklist...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.add_task_rounded,
                        size: 18, color: Color(0xFF2EAD65)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _tambahChecklist(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _tambahChecklist,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2EAD65),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item, Color accentColor) {
    final isi = item['isi'] ?? '';
    final isSelesai = item['selesai'] == 'y';
    final idChecklist = item['idChecklist'] ?? 0;
    final tglSelesai = (item['tglSelesai'] ?? '').toString();

    return Dismissible(
      key: Key('checklist_$idChecklist'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('Hapus Checklist',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                content: Text('Hapus "$isi" dari daftar checklist?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Hapus',
                        style: TextStyle(color: Color(0xFFE91E63))),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _deleteChecklist(idChecklist),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 0),
        decoration: BoxDecoration(
          color: const Color(0xFFE91E63).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline,
            color: Color(0xFFE91E63), size: 20),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelesai
              ? const Color(0xFF2EAD65).withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelesai
                ? const Color(0xFF2EAD65).withValues(alpha: 0.3)
                : const Color(0xFFEEEEEE),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleChecklist(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelesai ? const Color(0xFF2EAD65) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelesai
                        ? const Color(0xFF2EAD65)
                        : Colors.grey.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isSelesai
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isi,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelesai ? Colors.grey : Colors.black87,
                        decoration:
                            isSelesai ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.grey,
                      )),
                  if (isSelesai && tglSelesai.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                          'Selesai: ${tglSelesai.length >= 10 ? tglSelesai.substring(0, 10) : tglSelesai}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editChecklist(item),
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: Colors.black38),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}