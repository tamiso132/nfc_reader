part of "cmd.dart";

String toHex(int value, {int width = 2}) {
  return "${value.toRadixString(16).toUpperCase().padLeft(width, '0')}";
}

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

enum AppID{
  idLSD_1([0xA0, 0x00, 0x00, 02, 0x47, 0x10, 0x01]);

  final List<int> _id;
  const AppID(this._id);

  Uint8List getID(){
    return Uint8List.fromList(_id);
  }

}

abstract class IEfID{
  int get shortID;
  Uint8List getFullID();

  AppID? appIdentifier();
}



enum EfIdGlobal implements IEfID {
  cardAccess(0x1C, [0x01, 0x1C]),
  cardSecurity(0x1D,  [0x01, 0x1D]),
  atrInfo(0x01, [0x2F, 0x01]),
  dir(0x1E, [0x2F, 0x00]);

  final int _shortId;
  final List<int> _fullID;

  const EfIdGlobal(this._shortId, this._fullID);

  @override
  Uint8List getFullID(){
    return Uint8List.fromList(_fullID);
  }

  @override
  int get shortID => _shortId;

  @override
  AppID? appIdentifier() {
    return null;
  }
}


/*
Id for files that are for LDS1 application
*/
enum EfIdAppSpecific implements IEfID {
  com(0x1E, [0x01, 0x1E]),
  dg1(0x01, [0x01, 0x01]),
  dg2(0x02, [0x01, 0x02]),
  dg3(0x03, [0x01, 0x03]),
  dg4(0x04, [0x01, 0x04]),
  dg5(0x05, [0x01, 0x05]),
  dg6(0x06, [0x01, 0x06]),
  dg7(0x07, [0x01, 0x07]),
  dg8(0x08, [0x01, 0x08]),
  dg9(0x09, [0x01, 0x09]),
  dg10(0x0A, [0x01, 0x0A]),
  dg11(0x0B, [0x01, 0x0B]),
  dg12(0x0C, [0x01, 0x0C]),
  dg13(0x0D, [0x01, 0x0D]),
  dg14(0x0E, [0x01, 0x0E]),
  dg15(0x0F, [0x01, 0x0F]),
  dg16(0x10, [0x01, 0x10]),
  sod(0x1D, [0x01, 0x1D]);

  final int _shortId;
  final List<int> _fullID;
  const EfIdAppSpecific(this._shortId, this._fullID);

  @override
  Uint8List getFullID(){
    return Uint8List.fromList(_fullID);
  }

  @override
  int get shortID => _shortId;

  @override
  AppID? appIdentifier() {
    return AppID.idLSD_1;
  }
}

/*
Response Structure
*/
class ResponseCommand{

  ResponseCommand(this.sw1, this.sw2, {this.data}) {
    print("SW: 0x${toHex(sw1)}${toHex(sw2)}");
    int data_len = 0;
    if(this.data != null) {
      data_len = this.data!.length;
    }
    print("Data len: 0x${toHex(data_len)}");
    print("");

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


class _CommandPackage{

  _CommandPackage(this.cla, this.ins, this.p1, this.p2, {this.data, this.le});

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
// TODO, document what the different variables mean
  int cla = 0;
  int ins = 0;
  int p1 = 0;
  int p2 = 0;
  Uint8List? data;
  int? le;
}

