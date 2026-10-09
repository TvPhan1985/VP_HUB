import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'theme.dart';

/// Mot muc trong menu he thong
class DrawerEntry {
  final IconData icon;
  final String label;

  /// Chu phu ben phai (vd gia tri dang chon)
  final String? value;
  final VoidCallback? onTap;
  final bool selected;

  /// Muc nguy hiem (ngat ket noi): chu do
  final bool danger;
  final bool enabled;

  /// Bam xong van de menu mo (vd cong tac)
  final bool keepOpen;
  final Widget? trailing;
  const DrawerEntry({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.selected = false,
    this.danger = false,
    this.enabled = true,
    this.keepOpen = false,
    this.trailing,
  });
}

class DrawerSection {
  final String title;
  final List<DrawerEntry> items;
  const DrawerSection(this.title, this.items);
}

/// Menu he thong (Navigation Drawer) truot tu canh trai khi bam [≡]:
/// khoi thong tin o tren (avatar, ten, vai tro, trang thai ket noi), ben duoi la cac nhom muc.
/// Rong 82% man hinh, toi da 320dp; cham vung mo ben phai hoac vuot trai de dong.
class AppDrawer extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final List<DrawerSection> sections;
  const AppDrawer({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.sections,
  });

  /// Chu viet tat lam avatar: 2 ky tu dau cua ten
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s\-_]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _item(BuildContext context, DrawerEntry e) {
    final bars = VpBars.of(context);
    final fg = !e.enabled
        ? bars.sub.withValues(alpha: 0.4)
        : (e.danger ? Vp.barStop : (e.selected ? Vp.onBar : Vp.onBar.withValues(alpha: 0.86)));
    return InkWell(
      onTap: !e.enabled || e.onTap == null
          ? null
          : () {
              if (!e.keepOpen) Navigator.of(context).pop();
              e.onTap!();
            },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: e.selected ? bars.tabs : null,
          border: Border(left: BorderSide(color: e.selected ? bars.accent : Colors.transparent, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(17, 6, 12, 6),
        child: Row(
          children: [
            Icon(e.icon, size: 22, color: e.danger || !e.enabled ? fg : (e.selected ? bars.accent : bars.sub)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(e.label,
                  style: TextStyle(color: fg, fontSize: 15, fontWeight: e.selected ? FontWeight.w600 : FontWeight.w500)),
            ),
            if (e.value != null) Text(e.value!, style: TextStyle(color: bars.sub, fontSize: 13)),
            ?e.trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.of(context).size.width * 0.82, 320.0);
    final bars = VpBars.of(context);
    return Drawer(
      width: width,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                color: bars.tabs,
                border: Border(bottom: BorderSide(color: bars.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: bars.avatar,
                        foregroundColor: bars.onAvatar,
                        child: DefaultTextStyle.merge(
                          style: TextStyle(color: bars.onAvatar, fontWeight: FontWeight.w700, fontSize: 16),
                          child: avatar,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Vp.onBar, fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: bars.accent, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: statusColor, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final sec in sections)
                    if (sec.items.isNotEmpty) ...[
                      // Nhom khong tieu de: chi cach mot khoang
                      if (sec.title.isEmpty)
                        const SizedBox(height: 10)
                      else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 6),
                        child: Text(
                          sec.title.toUpperCase(),
                          style: TextStyle(
                              color: bars.sub.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                        ),
                      ),
                      for (final e in sec.items) _item(context, e),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nut [≡] goc tren ben trai cua Top App Bar
class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: S.openMenu,
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
}
