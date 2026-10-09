# LICENSES — thư viện dùng trong app VP Hub

Sinh từ `app/pubspec.lock` (chạy `dart pub deps` + đọc file LICENSE của từng gói trong pub cache). Cập nhật: 2026-10-09, app 1.4.0.

Quy tắc của dự án: chỉ dùng gói có license **BSD / MIT / Apache / Zlib**. Gói khác phải ghi **🔴** ở đây và báo người dùng.

## Gói dùng trực tiếp

| Gói | Bản | License |
|---|---|---|
| `file_picker` | 13.1.0 | MIT |
| `fl_chart` | 1.2.0 | MIT |
| `flutter` | SDK | BSD-3-Clause (Flutter SDK) |
| `flutter_launcher_icons` | 0.14.4 | MIT (chỉ dùng lúc phát triển) |
| `flutter_lints` | 6.0.0 | BSD-3-Clause (chỉ dùng lúc phát triển) |
| `flutter_localizations` | SDK | BSD-3-Clause (Flutter SDK) |
| `flutter_test` | SDK | BSD-3-Clause (Flutter SDK) (chỉ dùng lúc phát triển) |
| `intl` | 0.20.3 | BSD-3-Clause |
| `package_info_plus` | 10.2.2 | BSD-3-Clause |
| `path_provider` | 2.1.6 | BSD-3-Clause |
| `permission_handler` | 11.4.0 | MIT |
| `share_plus` | 13.3.1 | BSD-3-Clause |
| `shared_preferences` | 2.5.6 | BSD-3-Clause |
| `universal_ble` | 2.3.0 | BSD-3-Clause |
| `wakelock_plus` | 1.8.0 | BSD-3-Clause |

## Gói kéo theo (transitive)

| Gói | Bản | License |
|---|---|---|
| `android_file_picker` | 2.0.1 | MIT |
| `archive` | 4.3.0 | MIT |
| `args` | 2.7.0 | BSD-3-Clause |
| `async` | 2.13.1 | BSD-3-Clause |
| `bluez` | 0.8.3 | 🔴 **MPL-2.0** |
| `boolean_selector` | 2.1.2 | BSD-3-Clause |
| `characters` | 1.4.1 | BSD-3-Clause |
| `checked_yaml` | 2.0.4 | BSD-3-Clause |
| `cli_util` | 0.4.2 | BSD-3-Clause |
| `clock` | 1.1.3 | Apache-2.0 |
| `code_assets` | 1.2.1 | BSD-3-Clause |
| `collection` | 1.19.1 | BSD-3-Clause |
| `cross_file` | 0.3.5+5 | BSD-3-Clause |
| `crypto` | 3.0.7 | BSD-3-Clause |
| `dbus` | 0.7.15 | 🔴 **MPL-2.0** |
| `equatable` | 2.1.0 | MIT |
| `fake_async` | 1.3.3 | Apache-2.0 |
| `ffi` | 2.2.0 | BSD-3-Clause |
| `ffi_leak_tracker` | 0.1.2 | BSD-3-Clause |
| `file` | 7.0.1 | BSD-3-Clause |
| `file_picker_darwin` | 2.1.2 | MIT |
| `file_picker_linux` | 2.0.0 | MIT |
| `file_picker_platform_interface` | 4.0.0 | MIT |
| `file_picker_web` | 4.0.1 | MIT |
| `fixnum` | 1.1.1 | BSD-3-Clause |
| `flutter_web_bluetooth` | 1.1.0 | MIT |
| `flutter_web_plugins` | SDK | BSD-3-Clause (Flutter SDK) |
| `hooks` | 2.0.2 | BSD-3-Clause |
| `http` | 1.6.0 | BSD-3-Clause |
| `http_parser` | 4.1.2 | BSD-3-Clause |
| `image` | 4.10.1 | MIT |
| `jni` | 1.1.0 | BSD-3-Clause |
| `jni_flutter` | 1.0.4+1 | BSD-3-Clause |
| `jni_util` | 1.0.0 | BSD-3-Clause |
| `json_annotation` | 4.12.0 | BSD-3-Clause |
| `leak_tracker` | 11.0.2 | BSD-3-Clause |
| `leak_tracker_flutter_testing` | 3.0.10 | BSD-3-Clause |
| `leak_tracker_testing` | 3.0.2 | BSD-3-Clause |
| `lints` | 6.1.0 | BSD-3-Clause |
| `logging` | 1.3.0 | BSD-3-Clause |
| `matcher` | 0.12.20 | BSD-3-Clause |
| `material_color_utilities` | 0.13.0 | Apache-2.0 |
| `meta` | 1.18.3 | BSD-3-Clause |
| `mime` | 2.1.0 | BSD-3-Clause |
| `objective_c` | 9.5.0 | BSD-3-Clause |
| `package_config` | 3.0.0 | BSD-3-Clause |
| `package_info_plus_platform_interface` | 4.1.0 | BSD-3-Clause |
| `path` | 1.9.1 | BSD-3-Clause |
| `path_provider_android` | 2.3.1 | BSD-3-Clause |
| `path_provider_foundation` | 2.6.0 | BSD-3-Clause |
| `path_provider_linux` | 2.2.2 | BSD-3-Clause |
| `path_provider_platform_interface` | 2.1.3 | BSD-3-Clause |
| `path_provider_windows` | 2.3.0 | BSD-3-Clause |
| `permission_handler_android` | 12.1.0 | MIT |
| `permission_handler_apple` | 9.6.2 | MIT |
| `permission_handler_html` | 0.1.4+1 | MIT |
| `permission_handler_platform_interface` | 4.4.1 | MIT |
| `permission_handler_windows` | 0.2.2 | MIT |
| `petitparser` | 7.0.2 | MIT |
| `platform` | 3.2.0 | BSD-3-Clause |
| `plugin_platform_interface` | 2.1.8 | BSD-3-Clause |
| `posix` | 6.5.2 | MIT |
| `pub_semver` | 2.2.1 | BSD-3-Clause |
| `record_use` | 0.6.0 | BSD-3-Clause |
| `share_plus_platform_interface` | 7.2.0 | BSD-3-Clause |
| `shared_preferences_android` | 2.4.28 | BSD-3-Clause |
| `shared_preferences_foundation` | 2.5.7 | BSD-3-Clause |
| `shared_preferences_linux` | 2.4.1 | BSD-3-Clause |
| `shared_preferences_platform_interface` | 2.4.2 | BSD-3-Clause |
| `shared_preferences_web` | 2.4.3 | BSD-3-Clause |
| `shared_preferences_windows` | 2.4.1 | BSD-3-Clause |
| `sky_engine` | SDK | BSD-3-Clause (Flutter SDK) |
| `source_span` | 1.10.2 | BSD-3-Clause |
| `stack_trace` | 1.12.2 | BSD-3-Clause |
| `stream_channel` | 2.1.4 | BSD-3-Clause |
| `string_scanner` | 1.4.1 | BSD-3-Clause |
| `term_glyph` | 1.2.2 | BSD-3-Clause |
| `test_api` | 0.7.12 | BSD-3-Clause |
| `typed_data` | 1.4.0 | BSD-3-Clause |
| `url_launcher_linux` | 3.2.3 | BSD-3-Clause |
| `url_launcher_platform_interface` | 2.3.2 | BSD-3-Clause |
| `url_launcher_web` | 2.4.3 | BSD-3-Clause |
| `url_launcher_windows` | 3.1.6 | BSD-3-Clause |
| `uuid` | 4.6.0 | MIT |
| `vector_math` | 2.4.0 | BSD-3-Clause |
| `vm_service` | 15.3.0 | BSD-3-Clause |
| `wakelock_plus_platform_interface` | 1.7.0 | BSD-3-Clause |
| `web` | 1.1.1 | BSD-3-Clause |
| `win32` | 6.4.0 | BSD-3-Clause |
| `windows_file_picker` | 2.0.1 | MIT |
| `xdg_directories` | 1.1.0 | BSD-3-Clause |
| `xml` | 7.0.1 | MIT |
| `yaml` | 3.1.4 | MIT |

## Ghi chú

- **Thư viện BLE**: `universal_ble` 2.3.0, BSD-3-Clause (Navideck Labs OÜ) — thay `flutter_blue_plus` 2.x (license riêng, công ty có lợi nhuận phải mua). Đã đọc file LICENSE trong gói và nhãn `license:bsd-3-clause` trên pub.dev.
- 🔴 `bluez`, `dbus`: **MPL-2.0**. Đây là gói **chỉ dùng cho Linux desktop**, kéo theo bởi `universal_ble` (BLE trên Linux) và `file_picker_linux`; đã có sẵn trong `pubspec.lock` từ bản 1.3 (không phải gói mới thêm). MPL-2.0 là copyleft **theo từng file**: dùng nguyên bản, không sửa mã của gói thì được phép dùng trong sản phẩm thương mại, chỉ cần giữ thông báo bản quyền (màn *Open-source licenses* của app đã hiện). App chỉ phát hành cho Android nên phần mã này không được gọi tới.
- Màn **Settings → About → Open-source licenses** trong app hiện toàn văn license của mọi gói (hàm `showLicensePage()` của Flutter).
- Khi thêm gói mới: chạy lại việc rà này và cập nhật bảng.
