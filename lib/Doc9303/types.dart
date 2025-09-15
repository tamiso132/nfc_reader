part of "cmd.dart";

String toHex(int value, {int width = 2}) {
  return "${value.toRadixString(16).toUpperCase().padLeft(width, '0')}";
}

enum SwStatus {success(0x90, 0x00, "Command successful."),
  moreDataAvailable(0x61, -1, "More data available. Use GET RESPONSE."), // SW2 is length
  warningNvMemoryUnchanged(0x62, -1, "Warning (NV memory unchanged)."), // SW2 is specific
  warningNvMemoryChanged(0x63, -1, "Warning (NV memory changed)."),   // SW2 is specific
  wrongRespLen(0x67, 0x00, "Error: Wrong length in Le field."),
  funcInClaNotSupported(0x68, 0x00, "Error: Function in CLA not supported."), // Can be generic for 0x68xx
  securityNotSatisfied(0x69, 0x82, "Error: Security status not satisfied."),
  authMethodBlocked(0x69, 0x83, "Error: Authentication method blocked."),
  referencedDataInvalidated(0x69, 0x84, "Error: Referenced data invalidated."),
  conditionsOfUseNotSatisfied(0x69, 0x85, "Error: Conditions of use not satisfied."),
  commandNotAllowedNoEfSelected(0x69, 0x86, "Error: Command not allowed or no EF selected."),
  // Generic 69xx if not more specific
  commandNotAllowedGeneric(0x69, -1, "Error: Command not allowed (generic)."),
  fileNotFound(0x6A, 0x82, "Error: File or application not found."),
  recordNotFound(0x6A, 0x83, "Error: Record not found."),
  notEnoughMemory(0x6A, 0x84, "Error: Not enough memory in file."),
  lcInconsistentP1P2(0x6A, 0x85, "Error: Lc inconsistent with P1-P2."),
  incorrectParameterP1P2(0x6A, 0x86, "Error: Incorrect P1 or P2 parameters."),
  lcInconsistentTlv(0x6A, 0x87, "Error: Lc inconsistent with TLV structure."),
  dataInvalid(0x6A, 0x88, "Error: Referenced data not usable."),
  funcNotSupportedByCard(0x6A, 0x81, "Error: Function not supported by card."),
  // Generic 6Axx if not more specific
  incorrectParameterGeneric(0x6A, -1, "Error: Incorrect parameters P1-P2 (generic)."),
  instructionNotSupported(0x6D, 0x00, "Error: Instruction code not supported or invalid."),
  classNotSupported(0x6E, 0x00, "Error: Class not supported."),
  commandAborted(0x6F, 0x00, "Error: No precise diagnosis (command aborted)."),
  cardDead(0x6F, 0xFF, "Error: Card seems dead or unresponsive."), // Example for a very specific 6FFF
  unknown(-1, -1, "Unknown status."); // Default/fallback

  final int sw1Value;
  final int sw2Value; // Use -1 if SW2 is variable or not part of the primary status code
  final String message;

  const SwStatus(this.sw1Value, this.sw2Value, this.message);

  /// Create SwStatus from combined SW1,SW2 int value
  factory SwStatus.fromCombInt(int combinedCode) {
    int sw1 = (combinedCode >> 8) & 0xFF;
    int sw2 = combinedCode & 0xFF;
    return SwStatus.fromSw1Sw2(sw1, sw2);
  }
  /// Creates an SwStatus from separate SW1 and SW2 integer values.
  static SwStatus fromSw1Sw2(int sw1, int sw2) {
    // Check for exact SW1 and SW2 matches first
    for (final status in SwStatus.values) {
      if (status.sw1Value == sw1 && status.sw2Value == sw2) {
        return status;
      }
    }

    // Check for SW1 group matches where SW2 is variable or needs special handling
    // (like 0x61xx where xx is length, or 0x62xx/0x63xx for warnings)
    if (sw1 == SwStatus.moreDataAvailable.sw1Value) { // 0x61
      return SwStatus.moreDataAvailable; // SW2 is the length, not part of the status itself
    }
    if (sw1 == SwStatus.warningNvMemoryUnchanged.sw1Value) { // 0x62
      // You could create more specific warning enums if needed, or just return the generic
      return SwStatus.warningNvMemoryUnchanged;
    }
    if (sw1 == SwStatus.warningNvMemoryChanged.sw1Value) { // 0x63
      return SwStatus.warningNvMemoryChanged;
    }

    // Check for generic SW1 matches where a specific SW2 wasn't found above
    for (final status in SwStatus.values) {
      if (status.sw1Value == sw1 && status.sw2Value == -1) { // -1 indicates generic for that SW1
        // Check if there's a more specific SW1 match already (avoid overriding success by mistake)
        if (sw1 == 0x90 && sw2 == 0x00) return SwStatus.success; // Ensure success is not overridden
        return status;
      }
    }


    // If no match is found, return unknown
    // You might want to log the unknown code here as well
    print('Warning: Unknown SW code encountered: SW1=0x${toHex(sw1)}, SW2=0x${toHex(sw2)}');
    return SwStatus.unknown;
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
class ResponseCommand {
  final int sw1;
  final int sw2;
  final Uint8List? data;
  final SwStatus status; // Final field

  // Initialize 'status' in the initializer list
  ResponseCommand(this.sw1, this.sw2, {this.data})
      : status = SwStatus.fromSw1Sw2(sw1, sw2) {
    print("SW: 0x${toHex(sw1)}${toHex(sw2)} (${status.message})");
    int data_len = 0;
    if (this.data != null) {
      data_len = this.data!.length;
    }
    print("Data len: ${data_len} (0x${toHex(
        data_len, width: data_len > 0xFF ? 4 : 2)})");
    if (data_len > 0 &&
        this.data != null) { // Added null check for data before take()
      // Optionally print a snippet of the data for debugging
      // print("Data: ${this.data!.take(16).map((b) => toHex(b)).join(' ')}...");
    }
    print("");
  }
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
  int cla = 0; //Class byte of the command, (0x00 basic industry command no secure messaging. 0xC0 if secure messaging in line with ISO 7816-4
  int ins = 0; // Instruction byte. Chose operation
  int p1 = 0; // Parameter bytes 1 & 2, qualify the instruction
  int p2 = 0;
  Uint8List? data; // Optional command data field
  int? le; //Optional expected length of data in response (00 = max, 256 = short, 65536 = extended)
}

