// OFFICIAL
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

// USER Libs
import "nfc_comm.dart" as nfc;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NfcExample(),
    );
  }
}

class NfcExample extends StatefulWidget {
  @override
  NfcExampleState createState() => NfcExampleState();
}

enum NfcState{
  startNFC("Start NFC Scan"),
  closeNFC("Stop NFC Scan");
  //hhtchtch

  final String label;
  const NfcState(this.label);
}

class NfcExampleState extends State<NfcExample> {

  NfcState _nfcState = NfcState.startNFC;


  void _startNfcSession() async{
    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (tag) async{
        NfcAAndroid? nfc = NfcAAndroid.from(tag); // passport protocol
        if(nfc!= null) {
          //TODO Begin handshake protocol
         // var response = await nfc.transceive();
        }
        else {
          // TODO, invalid tag type
        }

        await NfcManager.instance.stopSession();
      },
      alertMessageIos: "Hold your device near the NFC tag",
    );

  }

  void _stopNfcSession() async{
    NfcManager.instance.stopSession();


  }

  void _onPress() async{

      switch(_nfcState){
        case NfcState.startNFC:
          _startNfcSession();
          _nfcState = NfcState.closeNFC;
          break;
        case NfcState.closeNFC:
          _stopNfcSession();
          _nfcState = NfcState.startNFC;
          break;
      }
      // rebuild ui
      //Testter
      setState(() {
      });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NFC Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                _onPress();
              },
              child: Text(_nfcState.label),
            ),
          ],
        ),
      ),
    );
  }
}
