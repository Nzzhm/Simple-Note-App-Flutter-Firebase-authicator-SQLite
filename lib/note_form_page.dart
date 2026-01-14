import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'note.dart';
import 'note_db.dart';

class NoteFormPage extends StatefulWidget {
  final Note? note;
  const NoteFormPage({super.key, this.note});

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _contentC = TextEditingController();
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleC.text = widget.note!.title;
      _contentC.text = widget.note!.content;
      _deadline = widget.note!.deadline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadlineText = _deadline == null
        ? 'Tanpa deadline'
        : DateFormat('dd MMM yyyy').format(_deadline!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Tambah Note' : 'Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleC,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Judul wajib' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentC,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Isi',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Isi wajib' : null,
              ),
              const SizedBox(height: 16),
              Text('Deadline: $deadlineText'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: _deadline ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _deadline = picked);
                        }
                      },
                      child: const Text('Pilih Deadline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _deadline = null);
                      },
                      child: const Text('Hapus Deadline'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final data = {
                    'title': _titleC.text,
                    'content': _contentC.text,
                    'deadline': _deadline?.millisecondsSinceEpoch,
                    'createdAt':
                        widget.note?.createdAt.millisecondsSinceEpoch ??
                        DateTime.now().millisecondsSinceEpoch,
                  };

                  if (widget.note == null) {
                    await NoteDb.instance.insert(data);
                  } else {
                    await NoteDb.instance.update(widget.note!.id, data);
                  }

                  if (mounted) Navigator.pop(context, true);
                },
                child: Text(widget.note == null ? 'Simpan' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
