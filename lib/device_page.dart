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
  @override
  void initState() {
    connectionStream = FlutterReactiveBle().connectToDevice(
        id: widget.deviceId,
        servicesWithCharacteristicsToDiscover: {
          bleServiceUuid: [bleNotifyUuid, bleWriteUuid]
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
          if (data.isNotEmpty) {
            if (data.isNotEmpty) {
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
              ];
              for (int i = 1; i <= length; i++) {
                result.add(
                    data[i + ParkingLockProtocolIndex.cmd] ^ decryptedRand);
              }
              result.add(data[result.length]);
              switch (cmd) {
                case BleParkingLockCommand.communicationKey:
                  {
                    if (result[6] == 0) {
                      print('key failed');
                    } else {
                      setState(() {
                        eKey = key;
                      });
                    }
                    break;
                  }
                case BleParkingLockCommand.unlock:
                  if (result[6] == 0) {
                    print('unlock start');
                  } else if (result[6] == 1) {
                    print('unlock success');
                  } else {
                    print('unlock overtime');
                  }
                  break;
                case BleParkingLockCommand.status:
                  print('status $data');
              }
            }
          }
        });
      }
    });
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
                  return ElevatedButton(
                    onPressed: () {
                      CabinetLockDataSource()
                          .getCommunicationKeyParkingLock(widget.deviceId);
                    },
                    child: const Text('get key'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('connected'),
                    ElevatedButton(
                      onPressed: () {
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
                      connectionStream = FlutterReactiveBle().connectToDevice(
                        id: widget.deviceId,
                        servicesWithCharacteristicsToDiscover: {
                          bleServiceUuid: [bleNotifyUuid, bleWriteUuid]
                        },
                      ).asBroadcastStream();
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
