unit uEncoding;

interface

Function doXOR(const Value: String; const password: String): String;
function BytesToHex(const Value: TArray<Byte>): string;
function StrToHex(const Value: string): string;
function HexToStr(const Value: string): string;
function EncodePassword(const Value: string): string;
function DecodePassword(const Value: string): string;
function EncryptString(const CipherPassword: string; const Value: string): string;
function DecryptString(const CipherPassword: string; const Value: string): string;

implementation

uses
    utplb_Codec,
    uTPLb_CryptographicLibrary,
    uTPLb_Constants,
    System.SysUtils,
    System.NetEncoding;


function EncryptString(const CipherPassword: string; const Value: string): string;
var
    EL: Exception;
begin
    Result := '';
    var
    Codec := TCodec.Create(nil);
    var
    CryptographicLibrary := TCryptographicLibrary.Create(nil);
    try
        Codec.CryptoLibrary := CryptographicLibrary;
        Codec.StreamCipherId := uTPLb_Constants.BlockCipher_ProgId;
        Codec.BlockCipherId := 'native.AES-256';
        Codec.ChainModeId := uTPLb_Constants.CBC_ProgId;
        Codec.password := DecodePassword(CipherPassword);
        Codec.EncryptString(Value, Result, TEncoding.UTF8);
    except
        Codec.Free;
        CryptographicLibrary.Free;
        raise;
    end;
    Codec.Free;
    CryptographicLibrary.Free;
end;


function DecryptString(const CipherPassword: string; const Value: string): string;
begin
    var
    Codec := TCodec.Create(nil);
    var
    CryptographicLibrary := TCryptographicLibrary.Create(nil);
    try
        Codec.CryptoLibrary := CryptographicLibrary;
        Codec.StreamCipherId := uTPLb_Constants.BlockCipher_ProgId;
        Codec.BlockCipherId := 'native.AES-256';
        Codec.ChainModeId := uTPLb_Constants.CBC_ProgId;
        Codec.password := DecodePassword(CipherPassword);
        Codec.DecryptString(Result, Value, TEncoding.UTF8);
    except
        Codec.Free;
        CryptographicLibrary.Free;
        raise;
    end;
    Codec.Free;
    CryptographicLibrary.Free;
end;


Function doXOR(const Value: String; const password: String): String;
Var
    N, i: integer;
Begin
    Result := Value;
    N := 1;
    For i := 1 to Length(Result) do
    Begin
        Result[i] := chr(Ord(Result[i]) xor Ord(password[N]));
        If N < Length(password) then
            N := N + 1
        else
            N := 1;
    End;
End;


function BytesToHex(const Value: TArray<Byte>): string;
begin
    Result := '';
    for var B in Value do
        Result := Result + IntToHex(B);
end;


function StrToHex(const Value: string): string;
begin
// кажется, эти функции некорректно работают с кириллицей (Unicode / UTF8)
    Result := '';
    for var B in BytesOf(Value) do
        Result := Result + IntToHex(B);
end;


function HexToStr(const Value: string): string;
begin
// кажется, эти функции некорректно работают с кириллицей (Unicode / UTF8 ?)
    var
    src := Value;
    Result := '';
    while src.Length >= 2 do
    begin
        Result := Result + chr(StrToInt('$' + src.Substring(0, 2)));
        src := src.Substring(2);
    end;
    Result := Result;
end;


function EncodePassword(const Value: string): string;
begin
    Result := StrToHex(TNetEncoding.Base64.Encode(Value));
end;


function DecodePassword(const Value: string): string;
begin
    Result := TNetEncoding.Base64.Decode(HexToStr(Value));
end;

end.
