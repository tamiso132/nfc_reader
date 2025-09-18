import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:test_flutter/socket.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC WebSocket Bridge',
      home: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text('NFC WebSocket Bridge')),
        body: ConnectionScreen(),
      ),
    );
  }
}

// Define the connection screen here
class ConnectionScreen extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}
class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _portController = TextEditingController(text: '5000');
  final TextEditingController _ipController = TextEditingController(text: '192.168.0.108');
  late final NfcWebSocketBridge _bridge = NfcWebSocketBridge();
  String _selectedOption = 'Localhost';
  final List<String> _options = ['Localhost', 'Custom IP'];
  final TextEditingController _customIpController = TextEditingController();
  List<LogEntry> _logList = [];

  @override
  void initState() {
    super.initState();
    NfcWebSocketBridge.logFunc = _logTxt;
    print("Controller initialized");
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
        ),
        child: Column(
          children: [
            // Log box at the top
            Container(
              width: double.infinity,
              height: 200,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  reverse: true,
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _logList.map((entry) {
                        Color color;
                        switch (entry.type) {
                          case LogType.error:
                            color = Colors.redAccent;
                            break;
                          case LogType.warning:
                            color = Colors.orangeAccent;
                            break;
                          case LogType.info:
                            color = Colors.greenAccent;
                            break;
                        }
                        String time =
                            "${entry.timestamp.hour.toString().padLeft(2,'0')}:"
                            "${entry.timestamp.minute.toString().padLeft(2,'0')}:"
                            "${entry.timestamp.second.toString().padLeft(2,'0')}";
                        return Text(
                          "[$time] ${entry.message}",
                          style: TextStyle(fontFamily: 'monospace', color: color),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedOption,
              items: _options
                  .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedOption = value!);
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'IP Address',
                      hintText: 'e.g. 192.168.1.100',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 80,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Port',
                      hintText: '5000',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _bridge.isConnected ? _websocketCancel : _websocketConnect,
                    child: Text(_bridge.isConnected ? 'Cancel' : 'Connect'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _bridge.startNFCSession,
                    child: Text('Start NFC'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _websocketConnect() async {
    final port = _portController.text.trim();
    final ip = _ipController.text.trim();

    final fullIp = 'ws://$ip:${port.isEmpty ? '5000' : port}';
    _bridge.startWebSocket(fullIp);
    setState(() {

    });
  }

  void _websocketCancel() async {
    _bridge.cancelSessionWebSocket();
    setState(() {

    });
  }

  void _logTxt(String msg, LogType type){
    setState(() {
      _logList.add(LogEntry(msg, type));
    });
  }

  @override
  void dispose() {
    _bridge.dispose();
    _portController.dispose();
    _customIpController.dispose();
    super.dispose();
  }
}


enum LogType { info, warning, error }

class LogEntry {
  final String message;
  final LogType type;
  final DateTime timestamp;

  LogEntry(this.message, this.type) : timestamp = DateTime.now();
}

