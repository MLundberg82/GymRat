import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../data/open_food_facts_client.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _scanner;
  late final OpenFoodFactsClient _products;
  bool _lookingUp = false;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const <BarcodeFormat>[
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
    _products = OpenFoodFactsClient();
  }

  Future<void> _detected(BarcodeCapture capture) async {
    if (_lookingUp) return;
    String? code;
    for (final barcode in capture.barcodes) {
      final candidate = barcode.rawValue?.replaceAll(RegExp(r'\D'), '');
      if (candidate != null &&
          candidate.length >= 8 &&
          candidate.length <= 14) {
        code = candidate;
        break;
      }
    }
    if (code == null) return;
    setState(() {
      _lookingUp = true;
      _errorKey = null;
    });
    await _scanner.stop();
    if (!mounted) return;
    try {
      final locale = Localizations.localeOf(context);
      final countryCode =
          WidgetsBinding.instance.platformDispatcher.locale.countryCode;
      final product = await _products.lookup(
        code,
        languageCode: locale.languageCode,
        countryCode: countryCode,
      );
      if (!mounted) return;
      if (product != null) {
        Navigator.of(context).pop(product);
        return;
      }
      setState(() {
        _lookingUp = false;
        _errorKey = 'barcodeProductNotFound';
      });
      await _scanner.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _errorKey = 'barcodeLookupFailed';
      });
      await _scanner.start();
    }
  }

  @override
  void dispose() {
    _products.close();
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    appBar: AppBar(
      backgroundColor: GymRatColors.black,
      title: Text(
        context.tr.t('scanBarcode'),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scanner,
          tapToFocus: true,
          onDetect: _detected,
          errorBuilder: (context, _) => _ScannerMessage(
            icon: Icons.no_photography_outlined,
            text: context.tr.t('cameraUnavailable'),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: .68,
                colors: [
                  Colors.transparent,
                  GymRatColors.black.withValues(alpha: .82),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 292,
            height: 178,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GymRatColors.green, width: 3),
              boxShadow: [
                BoxShadow(
                  color: GymRatColors.green.withValues(alpha: .22),
                  blurRadius: 28,
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GymRatColors.surface.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: GymRatColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_lookingUp)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: LinearProgressIndicator(color: GymRatColors.green),
                    ),
                  Text(
                    context.tr.t(
                      _lookingUp ? 'barcodeLookingUp' : 'barcodeScanHelp',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_errorKey != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.tr.t(_errorKey!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GymRatColors.gold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    context.tr.t('openFoodFactsAttribution'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GymRatColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ScannerMessage extends StatelessWidget {
  const _ScannerMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: GymRatColors.black,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: GymRatColors.gold, size: 42),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
