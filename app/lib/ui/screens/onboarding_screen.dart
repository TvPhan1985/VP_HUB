import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/consts.dart';
import '../../core/transport/ble_scanner.dart';
import '../../l10n/l10n.dart';

/// Man gioi thieu lan dau mo app: logo, mot cau gioi thieu, vi sao can quyen Bluetooth.
/// Bam nut moi goi hop xin quyen cua Android, roi sang man Quet (du duoc cap hay khong).
class OnboardingScreen extends StatefulWidget {
  /// Ham xin quyen; null = xin quyen that (test truyen ham gia)
  final Future<bool> Function()? requestPermission;
  const OnboardingScreen({super.key, this.requestPermission});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;

  Future<void> _allow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final settings = SettingsScope.maybeOf(context);
    try {
      await (widget.requestPermission ?? requestBlePermissions)();
    } finally {
      // Bi tu choi van vao man Quet: o do co the huong dan mo cai dat
      await settings?.setOnboarded();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.hub, size: 96, color: cs.primary),
              const SizedBox(height: 16),
              Text(kAppName, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(context.l.onboardBody, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bluetooth, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.l.onboardWhy, style: theme.textTheme.bodyMedium)),
                ],
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _allow,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(context.l.onboardAllow),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
