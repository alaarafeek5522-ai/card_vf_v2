class OfferModel {
  final String id;
  final String title;
  final String message;
  final String imageUrl;
  final String whatsapp;
  final String telegram;
  final bool active;
  final DateTime? createdAt;

  OfferModel({
    required this.id,
    required this.title,
    required this.message,
    required this.imageUrl,
    required this.whatsapp,
    required this.telegram,
    this.active = true,
    this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['image_url'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      telegram: json['telegram'] ?? '',
      active: json['active'] == true,
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'image_url': imageUrl,
    'whatsapp': whatsapp,
    'telegram': telegram,
    'active': active,
    'created_at': createdAt?.toIso8601String(),
  };
}
