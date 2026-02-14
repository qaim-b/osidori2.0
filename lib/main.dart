import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/local_prefs.dart';
import 'data/datasources/supabase_client.dart';
import 'presentation/providers/appearance_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/group_provider.dart';
import 'presentation/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    setUrlStrategy(HashUrlStrategy());
  }

  // Initialize Supabase
  await AppSupabase.initialize();

  runApp(const ProviderScope(child: OsidoriApp()));
}

class OsidoriApp extends ConsumerStatefulWidget {
  const OsidoriApp({super.key});

  @override
  ConsumerState<OsidoriApp> createState() => _OsidoriAppState();
}

class _OsidoriAppState extends ConsumerState<OsidoriApp> {
  String? _hydratedUserId;

  Future<void> _hydrateSavedPreferences(String userId) async {
    if (_hydratedUserId == userId) return;
    _hydratedUserId = userId;

    final presetName = await LocalPrefs.getString(
      LocalPrefs.themePresetKey(userId),
    );
    if (!mounted) return;
    if (presetName != null) {
      AppThemePreset? preset;
      for (final candidate in AppThemePreset.values) {
        if (candidate.name == presetName) {
          preset = candidate;
          break;
        }
      }
      if (preset != null) {
        ref.read(themePresetProvider.notifier).state = preset;
      }
    }

    final activeGroupId = await LocalPrefs.getString(
      LocalPrefs.activeGroupKey(userId),
    );
    if (!mounted) return;
    ref.read(activeGroupIdStateProvider.notifier).state = activeGroupId;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      final userId = next.valueOrNull?.id;
      if (userId == null) {
        _hydratedUserId = null;
        ref.read(activeGroupIdStateProvider.notifier).state = null;
        return;
      }
      _hydrateSavedPreferences(userId);
    });

    ref.listen<AppThemePreset>(themePresetProvider, (_, next) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      LocalPrefs.setString(LocalPrefs.themePresetKey(userId), next.name);
    });

    ref.listen<String?>(activeGroupIdStateProvider, (_, next) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      if (next == null) {
        LocalPrefs.remove(LocalPrefs.activeGroupKey(userId));
        return;
      }
      LocalPrefs.setString(LocalPrefs.activeGroupKey(userId), next);
    });

    final router = ref.watch(appRouterProvider);
    final preset = ref.watch(activeThemePresetDataProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(preset),
      routerConfig: router,
    );
  }
}
