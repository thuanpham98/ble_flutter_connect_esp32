
import 'package:equatable/equatable.dart';
import 'ble_module.dart';

abstract class ScanDeviceState extends Equatable {
  const ScanDeviceState();
  
  @override
  List<Object> get props => [];
}

class ScanDeviceStateInitialed extends ScanDeviceState{}

class ScanDeviceStateStarted extends ScanDeviceState{}

class ScanDeviceStatePermissionDenied extends ScanDeviceState {}

class ScanDeviceStateLoaded extends ScanDeviceState{
  final List<BleModule> bleDevices;
  final BleModule selectedDevice;

  const ScanDeviceStateLoaded([this.bleDevices = const [],this.selectedDevice]);

  @override 
  List<Object> get props => [bleDevices,selectedDevice];

  @override 
  String toString() => 'Device loaded : {bleDevice : $bleDevices, selected : $selectedDevice}';
}