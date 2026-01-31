import 'package:flutter/material.dart';
import '../data/local_db.dart';
import '../models/job.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List<Job> jobs = [];

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

    await LocalDb.insertJob(job.toMap());
    await _loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: jobs.isEmpty
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addTestJob,
        child: const Icon(Icons.add),
      ),
    );
  }
}
