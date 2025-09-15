part of 'cmd.dart';

// omg there is a protocol for OID
class AsnNode {
  final TagID tag;
  final Uint8List? value;
  final List<AsnNode>? children;

  AsnNode(this.tag, {this.value, this.children});

  // Parses a single ASN.1 element from the reader
  static List<AsnNode> parse(ByteReader reader)
  {
    List<AsnNode> nodes = [];
    while (reader.hasRemaining()) {
      AsnInfo asnInfo = reader.readASN1(); // reads tag, length, value bytes

      TagID tag = asnInfo.tag;

      if (tag == TagID.sequence || tag == TagID.set) {

        ByteReader innerReader = ByteReader(asnInfo.data);
        List<AsnNode> children = [];

        while (innerReader.hasRemaining()) {
          children.addAll(AsnNode.parse(innerReader));
        }

        nodes.add(AsnNode(tag, children: children));
      } else {
        // Primitive type: store value
        nodes.add(AsnNode(tag, value: asnInfo.data));
      }
    }
    return nodes;
  }

  void printTree([int indent = 0]) {
    final prefix = '  ' * indent;
    if (children != null && children!.isNotEmpty) {
      print('$prefix${tag.tagName} (constructed)');
      for (var child in children!) {
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