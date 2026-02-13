import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/datasources/supabase_client.dart';
import 'presentation/providers/appearance_provider.dart';
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

class OsidoriApp extends ConsumerWidget {
  const OsidoriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
