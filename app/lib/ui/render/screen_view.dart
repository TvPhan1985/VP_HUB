import 'package:flutter/material.dart';

import '../../core/cond.dart';
import '../../core/device_session.dart';
import '../../core/model/vph_schema.dart';
import '../../l10n/strings_vi.dart';
import 'field_widget.dart';
import 'num_field.dart';
import 'trend_chart.dart';

/// Noi dung mot tab, ve hoan toan tu schema (SPEC §4)
class ScreenView extends StatelessWidget {
  final DeviceSession session;
  final int index;
  const ScreenView({super.key, required this.session, required this.index});

  Widget _card(BuildContext context, String? title, List<Widget> children) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 4),
            ...children,
            const SizedBox(height: 4),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final screen = session.screens[index];
    if (screen.error != null) {
      final cs = Theme.of(context).colorScheme;
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: cs.errorContainer,
            child: ListTile(
              leading: Icon(Icons.error_outline, color: cs.onErrorContainer),
              title: Text(S.schemaError, style: TextStyle(color: cs.onErrorContainer)),
              subtitle: Text(screen.error!, style: TextStyle(color: cs.onErrorContainer)),
            ),
          ),
        ],
      );
    }

    // Dieu kien if/en tinh tren gia tri thiet bi + gia tri dang sua cua man nay
    final cond = <String, dynamic>{...session.values, ...?session.drafts[index]};
    Widget fw(VphField f) => FieldWidget(session: session, screen: index, field: f, condValues: cond);
    Widget trend(VphField f) => TrendChart(field: f, points: session.trends[f.id] ?? const []);

    final items = <Widget>[];
    final visible = [for (final f in screen.fields) if (evalCond(f.ifCond, cond)) f];

    // The so lon dua len dau tab
    for (final f in visible.where((f) => f.hint('big') && f.type == 'num')) {
      items.add(BigValueCard(field: f, value: session.valueOf(index, f.id)));
      if (f.hint('trend')) items.add(_card(context, null, [trend(f)]));
    }

    // Cac truong con lai: cung nhom `g` lien nhau gom vao mot the
    String? group;
    var rows = <Widget>[];
    var open = false;
    void flush() {
      if (open && rows.isNotEmpty) items.add(_card(context, group, rows));
      rows = <Widget>[];
      open = false;
    }

    for (final f in visible) {
      if (f.hint('big') && f.type == 'num') continue;
      if (!open || f.group != group) {
        flush();
        group = f.group;
        open = true;
      }
      rows.add(fw(f));
      if (f.hint('trend') && f.type == 'num') rows.add(trend(f));
    }
    flush();

    // Khoi lap: moi lan lap mot the; `cnt` gioi han so the theo gia tri mot truong
    final rep = screen.rep;
    if (rep != null) {
      var shown = screen.repGroups.length;
      final cnt = rep.cnt == null ? null : cond[rep.cnt];
      if (cnt is num) shown = cnt.toInt().clamp(0, shown);
      for (final g in screen.repGroups.take(shown)) {
        final fs = [for (final f in g.fields) if (evalCond(f.ifCond, cond)) fw(f)];
        if (fs.isNotEmpty) items.add(_card(context, '${rep.label ?? S.repDefault} ${g.index}', fs));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      children: items,
    );
  }
}
