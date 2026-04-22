extension StringExtensions on String {
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get sentenceCase {
    if (isEmpty) return this;
    return replaceAll(RegExp(r'[_-]'), ' ').capitalized;
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(r'^\+?[\d\s()-]{10,}$').hasMatch(this);
  }
}