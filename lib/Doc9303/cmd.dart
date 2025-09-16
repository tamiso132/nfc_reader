// Base interface for requests: must provide bytes to send

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/asn1/object_identifiers_database.dart';
import 'package:pointycastle/ecc/curves/brainpoolp256r1.dart';
import 'package:pointycastle/ecc/curves/brainpoolp384r1.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';
import 'dart:math';
import 'dart:typed_data';


part 'types.dart';
part 'interfaces.dart';
part 'helper.dart';
part 'efParser.dart';
part 'encrypt.dart';
part 'asn1.dart';
part 'Dummytester.dart';




class Command{

  static Future<ResponseCommand> readBinary(IsoDepAndroid isoDep, IEfID efID,  {int offset = 0x00, int le = 0x00,int cla = 0x00}) async{

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
      printUint8List(responseBytes);
      final data = responseBytes.sublist(0, responseBytes.length -2);
      return ResponseCommand(responseBytes[responseBytes.length - 2], responseBytes[responseBytes.length - 1], data: data);
    }

    throw ArgumentError("No response was received");
  }

  //TODO Skicka till chippet:
  //The command MSE:Set AT is used to select and initialize the PACE protocol. The use of MSE:Set AT for PACE is indicated
  // by a PACE Object Identifier (see Sections 4.4.3 and 9.2.3) contained as cryptographic mechanism reference with tag 0x80,
  // see table below.


  // 0x83 - Reference of a public key / secret key, The password to be used is indicated by the following values in this data
  // object: 0x01: MRZ_information, 0x02: CAN

  // 0x84 - Reference of a private key / Reference for computing a session key. This data object is REQUIRED to indicate the identifier of the domain
  // parameters to be used if the domain parameters are ambiguous, i.e.
  // more than one set of domain parameters is available for PACE.

  // 0x7F4C - Certificate Holder Authorization Template??????


  static Future<ResponseCommand> _mseSetAT(IsoDepAndroid isoDep, Uint8List oid, Uint8List mrz, Uint8List parameterID, {Uint8List? chat, int cla = 0x00}) async{

   Uint8List data = AsnBuilder().addCustomTag(0x80, oid).addCustomTag(0x83, mrz).addCustomTag(0x84, parameterID).build();

  Uint8List cmdRead  =_CommandPackage(cla, 0x22, 0xC1, 0xA4, data: data).toBytes();
  final responseBytes = await isoDep.transceive(cmdRead);

  if(responseBytes.length >= 2) {
    printUint8List(responseBytes);
    final data = responseBytes.sublist(0, responseBytes.length -2);
    return ResponseCommand(responseBytes[responseBytes.length - 2], responseBytes[responseBytes.length - 1], data: data);
  }

  throw ArgumentError("No response was received");

  }

  // if we selected an application
  static bool mIsActiveApp = false;


}