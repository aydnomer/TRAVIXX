import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/qr_service.dart';

/// `/qr/:code` — telefon kamerasıyla okutulan QR linkinin açtığı sayfa.
/// Kodu mekana çözer ve mekan detayına yönlendirir.
class QrOpenScreen extends StatefulWidget {
  final String code;
  const QrOpenScreen({super.key, required this.code});

  @override
  State<QrOpenScreen> createState() => _QrOpenScreenState();
}

class _QrOpenScreenState extends State<QrOpenScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    String? placeId;
    try {
      placeId = await QrService.resolvePlaceId(widget.code);
    } catch (_) {}
    if (!mounted) return;
    if (placeId != null) {
      context.go('/place/$placeId');
    } else {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(I18n.t('qr.title'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _failed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      I18n.t('qr.notRegistered'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/qr-scan'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(I18n.t('qr.title')),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(I18n.t('qr.processing')),
                  ],
                ),
        ),
      ),
    );
  }
}
