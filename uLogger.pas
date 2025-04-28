unit uLogger;

{$I defines.inc}

interface

type
    TLogLevel = (llNone, llErrors, llAll);

type
    TLogType = (ltGeneral, ltInfo, ltError);

type
    TLogProc = procedure(const Data: string; const Params: array of const; const LogType: TLogType = ltInfo) of object;

type
    TGraylogPacket = record
        version: string;
        host: string;
        short_message: string;
        full_message: string;
        level: Byte;
        facility: string;
    end;

type
    TLogger = record

    private
        procedure WriteLogToConsole(const Data: string; const LogType: TLogType);
        procedure WriteLogToFile(const Data: string; const LogType: TLogType);
        procedure WriteLogToGrayLog(const Data: string; const LogType: TLogType; const AHost: string);

    public
        LogPrefix: string;
        LogDirectory: string;

        log_level_to_screen: TLogLevel;  // = llErrors;
        log_level_to_file: TLogLevel;    // = llAll;
        log_level_to_graylog: TLogLevel; // = llAll;
        graylog_host: string;            // = '';
        graylog_port: word;              // = 0;
        graylog_stream_name: string;

        procedure WriteLog(const Data: string; const Params: array of const; const LogType: TLogType = ltInfo); overload;
        procedure WriteLog(const Data: string; const LogType: TLogType = ltInfo); overload;

        procedure WriteLogG(const Data: string; const Params: array of const); overload;
        procedure WriteLogG(const Data: string); overload;

        procedure WriteLogE(const Data: string; const Params: array of const); overload;
        procedure WriteLogE(const Data: string); overload;

        function GetLogFileName(const sPrefix: string = ''; const sDate: string = ''): string;
    end;

implementation

uses
    uUtils,
    IdGlobal,
    IdUDPClient,
    System.IOUtils,
    System.SysUtils,
    System.Classes,
    XSuperObject;

{ TLogger }


procedure TLogger.WriteLogToConsole(const Data: string; const LogType: TLogType);
{$IFDEF ANDROID}
var
    m: TMarshaller;
{$ENDIF}
begin
    if (log_level_to_screen = llAll) or ((log_level_to_screen = llErrors) and (LogType in [ltGeneral, ltError])) then
    begin
{$IFDEF ANDROID}
        __android_log_write(android_LogPriority.ANDROID_LOG_INFO, LOG_PREFIX, m.AsUtf8(Data).ToPointer);
{$ENDIF ANDROID}
{$IFDEF WRITELOG_CONSOLE}
        try
            if IsConsole then
                System.WriteLN(Data);
        except
        end;
{$ENDIF WRITELOG_CONSOLE}
    end;
end;


procedure TLogger.WriteLogToFile(const Data: string; const LogType: TLogType);
begin
    var
    LFileName := GetLogFileName;
    try
        if (log_level_to_file = llAll) or ((log_level_to_file = llErrors) and (LogType in [ltGeneral, ltError])) then
            TFile.AppendAllText(LFileName, Data + #13#10, TEncoding.UTF8);
    except
        on E: Exception do
            WriteLogToConsole(Format('WriteLogToFile exception [%s][%s]: %s', [E.ClassName, LFileName, E.Message]), TLogType.ltError);
    end;
end;


procedure TLogger.WriteLogToGrayLog(const Data: string; const LogType: TLogType; const AHost: string);
var
    log: TGraylogPacket;
    prefix: string;
begin
    if graylog_host.IsEmpty OR (graylog_port <= 0) then
        exit;
    if (log_level_to_graylog = llAll) or ((log_level_to_graylog = llErrors) and (LogType in [ltGeneral, ltError])) then
    begin
        log.version := '1.1';
        log.host := AHost;
        log.facility := graylog_stream_name;
        with TStringList.Create do
        begin
            Text := Data;
            prefix := Strings[0];
            Destroy;
        end;
        log.short_message := prefix;
        log.full_message := Data;
        case LogType of
            ltGeneral:
                log.level := 6;
            ltInfo:
                log.level := 6;
            ltError:
                log.level := 3;
        end;
(*
    1 = ALERT;
    2 = CRITICAL;
    3 = ERROR;
    4 = WARNING;
    5 = NOTICE;
    6 = INFO;
    7 = DEBUG;
*)
        with TIdUDPClient.Create(nil) do
        begin
            try
                Send(graylog_host, graylog_port, TJSON.Stringify(log, true), IndyTextEncoding(IdTextEncodingType.encUTF8));
            except
            end;
            Destroy;
        end;
    end;
end;


function TLogger.GetLogFileName(const sPrefix: string = ''; const sDate: string = ''): string;
var
    LPrefix: string;
    LDate: string;
begin
    if sPrefix.IsEmpty then
        LPrefix := LogPrefix
    else
        LPrefix := sPrefix;

    if sDate.IsEmpty then
        LDate := FormatDateTime('yyyy-mm-dd', Now)
    else
        LDate := sDate;

    var
    LWorkDir := TPath.Combine(LogDirectory, LDate);

    Result := TPath.Combine(LWorkDir, LDate + '_' + LPrefix + '.log');

    if sPrefix.IsEmpty AND sDate.IsEmpty AND (not FileExists(Result)) then
        ForceDirectories(LWorkDir);
end;


procedure TLogger.WriteLog(const Data: string; const LogType: TLogType = ltInfo);
begin
    var
    LLogger := Self;
    DoSync(
        procedure
        begin
            var
            sData := Format('[%s]: %s', [FormatDateTime('YYYY-MM-DD hh:nn:ss.zzz', Now), Data]);
            LLogger.WriteLogToConsole(sData, LogType);
            LLogger.WriteLogToFile(sData, LogType);
            LLogger.WriteLogToGrayLog(sData, LogType, FHostIP);
        end)
end;


procedure TLogger.WriteLog(const Data: string; const Params: array of const; const LogType: TLogType = ltInfo);
begin
    if Length(Params) > 0 then
        WriteLog(Format(Data, Params), LogType)
    else
        WriteLog(Data, LogType);
end;


procedure TLogger.WriteLogE(const Data: string; const Params: array of const);
begin
    WriteLog(Data, Params, TLogType.ltError);
end;


procedure TLogger.WriteLogE(const Data: string);
begin
    WriteLog(Data, TLogType.ltError);
end;


procedure TLogger.WriteLogG(const Data: string; const Params: array of const);
begin
    WriteLog(Data, Params, TLogType.ltGeneral);
end;


procedure TLogger.WriteLogG(const Data: string);
begin
    WriteLog(Data, TLogType.ltGeneral);
end;

end.
