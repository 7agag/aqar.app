class AiMessageEntity {
  final String id;
  final String text;
  final bool isUser;
  final List<Map<String, dynamic>>? properties;

  const AiMessageEntity({
    required this.id,
    required this.text,
    required this.isUser,
    this.properties,
  });

  factory AiMessageEntity.fromJson(Map<String, dynamic> json) {
    return AiMessageEntity(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      text: json['text']?.toString() ?? json['content']?.toString() ?? '',
      isUser: json['isUser'] == true || json['role'] == 'user',
      properties: (json['properties'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        if (properties != null) 'properties': properties,
      };
}
