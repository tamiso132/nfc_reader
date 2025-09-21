import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'main.dart';

String toHexString(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}


class NfcWebSocketBridge {
  late String wsUrl;
  late WebSocketChannel _channel;
  IsoDepAndroid? _isoDep;
  bool isConnected = false;
  List<String> logList = [];
  late StreamSubscription _stream;

  static late void Function(String, LogType) logFunc;

  NfcWebSocketBridge();

  Future<void> startWebSocket(String url) async {
    wsUrl = url;

    try {
      _channel =  WebSocketChannel.connect(Uri.parse(wsUrl));
      logFunc("Connecting to $wsUrl", LogType.info);

      _stream = _channel.stream.listen(
            (message) async {
          if (_isoDep != null) {
            Uint8List rawBytes = Uint8List.fromList(message);
            CommandPacket cmd = CommandPacket.tryFromBytes(rawBytes);

            try {
              logFunc("Sent to NFC: ${toHexString(cmd.Data())}", LogType.info);
              Uint8List response = await _isoDep!.transceive(cmd.Data());
              logFunc("Response from NFC: ${toHexString(response)}", LogType.info);

              _sendToServer(CommandPacket(CommandType.Package, response.length, response));
            } catch (e) {
              logFunc("Error communicating with NFC: $e", LogType.error);
              _notifyServerError("NFC communication failed: $e");
            }
          }
          else{
            logFunc("NFC Communication is Closed", LogType.error);
          }
        },
        onDone: () {
          logFunc('WebSocket Closed', LogType.info);
          isConnected = false;
        },
        onError: (error) {
          logFunc('WebSocket error: $error', LogType.error);
          isConnected = false;
        },
      );


      isConnected = true; // mark connection established
    } catch (e) {
      logFunc("Failed to connect to WebSocket: $e", LogType.error);
      isConnected = false;
    }
  }

  void cancelSessionWebSocket(){
    logFunc("Cancel Session", LogType.info);
    _stream.cancel();
    _channel.sink.close();
    isConnected = false;
  }

  void startNFCSession() {
    logFunc("Start NFC", LogType.info);
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        _isoDep = IsoDepAndroid.from(tag);
        if (_isoDep == null) return;

        final bytes = CommandPacket(CommandType.NewNFCScan, 0).ToBytes();
        if(isConnected) {
          _channel.sink.add(bytes);
        }
        else{
          logFunc("NFC Discovered but the connection to the server is missing", LogType.info);
        }

      },   pollingOptions: {NfcPollingOption.iso14443},
    );
  }

  void _sendToServer(CommandPacket packet) {
    try {
      _channel.sink.add(packet.ToBytes());
    } catch (e) {
      logFunc("Error sending to Server: $e", LogType.error);
    }
  }

  void _notifyServerError(String message) {
      Uint8List errorPayload = Uint8List.fromList(utf8.encode(message));
      _sendToServer(CommandPacket(CommandType.NFCLost, errorPayload.length, errorPayload));
  }



  Future<void> dispose() async {
    await _channel.sink.close();
    await NfcManager.instance.stopSession();
  }
}




enum CommandType {
  NewNFCScan(0x01) , // 0x01
  NFCLost(0x02),    // 0x02
  Error(0x03),      // 0x03
  Package(0x04);    // 0x04

  const CommandType(this.id);
  static CommandType fromInt(int index){
    for(final val in CommandType.values){
      if(val.id == index){
        return val;
      }
    }
    throw ArgumentError('Unknown CommandType: $index');
  }

  final int id;
}

class CommandPacket {
  final CommandType type;
  final int length;
  final List<int> data;

  CommandPacket(this.type, this.length, [Uint8List? data])
      : data = data ?? Uint8List(0);


  factory CommandPacket.tryFromBytes(Uint8List bytes) {
    if (bytes.length < 5) {
      throw ArgumentError('Response is invalid: $bytes');
    }
    print(bytes.length);
    // First byte is the type
    CommandType type = CommandType.fromInt(bytes[0]);

    // Next 4 bytes are length (big-endian)
    final bd = bytes.sublist(1,5);
    final length = bd[0] |
    (bd[1] << 8) |
    (bd[2] << 16) |
    (bd[3] << 24);

    // Remaining bytes are the data
    Uint8List data = bytes.sublist(5);

    return CommandPacket(type, length, data);
  }
  Uint8List Data(){
    return Uint8List.fromList(data);
  }

  Uint8List ToBytes() {
    final list = <int>[];
    list.add(type.id);

    // Add 4-byte big-endian length
    list.add((length >> 24) & 0xFF);
    list.add((length >> 16) & 0xFF);
    list.add((length >> 8) & 0xFF);
    list.add(length & 0xFF);

    // Add data
    list.addAll(data);

    NfcWebSocketBridge.logFunc("", LogType.info);

    // Convert to fixed-length Uint8List for sending
    return Uint8List.fromList(list);
  }
}


