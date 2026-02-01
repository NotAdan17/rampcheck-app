class Job {
  final int? id;
  final String aircraftReg;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Job({
    this.id,
    required this.aircraftReg,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Job copyWith({
    int? id,
    String? aircraftReg,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      aircraftReg: aircraftReg ?? this.aircraftReg,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'aircraftReg': aircraftReg,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Job.fromMap(Map<String, dynamic> map) => Job(
        id: map['id'] as int?,
        aircraftReg: map['aircraftReg'] as String,
        status: map['status'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
