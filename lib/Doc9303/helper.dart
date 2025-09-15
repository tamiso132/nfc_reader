
part of 'cmd.dart';

// TODO, write tests
class AsnInfo{
  AsnInfo(this.tag, this.data);

  int tag;
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
    int tag = readInt(1);
    int len = readLength();
    Uint8List data = readBytes(len);

    return AsnInfo(tag, data);
  }

  Uint8List _data;
  late int offset;
}