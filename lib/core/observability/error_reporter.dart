import 'package:flutter/foundation.dart';

/// Central sink for uncaught errors.
///
/// Today this logs to the console. Wire a real crash reporter here before a
/// public launch (the app currently has zero crash visibility):
///   1. add `sentry_flutter` (or `firebase_crashlytics`) to pubspec,
///   2. initialize it in `main()` with a DSN from `--dart-define`,
///   3. forward the calls below to `Sentry.captureException(...)`.
/// Keeping every call site behind this class means that's a one-file change.
abstract final class ErrorReporter {
  static void recordError(Object error, StackTrace? stack) {
    debugPrint('[ErrorReporter] $error');
    if (stack != null) {
      debugPrintStack(stackTrace: stack);
    }
    // TODO(observability): Sentry.captureException(error, stackTrace: stack);
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    debugPrint('[ErrorReporter] Flutter error: ${details.exceptionAsString()}');
    // TODO(observability): Sentry.captureException(
    //   details.exception, stackTrace: details.stack);
  }
}
