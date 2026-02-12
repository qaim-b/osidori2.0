/// Controls who can see a transaction.
/// personal = only the creator. shared = all group members.
/// This is EXPLICIT — never implicit or hidden.
enum VisibilityType {
  personal,
  shared;

  String get label {
    switch (this) {
      case VisibilityType.personal:
        return 'Personal';
      case VisibilityType.shared:
        return 'Shared';
    }
  }

  String get icon {
    switch (this) {
      case VisibilityType.personal:
        return '🔒';
      case VisibilityType.shared:
        return '👥';
    }
  }

  static VisibilityType fromString(String value) {
    return VisibilityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VisibilityType.personal,
    );
  }
}
