import 'dart:async';
import 'package:cabinet_ble_test/device_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<DiscoveredDevice> scanResult;

  List<DiscoveredDevice> loResult = [];
  late Future<Map<Permission, PermissionStatus>> permissions;
  @override
  void initState() {
    _requestPermission();
    super.initState();
  }

  _requestPermission() async {
    await loc.Location.instance.requestService();
    permissions = [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    permissions.then((value) {
      if (value.entries.every((element) => element.value.isGranted)) {
        _scan();
      }
    });
  }

  _scan() {
    scanResult = flutterReactiveBle.scanForDevices(
      withServices: [],
    ).listen((event) {
      if (event.id == 'E8:9F:61:A5:7B:CF') {
        if (!loResult.any((element) => element.id == event.id)) {
          setState(() {
            loResult.add(event);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                loResult.clear();
                scanResult.cancel();
                _scan();
              });
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: loResult.length,
        itemBuilder: (context, i) {
          return Column(
            children: [
              const Divider(),
              Text(
                loResult[i].id.toString(),
              ),
              Text(loResult[i].name),
              Text(loResult[i].serviceData.length.toString()),
              Wrap(
                children: loResult[i]
                    .serviceData
                    .entries
                    .map((e) => Text(e.value.toString()))
                    .toList(),
              ),
              Text('m:  + ${loResult[i].manufacturerData.toString()}'),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DevicePage(
                        deviceId: loResult[i].id,
                      ),
                    ),
                  );
                },
                child: const Text('connect'),
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}
