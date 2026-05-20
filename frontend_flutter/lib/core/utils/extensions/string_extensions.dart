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
    final digits = replaceAll(RegExp(r'\D'), '');
    // Brazilian phones: 10 digits (landline) or 11 digits (mobile with 9th digit)
    if (digits.length < 10 || digits.length > 11) return false;
    return RegExp(r'^\d{10,11}$').hasMatch(digits);
  }
}
