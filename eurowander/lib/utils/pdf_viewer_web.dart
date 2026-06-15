import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

/// Web implementation: registers an iframe platform view for PDF display.
void registerPdfViewFactory(String viewType, String url) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'fullscreen';
      return iframe;
    },
  );
}

Widget buildPdfView(String viewType) {
  return HtmlElementView(viewType: viewType);
}
