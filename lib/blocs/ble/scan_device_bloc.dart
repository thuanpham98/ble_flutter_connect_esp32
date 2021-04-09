import 'dart:async';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:get_it/get_it.dart';
import 'package:bloc/bloc.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import 'ble_module.dart';
import 'package:ble_app/services/ble_service.dart';
import 'package:ble_app/services/logger_service.dart';
import 'bloc.dart';
// import 'package:ble_app/service_locator.dart';

class ScanDeviceBloc extends Bloc<ScanDeviceEvent, ScanDeviceState> {
  StreamSubscription<ScanResult> _scanSubscription;
  BleService _bleService = GetIt.I<BleService>();
  List<BleModule> bleDevices = new List<BleModule>();
  BleModule selectedDevice;
  Logger log = GetIt.I<LoggerService>().getLog();
  
  ScanDeviceBloc() : super(ScanDeviceStateInitialed());

  @override
  ScanDeviceState get initialState => ScanDeviceStateInitialed();

  @override
  Stream<ScanDeviceState> mapEventToState(
    ScanDeviceEvent event,
  ) async* {
    if (event is ScanDeviceEventStart) {
      yield* _mapStartToState();
    } else if (event is ScanDeviceEventUpdated) {
      yield* _mapUpdatedToState(event);
    } else if (event is ScanDeviceEventSelected) {
      yield* _mapSelectToState(event);
    } else if (event is ScanDeviceEventStop) {
      await _bleService.stopScanBle();
    } else if (event is ScanDeviceEventPermissionDenied) {
      yield ScanDeviceStatePermissionDenied();
    }
  }

  Stream<ScanDeviceState> _mapStartToState() async* {
    try {
      bool permissionIsOk = await _bleService.checkBlePermissions();
      if (!permissionIsOk) {
        add(ScanDeviceEventPermissionDenied());
        return;
      }
      BluetoothState state = await _bleService.start();
      if (state == BluetoothState.UNAUTHORIZED) {
        add(ScanDeviceEventPermissionDenied());
        return;
      }
    } catch (e) {
      log.e('Error start ble service $e');
      return;
    }

    _scanSubscription?.cancel();
    _scanSubscription = _bleService
        .scanBle().debounce((_) => TimerStream(true, Duration(milliseconds: 100)))
        .listen((ScanResult scanResult) {
          var bleDevice = BleModule(scanResult);
          if (scanResult.advertisementData.localName != null) {
            var idx = bleDevices.indexWhere((e) => e.id == bleDevice.id);

            if (idx < 0) {
              bleDevices.add(bleDevice);
            } else {
              bleDevices[idx] = bleDevice;
            }
            add(ScanDeviceEventUpdated(bleDevices));
        }
    });
                               
  }

  Stream<ScanDeviceState> _mapUpdatedToState(ScanDeviceEventUpdated event) async* {
    yield ScanDeviceStateLoaded(List.from(event.bleDevices), selectedDevice);
  }

  Stream<ScanDeviceState> _mapSelectToState(ScanDeviceEventSelected event) async*{
    _bleService.select(event.selectedModule.peripheral);
  }

  @override
  Future<void> close() {
    log.i('scan bloc dispose');
    _scanSubscription?.cancel();
  }
}
