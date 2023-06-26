import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(const MyApp());
    });
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBluePlus.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            print("checking state == ${state}");

            // return BluetoothOffScreen(state: state, fluBluePlus: bluetooth);
            return MyHomePage(state: state);
            // print("checking state == ${state}");
            // return Text("bluetooth is off");
          }),
      // home:   BluetoothStatusPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.state});

  final BluetoothState? state;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isBluetoothOn = false;
  final bluetooth = FlutterBluePlus.instance;
  bool isPermissionRequestInProgress = false;
  bool isScanning = false;
  var device;

  @override
  void initState() {
    switchOnBluetooth();
    super.initState();
  }

  bool switchOnBluetooth() {
    if (widget.state != BluetoothState.on) {
      FlutterBluePlus.instance.turnOn();
      return true;
    } else {
      return false;
    }
  }

  void startBluetoothScan() {
    setState(() {
      isScanning = true;
    });

    // Start scanning
    FlutterBluePlus.instance.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    var subscription = FlutterBluePlus.instance.scanResults.listen((results) {
      // Handle scan results as needed
    });

    // Stop scanning after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      subscription.cancel();
      setState(() {
        isScanning = false;
      });
    });
  }

  StreamBuilder<List<BluetoothDevice>> streamBluetoothList() {
    print("checking sbBTDS");
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 2))
          .asyncMap((_) => FlutterBluePlus.instance.connectedDevices),
      builder: (c, snapshot) => Column(
        children: snapshot.data!
            .map((device) => ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.id.toString()),
                  trailing: StreamBuilder<BluetoothDeviceState>(
                    stream: device.state,
                    initialData: BluetoothDeviceState.disconnected,
                    builder: (c, snapshot) {
                      print("checking snapshot.data == ${snapshot.data}");
                      if (snapshot.data == BluetoothDeviceState.connected) {
                        return ElevatedButton(
                            child: const Text('OPEN'), onPressed: () {}

                            // => Navigator.of(context).push(
                            // MaterialPageRoute(
                            //     builder: (context) =>
                            //         DeviceScreen(device: device))),
                            );
                      }
                      return Text(snapshot.data.toString());
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Center(
              child: widget.state == BluetoothState.on
                  ? Icon(
                      Icons.bluetooth,
                      color: Colors.green,
                      size: 100,
                    )
                  : Icon(
                      Icons.bluetooth_disabled,
                      color: Colors.red,
                      size: 100,
                    ),
            ),
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.instance.scanResults,
                initialData: [], // Provide an empty list as the initial data
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<ScanResult>? scanResults = snapshot.data;
                    // Use the scanResults list as needed
                    return ListView.builder(
                      itemCount: scanResults!.length,
                      itemBuilder: (context, index) {
                        ScanResult result = scanResults[index];
                        return result.device.name.isNotEmpty
                            ? ListTile(
                                title: ElevatedButton(
                                  onPressed: () async {},
                                  child: Text(result.device.name.isEmpty
                                      ? '-'
                                      : result.device.name),
                                ),
                                subtitle:
                                    Text('device id: ${result.device.type}'),
                              )
                            : Text('test: ${result.rssi}');
                      },
                    );
                  } else {
                    return const Text("No Data");
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                // sbBTDS();
              },
              tooltip: 'Stream',
              child: Icon(Icons.search),
            ),
            FloatingActionButton(
              onPressed: () {
                if (widget.state != BluetoothState.on) {
                  FlutterBluePlus.instance.turnOn();
                  print("checking bluetooth is on");
                } else if (!isScanning) {
                  startBluetoothScan();
                }
              },
              tooltip: 'Bluetooth',
              child:
                  Icon(isScanning ? Icons.bluetooth_disabled : Icons.bluetooth),
            ),
          ],
        ),
      ),
    );
  }
}
