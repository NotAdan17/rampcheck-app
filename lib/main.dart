import 'package:flutter/material.dart';
import 'screens/job_list_screen.dart';

void main() {
  runApp(const RampCheckApp());
}

class RampCheckApp extends StatelessWidget {
  const RampCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: JobListScreen(),
    );
  }
}
