import 'package:flutter/material.dart';

import '../../core/model/vph_schema.dart';
import '../theme.dart';

/// Goi y note: mot dong chu mau canh bao (nhan cua bool, hoac gia tri cua text)
class NoteLine extends StatelessWidget {
  final VphField field;
  final dynamic value;
  const NoteLine({super.key, required this.field, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = value;
    final text = field.type == 'text' && v is String && v.isNotEmpty ? v : field.label;
    // Trang thai canh bao: nen vang nhat / chu nau (sang), nen nau dam / chu vang (toi)
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Vp.gap / 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Vp.cautionContainer(cs), borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: cs.onTertiaryContainer, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
