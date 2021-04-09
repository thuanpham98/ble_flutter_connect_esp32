import 'package:rxdart/rxdart.dart';
import 'ble_module.dart';

class MissingPickedDeviceException implements Exception {}

class BleDeviceRepository{
  static BleModule _bleModule;
  BehaviorSubject<BleModule> _deviceController;

  static final BleDeviceRepository _deviceRepository = BleDeviceRepository._internal();

  factory BleDeviceRepository(){
    return _deviceRepository;
  }

  BleDeviceRepository._internal(){
    _deviceController = BehaviorSubject<BleModule>.seeded(_bleModule);
  }

  void pickDevice(BleModule bleModule){
    _bleModule = bleModule;
    _deviceController.add(_bleModule);
  }

  ValueStream<BleModule> get pickedDevice =>
   _deviceController.stream.shareValueSeeded(_bleModule);

  bool get hasPickedDevice => _bleModule!=null;
}