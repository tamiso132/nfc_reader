// Base interface for requests: must provide bytes to send

import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager_android.dart';

part 'types.dart';
part 'interfaces.dart';
part 'helper.dart';
part 'efParser.dart';
part 'encrypt.dart';




class Command{

  static Future<ResponseCommand> readBinary(IsoDepAndroid isoDep, IEfID efID, int offset, int le, {int cla = 0x00}) async{


    // TODO, check if app of the ef is selected
   // await _elementFileSelect(isoDep, efID.getFullID());

    return await _readBinaryFullID(isoDep, efID.getFullID(), offset, le);
  }


  static Future<ResponseCommand> selectApplication(IsoDepAndroid isoDep, AppID app) async{
    Uint8List appLDS1ID =Uint8List.fromList([0xA0, 0x00, 0x00, 02, 0x47, 0x10, 0x01]);
    return await _applicationSelect(isoDep, appLDS1ID);
  }

  static Future<ResponseCommand> _elementFileSelect(IsoDepAndroid isoDep, Uint8List fileID, {int cla = 0x00}) async{
    Uint8List bytes = _CommandPackage(cla, 0xA4, 0x02, 0x0C, data:fileID).toBytes();

    Uint8List response = await isoDep.transceive(bytes);
 int sw1 = response[response.length - 2];
 int sw2 = response[response.length - 1];
    if (response.length != 2) {
      throw ArgumentError("Invalid response\nresponse length: ${response.length}");
    }

    return ResponseCommand(response[0], response[1]);
  }

  static Future<ResponseCommand> _applicationSelect(IsoDepAndroid isoDep, Uint8List appID) async{

    Uint8List bytes = _CommandPackage(0x00, 0xA4, 0x04, 0x0C, data: appID).toBytes();


    Uint8List response = await isoDep.transceive(bytes);

    if (response.length != 2) {
      throw ArgumentError("Invalid response\nresponse length: ${response.length}");
    }
    mIsActiveApp = true;
    return ResponseCommand(response[0], response[1]);

  }

  static Future<ResponseCommand> _readBinaryShort(IsoDepAndroid isoDep, int efID, int offset, int le, {int cla = 0x00}) async{
    Uint8List bytes = _CommandPackage(cla, 0xB0, efID, offset, le: le).toBytes();
    final responseBytes =  await isoDep.transceive(bytes);

    if (responseBytes.length > 2) {
      final data = responseBytes.sublist(0, responseBytes.length - 2); // bytes from index 2 to end
      return ResponseCommand(responseBytes.length - 2, responseBytes.length - 1, data: data);
    } else if(responseBytes.length == 2) {
      return ResponseCommand(responseBytes[0], responseBytes[1]);
    }

    throw ArgumentError("No response was received");


  }

  static Future<ResponseCommand> _readBinaryFullID(IsoDepAndroid isoDep, Uint8List efID, int offset, int le, {int cla = 0x00}) async{
    // TODO, check for error
    await _elementFileSelect(isoDep, efID);


    Uint8List cmdRead = _CommandPackage(0x00, 0xB0, 0x00, 0x00, le: le).toBytes();
    final responseBytes = await isoDep.transceive(cmdRead);

    if(responseBytes.length >= 2) {
      final data = responseBytes.sublist(0, responseBytes.length -2);
      print("response len: ${responseBytes.length}");
      return ResponseCommand(responseBytes[responseBytes.length - 2], responseBytes[responseBytes.length - 1], data: data);
    }

    throw ArgumentError("No response was received");
  }

  // if we selected an application
  static bool mIsActiveApp = false;


}