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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: Vp.warn(cs)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: Vp.warn(cs)))),
        ],
      ),
    );
  }
}
