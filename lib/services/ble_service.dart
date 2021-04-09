import 'dart:io';
import 'dart:async';

import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'package:rxdart/rxdart.dart';
import 'package:ble_app/services/permissions_service.dart';
import 'package:ble_app/services/logger_service.dart';

import 'package:location/location.dart';

class BleService{
  static BleService _instance;
  static BleManager _bleManager;
  static Logger logger;
  bool _isPoweron = false;
  StreamSubscription<ScanResult> _scanSubscription;
  StreamSubscription<BluetoothState> _stateSubscription;
  Peripheral selectedPeripheral;
  String selectedId;

  static BleService getInstance() {
    if(_instance == null){
      _instance = BleService();
    }
    if(_bleManager ==null){
      _bleManager = BleManager();
      logger = GetIt.I<LoggerService>().getLog();
    }
    logger.v('bleservice started');

    return _instance;
  }

  BleManager getMaganer() {
    return _bleManager;
  }

  // start 
  Future<BluetoothState> start() async{
    if(_isPoweron){
      var state = await _waitForBluetoothPoweredOn();
      logger.i('Device power was on $state');
      return state;
    }

    var isPermissionOk = await checkBlePermissions();
    if(!isPermissionOk){
      throw Future.error(Exception('Location permission not granted'));
    }

    logger.v('createClient');

    await _bleManager.createClient(
      restoreStateIdentifier: "pas-ble-client",
      restoreStateAction: (peripherals) {
        peripherals?.forEach((peripheral) {
          logger.i("Restored peripheral: ${peripheral.name}");
          peripheral.disconnectOrCancelConnection();
          // selectedPeripheral = peripheral;
        }); 
      }
    );

    logger.v('enableRadio');
    // await _waitForBluetoothPoweredOn().then((value) async{
    //   if(value == BluetoothState.POWERED_OFF){
          
    //   }
    // });

    try {
      var state = await _waitForBluetoothPoweredOn();
      _isPoweron = state == BluetoothState.POWERED_ON;
      if(!_isPoweron){
        if (Platform.isAndroid) {
          await _bleManager.enableRadio();
          _isPoweron=true;
        }
      }
      return state;
    } catch (e) {
      logger.e('Error ${e.toString()}');
    }
    return BluetoothState.UNKNOWN;
  }

  void selectId(String id) {
    if (selectedId == null) {
      selectedId = id;
    }
  }

  void select(Peripheral peripheral) async {
    var a = await selectedPeripheral?.isConnected();
    if(a == true){
      await selectedPeripheral?.disconnectOrCancelConnection();
    }
    selectedPeripheral = peripheral;
    logger.v('selectedPeripheral = $selectedPeripheral');
  }

  Future<bool> stop() async{
    if (!_isPoweron) {
      return true;
    }
    _isPoweron = false;
    stopScanBle();
    await _stateSubscription?.cancel();
    await _scanSubscription?.cancel();
    var a = await selectedPeripheral?.isConnected();
    if(a == true){
      await selectedPeripheral?.disconnectOrCancelConnection();
    }

    if (Platform.isAndroid) {
      await _bleManager.disableRadio();
    }
    await _bleManager.destroyClient();
    return true;
  }

  Stream<ScanResult> scanBle() {
    stopScanBle();
    return _bleManager.startPeripheralScan(
        uuids: ["021a9004-0382-4aea-bff4-6b3f1c5adfb4"],
        scanMode: ScanMode.lowPower,
        allowDuplicates: true);
  }

  Future<void> stopScanBle() {
    return _bleManager.stopPeripheralScan();
  }
  
  Future<Peripheral> scanPeripheral() async {
    Completer completer = Completer<BluetoothState>();
    _scanSubscription?.cancel();
    _scanSubscription = scanBle()
        .debounce((_) => TimerStream(true, Duration(milliseconds: 1000)))
        .listen((ScanResult scanResult) {
      if (scanResult.advertisementData.localName != null &&
          selectedPeripheral != null &&
          scanResult.peripheral.identifier == selectedPeripheral.identifier) {
        // stopScanBle();
        completer.complete(scanResult.peripheral);
      }
    });
    return completer.future;
  }
  
  Future<BluetoothState> _waitForBluetoothPoweredOn() async{
    Completer completer = Completer<BluetoothState>();
    _stateSubscription?.cancel();
    _stateSubscription = _bleManager.observeBluetoothState(emitCurrentValue: true).listen((bluetoothState) async{
      logger.v('bluetoothState = $bluetoothState');

      if((bluetoothState == BluetoothState.POWERED_ON || bluetoothState == BluetoothState.UNAUTHORIZED) && !completer.isCompleted){
        completer.complete(bluetoothState);
      }
    });

    return completer.future.timeout(
      Duration(seconds: 5),
      onTimeout: () {}
    );
  }

  Future<bool> checkBlePermissions() async {
    Location location = new Location();
    bool _serviceEnabled;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    bool isLocationGranted =await GetIt.I<PermissionsService>().requestLocationPermission();
    logger.v('checkBlePermissions, isLocationGranted=$isLocationGranted');
    return isLocationGranted;
  }

}