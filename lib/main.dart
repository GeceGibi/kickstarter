import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/runner/repos/repos.dart';
import 'features/runner/screens/screens.dart';
import 'features/runner/services/services.dart';

/// Application entry point supporting both GUI mode and `--install` CLI flag.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.contains('--install')) {
    final baseDir = PathsRepo.resolveBaseDir();
    final msg = await LaunchAgentService(baseDir: baseDir).install();
    stdout.writeln(msg);
    exit(0);
  }
  runApp(const ProviderScope(child: KickstarterApp()));
}

/// Root application widget.
final class KickstarterApp extends StatelessWidget {
  const KickstarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kickstarter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: .dark,
        colorSchemeSeed: const Color(0xFF38BDF8),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const RunnerScreen(),
    );
  }
}
