unit uUtils;

{$I defines.inc}

interface

uses
    IdStack,
{$IFDEF MSWINDOWS}
    Winapi.IpHlpApi, Winapi.IpTypes, Winapi.Windows,
{$ENDIF}
{$IFDEF LINUX}
    Posix.Base,
    Posix.Fcntl,
{$ENDIF}
    System.Classes,
    System.Variants,
    System.SysUtils,
    System.DateUtils,
    System.Generics.Collections,
    System.Net.HttpClient,
    System.Net.URLClient,
    IdHashMessageDigest,
    uTypes,
    XSuperObject;

const
    DefaultConnectionTimeout = 5 * 1000;  // milliseconds (5 seconds)
    DefaultResponseTimeout   = 20 * 1000; // milliseconds (20 seconds)

type
    THTTPRequestHeaders = System.Generics.Collections.TDictionary<String, String>;

type
    THTTPRequestParams = System.Generics.Collections.TDictionary<String, Variant>;

type
    THTTPResponseHeaders = TArray<TPair<string, string>>;

type
    TCustomHTTPResponse = record
        Status_Code: integer;
        Status_Text: string;
        Headers: THTTPResponseHeaders;
        Response_Body: string;
    end;

type
    TCustomHTTPResponseHeaders = record
        Status_Code: integer;
        Status_Text: string;
        Headers: THTTPResponseHeaders;
    end;

type
    THTTPRequestMethod = (rmGET, rmPOST);

type
    TMyHTTPClient = class
    private
        FClient: System.Net.THTTPClient;
        function GetConnectionTimeout: integer;
        procedure SetConnectionTimeout(const Value: integer);
        function GetResponseTimeout: integer;
        procedure SetResponseTimeout(const Value: integer);
    public
        Method: THTTPRequestMethod;
        URL: string;
        RequestHeaders: THTTPRequestHeaders;
        RequestParams: THTTPRequestParams;
        RequestBody: string;
        Proxy: TProxyRecord;
        constructor Create(const aURL: string; const aMethod: THTTPRequestMethod = THTTPRequestMethod.rmPOST);
        function Send(ADestStream: TStream; const aURL: string = ''; aReceiveDataCallback: TReceiveDataCallback = nil; const FreeOnFinish: boolean = true): TCustomHTTPResponseHeaders; overload;
        function Send(const aURL: string = ''; aReceiveDataCallback: TReceiveDataCallback = nil; const FreeOnFinish: boolean = true): TCustomHTTPResponse; overload;
        procedure Send(var Result: TCustomHTTPResponse; aReceiveDataCallback: TReceiveDataCallback = nil; const FreeOnFinish: boolean = true); overload;
        procedure doOnValidateServerCertificate(const Sender: TObject; const ARequest: TURLRequest; const Certificate: TCertificate; var Accepted: boolean);
        destructor Destroy;
        procedure Free;
        property ConnectionTimeout: integer read GetConnectionTimeout write SetConnectionTimeout;
        property ResponseTimeout: integer read GetResponseTimeout write SetResponseTimeout;
    end;

type
    TDownloadProgressCallbackProc = reference to procedure(const Sender: TObject; AContentLength: int64; AReadCount: int64; var Abort: boolean);

function CurrentFormatSettings: TFormatSettings;

type
    PlatformVersionInt = (pvAndroid, pvAndroid64, pvIOS, pvMACOS, pvMSWINDOWS, pvLINUX);

const
    PlatformVersionStr: TArray<string> = ['ANDROID', 'ANDROID64', 'IOS', 'MACOS', 'MSWINDOWS', 'LINUX'];

function GetWorkDirectory(const isPublic: boolean = false): string;

function StrInArrayI(const src: string; const StringArray: TArray<string>; const CaseSensitive: boolean = true; const From: integer = 0): integer;
function StrInArrayB(const src: string; const StringArray: TArray<string>; const CaseSensitive: boolean = true; const From: integer = 0): boolean;
function IntInArrayI(const src: int64; const IntArray: TArray<int64>; const From: integer = 0): integer;
function IntInArrayB(const src: int64; const IntArray: TArray<int64>; const From: integer = 0): boolean;

function MD5(const Source: string): string; overload;
function MD5(Buf: Pointer; const BufSize: integer): string; overload;

function GetPlatformVersion: TArray<PlatformVersionInt>;
function GetPlatformVersionStr: TArray<string>;

procedure DoSync(proc: TThreadProcedure);

function GetEndOfDate(const Value: TDateTime): TDateTime;

function GetTimestamp(const AValue: System.TDateTime = 0): int64;

Function GetExceptionMessage(E: Exception): string;

function Exc(const AValue: integer): Exception;

function CompressString(const aText: string): string;
function DeCompressString(const aText: string): string;

function GetMacAddressList: TStringList;

var
    FGUID: string = '';
    FHostIP: string = '';
    FAddressList: TArray<String> = [];

implementation

uses
    idGlobal,
    System.IOUtils,
    System.ZLib,
    System.NetEncoding;

var
    callback_proc: TDownloadProgressCallbackProc = nil;


procedure ClearMacList(AValue: TStringList);
const
    EmptyMacAddressList: TArray<String> = ['00:00:00:00:00:00', 'FF:FF:FF:FF:FF:FF'];
begin
    for var MAC IN EmptyMacAddressList do
        try
            var
            index := AValue.IndexOf(MAC);
            if index <> -1 then
                AValue.Delete(Index);
        except
        end;
end;

{$IFDEF LINUX}

type
    TStreamHandle = Pointer;

function popen(const Command: MarshaledAString; const _type: MarshaledAString): TStreamHandle; cdecl; external libc name _PU + 'popen';
function pclose(FileHandle: TStreamHandle): int32; cdecl; external libc name _PU + 'pclose';
function fgets(Buffer: Pointer; Size: int32; Stream: TStreamHandle): Pointer; cdecl; external libc name _PU + 'fgets';


function BufferToString(Buffer: Pointer; MaxSize: uint32): string;
var
    cursor: ^uint8;
    EndOfBuffer: nativeuint;
begin
    Result := '';
    if not Assigned(Buffer) then
        exit;
    cursor := Buffer;
    EndOfBuffer := nativeuint(cursor) + MaxSize;
    while (nativeuint(cursor) < EndOfBuffer) and (cursor^ <> 0) do
    begin
        Result := Result + chr(cursor^);
        cursor := Pointer(succ(nativeuint(cursor)));
    end;
end;


function ExecuteCommand(const AValue: PAnsiChar): TStringList;
var
    Data: array [0 .. 511] of uint8;
begin
    Result := TStringList.Create;
    try
        var
        Handle := popen(AValue, 'r');
        try
            while fgets(@Data[0], SizeOf(Data), Handle) <> nil do
            begin
                var
                s := BufferToString(@Data[0], SizeOf(Data)).Trim;
                if Result.IndexOf(s) = -1 then
                    Result.Add(s);
            end;
        finally
            pclose(Handle);
        end;
    except
// on E: Exception do
// WriteLog(Format('[%s] %s', [E.ClassName, E.Message]), ltError);
    end;
end;


function GetMacAddressList: TStringList;
begin
    Result := ExecuteCommand('cat /sys/class/net/*/address');
    for var i := 0 to Result.Count - 1 do
        Result.Strings[i] := Result.Strings[i].ToUpper;
    ClearMacList(Result);
end;

{$ENDIF LINUX} //

{$IFDEF MSWINDOWS}


function GetMacAddressList: TStringList;
var
    NumInterfaces: Cardinal;
    Adapters: array of TIpAdapterInfo;
begin
    Result := TStringList.Create;

    try
        GetNumberOfInterfaces(NumInterfaces);
        SetLength(Adapters, NumInterfaces);
        var
        outBufLen := NumInterfaces * SizeOf(TIpAdapterInfo);
        GetAdaptersInfo(@Adapters[0], outBufLen);

        for var adapter IN Adapters do
            if adapter.AddressLength > 0 then
            begin
                var
                MAC := '';

                for var i := 0 to adapter.AddressLength - 1 do
                    MAC := Format('%s:%.2x', [MAC, adapter.address[i]]);
                MAC := MAC.Trim([':']).ToUpper;

                if Result.IndexOf(MAC) = -1 then
                    Result.Add(MAC);
            end;
    except
    end;

    ClearMacList(Result);
end;

{$ENDIF MSWINDOWS}


function CompressString(const aText: string): string;
begin
    Result := '';
    var
    Bytes := TEncoding.UTF8.GetBytes(aText);
    var
    LStream := TMemoryStream.Create;
    try
        var
        Compressor := TCompressionStream.Create(clMax, LStream);
        try
            Compressor.Write(Bytes[0], Length(Bytes));
        finally
            Compressor.Free;
        end;
        SetLength(Bytes, 0);
        SetLength(Bytes, LStream.Size);
        LStream.Position := 0;
        LStream.Read(Bytes, LStream.Size);
        Result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
    finally
        LStream.Free;
    end;
end;


function DeCompressString(const aText: string): string;
begin
    Result := '';
    var
    LStream := TMemoryStream.Create;
    try
        var
        Bytes := TNetEncoding.Base64.DecodeStringToBytes(aText);
        LStream.Write(Bytes[0], Length(Bytes));
        SetLength(Bytes, 0);
        LStream.Position := 0;
        var
        DeCompressor := TDecompressionStream.Create(LStream);
        try
            SetLength(Bytes, DeCompressor.Size);
            DeCompressor.Read(Bytes, Length(Bytes));
            Result := TEncoding.UTF8.GetString(Bytes);
        finally
            DeCompressor.Free;
        end;
    finally
        LStream.Free;
    end;
end;


function Exc(const AValue: integer): Exception;
begin
    Result := Exception.CreateHelp('', AValue);
end;


Function GetExceptionMessage;
begin
    Result := '';
    if E.HelpContext in [ { 0 } 1 .. Byte(Length(ResponseText) - 1)] then
        Result := ResponseText[E.HelpContext]
    else if E.Message <> '' then
        Result := E.Message;
end;


function GetTimestamp(const AValue: System.TDateTime = 0): int64;
begin
    if AValue = 0 then
        Result := MilliSecondsBetween(Now, UnixDateDelta)
    else
        Result := MilliSecondsBetween(AValue, UnixDateDelta);
end;


function GetEndOfDate(const Value: TDateTime): TDateTime;
begin
    Result := EncodeDateTime(YearOf(Value), MonthOf(Value), DayOf(Value), 23, 59, 59, 999);
end;


procedure DoSync(proc: TThreadProcedure);
begin
{$IFDEF DOSYNC}
    TThread.Synchronize(TThread.CurrentThread, proc);
{$ELSE}
    proc
{$ENDIF}
end;


function GetPlatformVersion;
begin
    SetLength(Result, 0);
{$IFDEF ANDROID}
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := pvAndroid;
{$ENDIF ANDROID}
{$IFDEF ANDROID64}
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := pvAndroid64;
{$ENDIF ANDROID64}
{$IFDEF IOS}
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := pvIOS;
{$ENDIF IOS}
{$IFDEF MACOS}
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := pvMACOS;
{$ENDIF MACOS}
{$IFDEF MSWINDOWS}
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := pvMSWINDOWS;
{$ENDIF MSWINDOWS}
{$IFDEF LINUX}
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := pvLINUX;
{$ENDIF MACOS}
end;


function GetPlatformVersionStr;
var
    p: PlatformVersionInt;
begin
    SetLength(Result, 0);
    for p in GetPlatformVersion do
    begin
        SetLength(Result, Length(Result) + 1);
        Result[Length(Result) - 1] := PlatformVersionStr[Byte(p)];
    end;
    if Length(Result) <= 0 then
    begin
        SetLength(Result, Length(Result) + 1);
        Result[Length(Result) - 1] := 'UNKNOWN';
    end;
end;


function CurrentFormatSettings: TFormatSettings;
begin
    Result.DecimalSeparator := '.';
    Result.ShortDateFormat := 'yyyy-mm-dd';
end;


procedure DownloadCallback(const Sender: TObject; AContentLength: int64; AReadCount: int64; var Abort: boolean);
begin
    if Assigned(callback_proc) then
        callback_proc(Sender, AContentLength, AReadCount, Abort);
end;


function StrInArrayI;
var
    i: integer;
begin
    Result := -1;
    if From < Length(StringArray) then
        for i := From to Length(StringArray) - 1 do
            if (CaseSensitive and (src = StringArray[i])) or (not CaseSensitive and SameText(src, StringArray[i])) then
                Result := i;
end;


function StrInArrayB;
begin
    Result := StrInArrayI(src, StringArray, CaseSensitive, From) <> -1;
end;


function IntInArrayI;
var
    i: integer;
begin
    Result := -1;
    if From < Length(IntArray) then
        for i := From to Length(IntArray) - 1 do
            if (src = IntArray[i]) then
                Result := i;
end;


function IntInArrayB;
begin
    Result := IntInArrayI(src, IntArray, From) <> -1;
end;


function GetWorkDirectory(const isPublic: boolean = false): string;
begin
{$IFDEF ANDROID}
    if isPublic then
        Result := TPath.GetSharedDownloadsPath
    else
        Result := TPath.GetDocumentsPath;
{$ENDIF ANDROID}
{$IFDEF IOS}
    Result := TPath.GetSharedDocumentsPath;
{$ENDIF IOS}
{$IFDEF MACOS}
    Result := TPath.GetDocumentsPath;
{$ENDIF MACOS}
{$IFDEF MSWINDOWS}
    Result := ExtractFilePath(ParamStr(0));
{$ENDIF MSWINDOWS}
{$IFDEF LINUX}
    Result := ExtractFilePath(ParamStr(0));
    Result := TDirectory.GetCurrentDirectory;
{$ENDIF LINUX}
end;


function MD5(Buf: Pointer; const BufSize: integer): string;
var
    IdHash: TIdHashMessageDigest5;
    st: TStream;
begin
    st := TMemoryStream.Create;
    st.Write(Buf^, BufSize);
    st.Position := 0;
    IdHash := TIdHashMessageDigest5.Create;
    Result := IdHash.HashStreamAsHex(st);
    IdHash.Destroy;
    st.Destroy;
end;


function MD5(const Source: string): string;
begin
    with TIdHashMessageDigest5.Create do
    begin
        Result := HashStringAsHex(Source);
        Free;
    end;
end;

{ TMyHTTPClient }


constructor TMyHTTPClient.Create;
begin
    FClient := System.Net.HttpClient.THTTPClient.Create;
    FClient.OnValidateServerCertificate := Self.doOnValidateServerCertificate;
    FClient.SecureProtocols := [THTTPSecureProtocol.TLS1, THTTPSecureProtocol.TLS12];
    FClient.ContentType := 'application/json';
    FClient.Accept := 'application/json';

    Self.URL := aURL;
    Self.Method := aMethod;
    Self.ConnectionTimeout := DefaultConnectionTimeout;
    Self.ResponseTimeout := DefaultResponseTimeout;
    Self.RequestHeaders := System.Generics.Collections.TDictionary<string, String>.Create;
    Self.RequestParams := System.Generics.Collections.TDictionary<string, Variant>.Create;
end;


function TMyHTTPClient.Send(ADestStream: TStream; const aURL: string = ''; aReceiveDataCallback: TReceiveDataCallback = nil; const FreeOnFinish: boolean = true): TCustomHTTPResponseHeaders;
const
    HTTPRequestMethodStr: TArray<string> = ['GET', 'POST'];
var
    Response: IHTTPResponse;
begin
    SetLength(Result.Headers, 0);

    if not aURL.IsEmpty then
        Self.URL := aURL;

    FClient.ReceiveDataCallBack := aReceiveDataCallback;

    for var hdr in RequestHeaders do
        FClient.CustHeaders.Add(hdr.Key, hdr.Value);

    if (not Proxy.host.IsEmpty) AND (not(Proxy.port > 0)) then
        FClient.ProxySettings := TProxySettings.Create(Proxy.host, Proxy.port, Proxy.username, Proxy.password);

    if Self.RequestBody.IsEmpty OR (not SO().Check(Self.RequestBody)) then
        Self.RequestBody := '{}';

    var
    X := SO(Self.RequestBody);

    try
        case Method of

            THTTPRequestMethod.rmPOST:
                begin
                    for var Param in RequestParams.ToArray do
                        X.V[Param.Key] := Param.Value;
                    var
                    st := TStringStream.Create(X.AsJSON(true), TEncoding.UTF8);
                    try
                        Response := FClient.Post(URL, st);
                        st.Destroy;
                    except
                        st.Destroy;
                        raise;
                    end;
                end;

            THTTPRequestMethod.rmGET:
                begin
                    var
                    URI := TUri.Create(URL);
                    for var Param in RequestParams.ToArray do
                        URI.AddParameter(Param.Key, Param.Value);
                    if X.Count > 0 then
                        while not X.Eof do
                        begin
                            URI.AddParameter(X.CurrentKey, VarToStrDef(X.V[X.CurrentKey], ''));
                            X.Next;
                        end;
                    var
                    Request := FClient.GetRequest(HTTPRequestMethodStr[Byte(Method)], URI);
                    Response := FClient.Execute(Request);
                end;

        end;

        Result.Status_Code := Response.StatusCode;
        Result.Status_Text := Response.StatusText;

        if Assigned(ADestStream) then
            ADestStream.CopyFrom(Response.ContentStream);

        for var hdr IN Response.Headers do
        begin
            SetLength(Result.Headers, Length(Result.Headers) + 1);
            Result.Headers[Length(Result.Headers) - 1].Key := hdr.Name;
            Result.Headers[Length(Result.Headers) - 1].Value := hdr.Value;
        end;
    except
        On E: Exception do
        begin
            Result.Status_Code := 0;
            Result.Status_Text := E.Message;
        end;
    end;

    if FreeOnFinish then
        Self.Destroy;
end;


function TMyHTTPClient.Send(const aURL: string = ''; aReceiveDataCallback: TReceiveDataCallback = nil; const FreeOnFinish: boolean = true): TCustomHTTPResponse;
begin
    var
    LStream := TStringStream.Create('', TEncoding.UTF8);
    Result := TJSON.Parse<TCustomHTTPResponse>(TJSON.SuperObject(Send(LStream, aURL, aReceiveDataCallback, FreeOnFinish)));
    Result.Response_Body := LStream.DataString;
    LStream.Destroy;
    if Result.Response_Body.IsEmpty then
        Result.Response_Body := '{}';
end;


procedure TMyHTTPClient.Send(var Result: TCustomHTTPResponse; aReceiveDataCallback: TReceiveDataCallback = nil; const FreeOnFinish: boolean = true);
begin
    Result := Send('', aReceiveDataCallback, FreeOnFinish);
end;


destructor TMyHTTPClient.Destroy;
begin
    if Assigned(RequestHeaders) then
        RequestHeaders.Destroy;
    if Assigned(RequestParams) then
        RequestParams.Destroy;
    if Assigned(FClient) then
        FClient.Destroy;

    inherited;
end;


procedure TMyHTTPClient.Free;
begin
    Destroy;
end;


function TMyHTTPClient.GetConnectionTimeout: integer;
begin
    Result := FClient.ConnectionTimeout;
end;


function TMyHTTPClient.GetResponseTimeout: integer;
begin
    Result := FClient.ResponseTimeout;
end;


procedure TMyHTTPClient.doOnValidateServerCertificate(const Sender: TObject; const ARequest: TURLRequest; const Certificate: TCertificate; var Accepted: boolean);
begin
    Accepted :=                                      //
         Certificate.CertName.EndsWith('.iberica.kz')//
// and                                         //
// (Certificate.Expiry > Now)                  //
         ;
end;


procedure TMyHTTPClient.SetConnectionTimeout(const Value: integer);
begin
    FClient.ConnectionTimeout := Value;
end;


procedure TMyHTTPClient.SetResponseTimeout(const Value: integer);
begin
    FClient.ResponseTimeout := Value;
end;

initialization

if FGUID.IsEmpty then
    FGUID := MD5(MilliSecondsBetween(Now, UnixDateDelta).ToString + random(999999999).ToString);
if FHostIP.IsEmpty then
    try
        TIdStack.IncUsage;
        FAddressList := GStack.LocalAddresses.ToStringArray;
        FHostIP := GStack.LocalAddress;
    finally
        TIdStack.DecUsage;
    end;

end.
