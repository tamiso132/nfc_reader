
part of 'cmd.dart';

// FORMAT,  birth/Expire: YYMMDD
String getMrz(String docNr, String birth, String dateExpire){
  while(docNr.length < 9){
    docNr += "<";
  }

  String fullStr = "";
  fullStr += docNr + getCheckDigit(docNr);
  fullStr += getCheckDigit(docNr);
  fullStr += birth + getCheckDigit(birth);
  fullStr += dateExpire + getCheckDigit(dateExpire);

  return fullStr;
}

String getCheckDigit(String s){

  List<int> lookupWeight = [7, 3, 1];
  int lookupIndex = 0;
  int sum = 0;
  for(final c in s.toLowerCase().characters){
  int asciCode = c.codeUnitAt(0);

   if(asciCode >= 48 && asciCode <= 57){ // 0-9
     sum += int.parse(c) * lookupWeight[lookupIndex];
   }
   else if(asciCode >= 97 && asciCode <= 122) {// a-z{
     sum += (asciCode - 87) * lookupWeight[lookupIndex];

   }
   else if(c != '<'){
      throw Exception("Illegal character for check digit");
   }


    lookupIndex += 1;
    lookupIndex %= 3;
  }

  return (sum % 10).toString();

}

void printUint8List(Uint8List bytes) {
  final hexString = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  print(hexString);
}

String decodeOid(Uint8List bytes) {
  if (bytes.isEmpty) return '';

  final buffer = StringBuffer();
  int first = bytes[0] ~/ 40;
  int second = bytes[0] % 40;
  buffer.write('$first.$second');

  int value = 0;
  for (int i = 1; i < bytes.length; i++) {
    int b = bytes[i];
    value = (value << 7) | (b & 0x7F);
    if ((b & 0x80) == 0) { // end of subidentifier
      buffer.write('.$value');
      value = 0;
    }
  }

  return buffer.toString();
}

// TODO, write tests
class AsnInfo{
  AsnInfo(this.tag, this.data);

  TagID tag;
  Uint8List data;
}

class ByteReader{

  ByteReader(this._data){
    offset = 0;
  }

  Uint8List readBytes(int len){
    final sublist = _data.sublist(offset, offset + len);
    offset += len;
    return sublist;
  }

  int readInt(int len){
   Uint8List list =  readBytes(len);
   int ret = 0;
   for(int i = 0; i < list.length; i++){
     ret  |= list[i] << ((list.length - i - 1) * 8);
   }
   return ret;
  }

  String readString(int len){
    String s = String.fromCharCodes(_data.sublist(offset, offset + len));
    offset += len;
    return s;
  }
  void paddingNext(int len){
    offset += len;
  }

  /// Är det fler bytes kvar?
  bool hasRemaining() {
    return offset < _data.length;
  }

  /// Läs BER/DER length-fält
  int readLength() {
    int first = readInt(1);
    if (first < 0x80) {
      return first;
    }
    int numBytes = first & 0x7F;
    return readInt(numBytes);
  }

  AsnInfo readASN1(){
    TagID tag = TagID.fromInt(readInt(1));
    int len = readLength();
    Uint8List data = readBytes(len);

    return AsnInfo(tag, data);
  }

  Uint8List _data;
  late int offset;
}

// --- Hex Encoding and Decoding ---

/// Encodes a [Uint8List] into a hexadecimal string.
String hexEncode(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    // b.toRadixString(16) might produce "f" for 15. padLeft ensures "0f".
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Decodes a hexadecimal string into a [Uint8List].

Uint8List hexDecode(String hexString) {
  if (hexString.length % 2 != 0) {
    throw FormatException("Hex string must have an even number of characters.", hexString);
  }

  final result = Uint8List(hexString.length ~/ 2);
  for (int i = 0; i < hexString.length; i += 2) {
    final hexPair = hexString.substring(i, i + 2);
    final byteValue = int.tryParse(hexPair, radix: 16);
    if (byteValue == null) {
      throw FormatException("Invalid hex character found in string.", hexPair, i);
    }
    result[i ~/ 2] = byteValue;
  }
  return result;
}
