/// UUID cua giao thuc VPH v1 (PROTOCOL §3) va 2 thiet bi doi cu (LEGACY.md)
library;

String _vph(String x) => '5b39$x-5578-4ab2-9265-4b994a7bc724';

final String kVphService = _vph('0001');
final String kVphInfo = _vph('0002');
final String kVphSelect = _vph('0003');
final String kVphSchema = _vph('0004');
final String kVphValues = _vph('0005');
final String kVphWrite = _vph('0006');
final String kVphResult = _vph('0007');

String _c3(String x) => '6e4000$x-c3a1-4b2c-9d10-0000000000a0';

final String kC3Service = _c3('01');
final String kC3Status = _c3('02');
final String kC3Config = _c3('03');
final String kC3Cmd = _c3('04');
final String kC3Result = _c3('05');

String _kiln(String x) => '6a1e00$x-b5c3-4a4d-8a1e-5b6c7d8e9f00';

final String kKilnService = _kiln('01');
final String kKilnSchema = _kiln('02');
final String kKilnValues = _kiln('03');
final String kKilnWrite = _kiln('04');
final String kKilnSelect = _kiln('05');

/// Cac UUID dich vu dung de loc khi quet
final List<String> kScanServices = [kVphService, kC3Service, kKilnService];
