import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Manages device ID for key derivation
/// Device ID is persistent across app launches but unique per device
class DeviceIdManager {
  static final DeviceIdManager _instance = DeviceIdManager._internal();
  factory DeviceIdManager() => _instance;
  DeviceIdManager._internal();

  final _storage = const FlutterSecureStorage();
  static const _deviceIdKey = 'device_id_v2';
  String? _cachedDeviceId;

  /// Get or generate device ID
  /// Format: {platform}_{hardware_id}_{generated_uuid}
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    // Try to load from secure storage
    String? storedId = await _storage.read(key: _deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      _cachedDeviceId = storedId;
      return storedId;
    }

    // Generate new device ID
    String newId = await _generateDeviceId();
    await _storage.write(key: _deviceIdKey, value: newId);
    _cachedDeviceId = newId;
    return newId;
  }

  /// Generate a unique device identifier
  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String hardwareId = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Use androidId as unique identifier
        hardwareId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Use identifierForVendor
        hardwareId = iosInfo.identifierForVendor ?? 'unknown_ios';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        // Use computer name + user name hash
        hardwareId = '${windowsInfo.computerName}_${windowsInfo.userName}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        // Use system GUID
        hardwareId = macInfo.systemGUID ?? 'unknown_macos';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        // Use machine ID
        hardwareId = linuxInfo.machineId ?? 'unknown_linux';
      }
    } catch (e) {
      print('Error getting hardware ID: $e');
      hardwareId = 'unknown';
    }

    // Create deterministic hash of hardware ID
    final bytes = utf8.encode(hardwareId);
    final hash = sha256.convert(bytes);
    final deviceId = hash.toString().substring(0, 32);

    return '${Platform.operatingSystem}_$deviceId';
  }

  /// Clear device ID (for testing or logout)
  Future<void> clearDeviceId() async {
    _cachedDeviceId = null;
    await _storage.delete(key: _deviceIdKey);
  }

  /// Check if device ID exists
  Future<bool> hasDeviceId() async {
    if (_cachedDeviceId != null) return true;
    final stored = await _storage.read(key: _deviceIdKey);
    return stored != null && stored.isNotEmpty;
  }
}
