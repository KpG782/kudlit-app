import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/app/app.dart';
import 'package:kudlit_ph/core/config/supabase_config.dart';
import 'package:kudlit_ph/core/observability/error_reporter.dart';
import 'package:kudlit_ph/features/translator/data/datasources/flutter_gemma_bootstrap.dart';

Future<void> main() async {
  // Run the whole app inside a guarded zone so uncaught async errors are
  // captured instead of silently dropped.
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Route Flutter framework + platform errors to the reporter.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        ErrorReporter.recordFlutterError(details);
      };
      ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        ErrorReporter.recordError(error, stack);
        return true;
      };
      // Branded fallback instead of the raw red error screen in release.
      ErrorWidget.builder = (FlutterErrorDetails details) =>
          const _AppErrorFallback();

      await dotenv.load();
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      // NOTE: the Hugging Face token is intentionally no longer bundled in the
      // client. Gated model downloads must use a server-minted signed URL or a
      // public bucket. Passing null keeps non-gated/public models working.
      await initializeFlutterGemma();

      runApp(const ProviderScope(child: KudlitApp()));
    },
    (Object error, StackTrace stack) {
      ErrorReporter.recordError(error, stack);
    },
  );
}

class _AppErrorFallback extends StatelessWidget {
  const _AppErrorFallback();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFF0E1425),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Something went wrong. Please restart Kudlit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
