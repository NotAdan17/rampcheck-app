class Job {
  final int? id;
  final String aircraftReg;
  final String status;
  final DateTime createdAt;

  Job({
    this.id,
    required this.aircraftReg,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'aircraftReg': aircraftReg,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Job.fromMap(Map<String, dynamic> map) => Job(
        id: map['id'] as int?,
        aircraftReg: map['aircraftReg'] as String,
        status: map['status'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
