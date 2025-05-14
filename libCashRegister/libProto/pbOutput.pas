unit pbOutput;


interface

uses Classes,
    SysUtils,
    StrBuffer,
    pbPublic;

type

    TProtoBufOutput = class;

    IpbMessage = interface
        function getSerializedSize: integer;
        procedure writeTo(buffer: TProtoBufOutput);
    end;

    TProtoBufOutput = class(TInterfacedObject, IpbMessage)
    private
        FBuffer: TSegmentBuffer;
        procedure DoWriteRawVarint32(const aValue: integer);
    public
        constructor Create;
        destructor Destroy; override;
        procedure SaveToStream(Stream: TStream);
        procedure SaveToFile(const FileName: string);
        procedure Clear;

    (* Encode and write varint. *)
        procedure writeRawVarint32(const value: integer);
    (* Encode and write varint. *)
        procedure writeRawVarint64(const aValue: int64);
    (* Encode and write tag. *)
        procedure writeTag(const fieldNumber: integer; const wireType: integer);
    (* Write the data with specified size. *)
        procedure writeRawDataPointer(const p: Pointer; const size: integer); overload;
        procedure writeRawData(const buf; const size: integer); overload;

    (* Get the result as a string *)
        function GetText: TBytes { AnsiString };
    (* Write a double field, including tag. *)
        procedure writeDouble(const fieldNumber: integer; const value: double);
    (* Write a single field, including tag. *)
        procedure writeFloat(const fieldNumber: integer; const value: single);
    (* Write a int64 field, including tag. *)
        procedure writeInt64(const fieldNumber: integer; const value: int64);
    (* Write a int64 field, including tag. *)
        procedure writeInt32(const fieldNumber: integer; const value: integer);
    (* Write a fixed64 field, including tag. *)
        procedure writeFixed64(const fieldNumber: integer; const value: int64);
    (* Write a fixed32 field, including tag. *)
        procedure writeFixed32(const fieldNumber: integer; const value: integer);
    (* Write a boolean field, including tag. *)
        procedure writeRawBoolean(const value: Boolean);
        procedure writeBoolean(const fieldNumber: integer; const value: Boolean);
    (* Write a string field, including tag. *)
        procedure writeString(const fieldNumber: integer; const value: string);
    { * Write a bytes field, including tag. * }
        procedure writeBytes(const fieldNumber: integer; const value: TBytes);
    (* Write a message field, including tag. *)
        procedure writeMessage(const fieldNumber: integer; const value: IpbMessage);
    (* Write a unsigned int32 field, including tag. *)
        procedure writeUInt32(const fieldNumber: integer; const value: cardinal);

        procedure writeRawSInt32(const value: integer);
        procedure writeRawSInt64(const value: int64);
        procedure writeSInt32(const fieldNumber: integer; const value: integer);
        procedure writeSInt64(const fieldNumber: integer; const value: int64);
    (* Get serialized size *)
        function getSerializedSize: integer;
    (* Write to buffer *)
        procedure writeTo(buffer: TProtoBufOutput);
    end;

function EncodeZigZag32(const A: LongInt): LongWord;
function EncodeZigZag64(const A: int64): UInt64;

implementation

{$R-}


// returns SInt32 encoded to LongWord using 'ZigZag' encoding
function EncodeZigZag32(const A: LongInt): LongWord;
var
    I: int64;
begin
    if A < 0 then
    begin
      // use Int64 value to negate A without overflow
        I := A;
        I := -I;
      // encode ZigZag
        Result := (LongWord(I) - 1) * 2 + 1
    end
    else
        Result := LongWord(A) * 2;
end;


// returns SInt64 encoded to UInt64 using 'ZigZag' encoding
function EncodeZigZag64(const A: int64): UInt64;
var
    I: UInt64;
begin
    if A < 0 then
    begin
      // use two's complement to negate A without overflow
        I := not A;
        Inc(I);
      // encode ZigZag
        Dec(I);
        I := I * 2;
        Inc(I);
        Result := I;
    end
    else
        Result := UInt64(A) * 2;
end;

{ TProtoBuf }


constructor TProtoBufOutput.Create;
begin
    FBuffer := TSegmentBuffer.Create;
    inherited Create;
end;


destructor TProtoBufOutput.Destroy;
begin
    FBuffer.Free;
    inherited Destroy;
end;


procedure TProtoBufOutput.Clear;
begin
    FBuffer.Clear;
end;


procedure TProtoBufOutput.writeRawBoolean(const value: Boolean);
var
    b: ShortInt;
begin
    b := ord(value);
    writeRawData(b, SizeOf(Byte));
end;


procedure TProtoBufOutput.writeRawData(const buf; const size: integer);
begin
    writeRawDataPointer(@buf, size);
end;


procedure TProtoBufOutput.writeRawSInt32(const value: integer);
begin
    writeRawVarint32(EncodeZigZag32(value));
end;


procedure TProtoBufOutput.writeRawSInt64(const value: int64);
begin
    writeRawVarint64(EncodeZigZag64(value));
end;


procedure TProtoBufOutput.writeRawDataPointer(const p: Pointer; const size: integer);
begin
    FBuffer.AddP(p, size);
end;


procedure TProtoBufOutput.writeTag(const fieldNumber: integer; const wireType: integer);
begin
    writeRawVarint32(makeTag(fieldNumber, wireType));
end;


procedure TProtoBufOutput.writeRawVarint32(const value: integer);
begin
    if value < 0 then
        writeRawVarint64(value)
    else
        DoWriteRawVarint32(value);
end;


procedure TProtoBufOutput.DoWriteRawVarint32(const aValue: integer);
var
    b: ShortInt;
    value: integer;
begin
    value := aValue;
    repeat
        b := value and $7F { 127 };
        value := value shr 7;
        if value <> 0 then
            b := b + $80 { 128 };
        writeRawData(b, SizeOf(ShortInt));
    until value = 0;
end;


procedure TProtoBufOutput.writeRawVarint64(const aValue: int64);
var
    b: ShortInt;
    value: integer;
begin
    value := aValue;
    repeat
        b := value and $7F;
        value := value shr 7;
        if value <> 0 then
            b := b + $80;
        writeRawData(b, SizeOf(ShortInt));
    until value = 0;
end;


procedure TProtoBufOutput.writeBoolean(const fieldNumber: integer; const value: Boolean);
begin
    writeTag(fieldNumber, WIRETYPE_VARINT);
    writeRawBoolean(value);
end;


procedure TProtoBufOutput.writeBytes(const fieldNumber: integer; const value: TBytes);
begin
    writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
    writeRawVarint32(length(value));
    if length(value) > 0 then
        writeRawData(value[0], length(value));
end;


procedure TProtoBufOutput.writeDouble(const fieldNumber: integer; const value: double);
begin
    writeTag(fieldNumber, WIRETYPE_FIXED64);
    writeRawDataPointer(@value, SizeOf(value));
end;


procedure TProtoBufOutput.writeFloat(const fieldNumber: integer; const value: single);
begin
    writeTag(fieldNumber, WIRETYPE_FIXED32);
    writeRawDataPointer(@value, SizeOf(value));
end;


procedure TProtoBufOutput.writeFixed32(const fieldNumber: integer; const value: integer);
begin
    writeTag(fieldNumber, WIRETYPE_FIXED32);
    writeRawDataPointer(@value, SizeOf(value));
end;


procedure TProtoBufOutput.writeFixed64(const fieldNumber: integer; const value: int64);
begin
    writeTag(fieldNumber, WIRETYPE_FIXED64);
    writeRawDataPointer(@value, SizeOf(value));
end;


procedure TProtoBufOutput.writeInt32(const fieldNumber: integer; const value: integer);
begin
    writeTag(fieldNumber, WIRETYPE_VARINT);
    writeRawVarint32(value);
end;


procedure TProtoBufOutput.writeInt64(const fieldNumber: integer; const value: int64);
begin
    writeTag(fieldNumber, WIRETYPE_VARINT);
    writeRawVarint64(value);
end;


procedure TProtoBufOutput.writeSInt32(const fieldNumber: integer; const value: integer);
begin
    writeTag(fieldNumber, WIRETYPE_VARINT);
    writeRawSInt32(value);
end;


procedure TProtoBufOutput.writeSInt64(const fieldNumber: integer; const value: int64);
begin
    writeTag(fieldNumber, WIRETYPE_VARINT);
    writeRawSInt64(value);
end;


procedure TProtoBufOutput.writeString(const fieldNumber: integer; const value: string);
var
    buf: TBytes;
begin
    writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
    buf := TEncoding.UTF8.GetBytes(value);
    writeRawVarint32(length(buf));
    if length(buf) > 0 then
        writeRawData(buf[0], length(buf));
end;


procedure TProtoBufOutput.writeUInt32(const fieldNumber: integer; const value: cardinal);
begin
    writeTag(fieldNumber, WIRETYPE_VARINT);
    writeRawVarint32(value);
end;


procedure TProtoBufOutput.writeMessage(const fieldNumber: integer; const value: IpbMessage);
begin
    writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
    writeRawVarint32(value.getSerializedSize());
    value.writeTo(self);
end;


function TProtoBufOutput.GetText: TBytes { AnsiString };
begin
    Result := FBuffer.GetText;
end;


procedure TProtoBufOutput.SaveToFile(const FileName: string);
begin
    FBuffer.SaveToFile(FileName);
end;


procedure TProtoBufOutput.SaveToStream(Stream: TStream);
begin
    FBuffer.SaveToStream(Stream);
end;


function TProtoBufOutput.getSerializedSize: integer;
begin
    Result := FBuffer.GetCount;
end;


procedure TProtoBufOutput.writeTo(buffer: TProtoBufOutput);
begin
    buffer.FBuffer.AddS(GetText);
end;

end.


