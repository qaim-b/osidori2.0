/// Whether an account belongs to an individual or is shared by the group.
enum OwnerScope {
  personal,
  shared;

  String get label {
    switch (this) {
      case OwnerScope.personal:
        return 'Personal';
      case OwnerScope.shared:
        return 'Shared';
    }
  }

  static OwnerScope fromString(String value) {
    return OwnerScope.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OwnerScope.personal,
    );
  }
}
