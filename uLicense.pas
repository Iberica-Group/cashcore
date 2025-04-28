unit uLicense;

interface

uses
    uUtils,
    uTypes,
    uLogger,
    uCashRegisterTypes,
    System.Classes;

const
    CipherPasswordLicense = '54476c6a5a57357a5a54705461573177624756665132467a61454e76636d55745547467a63336476636d51764d6a41794e4334774f4334774d79453d';

const
    maximum_license_offline_duration = 24; // сутки

const
    TLicenseTypeStr: TArray<string> = ['Free', 'Desktop', 'Server'];

type
    TLicenseType = (ltFree, ltDesktop, ltServer);

type
    TPeriodDimension = (pdDay, pdMonth, pdYear); // размерность периода: день, месяц, год

type
    TLicenseRecord = record
    private
//
    public
//
        isSuspended: boolean;                      // признак того, что лицензия приостановлена
        email: string;                             // email владельца
        phone: string;                             // номер телефона в формате (+7**********)
        owner: string;                             // наименование владельца
        orgId: string;                             // ИИН/БИН владельца
        address: string;                           // адрес владельца
        licenseKey: string;                        // лицензионный ключ
        activationCode: string;                    // код активации
        activationDate: System.TDateTime;          // дата активации лицензии
        validityPeriodValue: word;                 // срок действия: количество...
        validityPeriodDimension: TPeriodDimension; // ...дней, месяцев, лет
        onlineCheckPeriod: word;                   // периодичность проверки в днях
        lastSuccessOnlineCheck: System.TDateTime;  // TODO: этот параметр нужно менять и сохранять в текущем лиц.файле! иначе ядро просто будут перезапускать каждые N-дней и счётчик будет работать снова
        maxKKMCount: integer;                      // максимально допустимое количество касс
        licenseType: TLicenseType;                 // тип лицензии
        ofdList: TArray<TOfdRecord>;               // список доступных ОФД
        function ValidFrom: TDateTime;
        function ValidThru: TDateTime;
        procedure Clear;
        function ToString: string;
        procedure FromString(const Value: string);
        function LoadFromFile(const FileName: string): boolean;
        function SaveToFile(const FileName: string): boolean;
        procedure ClearOFDList;
        procedure AddOFD(const UID, Name, Host: string; const Port: word; const vendorIdPrefix, consumerAddress: string; const proxy: TProxyRecord); overload;
        procedure AddOFD(const Value: TOfdRecord); overload;
        function CheckActual: boolean;
        function GetOFDByUID(const AValue: string): TOfdRecord;
    end;


function GetActivationCode: string;
function GenerateLicenseKey: string;
function GetActivationCodeMatchesPercent(const AValue1, AValue2: string): byte;

function GetLicenseValidThru(const activationDate: TDateTime; const validityPeriodValue: integer; const validityPeriodDimension: TPeriodDimension): TDateTime;

Procedure SetLogProc(AValue: TLogProc);

implementation

uses
    idGlobal,
    System.DateUtils,
    System.SysUtils,
    System.IOUtils,
    System.NetEncoding,
    System.Math,
    uEncoding,
    XSuperObject;

var
    FWriteLog: TLogProc;


Procedure SetLogProc(AValue: TLogProc);
begin
    FWriteLog := AValue;
end;


procedure WriteLog(const Data: string; const Params: array of const; const LogType: TLogType = ltInfo);
begin
    if Assigned(FWriteLog) then
        FWriteLog(Data, Params, LogType);
end;


function GetLicenseValidThru(const activationDate: TDateTime; const validityPeriodValue: integer; const validityPeriodDimension: TPeriodDimension): TDateTime;
begin
    var
    ValidFrom := DateOf(activationDate);

    case validityPeriodDimension of
        pdDay:
            Result := IncDay(ValidFrom, validityPeriodValue);
        pdMonth:
            Result := IncMonth(ValidFrom, validityPeriodValue);
        pdYear:
            Result := IncYear(ValidFrom, validityPeriodValue);
        else
            Result := 0;
    end;

    if Result > 0 then
        Result := GetEndOfDate(Result);
end;


function GetActivationCodeMatchesPercent(const AValue1, AValue2: string): byte;
begin
    Result := 0;

    var
    tmpStr := AValue1;
    var
    List1 := TStringList.Create;
    while tmpStr.Length >= 12 do
    begin
        List1.Add(tmpStr.Substring(0, 12));
        tmpStr := tmpStr.Substring(12);
    end;

    tmpStr := AValue2;
    var
    List2 := TStringList.Create;
    while tmpStr.Length >= 12 do
    begin
        List2.Add(tmpStr.Substring(0, 12));
        tmpStr := tmpStr.Substring(12);
    end;

    var
    TotalCount := Max(List1.Count, List2.Count);
    var
    MatchesCount := 0;

    for var s in List1.ToStringArray do
        if List2.IndexOf(s) <> -1 then
            inc(MatchesCount, 1);

    List1.Destroy;
    List2.Destroy;

    Result := Round(MatchesCount / (TotalCount / 100));
end;


function GenerateLicenseKey: string;
begin
    Result :=                                                                              //
         MD5(MilliSecondsBetween(Now, UnixDateDelta).ToString + random(999999999).ToString)// 9dce458c6bb14d66b0511a021bb9e318
         .ToUpper                                                                          // 9DCE458C6BB14D66B0511A021BB9E318
         .Substring(0, 16)                                                                 // 9DCE458C6BB14D66
         .Insert(4, '-')                                                                   // 9DCE-458C6BB14D66
         .Insert(9, '-')                                                                   // 9DCE-458C-6BB14D66
         .Insert(14, '-')                                                                  // 9DCE-458C-6BB1-4D66
         ;
end;


procedure TLicenseRecord.Clear;
begin
    Self := Default (TLicenseRecord);
end;


procedure TLicenseRecord.ClearOFDList;
begin
    SetLength(Self.ofdList, 0);
end;


procedure TLicenseRecord.FromString(const Value: string);
begin
    Self.Clear;
    var
    sDecryptedData := DecryptString(CipherPasswordLicense, Value);
    Self := TJSON.Parse<TLicenseRecord>(sDecryptedData);
end;


function TLicenseRecord.GetOFDByUID(const AValue: string): TOfdRecord;
begin
{ если UID ОФД явно не задан, то выбираем первый доступный ОФД из списка: }
    if AValue.IsEmpty and (Length(Self.ofdList) > 0) then
    begin
        Result := Self.ofdList[0];
        exit;
    end;

{ если UID ОФД задан, то ищем: }
    for var ofd in ofdList do
        if SameText(ofd.UID, AValue) then
        begin
            Result := ofd;
            exit;
        end;

{ если ничего не нашлось: }
    raise Exc(rc_invalid_ofd_uid);
end;


function TLicenseRecord.SaveToFile(const FileName: string): boolean;
begin
    Result := true;
    try
        var
        sEncryptedData := EncryptString(CipherPasswordLicense, TJSON.Stringify(Self, false, false));
        TFile.WriteAllText(FileName, sEncryptedData);
    except
        on E: Exception do
        begin
            Result := false;
            WriteLog('TLicenseRecord.SaveToFile exception: [%s] %s', [E.ClassName, E.Message], ltError);
        end;
    end;
end;


function TLicenseRecord.ToString: string;
begin
    Result := '';
    Result := EncryptString(CipherPasswordLicense, TJSON.Stringify(Self, false, false));
end;


function TLicenseRecord.LoadFromFile(const FileName: string): boolean;
var
    sEncryptedData, sDecryptedData: string;
begin
    Result := false;

    Self.Clear;

    try
        sEncryptedData := TFile.ReadAllText(FileName);
    except
        on E: Exception do
        begin
            WriteLog('TLicenseRecord.LoadFromFile(%s) exception: [%s] %s', [FileName, E.ClassName, E.Message], TLogType.ltError);
            exit;
        end;
    end;

    try
        sDecryptedData := DecryptString(CipherPasswordLicense, sEncryptedData);
    except
        on E: Exception do
        begin
            WriteLog('Unable to decrypt license: [%s] %s', [E.ClassName, E.Message], ltError);
            exit;
        end;

    end;

    try
        Self := TJSON.Parse<TLicenseRecord>(sDecryptedData);
    except
        on E: Exception do
        begin
            WriteLog('Unable to parse license body: [%s] %s', [E.ClassName, E.Message], TLogType.ltError);
            exit;
        end;
    end;

    Result := true;
end;


procedure TLicenseRecord.AddOFD(const UID: string; const Name: string; const Host: string; const Port: word; const vendorIdPrefix: string; const consumerAddress: string; const proxy: TProxyRecord);
begin
    var
    i := Length(ofdList);
    SetLength(ofdList, i + 1);
    ofdList[i].UID := UID;
    ofdList[i].Name := Name;
    ofdList[i].Host := TNetEncoding.Base64.Encode(Host);
    ofdList[i].Port := Port;
    ofdList[i].vendorIdPrefix := vendorIdPrefix;
    ofdList[i].consumerAddress := consumerAddress;
    ofdList[i].proxy := proxy;
end;


procedure TLicenseRecord.AddOFD(const Value: TOfdRecord);
begin
    var
    i := Length(ofdList);
    SetLength(ofdList, i + 1);
    ofdList[i] := Value;
end;


function MacToActivationCodeSegment(const Value: string): string;
begin
    Result := Value.Replace('A', '1').Replace('B', '2').Replace('C', '3').Replace('D', '4').Replace('E', '5').Replace('F', '6').Replace(':', '');
end;


function GetActivationCode: string;
begin
    Result := '';

    var
    MacList := GetMacAddressList;

    for var MAC in MacList do
        Result := Result + MacToActivationCodeSegment(MAC);

    MacList.Destroy;
end;


function TLicenseRecord.ValidFrom: TDateTime;
begin
    Result := DateOf(Self.activationDate);
end;


function TLicenseRecord.ValidThru: TDateTime;
begin
    Result := GetLicenseValidThru(activationDate, validityPeriodValue, validityPeriodDimension);
end;


function TLicenseRecord.CheckActual: boolean;
begin
    var
    isLicensePeriodActual := (Self.ValidFrom <= Now) AND (Now <= Self.ValidThru);

    var
    isLicenseActivationCodeActual := GetActivationCodeMatchesPercent(Self.activationCode, GetActivationCode) >= 50;

    var
    isLicenseOnlineCheckActual := HoursBetween(Now, lastSuccessOnlineCheck) < maximum_license_offline_duration;

    Result := isLicensePeriodActual AND isLicenseActivationCodeActual AND isLicenseOnlineCheckActual;

    if not isLicenseOnlineCheckActual then
        raise Exc(rc_license_online_check_error);

    if not isLicensePeriodActual then
        raise Exc(rc_license_period_expired);

    if not isLicenseActivationCodeActual then
        raise Exc(rc_invalid_activation_code);

    if Length(ofdList) <= 0 then
        raise Exc(rc_ofd_list_is_empty);
end;

end.
