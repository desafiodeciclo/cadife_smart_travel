extension DateTimeExtensions on DateTime {
  String toDateString() => '$day/${month.toString().padLeft(2, '0')}/$year';

  String toTimeString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String toDateTimeString() => '$toDateString() $toTimeString()';
}

extension DateTimeNullableExtensions on DateTime? {
  String toDateStringOrEmpty() => this?.toDateString() ?? '';

  String toTimeStringOrEmpty() => this?.toTimeString() ?? '';
}