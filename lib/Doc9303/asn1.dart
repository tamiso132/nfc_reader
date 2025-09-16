part of 'cmd.dart';

// omg there is a protocol for OID


class AsnBuilder{
  AsnBuilder addCustomTag(int tag, Uint8List packetData){
    Uint8List packet = Uint8List.fromList([tag & 0xFF,packetData.length];
    packet.addAll(packetData);

    _data.addAll(packet);

    return this;
  }

  AsnBuilder addTag(TagID tag, Uint8List packetData){
    return addCustomTag(tag.id, packetData);
  }

  Uint8List build(){
    return Uint8List.fromList(_data);
  }


  final List<int> _data = [];
}

class AsnFind{
  AsnFind(this._topLevelNodes);

  List<AsnNode> filter(TagID id){
    List<AsnNode> matched = [];

    for(AsnNode node in _topLevelNodes){

      if(node.tag == id){
        matched.add(node);
      }
    }
    return matched;
  }
  List<AsnNode> getAllNodes(){
    return _topLevelNodes;
  }

  final List<AsnNode> _topLevelNodes;
}

class AsnNode {
  final TagID tag;
  final Uint8List? value;
  final List<AsnNode> children;

  AsnNode(this.tag, {this.value, List<AsnNode>? children}) : children = children ?? [];

   List<AsnNode> filter(TagID id){
     List<AsnNode> matched= [];
    for(AsnNode child in children){
      if(child.tag == id){
        matched.add(child);
      }
    }
    return matched;

  }

  AsnNode getChildNode(int i){
     if(children.length > i){
       return children[i];
     }
     throw Exception("Accessing non existing child node");
  }

  List<int> getValueAsOID(){
     return value!;
  }

  // Big endian implementation, might need to be little endian. dunno
  int getValueAsInt(){
     int ret = 0;
     for(int i = 0; i < value!.length; i++){
        ret |= value![i] << (8 * (value!.length - 1 - i));
     }
     return ret;
  }





  static AsnFind _parse(ByteReader reader)
  {
    List<AsnNode> nodes = [];
    while (reader.hasRemaining()) {
      AsnInfo asnInfo = reader.readASN1(); // reads tag, length, value bytes

      TagID tag = asnInfo.tag;

      if (tag == TagID.sequence || tag == TagID.set) {
        ByteReader innerReader = ByteReader(asnInfo.data);
        List<AsnNode> children = [];

        while (innerReader.hasRemaining()) {
          children.addAll(AsnNode._parse(innerReader).getAllNodes());
        }

        nodes.add(AsnNode(tag, children: children));
      } else {
        // Primitive type: store value
        nodes.add(AsnNode(tag, value: asnInfo.data));
      }
    }

    return AsnFind(nodes);
  }

  void printTree([int indent = 0]) {
    final prefix = '  ' * indent;
    if (children.isNotEmpty) {
      print('$prefix${tag.tagName} (constructed)');
      for (var child in children) {
        child.printTree(indent + 1);
      }
    } else if(value != null) {
      switch (tag) {
        case TagID.integer:
          int intValue = 0;
          for (var b in value!) {
            intValue = (intValue << 8) | b;
          }
          print('$prefix${tag.tagName}: $intValue');
          break;

        case TagID.octetString:
          print('$prefix${tag.tagName}: ${value!.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          break;

        case TagID.objectIdentifier:
          print('$prefix${tag.tagName}: ${decodeOid(value!)}');
          break;

        case TagID.boolean:
          print('$prefix${tag.tagName}: ${value![0] != 0}');
          break;

        default:
          print('$prefix${tag.tagName}: ${value!.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          break;
      }
    }
    else{
      print('$prefix${tag.tagName}: <empty>');
    }
  }
}