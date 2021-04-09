import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'ble_module.dart';

@immutable
abstract class ScanDeviceEvent extends Equatable {
  const ScanDeviceEvent();

  @override
  List<Object> get props => [];
}

class ScanDeviceEventStart extends ScanDeviceEvent{
  @override
  String toString() => 'start scan device BLE';
}

class ScanDeviceEventStarted extends ScanDeviceEvent{
  @override 
  String toString() => 'All condition is ok to Start';
}

class ScanDeviceEventStop extends  ScanDeviceEvent{
  @override 
  String toString() => 'Scaning is stopped';
}

class ScanDeviceEventResume extends ScanDeviceEvent{
  @override 
  String toString() => 'scaning is resumed agained';
}

class ScanDeviceEventPermissionDenied extends ScanDeviceEvent{
  @override 
  String toString() => 'Permission for scannign is denied';
}

class ScanDeviceEventUpdated extends ScanDeviceEvent{
  final List<BleModule> bleDevices;
  
  const ScanDeviceEventUpdated(this.bleDevices);

  @override 
  List<Object> get props => [bleDevices];

  @override 
  String toString() => 'bleDevices : $bleDevices';
}

class ScanDeviceEventSelected extends ScanDeviceEvent{
  final BleModule selectedModule;

  const ScanDeviceEventSelected(this.selectedModule);

  @override 
  List<Object> get props => [selectedModule];

  @override 
  String toString() => "Seleted Ble : $selectedModule";
}