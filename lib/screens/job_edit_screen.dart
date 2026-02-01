import 'package:flutter/material.dart';
import '../models/job.dart';

class JobEditScreen extends StatefulWidget {
  final Job job;

  const JobEditScreen({super.key, required this.job});

  @override
  State<JobEditScreen> createState() => _JobEditScreenState();
}

class _JobEditScreenState extends State<JobEditScreen> {
  late final TextEditingController _regCtrl;
  String _status = 'OPEN';

  @override
  void initState() {
    super.initState();
    _regCtrl = TextEditingController(text: widget.job.aircraftReg);
    _status = widget.job.status;
  }

  @override
  void dispose() {
    _regCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final reg = _regCtrl.text.trim().toUpperCase();
    if (reg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aircraft reg cannot be empty')),
      );
      return;
    }

    final updated = widget.job.copyWith(
      aircraftReg: reg,
      status: _status,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Job'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aircraft Registration'),
            const SizedBox(height: 6),
            TextField(
              controller: _regCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. G-ABCD',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Status'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'OPEN', child: Text('OPEN')),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN_PROGRESS')),
                DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'OPEN'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: tap Save to write changes locally first. Sync later when online.',
            ),
          ],
        ),
      ),
    );
  }
}
