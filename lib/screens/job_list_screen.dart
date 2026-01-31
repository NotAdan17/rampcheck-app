import 'package:flutter/material.dart';
import '../data/local_db.dart';
import '../data/sync_service.dart';
import '../models/job.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List<Job> jobs = [];
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final data = await LocalDb.getJobs();
    setState(() {
      jobs = data.map((e) => Job.fromMap(e)).toList();
    });
  }

  Future<void> _addTestJob() async {
    final job = Job(
      aircraftReg: 'G-TEST',
      status: 'OPEN',
      createdAt: DateTime.now(),
    );

    final newId = await LocalDb.insertJob(job.toMap());

    await LocalDb.enqueueSyncItem(
      entityType: 'job',
      entityId: newId,
      action: 'CREATE',
      payload: job.toMap().toString(),
    );

    await _loadJobs();
  }

  Future<void> _syncNow() async {
    setState(() => syncing = true);

    final result = await SyncService.syncNow();

    if (!mounted) return;
    setState(() => syncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs — SYNC READY ✅'),
        actions: [
          IconButton(
            onPressed: syncing ? null : _syncNow,
            icon: syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sync now',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: syncing ? null : _syncNow,
                icon: const Icon(Icons.sync),
                label: Text(syncing ? 'Syncing...' : 'Sync Now'),
              ),
            ),
          ),
          const Divider(height: 1),
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTestJob,
        child: const Icon(Icons.add),
      ),
    );
  }
}
