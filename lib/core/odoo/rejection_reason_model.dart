class RejectionReason {
  final int id;
  final String name;
  final bool needNote;

  RejectionReason({
    required this.id,
    required this.name,
    required this.needNote,
  });

  factory RejectionReason.fromJson(Map<String, dynamic> json) {
    return RejectionReason(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      needNote: json['need_note'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'need_note': needNote,
  };
}
