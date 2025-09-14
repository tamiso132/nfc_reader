// Base interface for requests: must provide bytes to send
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager_android.dart';

String toHex(int value, {int width = 2}) {
  return "${value.toRadixString(16).toUpperCase().padLeft(width, '0')}";
}

/*
Id for files that are not application specific
*/

enum SwStatus{
  success(0x9000),
  fileNotFound(0x6A82),
  recordNotFound(0x6A83),
  wrongRespLen(0x6700),
  securityNotSatisfied(0x6982),
  commandNotAllowed(0x6986),
  commandAborted(0x6F00),
  cardDead(0x6FFF),
  incorrectParameter(0x6a86);


  final int value;
  const SwStatus(this.value);

  factory SwStatus.fromInt(int code) {
    return SwStatus.values.firstWhere(
          (s) => s.value == code,
      orElse: () => throw Exception('Unknown SW code: 0x${toHex(code)}'),
    );
  }
}

enum EfIdGlobal {
  cardAccess(0x1C),
  cardSecurity(0x1D),
  atrInfo(0x01),
  dir(0x1E);

  final int value;
  const EfIdGlobal(this.value);
}


/*
Id for files that are for LDS1 application
*/
enum EfIdAppSpecific{
  com(0x1E),
  dg1(0x01),
  dg2(0x02),
  dg9(0x09),
  dg10(0x0A),
  sod(0x1D),
  dg16(0x10);
  final int value;
  const EfIdAppSpecific(this.value);
}


/*
Response Structure
*/
class ResponseCommand{

  ResponseCommand(this.sw1, this.sw2, {this.data}){
    print("resp: 0x${toHex(sw1)}${toHex(sw2)}");
  }

  int sw1 = 0;
  int sw2 = 0;
  Uint8List? data;
}


/*
Structure for Asn package,  TAG->length->data
*/
class AsnPackage{
  AsnPackage(this.tag, this.data);

  static List<AsnPackage> parse(Uint8List data){
    List<AsnPackage> packages = [];
    int current_len = 0;
    while(current_len < data.length){
     int tag = data[current_len] & 0xFF;
     current_len += 1;
     
     int length = (data[current_len] & 0xFF) >> 8 + (data[current_len+1] & 0xFF);
     current_len += 2;
     
     Uint8List d = data.sublist(current_len, length + current_len);
     current_len += length;

    packages.add(AsnPackage(tag, d));
    }

    return packages;
  }

  int tag;
  Uint8List data;
}

class CommandPackage{

  CommandPackage(this.cla, this.ins, this.p1, this.p2, {this.data, this.le});

  Uint8List toBytes() {
    final bytes = <int>[cla, ins, p1, p2];

    if (data != null && data!.isNotEmpty) {
      bytes.add(data!.length);  // Lc
      bytes.addAll(data!);
    }

    if (le != null) {
      bytes.add(le!);
    }

    return Uint8List.fromList(bytes);
  }

  int cla = 0;
  int ins = 0;
  int p1 = 0;
  int p2 = 0;
  Uint8List? data;
  int? le;
}



class Command{

  static Future<ResponseCommand> readBinaryGlobal(IsoDepAndroid isoDep, EfIdGlobal efID, int offset, int le, {int cla = 0x00}) async{
    Uint8List bytes = CommandPackage(cla, 0xB0, efID.value, offset, le: le).toBytes();
   final responseBytes =  await isoDep.transceive(bytes);

    if (responseBytes.length > 2) {
      final data = responseBytes.sublist(2); // bytes from index 2 to end
      return ResponseCommand(responseBytes.length - 2, responseBytes.length - 1, data: data);
    } else if(responseBytes.length == 2) {
      return ResponseCommand(responseBytes[0], responseBytes[1]);
    }
    else{
      throw ArgumentError("no response was recieved");
    }

  }

  static Future<ResponseCommand> readBinaryApp(IsoDepAndroid isoDep, EfIdAppSpecific efID, int offset, int le, {int cla = 0x00}) async{
    Uint8List bytes = CommandPackage(cla, 0xB0, efID.value, offset, le: le).toBytes();
    final responseBytes =  await isoDep.transceive(bytes);

    if (responseBytes.length > 2) {
      final data = responseBytes.sublist(2); // bytes from index 2 to end
      return ResponseCommand(responseBytes.length - 2, responseBytes.length - 1, data: data);
    } else if(responseBytes.length == 2) {
      return ResponseCommand(responseBytes[0], responseBytes[1]);
    }
    else{
      throw ArgumentError("no response was recieved");
    }

  }

  static Future<ResponseCommand> selectLDS1Application(IsoDepAndroid isoDep) async{
    Uint8List appLDS1ID =Uint8List.fromList([0xA0, 0x00, 0x00, 02, 0x47, 0x10, 0x01]);
    return await _applicationSelect(isoDep, appLDS1ID);
  }

  static Future<ResponseCommand> _elementfileSelect(IsoDepAndroid isoDep, Uint8List fileID, {int cla = 0x00}) async{
    Uint8List bytes = CommandPackage(cla, 0xA4, 0x02, 0x0C, data:fileID).toBytes();

    Uint8List response = await isoDep.transceive(bytes);

    if (response.length != 2) {
      throw ArgumentError("Invalid response\nresponse length: ${response.length}");
    }

    return ResponseCommand(response[0], response[1]);
  }

  static Future<ResponseCommand> _applicationSelect(IsoDepAndroid isoDep, Uint8List appID) async{

    Uint8List bytes = CommandPackage(0x00, 0xA4, 0x04, 0x0C, data: appID).toBytes();


    Uint8List response = await isoDep.transceive(bytes);

    if (response.length != 2) {
      throw ArgumentError("Invalid response\nresponse length: ${response.length}");
    }
    mIsActiveApp = true;
    return ResponseCommand(response[0], response[1]);

  }

  // if we selected an application
  static bool mIsActiveApp = false;


}