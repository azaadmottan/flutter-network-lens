import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the native share sheet for FlutterNetworkLens-generated text.
final class FlutterNetworkLensShare {
  FlutterNetworkLensShare._();

  /// Shares [text] using the platform share sheet.
  static Future<void> text(
    BuildContext context,
    String text, {
    required String subject,
  }) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        title: subject,
        sharePositionOrigin: renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size,
      ),
    );
  }
}
