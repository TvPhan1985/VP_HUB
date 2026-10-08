import 'package:flutter/material.dart';

import 'theme.dart';

/// Nhan trang thai nho o goc the ("Stable", "ON", "Firing")
enum ChipKind { ok, caution, stop, idle }

class StatusChip extends StatelessWidget {
  final String text;
  final ChipKind kind;
  const StatusChip({super.key, required this.text, required this.kind});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (kind) {
      ChipKind.ok => (Vp.okContainer(cs), Vp.onOkContainer(cs)),
      ChipKind.caution => (cs.tertiaryContainer, cs.onTertiaryContainer),
      ChipKind.stop => (cs.errorContainer, cs.onErrorContainer),
      ChipKind.idle => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

/// Khoi noi bat trong the: nen xam nhat, vach mau nhan ben trai (so chinh, trang thai chinh)
class AccentWell extends StatelessWidget {
  final Widget child;
  final Color? accent;
  const AccentWell({super.key, required this.child, this.accent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Vp.well(cs), borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(border: Border(left: BorderSide(color: accent ?? cs.primary, width: 4))),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: child,
      ),
    );
  }
}
