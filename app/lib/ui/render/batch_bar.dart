import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// Thanh duoi cung cua man batch: "Co N thay doi — [Huy] [Luu]"
class BatchBar extends StatelessWidget {
  final int count;
  final bool saving;
  final bool enabled;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  const BatchBar({
    super.key,
    required this.count,
    required this.saving,
    required this.enabled,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.tertiaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  S.batchChanges(count),
                  style: TextStyle(color: cs.onTertiaryContainer, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(onPressed: saving ? null : onCancel, child: const Text(S.cancel)),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: saving || !enabled ? null : onSave,
                icon: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save, size: 18),
                label: const Text(S.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
