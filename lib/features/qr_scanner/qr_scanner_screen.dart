import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.isEmpty) return;

    setState(() => _busy = true);

    try {
      // QR kodla eşleşen kayıt var mı?
      final response = await Supabase.instance.client
          .from('qr_codes')
          .select('place_id, scan_count')
          .eq('qr_data', code)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        _showSnack(I18n.t('qr.notRegistered'), isError: true);
        // Birkaç saniye bekleyip tekrar tarayabilsin
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _busy = false);
        return;
      }

      final placeId = response['place_id'] as String?;
      if (placeId == null) {
        _showSnack(I18n.t('qr.broken'), isError: true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _busy = false);
        return;
      }

      // Tarama sayısını artır (best-effort, hata olsa devam et)
      final currentCount = (response['scan_count'] as int?) ?? 0;
      Supabase.instance.client
          .from('qr_codes')
          .update({'scan_count': currentCount + 1})
          .eq('qr_data', code)
          .then((_) {}, onError: (_) {});

      // Detaya git
      if (mounted) {
        _showSnack(I18n.t('qr.foundOpening'), isError: false);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/place/$placeId');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('${I18n.t('auth.genericError')}: $e', isError: true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(I18n.t('qr.title')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.amber);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.white);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_photography,
                          size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        I18n.t('qr.cameraError'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.message ??
                            I18n.t('qr.cameraHint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Tarama çerçevesi
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.accentOrange,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          // Alt bilgi metni
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      I18n.t('qr.hint'),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_busy)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      I18n.t('qr.processing'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
