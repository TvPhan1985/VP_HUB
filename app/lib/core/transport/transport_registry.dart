import '../../l10n/strings.dart';
import '../schema_cache.dart';
import 'gatt_link.dart';
import 'legacy_c3relay.dart';
import 'legacy_kiln.dart';
import 'transport.dart';
import 'uuids.dart';
import 'vph_transport.dart';

/// Loai giao thuc, nhan ra tu UUID dich vu
enum TransportKind { vph, c3relay, kiln }

/// UUID dich vu -> loai transport. VPH duoc uu tien neu thiet bi co nhieu dich vu.
TransportKind? kindForServices(Iterable<String> uuids) {
  final set = {for (final u in uuids) u.toLowerCase()};
  if (set.contains(kVphService)) return TransportKind.vph;
  if (set.contains(kC3Service)) return TransportKind.c3relay;
  if (set.contains(kKilnService)) return TransportKind.kiln;
  return null;
}

/// Bieu tuong goi y khi chua doc duoc INFO (ket qua quet)
String iconForKind(TransportKind? k) => switch (k) {
      TransportKind.c3relay => 'relay',
      TransportKind.kiln => 'heater',
      _ => 'generic',
    };

DeviceTransport createTransport(TransportKind kind, GattLink link, SchemaCache cache) => switch (kind) {
      TransportKind.vph => VphTransport(link, cache),
      TransportKind.c3relay => C3RelayTransport(link),
      TransportKind.kiln => KilnTransport(link, cache),
    };

/// Ket noi roi chon transport theo dich vu tim thay tren thiet bi
Future<DeviceTransport> connectTransport(GattLink link, SchemaCache cache) async {
  try {
    await link.connect();
    final kind = kindForServices(link.services);
    if (kind == null) throw Exception(S.unsupportedDevice);
    return createTransport(kind, link, cache);
  } catch (_) {
    await link.disconnect();
    rethrow;
  }
}
