import 'dart:convert';

import 'package:flutter/material.dart';
import '../data/local_db.dart';
import '../data/sync_service.dart';
import '../models/job.dart';
import 'job_edit_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List<Job> jobs = [];
  bool syncing = false;

  int queuedCount = 0;
  DateTime? lastSyncAt;
  int? lastSyncDurationMs;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await _loadJobs();
    await _loadQueueCount();
  }

  Future<void> _loadJobs() async {
    final data = await LocalDb.getJobs();
    setState(() {
      jobs = data.map((e) => Job.fromMap(e)).toList();
    });
  }

  Future<void> _loadQueueCount() async {
    final c = await LocalDb.getSyncQueueCount();
    setState(() => queuedCount = c);
  }

  Future<void> _createJob() async {
    final job = Job(
      aircraftReg: 'G-TEST',
      status: 'OPEN',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final newId = await LocalDb.insertJob(job.toMap());

    // Queue CREATE with proper JSON payload
    await LocalDb.enqueueSyncItem(
      entityType: 'job',
      entityId: newId,
      action: 'CREATE',
      payload: jsonEncode(job.copyWith(id: newId).toMap()),
    );

    await _refreshAll();
  }

  Future<void> _editJob(Job job) async {
    final updated = await Navigator.push<Job?>(
      context,
      MaterialPageRoute(builder: (_) => JobEditScreen(job: job)),
    );

    if (updated == null || updated.id == null) return;

    await LocalDb.updateJob(updated.id!, updated.toMap());

    await LocalDb.enqueueSyncItem(
      entityType: 'job',
      entityId: updated.id!,
      action: 'UPDATE',
      payload: jsonEncode(updated.toMap()),
    );

    await _refreshAll();
  }

  Future<void> _deleteJob(Job job) async {
    if (job.id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text('Delete ${job.aircraftReg}? This will queue a DELETE for sync.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok != true) return;

    await LocalDb.deleteJob(job.id!);

    await LocalDb.enqueueSyncItem(
      entityType: 'job',
      entityId: job.id!,
      action: 'DELETE',
      payload: jsonEncode({'id': job.id}),
    );

    await _refreshAll();
  }

  Future<void> _syncNow() async {
    setState(() => syncing = true);

    final result = await SyncService.syncNow();

    if (!mounted) return;

    setState(() {
      syncing = false;
      if (result.ok) {
        lastSyncAt = DateTime.now();
        lastSyncDurationMs = result.durationMs;
      }
    });

    await _loadQueueCount();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.message} (${result.durationMs} ms)')),
    );
  }

  Widget _statusCard() {
    final last = lastSyncAt == null ? '—' : lastSyncAt!.toLocal().toString();
    final dur = lastSyncDurationMs == null ? '—' : '${lastSyncDurationMs}ms';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.cloud_sync),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Queued changes: $queuedCount'),
                  Text('Last sync: $last'),
                  Text('Last sync duration: $dur'),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: syncing ? null : _syncNow,
              icon: syncing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              label: Text(syncing ? 'Syncing' : 'Sync'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs — RampCheck'),
        actions: [
          IconButton(
            onPressed: syncing ? null : _refreshAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _statusCard(),
          const SizedBox(height: 8),
          Expanded(
            child: jobs.isEmpty
                ? const Center(child: Text('No jobs yet'))
                : ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return ListTile(
                        leading: const Icon(Icons.airplanemode_active),
                        title: Text(job.aircraftReg),
                        subtitle: Text('Status: ${job.status}'),
                        onTap: () => _editJob(job),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteJob(job),
                          tooltip: 'Delete',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createJob,
        child: const Icon(Icons.add),
      ),
    );
  }
}
