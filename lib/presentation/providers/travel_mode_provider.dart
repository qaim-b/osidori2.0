import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/local_prefs.dart';
import 'auth_provider.dart';

class TravelModeState {
  final bool enabled;
  final String destination;
  final bool isLoading;

  const TravelModeState({
    required this.enabled,
    required this.destination,
    required this.isLoading,
  });

  factory TravelModeState.initial() {
    return const TravelModeState(
      enabled: false,
      destination: '',
      isLoading: true,
    );
  }

  TravelModeState copyWith({
    bool? enabled,
    String? destination,
    bool? isLoading,
  }) {
    return TravelModeState(
      enabled: enabled ?? this.enabled,
      destination: destination ?? this.destination,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final travelModeProvider =
    StateNotifierProvider<TravelModeNotifier, TravelModeState>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      return TravelModeNotifier(userId);
    });

class TravelModeNotifier extends StateNotifier<TravelModeState> {
  final String? _userId;

  TravelModeNotifier(this._userId) : super(TravelModeState.initial()) {
    _load();
  }

  Future<void> _load() async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final enabledRaw = await LocalPrefs.getString(
      LocalPrefs.travelModeEnabledKey(userId),
    );
    final destination = await LocalPrefs.getString(
      LocalPrefs.travelModeDestinationKey(userId),
    );
    final enabled = enabledRaw == 'true';
    state = state.copyWith(
      enabled: enabled,
      destination: destination ?? '',
      isLoading: false,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final userId = _userId;
    if (userId == null) return;
    await LocalPrefs.setString(
      LocalPrefs.travelModeEnabledKey(userId),
      enabled ? 'true' : 'false',
    );
  }

  Future<void> setDestination(String destination) async {
    state = state.copyWith(destination: destination);
    final userId = _userId;
    if (userId == null) return;
    if (destination.trim().isEmpty) {
      await LocalPrefs.remove(LocalPrefs.travelModeDestinationKey(userId));
      return;
    }
    await LocalPrefs.setString(
      LocalPrefs.travelModeDestinationKey(userId),
      destination.trim(),
    );
  }
}
