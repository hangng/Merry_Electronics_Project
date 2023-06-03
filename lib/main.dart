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
    if (widget.state != BluetoothState.on) {
      FlutterBluePlus.instance.turnOn();
      print("checking bluetooth is on");
    }
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
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
                      return ListTile(
                        title: ElevatedButton(
                          onPressed: () async {
                            List<BluetoothService> services = await device.discoverServices();
                            services.forEach((service) {
                              // do something with service
                              print("checking service == ${service}");
                            });

                          },
                          child: Text(result.device.name.isEmpty
                              ? '-'
                              : result.device.name),
                        ),
                        subtitle: Text('RSSI: ${result.rssi}'),
                      );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!isScanning) {
            startBluetoothScan();
          }
        },
        tooltip: 'Bluetooth',
        child: Icon(isScanning ? Icons.bluetooth_disabled : Icons.bluetooth),
      ),
    );
  }
}
