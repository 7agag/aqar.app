class AiResponseEntity {
  final String reply;
  final List<Map<String, dynamic>> properties;

  const AiResponseEntity({
    required this.reply,
    this.properties = const [],
  });

  factory AiResponseEntity.fromJson(Map<String, dynamic> json) {
    return AiResponseEntity(
      reply: json['answer'] as String? ?? '',
      properties: (json['properties'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
