import 'package:flutter/material.dart';

class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Belajar Flutter', 'done': false, 'priority': 'Tinggi'},
    {'title': 'Kerjakan Tugas Kuliah', 'done': false, 'priority': 'Sedang'},
  ];

  void _showAddTaskDialog({int? editIndex}) {
    final titleController = TextEditingController(
      text: editIndex != null ? _tasks[editIndex]['title'] : '',
    );
    String selectedPriority =
        editIndex != null ? _tasks[editIndex]['priority'] : 'Sedang';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editIndex != null ? 'Edit Tugas' : 'Tambah Tugas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Nama Tugas',
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Prioritas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Tinggi', 'Sedang', 'Rendah'].map((p) {
                  final isSelected = selectedPriority == p;
                  final color = p == 'Tinggi'
                      ? const Color(0xFFE91E63)
                      : p == 'Sedang'
                          ? const Color(0xFFFF9800)
                          : const Color(0xFF2EAD65);
                  return GestureDetector(
                    onTap: () =>
                        setModalState(() => selectedPriority = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? color : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      setState(() {
                        if (editIndex != null) {
                          _tasks[editIndex]['title'] = titleController.text;
                          _tasks[editIndex]['priority'] = selectedPriority;
                        } else {
                          _tasks.add({
                            'title': titleController.text,
                            'done': false,
                            'priority': selectedPriority,
                          });
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EAD65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
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
    final done = _tasks.where((t) => t['done'] == true).length;

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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tugas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$done/${_tasks.length} selesai',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _tasks.isEmpty ? 0 : done / _tasks.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),

              // List
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada tugas',
                            style: TextStyle(color: Colors.black38),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final task = _tasks[i];
                            final color = _priorityColor(task['priority']);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: task['done']
                                    ? const Color(0xFFF5F6FA)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEEEEEE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => task['done'] = !task['done']),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: task['done']
                                            ? const Color(0xFF2EAD65)
                                            : Colors.white,
                                        border: Border.all(
                                          color: task['done']
                                              ? const Color(0xFF2EAD65)
                                              : Colors.grey.shade300,
                                          width: 2,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: task['done']
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['title'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: task['done']
                                                ? Colors.black38
                                                : Colors.black87,
                                            decoration: task['done']
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            task['priority'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _showAddTaskDialog(editIndex: i),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.black38,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _tasks.removeAt(i)),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: const Color(0xFF2EAD65),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}