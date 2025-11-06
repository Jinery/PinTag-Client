enum ContentType {
  link,
  photo,
  document,
  video,
  unknown;

  factory ContentType.fromString(String value) {
    return ContentType.values.firstWhere(
          (type) => type.name == value.toLowerCase(),
      orElse: () => ContentType.unknown,
    );
  }
}

extension ContentTypeExtension on ContentType {
  String get displayName {
    return switch (this) {
      ContentType.link => 'Ссылка',
      ContentType.photo => 'Фотография',
      ContentType.document => 'Документ',
      ContentType.video => 'Видео',
      ContentType.unknown => 'Неизвестный тип',
    };
  }
}