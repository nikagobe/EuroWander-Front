import 'package:flutter/widgets.dart';

/// Stub implementation for non-web platforms.
/// On mobile, PDF viewing would need a WebView package.
void registerPdfViewFactory(String viewType, String url) {
  // No-op on non-web platforms
}

Widget buildPdfView(String viewType) {
  return const Center(
    child: Text('PDF viewing is not supported on this platform'),
  );
}
