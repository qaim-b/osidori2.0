enum RecurrenceFrequency {
  weekly,
  monthly,
  yearly;

  static RecurrenceFrequency fromString(String value) {
    return RecurrenceFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => RecurrenceFrequency.monthly,
    );
  }
}
