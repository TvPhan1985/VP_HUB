import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/device_session.dart';
import '../../l10n/strings.dart';
import 'scan_screen.dart' show SignalBars;

/// Thong tin thiet bi (SPEC §5). Standard: ten, model, firmware, phan cung, song, trang thai.
/// Technician: them giao thuc, schema, MTU, so goi, dia chi.
class InfoScreen extends StatefulWidget {
  final DeviceSession session;
  const InfoScreen({super.key, required this.session});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  int? _rssi;

  @override
  void initState() {
    super.initState();
    _readRssi();
  }

  Future<void> _readRssi() async {
    final r = await widget.session.rssiReader?.call();
    if (mounted && r != null) setState(() => _rssi = r);
  }

  String _status(LinkStatus s) => switch (s) {
        LinkStatus.ready => S.linkOk,
        LinkStatus.connecting || LinkStatus.loading => S.connecting,
        LinkStatus.reconnecting => S.linkRetry,
        _ => S.linkLost,
      };

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final tech = SettingsScope.technician(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final i = session.info;
        final t = session.transport;
        final st = t?.stats;
        final cs = Theme.of(context).colorScheme;
        final rssi = _rssi;
        final rows = <(String, String)>[
          (S.infoName, session.displayName),
          if (i != null) ...[
            (S.infoModel, i.model),
            (S.infoFw, i.fw),
            if (i.hw != null) (S.infoHw, i.hw!),
          ],
          if (rssi != null)
            (S.infoSignal, tech ? '${S.signalLevel(SignalBars.level(rssi))} (${S.rssi(rssi)})' : S.signalLevel(SignalBars.level(rssi))),
          (S.infoStatus, _status(session.status)),
          if (tech) ...[
            if (i != null) (S.infoPv, '${i.pv}'),
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
            if (session.deviceId != null) (S.infoAddr, session.deviceId!),
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
          appBar: AppBar(titleSpacing: null, title: Text(S.menuInfo)),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Canh bao ve goi du lieu chi co nghia voi nguoi ky thuat.
              // VALUES cua adapter doi cu khong di qua BLE nguyen goi nen khong ap gioi han 240 byte
              if (tech && st != null && t != null && !t.legacy && st.maxValuesLen > 240) warn(S.valuesTooBig),
              if (tech && st != null && st.badPackets > 0) warn(S.badPacketsWarn),
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
