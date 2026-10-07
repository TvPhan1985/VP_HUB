import 'package:flutter/material.dart';

import '../../core/device_session.dart';
import '../../core/model/vph_schema.dart';
import '../../l10n/strings_vi.dart';
import '../theme.dart';
import 'field_widget.dart';
import 'icons.dart';
import 'trend_chart.dart';

/// Cum the so do (goi y tile) lien nhau: xep 2 cot, le thi the cuoi chiem ca dong.
/// The co `trend`: cham de mo bieu do ngay duoi hang the.
class TileGroup extends StatefulWidget {
  final DeviceSession session;
  final int screen;
  final List<VphField> fields;
  const TileGroup({super.key, required this.session, required this.screen, required this.fields});

  @override
  State<TileGroup> createState() => _TileGroupState();
}

class _TileGroupState extends State<TileGroup> {
  String? _open;

  bool _hasTrend(VphField f) => f.hint('trend') && f.type == 'num';

  @override
  Widget build(BuildContext context) {
    final fs = widget.fields;
    final s = widget.session;
    final out = <Widget>[];
    for (var i = 0; i < fs.length; i += 2) {
      final row = fs.sublist(i, i + 2 > fs.length ? fs.length : i + 2);
      out.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var k = 0; k < row.length; k++) ...[
              if (k > 0) const SizedBox(width: Vp.gap),
              Expanded(
                child: _Tile(
                  field: row[k],
                  value: s.valueOf(widget.screen, row[k].id),
                  open: _open == row[k].id,
                  onTap: _hasTrend(row[k])
                      ? () => setState(() => _open = _open == row[k].id ? null : row[k].id)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ));
      for (final f in row) {
        if (_open == f.id && _hasTrend(f)) {
          out.add(Card(child: TrendChart(field: f, points: s.trends[f.id] ?? const [])));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out);
  }
}

class _Tile extends StatelessWidget {
  final VphField field;
  final dynamic value;
  final bool open;
  final VoidCallback? onTap;
  const _Tile({required this.field, required this.value, required this.open, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ic = vphIcon(field.icon);
    final has = value != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ic != null) ...[
                      Icon(ic, size: 32, color: has ? cs.primary : Vp.idle(cs)),
                      const SizedBox(height: 4),
                    ],
                    Text(field.label, textAlign: TextAlign.center),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayValue(field, value),
                        style: const TextStyle(fontSize: Vp.tileNumber, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onTap != null)
              Positioned(
                top: 8,
                right: 8,
                child: Tooltip(
                  message: S.showTrend,
                  child: Icon(Icons.show_chart, size: 18, color: open ? cs.primary : Vp.idle(cs)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cum o so nho (goi y mini) lien nhau: gom vao mot the, chia cot deu
class MiniStrip extends StatelessWidget {
  final DeviceSession session;
  final int screen;
  final List<VphField> fields;
  const MiniStrip({super.key, required this.session, required this.screen, required this.fields});

  @override
  Widget build(BuildContext context) {
    final fs = fields;
    // Toi da 4 o mot hang; nhieu hon thi moi hang 3 o
    final per = fs.length <= 4 ? fs.length : 3;
    final rows = <Widget>[];
    for (var i = 0; i < fs.length; i += per) {
      final row = fs.sublist(i, i + per > fs.length ? fs.length : i + per);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(Row(
        children: [
          for (var k = 0; k < per; k++)
            Expanded(
              child: k >= row.length
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Text(row[k].label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            displayValue(row[k], session.valueOf(screen, row[k].id)),
                            style: const TextStyle(fontSize: Vp.miniNumber, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(children: rows),
      ),
    );
  }
}
