extension DateTimeExt on DateTime {
  DateTime startOfDay() {
    return isUtc ? DateTime.utc(year, month, day) : DateTime(year, month, day);
  }

  DateTime startOfHour() {
    return isUtc
        ? DateTime.utc(year, month, day, hour)
        : DateTime(year, month, day, hour);
  }
}
