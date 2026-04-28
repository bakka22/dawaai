import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelpService {
  static const String _defaultPhone = '+249123456789';
  static const String _defaultMessage = 'Hello, I need help with my order';

  static String generateHelpLink({
    String? phoneNumber,
    String? message,
    int? orderId,
  }) {
    final phone = phoneNumber ?? _defaultPhone;
    final cleanPhone = phone.startsWith('+') ? phone : '+$phone';

    String fullMessage;
    if (orderId != null) {
      fullMessage = message ?? 'Order #$orderId Help Needed';
    } else {
      fullMessage = message ?? _defaultMessage;
    }

    final encodedMessage = Uri.encodeComponent(fullMessage);
    return 'https://wa.me/$cleanPhone?text=$encodedMessage';
  }

  static Future<bool> openWhatsApp({
    String? phoneNumber,
    String? message,
    int? orderId,
  }) async {
    final link = generateHelpLink(
      phoneNumber: phoneNumber,
      message: message,
      orderId: orderId,
    );

    final uri = Uri.parse(link);

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}

class FloatingHelpButton extends StatelessWidget {
  final int? orderId;
  final String? customMessage;

  const FloatingHelpButton({super.key, this.orderId, this.customMessage});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openHelp(context),
      backgroundColor: const Color(0xFF25D366),
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }

  Future<void> _openHelp(BuildContext context) async {
    final success = await WhatsAppHelpService.openWhatsApp(
      orderId: orderId,
      message: customMessage,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Please install WhatsApp.'),
        ),
      );
    }
  }
}

class HelpButtonProvider extends InheritedWidget {
  final int? currentOrderId;

  const HelpButtonProvider({
    super.key,
    this.currentOrderId,
    required super.child,
  });

  static int? of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<HelpButtonProvider>();
    return provider?.currentOrderId;
  }

  @override
  bool updateShouldNotify(HelpButtonProvider oldWidget) {
    return currentOrderId != oldWidget.currentOrderId;
  }
}
