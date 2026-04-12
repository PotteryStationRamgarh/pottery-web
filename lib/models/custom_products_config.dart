class CustomProductsConfig {
  final String heroImageUrl;
  final String heroTitle;
  final String heroSubtitle;
  final List<String> glazeOptions;
  final List<String> productTypes;
  final String introText;
  final bool isEnabled;

  const CustomProductsConfig({
    required this.heroImageUrl,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.glazeOptions,
    required this.productTypes,
    required this.introText,
    required this.isEnabled,
  });

  factory CustomProductsConfig.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return CustomProductsConfig(
      heroImageUrl:
          data['heroImageUrl'] as String? ??
          'https://images.unsplash.com/photo-1565191999001-551c187427bb?q=80&w=1500&auto=format&fit=crop',
      heroTitle: data['heroTitle'] as String? ?? 'Bespoke Creations',
      heroSubtitle:
          data['heroSubtitle'] as String? ??
          'Design a custom ceramic piece in the Pottery Station aesthetic.',
      glazeOptions:
          (data['glazeOptions'] as List?)?.map((e) => e.toString()).toList() ??
          const [
            'Natural Matte',
            'Ash Glaze',
            'Gloss White',
            'Terracotta Wash',
            'Speckled Stone',
            'Satin Black',
          ],
      productTypes:
          (data['productTypes'] as List?)?.map((e) => e.toString()).toList() ??
          const ['Bowl', 'Vase', 'Mug', 'Plate', 'Decorative', 'Other'],
      introText:
          data['introText'] as String? ??
          'Shape a custom piece with your preferred form, glaze, and inspiration details.',
      isEnabled: data['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heroImageUrl': heroImageUrl,
      'heroTitle': heroTitle,
      'heroSubtitle': heroSubtitle,
      'glazeOptions': glazeOptions,
      'productTypes': productTypes,
      'introText': introText,
      'isEnabled': isEnabled,
    };
  }

  CustomProductsConfig copyWith({
    String? heroImageUrl,
    String? heroTitle,
    String? heroSubtitle,
    List<String>? glazeOptions,
    List<String>? productTypes,
    String? introText,
    bool? isEnabled,
  }) {
    return CustomProductsConfig(
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      heroTitle: heroTitle ?? this.heroTitle,
      heroSubtitle: heroSubtitle ?? this.heroSubtitle,
      glazeOptions: glazeOptions ?? this.glazeOptions,
      productTypes: productTypes ?? this.productTypes,
      introText: introText ?? this.introText,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
