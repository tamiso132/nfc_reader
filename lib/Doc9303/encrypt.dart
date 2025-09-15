part of "cmd.dart";

List<String> _splitOnId(String input) {
  List<String> results = [];
  int index = 0;

  while (index < input.length) {
    int start = input.indexOf('id-', index);
    if (start == -1) break;

    int nextStart = input.indexOf('id-', start + 1);

    if (nextStart == -1) {
      // This is the last item
      results.add(input.substring(start));
      break;
    } else {
      results.add(input.substring(start, nextStart));
      index = nextStart;
    }
  }

  return results;
}

class KeyEncryption{
    late KeyAgreement agreementType;
    late List<EncryptType> encryptType;

    fromObjectIdentifier(String paceProtocol){
paceProtocol.allMatches(string)
    }
}

class EncryptType{
  late CipherEncryption cipherEncrypt;
  late List<MacType> macType;
}

enum EncryptLength{
  len128,
  len192,
  len256
}

// TODO, function that depends on KeyAgreementType
enum KeyAgreement
{
  dh, // diffie-hellman
  ecDh, // eclipse curve diffe hellman
}

// TODO, function that depends on ciper encryption type
enum CipherEncryption
{
  aes,
  e3des,

}
// TODO, function that depends on mac type
enum MacType{
  cbc, // cbc-mac algoritm
  cMac, // CMac
}