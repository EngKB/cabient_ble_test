import 'dart:async';

import 'package:cabinet_ble_test/cabinet_lock_data_source.dart';
import 'package:cabinet_ble_test/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DevicePage extends StatefulWidget {
  final String deviceId;
  const DevicePage({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  late Stream<ConnectionStateUpdate> connectionStream;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription? _dataStream;
  int? eKey;
  _connect() {
    connectionStream = FlutterReactiveBle().connectToDevice(
        id: widget.deviceId,
        servicesWithCharacteristicsToDiscover: {
          bleServiceUuid: [
            bleNotifyUuid,
            bleWriteUuid,
          ]
        }).asBroadcastStream();
    _connection = connectionStream.listen((event) {
      if (event.connectionState == DeviceConnectionState.connected) {
        _dataStream = FlutterReactiveBle()
            .subscribeToCharacteristic(
          QualifiedCharacteristic(
            characteristicId: bleNotifyUuid,
            serviceId: bleServiceUuid,
            deviceId: widget.deviceId,
          ),
        )
            .listen((data) {
          if (data.isNotEmpty && data[0] == stx1 && data[1] == stx2) {
            print('response ' + data.toString());
            final length = data[ParkingLockProtocolIndex.len];
            final rand = data[ParkingLockProtocolIndex.rand];
            int decryptedRand;
            if (rand - 0x32 < 0) {
              decryptedRand = 255 - (0x31 - rand);
            } else {
              decryptedRand = rand - 0x32;
            }
            final key = data[ParkingLockProtocolIndex.key] ^ decryptedRand;
            final cmd = data[ParkingLockProtocolIndex.cmd] ^ decryptedRand;
            List<int> result = [
              //2 Bytes STX
              data[ParkingLockProtocolIndex.stx1],
              data[ParkingLockProtocolIndex.stx2],
              //1 byte length
              length,
              //decrypted rand
              decryptedRand,
              //key
              key,
              //cmd
              cmd,
              data[6] ^ decryptedRand
            ];
            print('decrypted response '+ result.toString());
            switch (cmd) {
              case BleParkingLockCommand.communicationKey:
                {
                  if (result[6] == 0) {
                    print('key failed');
                  } else {
                    final mKey =
                        data[ParkingLockProtocolIndex.key] ^ decryptedRand;
                    setState(() {
                      eKey = mKey;
                    });
                  }
                  break;
                }
              case BleParkingLockCommand.unlock:
                print('unlock response');
                if (result[6] == 1) {
                  print('unlock success');
                } else {
                  print('unlock result ${result[6]}');
                }
                break;
              case BleParkingLockCommand.status:
                print('status $result');
            }
          } else {
            // print('ignored $data');
          }
        });
        CabinetLockDataSource().getCommunicationKeyParkingLock(widget.deviceId);
      }
    });
  }

  @override
  void initState() {
    _connect();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deviceId,
        ),
      ),
      body: StreamBuilder<ConnectionStateUpdate>(
        stream: connectionStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }
          final DeviceConnectionState connectionState =
              snapshot.data!.connectionState;
          if (connectionState == DeviceConnectionState.connected) {
            return Center(
              child: Builder(builder: (context) {
                if (eKey == null) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('get communication key'),
                      CircularProgressIndicator()
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('connected'),
                    ElevatedButton(
                      onPressed: () {
                        print('unlock key ' + eKey!.toString());
                        CabinetLockDataSource()
                            .unlockParkingLock(widget.deviceId, eKey!);
                      },
                      child: const Text('unlock'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        CabinetLockDataSource()
                            .checkStatus(widget.deviceId, eKey!);
                      },
                      child: const Text('status'),
                    ),
                  ],
                );
              }),
            );
          } else if (connectionState == DeviceConnectionState.connecting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (connectionState == DeviceConnectionState.disconnected) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(
                    () {
                      eKey = null;
                      _connect();
                    },
                  );
                },
                child: const Text('reconnect'),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  @override
  void dispose() {
    _connection?.cancel();
    _dataStream?.cancel();
    super.dispose();
  }
}
