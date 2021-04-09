import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:app_settings/app_settings.dart';

import 'package:ble_app/service_locator.dart';
import 'package:ble_app/services/ble_service.dart';
import 'package:ble_app/blocs/ble/ble_module.dart';
import 'package:ble_app/blocs/ble/scan_device_bloc.dart';
import 'package:ble_app/blocs/ble/scan_device_event.dart';
import 'package:ble_app/blocs/ble/scan_device_state.dart';
import 'app_bloc_delegate.dart';
import 'dart:typed_data';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocDelegate();
  try {
    await setupLocator();
  } catch (error) {
    print('Locator setup has failed');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Ble scaner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver{
  AppLifecycleState _appState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appState = state;
      print('state = $state');
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _divider(BuildContext context, int index) {
    return Divider(
      color: Theme.of(context).dividerColor,
      height: 1.0,
    );
  }
  
  Widget _buildBleItem(BuildContext _context, BleModule bleDevice) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(4.0),
        child: Icon(
          FontAwesome.bluetooth,
          color: Colors.blueAccent,
        ),
      ),
      title: Text(
        bleDevice.name,
        style: TextStyle(color: Theme.of(context).accentColor),
      ),
      trailing: Text(bleDevice.rssi.toString()),
      onTap: () async{
        BlocProvider.of<ScanDeviceBloc>(_context).add(ScanDeviceEventStop());
        BlocProvider.of<ScanDeviceBloc>(_context).add(ScanDeviceEventSelected(bleDevice));
        Uint8List _value = Uint8List.fromList([90,100]);

        GetIt.I<BleService>().selectedPeripheral=bleDevice.peripheral;
        // CharacteristicWithValue ret ;

        // await GetIt.I<BleService>().selectedPeripheral.writeCharacteristic(
        //   "021a9004-0382-4aea-bff4-6b3f1c5adfb4", 
        //   "beb5483e-36e1-4688-b7f5-ea07361b26a8", 
        //   _value, 
        //   false
        // );
        try{
          GetIt.I<BleService>().select(bleDevice.peripheral);
          print(GetIt.I<BleService>().selectedPeripheral);
          await GetIt.I<BleService>().selectedPeripheral.connect().then((value) async{
            if(await GetIt.I<BleService>().selectedPeripheral.isConnected()){
              await bleDevice.peripheral.discoverAllServicesAndCharacteristics();
                await bleDevice.peripheral.characteristics("021a9004-0382-4aea-bff4-6b3f1c5adfb4").then((value) async{
                  await Future.forEach(value, (element) async{
                      print("--------------------------------------");
                      if(element.uuid=="beb5483e-36e1-4688-b7f5-ea07361b26a8"){
                        print(await element.read());
                        // await element.write(_value,false);
                      }else if(element.uuid == "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"){
                        // await element.write(_value,false);
                      }
                      print("--------------------------------------");
                  });
                });

                GetIt.I<BleService>().selectedPeripheral.disconnectOrCancelConnection();
            }
          });
          
        }catch (e) {
          print(e.toString());
        }

        BlocProvider.of<ScanDeviceBloc>(_context).add(ScanDeviceEventStart());
        
          // await GetIt.I<BleService>().selectedPeripheral.services().then((value) {
          //   value.forEach((element) async{
          //     print(element);
          //     if(element.uuid=="021a9004-0382-4aea-bff4-6b3f1c5adfb4"){
          //       await element.characteristics().then((charas) {
          //         charas.forEach((chara) {
          //           if(chara.uuid == "beb5483e-36e1-4688-b7f5-ea07361b26a8"){
          //             print(chara);
          //           }
          //         });
          //       }).whenComplete(() => BlocProvider.of<ScanDeviceBloc>(_context).add(ScanDeviceEventStart()));
          //     }
          //   });
          // });

        });

  
        // await Future.delayed(Duration(seconds: 10)).whenComplete(() {
        //   BlocProvider.of<ScanDeviceBloc>(_context).add(ScanDeviceEventStart());
        // });
  }

  Widget _buildBleList(BuildContext context,List<BleModule> bleDevices) {
    return Column(
      children: <Widget>[
        Container(child: Text("QUÉT THIẾT BỊ XUNG QUANH",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),),
        SizedBox(
            child: Container(
                padding: EdgeInsets.all(4.0),
                height: 80,
                child: Align(
                    alignment: Alignment.center,
                    child: SpinKitRipple(
                        color: Theme.of(context).textSelectionColor)))),
        SizedBox(
            child: ListView.separated(
                shrinkWrap: true,
                itemCount: bleDevices.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildBleItem(context, bleDevices[index]);
                },
                separatorBuilder: _divider))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Container(
          child: BlocProvider(
            create: (BuildContext context)=>ScanDeviceBloc()..add(ScanDeviceEventStart()),
            child: BlocBuilder<ScanDeviceBloc, ScanDeviceState>(
              builder: (BuildContext context, ScanDeviceState state) {
                if (state is ScanDeviceStateLoaded) {
                  // print("hfIETHUFethioeW");
                  if (_appState == AppLifecycleState.paused || _appState == AppLifecycleState.inactive) {
                    BlocProvider.of<ScanDeviceBloc>(context)
                        .add(ScanDeviceEventStop());
                  }
                  print(state.bleDevices);
                  return _buildBleList(context,state.bleDevices);
                }
                if (state is ScanDeviceStatePermissionDenied) {
                  print("device is dimission");
                  if (_appState == AppLifecycleState.resumed) {
                    BlocProvider.of<ScanDeviceBloc>(context)
                        .add(ScanDeviceEventStart());
                  }

                  return Center(
                      child: RaisedButton(
                          onPressed: () {
                            AppSettings.openLocationSettings();
                          },
                          textTheme: Theme.of(context).buttonTheme.textTheme,
                          child: Text('Open Location Settings')));
                }
                return Container(
                    child: Center(
                      child: SpinKitThreeBounce(
                        color: Theme.of(context).textSelectionColor,
                        size: 20,
                      ),
                    ));
              },
            ),
          ),
        ),
      ),
    );
  }
}
