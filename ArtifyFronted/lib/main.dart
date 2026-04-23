import 'package:client/core/theme/theme.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/view/pages/login_page.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:client/features/home/view/pages/home_page.dart';
import 'package:client/features/home/view/widgets/space_background.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
  }

  await Hive.initFlutter();
  await Hive.openBox('recent_songs');
  await Hive.openBox('recent_artists');
  await Hive.openBox('recent_albums');
  await Hive.openBox('playback_queue');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    // FIX: rimosso Image.asset('assets/images/app_icon.png') che era un
    // side-effect nel build — creava un widget mai inserito nel tree.
    // Se l'intento era precaricare l'immagine, usa precacheImage in didChangeDependencies.

    return MaterialApp(
      title: 'Artify',
      theme: AppTheme.darkThemeMode,
      home: authState.when(
        loading: () => const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: Loader()),
        ),
        error: (_, __) => const LoginPage(),
        data: (user) => user == null ? const LoginPage() : const HomePage(),
      ),
      builder: (context, child) {
        return SpaceShell(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
