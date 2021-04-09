import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:collection/collection.dart';

class BleModule{
  final Peripheral peripheral;
  final String name;
  final DeviceCategory category;
  final int rssi;

  String get id => peripheral.identifier;
  BleModule(ScanResult scanResult)
  : peripheral = scanResult.peripheral,
    name = scanResult.name,
    category =scanResult.category,
    rssi = scanResult.rssi;

  @override
  int get hashCode => id.hashCode;

  @override 
  String toString(){
    return 'BleDevice{name: $name}';
  }

}

enum DeviceCategory { hex, other }

extension on ScanResult {
  String get name =>
      peripheral.name ?? advertisementData.localName ?? "Unknown";

  DeviceCategory get category {
    if (name != null && name.startsWith("Hex")) {
      return DeviceCategory.hex;
    } else {
      return DeviceCategory.other;
    }
  }
}