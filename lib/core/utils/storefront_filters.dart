import '../../models/product.dart';

class StorefrontFilters {
  StorefrontFilters._();

  static bool showProduct(Product product) {
    return product.isActive &&
        ((product.sellingPrice > 0) || (product.mrp > 0));
  }

  static bool showExclusiveProduct(ExclusiveProduct product) {
    return product.isActive &&
        ((product.sellingPrice > 0) || (product.mrp > 0));
  }

  static List<String> careInstructionsForProduct(Product product) {
    if (product.careInstructions.isNotEmpty) {
      return product.careInstructions;
    }

    return const [
      'Handle with dry hands and avoid sudden temperature changes.',
      'Use a soft sponge for cleaning and avoid harsh scrubbers.',
      'Let the piece dry fully before storing it away.',
    ];
  }

  static List<String> careInstructionsForExclusive(ExclusiveProduct product) {
    if (product.careInstructions.isNotEmpty) {
      return product.careInstructions;
    }

    return const [
      'Wipe gently with a soft cloth to preserve the finish.',
      'Display indoors away from extreme heat, moisture, and direct impact.',
      'Clean carefully by hand and avoid abrasive cleaning agents.',
    ];
  }
}
