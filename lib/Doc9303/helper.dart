
part of 'cmd.dart';

// TODO, write tests
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

  Uint8List _data;
  late int offset;
}