import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:typed_data';

final bleServiceUuid =
    Uuid.parse('6e400001-b5a3-f393-e0a9-e50e24dcca9e'.toUpperCase());

final bleWriteUuid =
    Uuid.parse('6e400002-b5a3-f393-e0a9-e50e24dcca9e'.toUpperCase());

final bleNotifyUuid =
    Uuid.parse('6e400003-b5a3-f393-e0a9-e50e24dcca9e'.toUpperCase());

const stx1 = 0xa3;
const stx2 = 0xa4;
const rand = 0x34;

class BleParkingLockCommand {
  static const unlock = 0x05;
  static const lock = 0x15;
  static const communicationKey = 0x01;
  static const status = 0x31;
}

class BleParkingLockCommandLength {
  static const unlock = 0x0A;
  static const lock = 0x01;
  static const communicationKey = 0x08;
  static const status = 0x01;

}

class ParkingLockProtocolIndex {
  static const stx1 = 0;
  static const stx2 = 1;
  static const len = 2;
  static const rand = 3;
  static const key = 4;
  static const cmd = 5;
  static const data = 6;
}

class ParkingCommandTypes {
  static const control = 0x01;
  static const reply = 0x02;
  static const automatic = 0x03;
}

extension XOR on Uint8List {
  Uint8List xor(b) {
    Uint8List buffer = Uint8List(length);

    for (int i = 0; i < length; i++) {
      int a;
      try {
        a = elementAt(i);
      } catch (e) {
        a = 0;
      }

      buffer[i] = a ^ b;
    }

    return buffer;
  }
}
