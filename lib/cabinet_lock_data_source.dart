import 'dart:typed_data';

import 'package:crclib/catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'constants.dart';

class CabinetLockDataSource {
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  void getCommunicationKeyParkingLock(String deviceId) {
    Uint8List pass = _encodeParkingLockPassword();
    List<int> buffer = [
          stx1,
          stx2,
          BleParkingLockCommandLength.communicationKey,
          rand + 0x32,
          0x00 ^ rand,
          BleParkingLockCommand.communicationKey ^ rand
        ] +
        pass;

    final crcConverter = Crc8Maxim();
    final crc = crcConverter.convert(buffer).toBigInt();
    buffer.add(crc.toInt());
    flutterReactiveBle.writeCharacteristicWithResponse(
      QualifiedCharacteristic(
        characteristicId: bleWriteUuid,
        serviceId: bleServiceUuid,
        deviceId: deviceId,
      ),
      value: buffer,
    );
  }

  void checkStatus(String deviceId, int rKey) {
    final key = rKey ^ rand;
    const cmd = BleParkingLockCommand.status ^ rand;
    var data = [
      ParkingCommandTypes.control ^ rand,
    ];
    List<int> buffer = [
          stx1,
          stx2,
          BleParkingLockCommandLength.status,
          rand + 0x32,
          key,
          cmd,
        ] +
        data;
    try {
      final crc = Crc8MaximDow().convert(buffer).toBigInt();
      buffer.add(int.parse(crc.toRadixString(16), radix: 16));
      flutterReactiveBle.writeCharacteristicWithoutResponse(
          QualifiedCharacteristic(
              characteristicId: bleWriteUuid,
              serviceId: bleServiceUuid,
              deviceId: deviceId),
          value: buffer);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void unlockParkingLock(String deviceId, int rKey) {
    final key = rKey ^ rand;
    const cmd = BleParkingLockCommand.unlock ^ rand;
    var data = [
      ParkingCommandTypes.control ^ rand,
      0x01 ^ rand,
      0x02 ^ rand,
      0x03 ^ rand,
      0x04 ^ rand,
      0x30,
      0x11,
      0x5B,
      0xD7,
      0x00 ^ rand,
    ];
    List<int> buffer = [
          stx1,
          stx2,
          BleParkingLockCommandLength.unlock,
          rand + 0x32,
          key,
          cmd,
        ] +
        data;
    try {
      final crc = Crc8MaximDow().convert(buffer).toBigInt();
      buffer.add(int.parse(crc.toRadixString(16), radix: 16));
       flutterReactiveBle.writeCharacteristicWithoutResponse(
      QualifiedCharacteristic(
        characteristicId: bleWriteUuid,
        serviceId: bleServiceUuid,
        deviceId: deviceId,
      ),
      value: buffer,
    );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Uint8List _encodeParkingLockPassword() {
    //4F6D6E6957344758
    List<int> pass = [0x4f, 0x6d, 0x6e, 0x69, 0x57, 0x34, 0x47, 0x58];
    return Uint8List.fromList(pass).xor(rand);
  }

}
