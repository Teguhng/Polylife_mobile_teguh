class Pengumuman {
  final int id;
  final String title;
  final String? body;
  final String excerpt;
  final String? imageUrl;
  final String targetMode;
  final String publishedAt;
  final Map<String, dynamic>? creator;

  Pengumuman({
    required this.id,
    required this.title,
    this.body,
    required this.excerpt,
    this.imageUrl,
    required this.targetMode,
    required this.publishedAt,
    this.creator,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    final rawCreator = json['creator'];
    final parsedTitle = (json['title'] ?? '').toString().trim();
    final parsedTargetMode = (json['target_mode'] ?? '').toString().trim();

    return Pengumuman(
      id: _toInt(json['id']),
      title: parsedTitle.isEmpty ? 'Tanpa Judul' : parsedTitle,
      body: _toNullableString(json['body']),
      excerpt: _toNullableString(json['excerpt']) ?? '',
      imageUrl: _toNullableString(json['image_url']),
      targetMode: parsedTargetMode.isEmpty ? 'global' : parsedTargetMode,
      publishedAt: _toNullableString(json['published_at']) ?? '',
      creator: rawCreator is Map ? Map<String, dynamic>.from(rawCreator) : null,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse((value ?? '').toString()) ?? 0;
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  final parsed = value.toString().trim();
  return parsed.isEmpty ? null : parsed;
}
