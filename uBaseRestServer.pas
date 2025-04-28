unit uBaseRestServer;

interface

uses
{$REGION 'INDY Units'}
    idException,
    IdSSLOpenSSL,
    IdCustomHTTPServer,
    IdHTTPServer,
    IdContext,
    IdGlobal,
{$ENDREGION}
{$REGION 'SYSTEM Units'}
    System.SysUtils,
    System.IOUtils,
    System.DateUtils,
    System.Classes,
    System.Variants,
    System.RTTI,
    System.TypInfo,
    System.Generics.Collections,
    System.Generics.Defaults,
{$ENDREGION}
    uLogger,
    XSuperObject,
    XSuperJson;

type
    TBaseRestServer = class
    private
        FStartTime: System.TDateTime;
        FStarted: boolean;
        FServer: TIdHTTPServer;
        FHTTPPort: word;
        FHTTPSPort: word;
        FSSLCertFileName: string;
        FSSLKeyFileName: string;

        Procedure ExecuteMethod(const MethodName: string; const Args: array of TValue);
        procedure ProcessRequest(AContext: TIdContext; ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);

    protected
        function GetResponseTextByCode(const ResponseCode: integer): string;
        property GetStartTime: TDateTime read FStartTime;

    public
        property HTTPPort: word read FHTTPPort write FHTTPPort;
        property HTTPSPort: word read FHTTPSPort write FHTTPSPort;

        property SSLCertFileName: string read FSSLCertFileName write FSSLCertFileName;
        property SSLKeyFileName: string read FSSLKeyFileName write FSSLKeyFileName;

        property IsStarted: boolean read FStarted;

        constructor Create;
        destructor Destroy;
        procedure Free;
        function Start: boolean;
        function Stop: boolean;

        function EventTimestamp(ARequest: TIdHTTPRequestInfo): Int64;
        function GetAuthorizationString(ARequest: TIdHTTPRequestInfo): string;

        procedure BuildHttpResponse(const EventTimestamp: Int64; AResponse: TIdHTTPResponseInfo; const AResponseData: string; const httpResponseCode: integer = 200); overload;
        procedure BuildHttpResponse(const EventTimestamp: Int64; AResponse: TIdHTTPResponseInfo; const AResponseCode: byte; const httpResponseCode: integer = 200); overload;
        procedure BuildHttpResponse(const EventTimestamp: Int64; AResponse: TIdHTTPResponseInfo; const AResponseCode: byte; const ResponseData: string; const httpResponseCode: integer = 200); overload;

        procedure WriteLog(const Data: string; const LogType: TLogType = ltInfo); overload; virtual;
        procedure WriteLog(const Data: string; const Params: array of const; const LogType: TLogType = ltInfo); overload; virtual;

        function GetResponseMessage(const ResponseCode: integer; const AcceptLanguage: string): string; virtual;
        function GetRequestData(ARequest: TIdHTTPRequestInfo): string;

        procedure onQuerySSLPort(APort: TIdPort; var VUseSSL: boolean); virtual;
        procedure ProcessAuthorization(AContext: TIdContext; const AAuthType, AAuthData: String; var VUsername, VPassword: String; var VHandled: boolean); virtual;
        procedure ProcessException(AContext: TIdContext; AException: Exception); virtual;

    published
        procedure Ping(ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
        procedure favicon_ico(ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);

{$IFDEF DEBUG}
        procedure Disable(ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
{$ENDIF} //
    end;

implementation

uses
    uTypes,
    uUtils;


procedure TBaseRestServer.BuildHttpResponse(const EventTimestamp: Int64; AResponse: TIdHTTPResponseInfo; const AResponseData: string; const httpResponseCode: integer = 200);
begin
    if not Assigned(AResponse) then
        exit;

    AResponse.ResponseNo := httpResponseCode;
    AResponse.ResponseText := GetResponseTextByCode(AResponse.ResponseNo);

    var
    FResponseCode := rc_ok;

    if httpResponseCode <> 200 then
        FResponseCode := rc_operation_failed;

    var
    X := SO();

    X.i['response_code'] := FResponseCode;

    if SO.Check(AResponseData) then
    begin
        case SO(AResponseData).DataType of
            dtArray:
                X.A['response_data'] := SA(AResponseData);
            dtObject:
                X.O['response_data'] := SO(AResponseData);
            else
                X.S['response_data'] := AResponseData;
        end;
    end
    else
        if not AResponseData.IsEmpty then
            X.S['response_data'] := AResponseData
        else
            X.S['response_data'] := ResponseText[FResponseCode];

    X.S['message'] := GetResponseMessage(FResponseCode, AResponse.ContentLanguage);
    if X.S['message'].IsEmpty then
        X.Remove('message');

    AResponse.ContentText := X.AsJSON(true);

    WriteLog('[%d] ResponseHeaders [%d %s]: %s', [EventTimestamp, AResponse.ResponseNo, AResponse.ResponseText, #13#10 + AResponse.CustomHeaders.Text]);
    WriteLog('[%d] ResponseBody: %s', [EventTimestamp, #13#10 + AResponse.ContentText]);
end;


procedure TBaseRestServer.BuildHttpResponse(const EventTimestamp: Int64; AResponse: TIdHTTPResponseInfo; const AResponseCode: byte; const httpResponseCode: integer = 200);
var
    FResponseCode: byte;
begin
    if not Assigned(AResponse) then
        exit;

    AResponse.ResponseNo := httpResponseCode;
    AResponse.ResponseText := GetResponseTextByCode(AResponse.ResponseNo);

    FResponseCode := AResponseCode;
    if (httpResponseCode <> 200) AND (AResponseCode = 0) then
        FResponseCode := rc_unknown_result;

    var
    X := SO();

    X.i['response_code'] := FResponseCode;

    if FResponseCode in [0 .. byte(Length(ResponseText)) - 1] then
        X.S['response_data'] := ResponseText[byte(FResponseCode)]
    else
        X.S['response_data'] := Format('unknown_error: %d', [FResponseCode]);

    X.S['message'] := GetResponseMessage(FResponseCode, AResponse.ContentLanguage);
    if X.S['message'].IsEmpty then
        X.Remove('message');
    AResponse.ContentText := X.AsJSON(true);

    WriteLog('[%d] ResponseHeaders [%d %s]: %s', [EventTimestamp, AResponse.ResponseNo, AResponse.ResponseText, #13#10 + AResponse.CustomHeaders.Text]);
    WriteLog('[%d] ResponseBody: %s', [EventTimestamp, #13#10 + AResponse.ContentText]);
end;


procedure TBaseRestServer.BuildHttpResponse(const EventTimestamp: Int64; AResponse: TIdHTTPResponseInfo; const AResponseCode: byte; const ResponseData: string; const httpResponseCode: integer = 200);
var
    FResponseCode: byte;
begin
    if not Assigned(AResponse) then
        exit;

    AResponse.ResponseNo := httpResponseCode;
    AResponse.ResponseText := GetResponseTextByCode(AResponse.ResponseNo);

    FResponseCode := AResponseCode;
    if (httpResponseCode <> 200) AND (AResponseCode = 0) then
        FResponseCode := rc_unknown_result;

    var
    X := SO();

    X.i['response_code'] := FResponseCode;
    X.S['response_data'] := ResponseData;
    X.S['message'] := GetResponseMessage(FResponseCode, AResponse.ContentLanguage);
    if X.S['message'].IsEmpty then
        X.Remove('message');
    AResponse.ContentText := X.AsJSON(true);

    WriteLog('[%d] ResponseHeaders [%d %s]: %s', [EventTimestamp, AResponse.ResponseNo, AResponse.ResponseText, #13#10 + AResponse.CustomHeaders.Text]);
    WriteLog('[%d] ResponseBody: %s', [EventTimestamp, #13#10 + AResponse.ContentText]);
end;


constructor TBaseRestServer.Create;
begin
    inherited;
    FStarted := false;
end;


destructor TBaseRestServer.Destroy;
begin
    WriteLog('TBaseRestServer.Destroy', ltGeneral);

    if Assigned(FServer) then
        FServer.Destroy;

    inherited;
end;


procedure TBaseRestServer.ExecuteMethod(const MethodName: string; const Args: array of TValue);
begin
    var
    t := TRttiContext.Create.GetType(Self.ClassType);
    for var m in t.GetMethods do
        if (m.Visibility = mvPublished) AND (SameText(m.name, { 'public_' + } MethodName)) then
        begin
            m.Invoke(Self, Args);
            exit;
        end;
    raise Exc(rc_method_not_found);
end;


procedure TBaseRestServer.Free;
begin
    Destroy;
end;


function TBaseRestServer.GetAuthorizationString(ARequest: TIdHTTPRequestInfo): string;
begin
    try
        Result := ARequest.RawHeaders.Values['Authorization'];
        if Result.ToLower.StartsWith('bearer ', true) then
            Result := Result.Substring(7);
    except
        Result := '';
    end;
end;


function TBaseRestServer.GetRequestData(ARequest: TIdHTTPRequestInfo): string;
begin
    ARequest.ETag := '1';
    case ARequest.CommandType of
        hcPOST:
            begin
                try
                    if Assigned(ARequest.PostStream) then
                    begin
                        ARequest.PostStream.Position := 0;
                        Result := ReadStringFromStream(ARequest.PostStream, -1, IndyTextEncoding_UTF8) { .Trim };
                    end;
                except
                    Result := '';
                end;
            end;

        hcGET:
            begin
                var
                BodyAsJSON := SO();
                try
                    for var i := 0 to ARequest.Params.Count - 1 do
                        if not ARequest.Params.Names[i].IsEmpty then
                            try
                                BodyAsJSON.i[ARequest.Params.Names[i]] := StrToInt(ARequest.Params.ValueFromIndex[i]);
                            except
                                try
                                    BodyAsJSON.B[ARequest.Params.Names[i]] := StrToBool(ARequest.Params.ValueFromIndex[i]);
                                except
                                    try
                                        BodyAsJSON.D[ARequest.Params.Names[i]] := StrToDateTime(ARequest.Params.ValueFromIndex[i]);
                                    except
                                        BodyAsJSON.S[ARequest.Params.Names[i]] := ARequest.Params.ValueFromIndex[i];
                                    end;
                                end;
                            end;
                    Result := BodyAsJSON.AsJSON;
                except
                    Result := '';
                end;
            end;
        else
            Result := '';
    end;

    if Result.IsEmpty then
        Result := '{}';

    WriteLog('[%d] RequestBody: [%s] %s', [EventTimestamp(ARequest), ARequest.ETag, #13#10 + Result]);

    if not SO().Check(Result) then
        raise Exception.CreateHelp('', rc_invalid_fields);
end;


function TBaseRestServer.GetResponseMessage(const ResponseCode: integer; const AcceptLanguage: string): string;
begin
{ dummy }
end;


function TBaseRestServer.GetResponseTextByCode(const ResponseCode: integer): string;
begin
    case ResponseCode of
        200:
            Result := 'OK';
        400:
            Result := 'Bad Request';
        401:
            Result := 'Unauthorized';
        403:
            Result := 'Forbidden';
        500:
            Result := 'Internal Server Error';
        501:
            Result := 'Not Implemented';
        503:
            Result := 'Service Unavailable';
        else
            Result := '';
    end;
end;


procedure TBaseRestServer.onQuerySSLPort(APort: TIdPort; var VUseSSL: boolean);
begin
{ dummy }
    VUseSSL := APort = HTTPSPort;
    WriteLog('TBaseRestServer.onQuerySSLPort: APort = %d, VUseSSL = %s', [APort, VarToStr(VUseSSL)], ltGeneral);
end;


procedure TBaseRestServer.ProcessAuthorization(AContext: TIdContext; const AAuthType, AAuthData: String; var VUsername, VPassword: String; var VHandled: boolean);
begin
{ dummy }
    VHandled := true;
end;


procedure TBaseRestServer.ProcessException(AContext: TIdContext; AException: Exception);
begin
    if AException.ClassType <> EIdConnClosedGracefully then
        WriteLog('HTTP Exception: [%s] %s', [AException.ClassName, AException.Message], ltError);
end;


procedure TBaseRestServer.ProcessRequest(AContext: TIdContext; ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
const
    HTTPSchemaStr: array of string = ['http', 'https'];
var
    LHTTPResponseCode: integer;
begin
    var
    LEventTimeStamp := EventTimestamp(ARequest);

    WriteLog('[%d] [%s] %s://%s/%s, RemoteIP: %s, Headers:%s', [LEventTimeStamp, ARequest.command, HTTPSchemaStr[0], ARequest.host, ARequest.URI.TrimLeft(['/']), ARequest.RemoteIP, #13#10 + ARequest.RawHeaders.Text]);

    ARequest.ETag := '';

    AResponse.ContentLanguage := ARequest.RawHeaders.Values['Accept-Language'];

    AResponse.ContentType := 'application/json';

    var
    LMethodName := ARequest.URI.Trim(['/']).Replace('.', '_').Replace('/', '_');

    try
        ExecuteMethod(LMethodName, [ARequest, AResponse]);
    except
        on E: Exception do
        begin
            WriteLog('[%d] Method execution exception ("%s"): [%d / %s] %s', [LEventTimeStamp, LMethodName, E.HelpContext, E.ClassName, GetExceptionMessage(E)]);

            if (E.HelpContext in [1 .. byte(Length(ResponseText))]) then
            begin
                case E.HelpContext of

                    rc_invalid_fields, rc_access_code_incorrect, rc_invalid_operator_code, rc_invalid_kkm_credentials, rc_invalid_kkm_ofd_id:
                        LHTTPResponseCode := 400; // некорректный запрос

                    rc_kkm_access_denied, rc_kkm_invalid_bindings, rc_kkm_per_owner_limit_exceed, rc_kkm_operators_limit_exceed:
                        LHTTPResponseCode := 401; // отказано в доступе

                    rc_invalid_access_code:
                        LHTTPResponseCode := 403; // ошибка авторизации

                    rc_method_not_found:
                        LHTTPResponseCode := 404; // метод не найден

                    else
                        LHTTPResponseCode := 500; // прочие ошибки
                end;
                BuildHttpResponse(LEventTimeStamp, AResponse, E.HelpContext, LHTTPResponseCode);
            end
            else
                BuildHttpResponse(LEventTimeStamp, AResponse, rc_method_execution_exception, 500)
        end;
    end;

    if ARequest.ETag.IsEmpty then
        try
            GetRequestData(ARequest);
        except
        end;

    WriteLog('[%d] ResponseHeaders [%d %s]: %s', [LEventTimeStamp, AResponse.ResponseNo, AResponse.ResponseText, #13#10 + AResponse.CustomHeaders.Text]);

    if not SameText(AResponse.ContentType, 'application/save') then
        WriteLog('[%d] ResponseBody: %s', [LEventTimeStamp, #13#10 + AResponse.ContentText])
    else
        WriteLog('[%d] ResponseBody: %s', [LEventTimeStamp, #13#10 + AResponse.ContentDisposition]);

end;


procedure TBaseRestServer.favicon_ico(ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
var
    LStream: TFileStream;
begin
    LStream := nil;
    try
        LStream := TFileStream.Create(TPath.Combine(TDirectory.GetCurrentDirectory, 'favicon.ico'), fmOpenRead);
        AResponse.ContentStream := TMemoryStream.Create;
        AResponse.ContentStream.CopyFrom(LStream);
        LStream.Destroy;
    except
        if Assigned(LStream) then
            LStream.Destroy;
        AResponse.ResponseNo := 404;
        AResponse.ContentType := 'text/plain';
        AResponse.ContentText := 'File Not Found';
    end;
end;


function TBaseRestServer.EventTimestamp(ARequest: TIdHTTPRequestInfo): Int64;
begin
    Result := MilliSecondsBetween(ARequest.Date, UnixDateDelta);
end;


procedure TBaseRestServer.Ping(ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
begin
    BuildHttpResponse(EventTimestamp(ARequest), AResponse, rc_ok);
end;


function TBaseRestServer.Start: boolean;
begin
    FStartTime := Now;

    FServer := TIdHTTPServer.Create;
    FServer.OnParseAuthentication := ProcessAuthorization;
    FServer.OnCommandGet := ProcessRequest;
    FServer.OnException := ProcessException;
    FServer.onQuerySSLPort := onQuerySSLPort;
    FServer.ListenQueue := 100;
    FServer.KeepAlive := false;
    FServer.Bindings.Clear;

    if HTTPPort > 0 then
        FServer.Bindings.Add.SetBinding('', HTTPPort, Id_IPv4);

    if HTTPSPort > 0 then
    begin
        var
        FSSLHandler := TIdServerIOHandlerSSLOpenSSL.Create;
// FSSLHandler.SSLOptions.Mode := TIdSSLMode.sslmServer;
        FSSLHandler.SSLOptions.SSLVersions := [ { sslvSSLv2, sslvSSLv23, sslvSSLv3, sslvTLSv1, } sslvTLSv1_1, sslvTLSv1_2];
        FSSLHandler.SSLOptions.CertFile := FSSLCertFileName;
        FSSLHandler.SSLOptions.KeyFile := FSSLKeyFileName;
        FServer.IOHandler := FSSLHandler;
        FServer.Bindings.Add.SetBinding('', HTTPSPort, Id_IPv4);
    end;

    WriteLog('[TBaseRestServer.Start] FServer prepared', ltGeneral);

    FServer.Active := true;

    FStarted := true;

    Result := true;
end;


function TBaseRestServer.Stop: boolean;
begin
    FServer.Active := false;
// FServer.Bindings.Clear;
    Result := true;
end;


procedure TBaseRestServer.WriteLog(const Data: string; const LogType: TLogType = ltInfo);
begin
{ dummy }
end;


procedure TBaseRestServer.WriteLog(const Data: string; const Params: array of const; const LogType: TLogType = ltInfo);
begin
{ dummy }
end;

{$IFDEF DEBUG} // - только для отладки!


procedure TBaseRestServer.Disable(ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
begin
    BuildHttpResponse(EventTimestamp(ARequest), AResponse, rc_ok);
    FStarted := false;
end;
{$ENDIF DEBUG} //

end.
