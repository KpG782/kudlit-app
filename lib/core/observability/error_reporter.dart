import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Central sink for uncaught errors.
///
/// Forwards to Sentry when a DSN was provided at build time
/// (`--dart-define=SENTRY_DSN=...`, wired in `main()`); otherwise Sentry is
/// uninitialized and `Sentry.captureException` is a safe no-op, so the app
/// still runs without a DSN. Always logs to the console as a breadcrumb.
abstract final class ErrorReporter {
  static void recordError(Object error, StackTrace? stack) {
    debugPrint('[ErrorReporter] $error');
    if (stack != null) {
      debugPrintStack(stackTrace: stack);
    }
    // No-op when Sentry was never initialized (no DSN).
    Sentry.captureException(error, stackTrace: stack);
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    debugPrint('[ErrorReporter] Flutter error: ${details.exceptionAsString()}');
    Sentry.captureException(details.exception, stackTrace: details.stack);
  }
}
