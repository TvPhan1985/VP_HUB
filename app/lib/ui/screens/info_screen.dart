import 'package:flutter/material.dart';

import '../../core/device_session.dart';
import '../../l10n/strings_vi.dart';

/// Thong tin thiet bi (SPEC §5): INFO, giao thuc that, MTU, kich thuoc goi VALUES
class InfoScreen extends StatelessWidget {
  final DeviceSession session;
  const InfoScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final i = session.info;
        final t = session.transport;
        final st = t?.stats;
        final cs = Theme.of(context).colorScheme;
        final rows = <(String, String)>[
          (S.infoName, session.displayName),
          if (i != null) ...[
            (S.infoModel, i.model),
            (S.infoFw, i.fw),
            if (i.hw != null) (S.infoHw, i.hw!),
            (S.infoPv, '${i.pv}'),
          ],
          if (t != null) (S.infoProto, t.protoLabel),
          if (i != null) ...[
            (S.infoScreens, '${session.screens.length}'),
            if (i.sch != null) (S.infoSch, i.sch!),
            if (i.caps.isNotEmpty) (S.infoCaps, i.caps.join(', ')),
          ],
          if (st != null) ...[
            (S.infoSchemaSrc, st.schemaFromCache ? S.fromCache : S.fromDevice),
            if (st.mtu > 0) (S.infoMtu, '${st.mtu}'),
            (S.infoMaxValues, S.bytes(st.maxValuesLen)),
            (S.infoPackets, '${st.valuesCount}'),
            (S.infoBad, '${st.badPackets}'),
          ],
        ];
        Widget warn(String text) => Card(
              color: cs.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
                title: Text(text, style: TextStyle(color: cs.onErrorContainer)),
              ),
            );
        return Scaffold(
          appBar: AppBar(title: const Text(S.menuInfo)),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // VALUES cua adapter doi cu khong di qua BLE nguyen goi nen khong ap gioi han 240 byte
              if (st != null && t != null && !t.legacy && st.maxValuesLen > 240) warn(S.valuesTooBig),
              if (st != null && st.badPackets > 0) warn(S.badPacketsWarn),
              Card(
                child: Column(
                  children: [
                    for (final r in rows)
                      ListTile(
                        dense: true,
                        title: Text(r.$1),
                        trailing: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                          child: Text(r.$2,
                              textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
