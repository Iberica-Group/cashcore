unit uCashRegister;

// {$DEFINE KKM_BINARY_LOG}        //
// {$DEFINE KKM_EMULATE_RESPONSES} //

interface

uses
    proto.service,
    proto.message,
    proto.ticket,
    proto.report,
    proto.common,
    pbOutput,

    System.Classes,
    System.Generics.Collections,
    System.Types,
    System.Math,
    System.SysUtils,
    System.Variants,
    System.UITypes,
    System.RTTI,
    System.NetEncoding,

    idSocks,
    IdTCPClient,
    IdIOHandlerStack,

    FireDAC.Comp.Client,

    uLogger,
    uCashRegisterTypes,
    uTypes,

    XSuperObject;

const
    CashRegisterVersionCode = '25-05-13-16'; // y-m-d-h

type
    TCashRegister = record
    private
        FCheckVendorIDProc: TCheckVendorIDProc;
        FLogger: TLogger;
        FOFD: TOfdRecord;
        FDConnection: TFDConnection;
        FLastShiftNumber: Cardinal;
        FLastDocumentNumber: Cardinal;
        FOperator: TCashRegisterOperator;
        FEventTimestamp: int64;

        Function NonNullableSumsEquals(zx_report: TZXReport): boolean;
        Procedure CheckRegInfo(reg_info: TRegInfo);
        Function GetLastBill(Request: TRequest): integer;
        Function DoWithdrawMoney: TResultRecord;
        procedure GoOffline;
        procedure SetLogDirectory(const AValue: string);

    public
{ редактируемые поля }
        ofd_id: Cardinal;
        ofd_token: Cardinal;
        ofd_uid: string;
        local_name: string;
        use_software_vpn: boolean;
        printer: TPrinterEntity;
        auto_withdraw_money: boolean;
        vat_certificate: TVATCertificate;
        bindings: TBindings;
        custom_data: ISuperObject;

{ НЕ редактируемые поля }
        ID: integer;
        is_offline: boolean;
        is_invalid_token: boolean;
        is_blocked: boolean;
        blocked_info: string;
        ads_info: TArray<TSimpleTicketAD>;
        shift_state: TShiftState;
        shift_open_date: System.TDateTime;
        fr_shift_number: Cardinal;
        shift_document_number: Cardinal;
        owner_id: Cardinal;
        offline_start_date: System.TDateTime;
        offline_end_date: System.TDateTime;
        offline_ticket_number: integer;
        start_shift_non_nullable_sums: TSimpleNonNullableSum;
        non_nullable_sums: TSimpleNonNullableSum;
        vendor_id: string;
        req_num: word;
        cash_sum: Currency;
        revenue: Currency;
        reg_info: TRegInfoRecord;
        last_success_connect: System.TDateTime;

        Procedure WriteLog(const Data: string; const Params: array of TVarRec; ALogType: TLogType = TLogType.ltInfo); overload;
        Procedure WriteLog(const Data: string; ALogType: TLogType = TLogType.ltInfo); overload;

        procedure doCheckOfflineQueueDuration;
        procedure doCheckShiftDuration(const Command: TCommandTypeEnum);
        procedure DoOpenShift;
        Function DoCloseShift(Request: TRequest; Response: TResponse): TResultRecord; overload;
        Function DoCloseShift: boolean; overload;
        Function SendRequest(Request: TRequest; Response: TResponse; const DBRequestNumber: word = 0): TResultRecord;
        function GetFDConnection: TFDConnection;
        Function SaveRequest(Request: TRequest; Response: TResponse; const RequestNumber: word): int64;
        Function SaveResponse(Response: TResponse; const ARequestID: Cardinal): boolean;
        procedure CheckLastSuccessConnect;
        function isLongTimeDisconnected: boolean;

        Function GetLastShiftNumber: Cardinal;
        procedure SetLastShiftNumber(const AValue: Cardinal);
        Function GetLastDocumentNumber: Cardinal;
        procedure SetLastDocumentNumber(const AValue: Cardinal);
        Procedure SetOwnerID(const AValue: Cardinal);

        Function GetOfflineQueueStartDate(const AFrom: string): System.TDateTime;
        Function GetOperationData(const fr_shift_number_value: integer; const shift_document_number_value: integer; Request: TRequest; Response: TResponse): TResultRecord;
        Function GetAdsInfo: TArray<TSimpleTicketAD>;
        Procedure CheckOfflineQueue(OneTransaction: boolean = false);
        Procedure SetOFD(const AValue: TOfdRecord);
        Function GetOFD: TOfdRecord;
        Procedure SetNil;
        Function IsAssigned: boolean;
        Procedure AssignFrom(const Source: TCashRegisterRequest);
        Function AsJSON(const Ident: boolean = false; const UniversalTime: boolean = false; const Visibilities: TMemberVisibilities = DefaultVisibilities): string;
        Function AsJSON_Public(const Ident: boolean = false; const UniversalTime: boolean = false; const Visibilities: TMemberVisibilities = DefaultVisibilities): string;
        Function AsJSONObject_Public(const Visibilities: TMemberVisibilities = DefaultVisibilities): ISuperObject;
        function GetLastActivityDate: System.TDateTime;
        Function GetManufactureDate: System.TDateTime;

        Constructor FromJSON(const AValue: ISuperObject); overload;
        Constructor FromJSON(const AValue: String); overload;
        Procedure Destroy;
        Procedure Free;

        Procedure SetDBConnectionName(const AValue: string);
        function SetOperator(const AValue: TCashRegisterOperator): boolean;
        Function GetOperator: TCashRegisterOperator;
        procedure SetEventTimestamp(const AValue: int64);
        Procedure DoInit(DoRequestRegInfo: boolean = true);
        Procedure RequestRegInfo;

        Procedure BuildOfflineTicket(Request: proto.message.TRequest; Response: proto.message.TResponse);
        Function TradeOperation(Request: proto.message.TRequest): TResultRecord;
        Function BuildZXReport(report: TZXReport; const report_type: TReportTypeEnum): TResultRecord;
        Function ZXReport(const AReportType: proto.report.TReportTypeEnum; AResultReport: proto.report.TZXReport): TResultRecord;
        Function MoneyPlacement(const OperationType: TMoneyPlacementEnum; const OperationSum: Currency): TResultRecord;

        procedure SetLogger(const AValue: TLogger);

        procedure SetCheckVendorIDProc(AValue: TCheckVendorIDProc);
    end;


Function GenerateKKMVendorID(const AVendorIDPrefix: string): string;
Function GetKKMManufactureDate(const AValue: string): System.TDateTime;
Function GetCommandTypeStr(cmd: TCommandTypeEnum): string;
Function PrepareOperationsTable(FDConnection: TFDConnection): boolean;
function PrepareCashRegisterTables(FDConnection: TFDConnection): boolean;

implementation

uses
    uUtils,
    uDBUtils,
    DateUtils,
    uProtoUtils,
    Data.DB,
    idGlobal,
    System.IOUtils;


function PrepareCashRegisterTables(FDConnection: TFDConnection): boolean;
begin
    Result :=                                                            //
         CreateTableForClass(FDConnection, CashRegisterTableName)        //
         and                                                             //
         CreateTableForClass(FDConnection, CashRegisterOperatorTableName)//
         and                                                             //
         PrepareOperationsTable(FDConnection);
end;


Function GenerateKKMVendorID(const AVendorIDPrefix: string): string;
begin
    try
        Result := AVendorIDPrefix + '1' + MilliSecondsBetween(Now, StrToDate(cashbox_vendor_id_begin_date, CurrentFormatSettings)).ToString.PadLeft(cashbox_vendor_id_suffix_length - 1, '0');
    except
        Result := '';
    end;
end;


Function GetKKMManufactureDate(const AValue: string): System.TDateTime;
begin
    try
        Result := IncMilliSecond(StrToDate(cashbox_vendor_id_begin_date, CurrentFormatSettings), StrToInt64(AValue.Substring(AValue.Length - cashbox_vendor_id_suffix_length + 1)));
    except
        Result := 0;
    end;
end;


Function GetCommandTypeStr;
begin
    case cmd of
        COMMAND_SYSTEM:
            Result := 'COMMAND_SYSTEM';
        COMMAND_TICKET:
            Result := 'COMMAND_TICKET';
        COMMAND_CLOSE_SHIFT:
            Result := 'COMMAND_CLOSE_SHIFT';
        COMMAND_REPORT:
            Result := 'COMMAND_REPORT';
        COMMAND_NOMENCLATURE:
            Result := 'COMMAND_NOMENCLATURE';
        COMMAND_INFO:
            Result := 'COMMAND_INFO';
        COMMAND_MONEY_PLACEMENT:
            Result := 'COMMAND_MONEY_PLACEMENT';
        COMMAND_CANCEL_TICKET:
            Result := 'COMMAND_CANCEL_TICKET';
        COMMAND_AUTH:
            Result := 'COMMAND_AUTH';
        COMMAND_RESERVED:
            Result := 'COMMAND_RESERVED';
        else
            Result := 'UNKNOWN_COMMAND_TYPE';
    end;
end;


Procedure TCashRegister.SetDBConnectionName;
begin
    if AValue.IsEmpty then
        FreeDBConnection(FDConnection)
    else
        if not Assigned(FDConnection) then
            FDConnection := uDBUtils.GetDBConnection(AValue);
    if Assigned(FDConnection) then
        CheckLastSuccessConnect;
end;


procedure TCashRegister.SetEventTimestamp(const AValue: int64);
begin
    FEventTimestamp := AValue;
end;


procedure TCashRegister.SetLastDocumentNumber(const AValue: Cardinal);
begin
    FLastDocumentNumber := AValue;
end;


procedure TCashRegister.SetLastShiftNumber(const AValue: Cardinal);
begin
    FLastShiftNumber := AValue;
end;


procedure TCashRegister.SetLogDirectory(const AValue: string);
begin
    FLogger.LogDirectory := AValue;
end;


procedure TCashRegister.SetLogger(const AValue: TLogger);
begin
    FLogger := AValue;
end;


Procedure TCashRegister.SetNil;
begin
    self := Default (TCashRegister);
    SetLength(non_nullable_sums, byte(HIGH(TOperationTypeEnum)) + 1);
    SetLength(start_shift_non_nullable_sums, byte(HIGH(TOperationTypeEnum)) + 1);
    for var i := 0 to Length(non_nullable_sums) - 1 do
        non_nullable_sums[i] := 0;
    for var i := 0 to Length(start_shift_non_nullable_sums) - 1 do
        start_shift_non_nullable_sums[i] := 0;
end;


Procedure TCashRegister.SetOFD(const AValue: TOfdRecord);
begin
    FOFD := AValue;
    ofd_uid := FOFD.uid;
end;


function TCashRegister.SetOperator(const AValue: TCashRegisterOperator): boolean;
begin
    try
        Result :=                                  //
             (owner_id = 0) OR                     // если не задан владелец, значит касса добавлена в старой версии десктопного ядра
             (owner_id = AValue.ID) OR             // владелец
             (IntInArrayB(AValue.ID, bindings)) OR // кассир
             (IntInArrayB(ID, AValue.bindings))    // кассир
             ;
    except
        Result := false;
    end;

    if Result then
        FOperator := AValue;
end;


Procedure TCashRegister.SetOwnerID(const AValue: Cardinal);
begin
    owner_id := AValue;
end;


procedure TCashRegister.DoOpenShift;
begin
    WriteLog('TCashRegister.DoOpenShift for kkm_ofd_id = %d', [ofd_id]);

    if shift_state <> ssOpened then
    begin
        shift_state := TShiftState.ssOpened;
        shift_open_date := Now;
        WriteLog('Shift successfully opened now');
    end
    else
        WriteLog('Shift already opened since %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', shift_open_date)]);
end;


Function TCashRegister.DoWithdrawMoney: TResultRecord;
begin
    WriteLog('Method [DoWithdrawMoney] for kkm_ofd_id = %d', [ofd_id]);
    Result := MoneyPlacement(TMoneyPlacementEnum.MONEY_PLACEMENT_WITHDRAWAL, cash_sum);
end;


Procedure TCashRegister.Free;
begin
    Destroy;
end;


Procedure TCashRegister.Destroy;
begin
    if Assigned(FDConnection) then
    begin
        var
        X := TJSON.SuperObject(self);
        FDConnection.JSON_Object_Save(X, CashRegisterTableName);
        FreeDBConnection(FDConnection);
    end;
    SetNil;
end;


procedure TCashRegister.doCheckOfflineQueueDuration;
begin
    if (is_offline) and (offline_start_date > 0) and (SecondsBetween(offline_start_date, Now) >= cashbox_maximum_offline_queue_duration) then
    begin
        WriteLog('doCheckOfflineQueueDuration: more than 72 hours');
        raise Exc(rc_kkm_in_offline_mode_too_long);
    end
    else
        WriteLog('doCheckOfflineQueueDuration: OK');
end;


procedure TCashRegister.doCheckShiftDuration;
begin
    if (shift_state = TShiftState.ssOpened) AND (shift_open_date > 0) AND (HoursBetween(shift_open_date, Now) >= 24) then
    begin
        WriteLog('doCheckShiftDuration: more than 24 hours');
        if Command = TCommandTypeEnum.COMMAND_TICKET then // автозакрытие смены допустимо только при пробитии чека!
            DoCloseShift;
    end
    else
        WriteLog('doCheckShiftDuration: OK');
end;


Function TCashRegister.DoCloseShift(Request: TRequest; Response: TResponse): TResultRecord;
begin
    WriteLog('Method [DoCloseShift:TResultRecord] for kkm_ofd_id = %d', [ofd_id]);

    Request.Command := TCommandTypeEnum.COMMAND_CLOSE_SHIFT;
    Request.close_shift.fr_shift_number := fr_shift_number;
    Request.close_shift.printed_document_number := shift_document_number;

    if auto_withdraw_money AND (cash_sum > 0.00) then
    begin
        Result := DoWithdrawMoney;

        if not(Result.ResultCode in [rc_ok { , rc_connection_error } ]) then
            exit;

        Request.close_shift.withdraw_money := true;
    end;

    DateTimeToProto(Request.close_shift.close_time, Now);
    Request.close_shift.FieldHasValue[Request.close_shift.tag_close_time] := true;

    if FOperator.ID > 0 then
    begin
        Request.close_shift.&operator.code := FOperator.ID;
        Request.close_shift.&operator.name := FOperator.name;
    end
    else
    begin
        Request.close_shift.&operator.code := 0;
        Request.close_shift.&operator.name := 'auto_close_shift';
    end;
    Request.close_shift.FieldHasValue[Request.close_shift.tag_operator] := true;

    try
        Result := BuildZXReport(Request.close_shift.z_report, TReportTypeEnum.REPORT_Z);
    except
        on E: Exception do
        begin
            WriteLog('DoCloseShift -> BuildZXReport exception: [%s] %s', [E.ClassName, GetExceptionMessage(E)], ltError);
            raise;
        end;
    end;
    Request.close_shift.FieldHasValue[Request.close_shift.tag_z_report] := true;

    Request.FieldHasValue[Request.tag_close_shift] := true;

    Result := SendRequest(Request, Response);

    if Result.isPositive then
    begin
        Result.ResultCode := rc_ok;

        if is_offline then
        begin
            Request.close_shift.is_offline := true;

            Response.report.report := TReportTypeEnum.REPORT_Z;
            Response.report.zx_report.Assign(Request.close_shift.z_report);
            Response.report.FieldHasValue[Response.report.tag_zx_report] := true;
            Response.FieldHasValue[Response.tag_report] := true;

            Response.Result.result_code := byte(TResultTypeEnum.RESULT_TYPE_OK);
            Response.Result.result_text := 'ok(offline)';
            Response.FieldHasValue[Response.tag_result] := true;
        end;

        if is_offline then
            SaveRequest(Request, nil, req_num)
        else
            SaveRequest(Request, Response, req_num);

        for var operation_int := 0 to byte(HIGH(TOperationTypeEnum)) do
            start_shift_non_nullable_sums[operation_int] := non_nullable_sums[operation_int];

        inc(fr_shift_number);       // новая смена
        shift_state := ssClosed;    // не открытая
        shift_open_date := 0;       // обнуляем дату открытия новой смены
        shift_document_number := 1; // обнуляем номер документа новой смены
        revenue := 0;               // обнуляем выручку новой смены
    end;
end;


Procedure TCashRegister.DoInit;
begin
    WriteLog('TCashRegister.DoInit [%d], DoRequestRegInfo: %s', [ofd_id, VarToStr(DoRequestRegInfo)]);

    is_offline := GetOfflineQueueStartDate('DoInit') > 0;

    if (not is_offline) AND DoRequestRegInfo then
    begin
        var
        TryCount := {$IFDEF DEBUG} 1 {$ELSE} 3 {$ENDIF};
        while (TryCount > 0) do
        begin
            sleep((random(10)) * 100 + (random(10) + 1) * 100);
            try
                RequestRegInfo;
                break;
            except
                on E: Exception do
                    if E.HelpContext <> rc_connection_error then
                        break;
            end;
            dec(TryCount);
        end;
    end;

    if shift_document_number = 0 then
        shift_document_number := 1;
end;


Function TCashRegister.DoCloseShift: boolean;
var
    Request: TRequest;
    Response: TResponse;
    res: TResultRecord;
begin
    WriteLog('Method [DoCloseShift:boolean] for kkm_ofd_id = %d', [ofd_id]);
    Request := TRequest.Create;
    Response := TResponse.Create;
    res := DoCloseShift(Request, Response);
    Request.Destroy;
    Response.Destroy;
    Result := res.ResultCode in [rc_ok, rc_connection_error, rc_invalid_kkm_token];
end;


Procedure TCashRegister.CheckRegInfo(reg_info: TRegInfo);
begin
    if Assigned(FCheckVendorIDProc) then
        if not FCheckVendorIDProc(reg_info.kkm.serial_number, FOFD.vendorIdPrefix) then
        begin
            WriteLog('CheckRegInfo: unknown kkm.serial_number [%s]', [reg_info.kkm.serial_number]);
            raise Exc(rc_invalid_kkm_vendor_id);
        end;
end;


Constructor TCashRegister.FromJSON(const AValue: ISuperObject);
begin
    self.SetNil;
    self := TJSON.Parse<TCashRegister>(AValue);
end;


Constructor TCashRegister.FromJSON(const AValue: String);
begin
    self.FromJSON(SO(AValue));
end;


Procedure TCashRegister.RequestRegInfo;
const
    report_type: TArray<string>        = ['Z', 'X', 'SECTIONS', 'OPERATORS'];
    operation_type_str: TArray<string> = ['OPERATION_BUY', 'OPERATION_BUY_RETURN', 'OPERATION_SELL', 'OPERATION_SELL_RETURN'];
begin
    WriteLog('[TCashRegister.RequestRegInfo] kkm_ofd_id = %d', [ofd_id]);

    var
    Request := TRequest.Create;
    Request.Command := TCommandTypeEnum.COMMAND_INFO;

    var
    Response := TResponse.Create;

    var
    Result := SendRequest(Request, Response);
    Request.Destroy;

    if Result.ResultCode <> rc_ok then // если операция не успешна, то продолжать нельзя!
    begin
        Response.Destroy;
        raise Exc(Result.ResultCode);
    end;

    try
        CheckRegInfo(Response.service.reg_info);
    except
        Response.Destroy;
        raise;
    end;

    try
        if Response.FieldHasValue[Response.tag_service] AND Assigned(Response.service) AND Response.service.FieldHasValue[Response.service.tag_reg_info] AND Assigned(Response.service.reg_info) then
        begin
            reg_info.Assign(Response.service.reg_info);
            vendor_id := reg_info.kkm.serial_number;
        end;
    except
        on E: Exception do
        begin
            WriteLog(' [TCashRegister.RequestRegInfo] reg_info.Assign exception [%s] %s', [E.ClassName, GetExceptionMessage(E)], ltError);
            Response.Destroy;
            raise Exc(rc_kkm_reginfo_request_error);
        end;
    end;

    WriteLog('Received KKM state:');
    WriteLog('REPORT_%s', [report_type[byte(Response.report.report)]]);
    WriteLog('shift_open_date = %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', ProtoToDateTime(Response.report.zx_report.open_shift_time))]);
    WriteLog('shift_close_date = %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', ProtoToDateTime(Response.report.zx_report.close_shift_time))]);
    WriteLog('shift_number = %d', [Response.report.zx_report.shift_number]);
    WriteLog('cash_sum = %s', [FormatFloat('0.##', ProtoToSum(Response.report.zx_report.cash_sum))]);
    WriteLog('revenue = %s', [FormatFloat('0.##', ProtoToSum(Response.report.zx_report.revenue.sum, Response.report.zx_report.revenue.is_negative))]);

    if Response.report.zx_report.FieldHasValue[Response.report.zx_report.tag_non_nullable_sumsList] then
    begin
        WriteLog('non_nullable_sums:');
        for var nns in Response.report.zx_report.non_nullable_sumsList do
            WriteLog('[%d: %s] = %s', [byte(nns.operation), operation_type_str[byte(nns.operation)].PadRight(21, ' '), FormatFloat('0.##', ProtoToSum(nns.sum))]);
    end;

    is_offline := (GetOfflineQueueStartDate('RequestRegInfo') > 0);

    if is_offline then
    begin
        WriteLog('Unable to update local counters while offline.');
        Response.Destroy;
        exit;
    end;

    if                                                                      // если
         (Now < ProtoToDateTime(Response.report.zx_report.open_shift_time)) // текущая дата меньше даты открытия смены
         OR                                                                 // или
         (Now < ProtoToDateTime(Response.report.zx_report.close_shift_time))// текущая дата меньше даты закрытия смены
    then                                                                    // то блокируем работу кассы
    begin
        Response.Destroy;
        raise Exc(rc_invalid_local_date);
    end;

    if                                                                                  // если
         (byte(Response.report.report) <> byte(shift_state))                            // состояние смены различается
         or                                                                             // или
         (shift_open_date <> ProtoToDateTime(Response.report.zx_report.open_shift_time))// дата открытия смены различается
         or                                                                             // или
         (Response.report.zx_report.shift_number > fr_shift_number)                     // номер смены на сервере больше номера локальной смены
         or                                                                             // или
         (not NonNullableSumsEquals(Response.report.zx_report))                         // не совпадают необнуляемые суммы
    then                                                                                // то отобразим различия:
    begin
        WriteLog('Local KKM state:');
        WriteLog('REPORT_%s', [report_type[byte(shift_state)]]);
        WriteLog('shift_open_date = %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', shift_open_date)]);
        WriteLog('shift_number = %d', [fr_shift_number]);
        WriteLog('cash_sum = %s', [FormatFloat('0.##', cash_sum)]);
        WriteLog('revenue = %s', [FormatFloat('0.##', revenue)]);
        WriteLog('non_nullable_sums:');
        for var i := 0 to byte(HIGH(TOperationTypeEnum)) do
            WriteLog('[%d: %s] = %s', [i, operation_type_str[i].PadRight(21, ' '), FormatFloat('0.##', non_nullable_sums[i])]);
    end;

{ забираем все значения с сервера, т.к. это одно из основных требований к кассе! }

    if shift_document_number = 0 then
        shift_document_number := 1;

    shift_state := TShiftState(Response.report.report);
    revenue := ProtoToSum(Response.report.zx_report.revenue.sum, Response.report.zx_report.revenue.is_negative);

    if (Response.report.report = TReportTypeEnum.REPORT_Z) then
        shift_open_date := 0
    else
        shift_open_date := ProtoToDateTime(Response.report.zx_report.open_shift_time);

    fr_shift_number := Response.report.zx_report.shift_number;
    cash_sum := ProtoToSum(Response.report.zx_report.cash_sum);

    if                                                                                            // если
         (Response.report.report = TReportTypeEnum.REPORT_Z)                                      // смена не открыта
         and                                                                                      // и
         (Response.report.zx_report.FieldHasValue[Response.report.zx_report.tag_close_shift_time])// есть дата закрытия смены
         and                                                                                      // и
         (ProtoToDateTime(Response.report.zx_report.close_shift_time) > 0)                        // дата закрытия смены больше нуля
    then                                                                                          // значит
        inc(fr_shift_number);                                                                     // новая НЕоткрытая смена !!!

{ заполняем необнуляемые суммы значениями с сервера }
    if Response.report.zx_report.FieldHasValue[Response.report.zx_report.tag_non_nullable_sumsList] then
        for var nns in Response.report.zx_report.non_nullable_sumsList do
            if (non_nullable_sums[byte(nns.operation)] < ProtoToSum(nns.sum)) then
                non_nullable_sums[byte(nns.operation)] := ProtoToSum(nns.sum);

{ заполняем необнуляемые суммы на начало смены значениями с сервера }
    if Response.report.zx_report.FieldHasValue[Response.report.zx_report.tag_start_shift_non_nullable_sumsList] then
        for var nns in Response.report.zx_report.start_shift_non_nullable_sumsList do
            if (start_shift_non_nullable_sums[byte(nns.operation)] < ProtoToSum(nns.sum)) then
                start_shift_non_nullable_sums[byte(nns.operation)] := ProtoToSum(nns.sum);

    Response.Destroy;
end;


Function TCashRegister.GetAdsInfo: TArray<TSimpleTicketAD>;
begin
    Result := ads_info;
end;


function TCashRegister.GetFDConnection: TFDConnection;
begin
    Result := FDConnection;
end;


function TCashRegister.GetLastActivityDate: System.TDateTime;
begin
    Result := 0;
    Result := max(Result, shift_open_date);
    Result := max(Result, offline_start_date);
    Result := max(Result, offline_end_date);
end;


Function TCashRegister.GetLastBill;
begin
    WriteLog('Method [GetLastBill] for kkm_ofd_id = %d', [ofd_id]);
    Result := 0;
    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;
    try
        DB_Open(FDQuery, Format('SELECT * FROM `%s` WHERE (`kkm_id` = %d) AND (`command` = %d) ORDER BY `request_date` DESC LIMIT 1', [CashRegisterOperationsTableName, ID, byte(TCommandTypeEnum.COMMAND_TICKET)]));
    except
        FDQuery.SafeDestroy;
        exit;
    end;

    FDQuery.First;
    if FDQuery.RecordCount > 0 then
        Result := FDQuery.FieldByName('ID').AsLargeInt;

    if Result > 0 then
    begin
        var
        st := TMemoryStream.Create;
        try
            var
            bytes := FDQuery.FieldByName('request_data').AsBytes;
            st.Write(bytes[0], Length(bytes));
            st.Position := 0;
            Request.LoadFromStream(st);
        except
            on E: Exception do
            begin
                Result := 0;
                WriteLog('GetLastBill error [%s]: %s', [E.ClassName, E.message], ltError);
            end;
        end;
        st.Destroy;
    end;

    FDQuery.SafeDestroy;
    WriteLog('GetLastBill result: %d', [Result]);
end;


function TCashRegister.GetOFD: TOfdRecord;
begin
    Result := FOFD;
end;


Function TCashRegister.GetOfflineQueueStartDate;
begin
    Result := 0;

    WriteLog('Method [GetOfflineQueueStartDate] [from: %s] for kkm_ofd_id = %d', [AFrom, ofd_id]);

    if not Assigned(FDConnection) then
        exit;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;
    try
        DB_Open(FDQuery, Format('SELECT request_date FROM `%s` WHERE (`kkm_id` = %d) AND (`is_processed` = 0) AND (`is_offline` = 1) ORDER BY `request_date` LIMIT 1', [CashRegisterOperationsTableName, ID]));
        if FDQuery.RecordCount > 0 then
        begin
            FDQuery.First;
            Result := FDQuery.FieldByName('request_date').AsDateTime;
        end;
    except
        on E: Exception do
            WriteLog('GetOfflineQueueStartDate [from: %s] exception: [%s] %s', [AFrom, E.ClassName, E.message], ltError);
    end;

    FDQuery.SafeDestroy;
    WriteLog('GetOfflineQueueStartDate [from %s] result: %s', [AFrom, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Result)]);
end;


Function TCashRegister.GetOperationData;
begin
    WriteLog('Method [GetOperationData] for kkm_ofd_id = %d', [ofd_id]);
    Result.ResultCode := rc_operation_not_found;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;
    try
        DB_Open(FDQuery, Format('SELECT * FROM `%s` WHERE (`kkm_id` = %d) AND (`fr_shift_number` = %d) AND (`shift_document_number` = %d) ORDER BY `request_date` DESC', [CashRegisterOperationsTableName, ID, fr_shift_number_value, shift_document_number_value]));
    except
        FDQuery.SafeDestroy;
        exit;
    end;

    WriteLog('GetOperationData found operations: %d', [FDQuery.RecordCount]);

    if FDQuery.RecordCount > 0 then
    begin
        FDQuery.First;

        var
        st := TMemoryStream.Create;

        st.Size := 0;
        if not FDQuery.FieldByName('request_data').IsNull then
            try
                var
                bytes := FDQuery.FieldByName('request_data').AsBytes;
                st.Write(bytes[0], Length(bytes));
                st.Position := 0;
                Request.LoadFromStream(st);
                Result.ResultCode := rc_ok;
            except
                on E: Exception do
                begin
                    Result.ResultCode := rc_db_error;
                    WriteLog('GetOperationData error [%s]: %s', [E.ClassName, E.message], ltError);
                end;
            end;

        st.Size := 0;
        if not FDQuery.FieldByName('response_data').IsNull then
            try
                var
                bytes := FDQuery.FieldByName('response_data').AsBytes;
                st.Write(bytes[0], Length(bytes));
                st.Position := 0;
                Response.LoadFromStream(st);
                Result.ResultCode := rc_ok;
            except
                on E: Exception do
                begin
                    Result.ResultCode := rc_db_error;
                    WriteLog('GetOperationData error [%s]: %s', [E.ClassName, E.message], ltError);
                end;
            end;

        st.Destroy;
    end;

    FDQuery.SafeDestroy;

    WriteLog('GetOperationData result: %s', [ResponseText[Result.ResultCode]]);
end;


Function TCashRegister.GetLastDocumentNumber: Cardinal;
begin
    Result := FLastDocumentNumber;
end;


Function TCashRegister.GetLastShiftNumber: Cardinal;
begin
    Result := FLastShiftNumber;
end;


Function TCashRegister.GetManufactureDate: System.TDateTime;
begin
    Result := GetKKMManufactureDate(self.vendor_id);
end;


Function TCashRegister.SaveRequest(Request: TRequest; Response: TResponse; const RequestNumber: word): int64;
var
    LBytes: TBytes;
    last_id_selector: string;
    LOperation: byte;
begin
    WriteLog('[TCashRegister.SaveRequest] kkm_ofd_id = %d', [ofd_id]);

    Result := -1;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;

    case GetDBDriverID(FDQuery.Connection.ActualDriverID) of
        diSQLite:
            last_id_selector := 'last_insert_rowid';
        diPostgreSQL:
            last_id_selector := 'LASTVAL';
        diMySQL:
            last_id_selector := 'LAST_INSERT_ID';
    end;

    case Request.Command of
// COMMAND_CLOSE_SHIFT: ;
// COMMAND_REPORT: ;
// COMMAND_CANCEL_TICKET: ;
        COMMAND_TICKET:
            LOperation := byte(Request.ticket.operation);
        COMMAND_MONEY_PLACEMENT:
            LOperation := byte(Request.money_placement.operation);
        else
            LOperation := 0;
    end;

    FDQuery.SQL.Clear;

    FDQuery.SQL.Add('INSERT INTO `' + CashRegisterOperationsTableName + '` (');

    FDQuery.SQL.Add('`request_date`, ');
    FDQuery.SQL.Add('`command`, ');
    FDQuery.SQL.Add('`operation`, ');
    FDQuery.SQL.Add('`is_offline`, ');
    FDQuery.SQL.Add('`is_processed`, ');
    FDQuery.SQL.Add('`kkm_id`, ');
    FDQuery.SQL.Add('`fr_shift_number`, ');
    FDQuery.SQL.Add('`shift_document_number`, ');
    FDQuery.SQL.Add('`req_num`, ');
    FDQuery.SQL.Add('`request_data`, ');
    FDQuery.SQL.Add('`response_data`, ');
    FDQuery.SQL.Add('`response_date` ');

    FDQuery.SQL.Add(') VALUES ( ');
    FDQuery.SQL.Add(':request_date, ');
    FDQuery.SQL.Add(':command, ');
    FDQuery.SQL.Add(':operation, ');
    FDQuery.SQL.Add(':is_offline, ');
    FDQuery.SQL.Add(':is_processed, ');
    FDQuery.SQL.Add(':kkm_id, ');
    FDQuery.SQL.Add(':fr_shift_number, ');
    FDQuery.SQL.Add(':shift_document_number, ');
    FDQuery.SQL.Add(':req_num, ');
    FDQuery.SQL.Add(':request_data, ');
    FDQuery.SQL.Add(':response_data, ');
    FDQuery.SQL.Add(':response_date ');
    FDQuery.SQL.Add('); ');

    FDQuery.Params.ParamByName('request_date').AsDateTime := Now;
    FDQuery.Params.ParamByName('command').AsByte := byte(Request.Command);
    FDQuery.Params.ParamByName('operation').AsByte := LOperation;
    FDQuery.Params.ParamByName('is_offline').AsInteger := byte(is_offline);
    FDQuery.Params.ParamByName('kkm_id').AsInteger := ID;
    FDQuery.Params.ParamByName('fr_shift_number').AsInteger := fr_shift_number;
    FDQuery.Params.ParamByName('shift_document_number').AsInteger := shift_document_number;
    FDQuery.Params.ParamByName('req_num').AsWord := RequestNumber;
    FDQuery.Params.ParamByName('request_data').DataType := ftBlob;
    FDQuery.Params.ParamByName('response_data').DataType := ftBlob;

    var
    st := TMemoryStream.Create;

    try
        if Assigned(Request) then
        begin
            st.Size := 0;
            Request.SaveToStream(st);
            st.Position := 0;
            SetLength(LBytes, st.Size);
            st.Read(LBytes[0], Length(LBytes));
            FDQuery.Params.ParamByName('request_data').SetData(@LBytes[0], Length(LBytes));
            SetLength(LBytes, 0);
        end
        else
            FDQuery.Params.ParamByName('request_data').Value := null;

        if Assigned(Response) then
        begin
            st.Size := 0;
            Response.SaveToStream(st);
            st.Position := 0;
            SetLength(LBytes, st.Size);
            st.Read(LBytes[0], Length(LBytes));
            FDQuery.Params.ParamByName('response_data').SetData(@LBytes[0], Length(LBytes));
            FDQuery.Params.ParamByName('response_date').AsDateTime := Now;
            FDQuery.Params.ParamByName('is_processed').AsInteger := byte(true);
            SetLength(LBytes, 0);
        end
        else
        begin
            FDQuery.Params.ParamByName('response_data').Value := null;
            FDQuery.Params.ParamByName('response_date').AsDateTime := 0;
            FDQuery.Params.ParamByName('is_processed').AsInteger := byte(false);
        end;
    except
        on E: Exception do
        begin
            st.Destroy;
            FDQuery.SafeDestroy;
            WriteLog('[TCashRegister.SaveRequest] PREPARE exception: [%s] %s', [E.ClassName, E.message]);
            exit;
        end;
    end;

    st.Destroy;

    try
        DB_ExecSQL(FDQuery);
        DB_Open(FDQuery, Format('SELECT %s() as inserted_id;', [last_id_selector]));
        Result := FDQuery.FieldByName('inserted_id').AsLargeInt; // int64(FDQuery.Connection.GetLastAutoGenValue(''));
    except
        on E: Exception do
        begin
            WriteLog('[TCashRegister.SaveRequest] INSERT exception [%s]: %s', [E.ClassName, E.message], ltError);
            Result := -1;
        end;
    end;

    FDQuery.SafeDestroy;

    WriteLog('[TCashRegister.SaveRequest] kkm_ofd_id: %d, Result: %d', [ofd_id, Result]);
end;


Function TCashRegister.SaveResponse(Response: TResponse; const ARequestID: Cardinal): boolean;
var
    bytes: TBytes;
begin
    WriteLog('TCashRegister.SaveResponse: kkm_ofd_id = %d, ARequestID = %d', [ofd_id, ARequestID]);
    Result := false;

    var
    st := TMemoryStream.Create;
    try
        Response.SaveToStream(st);
    except
        on E: Exception do
        begin
            st.Destroy;
            WriteLog('TCashRegister.SaveResponse exception: [%s] %s', [E.ClassName, E.message], ltError);
            exit;
        end;
    end;
    st.Position := 0;
    SetLength(bytes, st.Size);
    st.Read(bytes[0], Length(bytes));
    st.Destroy;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;

    FDQuery.SQL.Text := 'UPDATE `' + CashRegisterOperationsTableName + '` SET `response_date` = :p0, `is_processed` = :p1, `response_data` = :p2 WHERE `ID` = :p3;';
    FDQuery.Params[0].AsDateTime := Now;
    FDQuery.Params[1].AsInteger := byte(true);
    FDQuery.Params[2].DataType := ftBlob;
    FDQuery.Params[2].SetData(@bytes[0], Length(bytes));
    FDQuery.Params[3].AsLargeInt := ARequestID;

    try
        DB_ExecSQL(FDQuery);
        Result := FDQuery.RowsAffected > 0;
    except
        on E: Exception do
        begin
            Result := false;
            WriteLog('SaveResponse UPDATE error [%s]: %s', [E.ClassName, E.message], ltError);
        end;
    end;

    FDQuery.SafeDestroy;

    WriteLog('TCashRegister.SaveResponse: kkm_ofd_id = %d, ARequestID = %d, Result = %s', [ofd_id, ARequestID, VarToStr(Result)]);
end;


procedure TCashRegister.GoOffline;
begin
    if not is_offline then
    begin
        WriteLog('Going to offline!');
        is_offline := true;
        offline_start_date := Now;
    end;
end;


Function TCashRegister.SendRequest(Request: TRequest; Response: TResponse; const DBRequestNumber: word = 0): TResultRecord;
var
    Header: THeader;
    TCPClient: TIdTCPClient;
    IOHandler: TIdIOHandlerStack;
    SocksInfo: TIdSocksInfo;
    st: TStream;
    FStream: TFileStream;
    LShiftNumber: integer;
begin
    Result.Clear;

    LShiftNumber := 0;
    case Request.Command of
        COMMAND_TICKET:
            LShiftNumber := Request.ticket.fr_shift_number;
        COMMAND_CLOSE_SHIFT:
            LShiftNumber := Request.close_shift.fr_shift_number;
        COMMAND_REPORT:
            LShiftNumber := Request.report.zx_report.shift_number;
        COMMAND_MONEY_PLACEMENT:
            LShiftNumber := Request.money_placement.fr_shift_number;
    end;

    var
    LShiftStateStr := TShiftStateStr[byte(shift_state)];
    if shift_state = ssOpened then
        LShiftStateStr := Format('%s since %s', [LShiftStateStr, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', shift_open_date)]);

    WriteLog('Method [SendRequest]: kkm_ofd_id = %d, command = %d [%s]', [ofd_id, byte(Request.Command), GetCommandTypeStr(Request.Command)]);
    WriteLog('LShiftNumber: %d, fr_shift_number: %d, shift_state: %s', [LShiftNumber, fr_shift_number, LShiftStateStr]);
    WriteLog('last_success_connect: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', last_success_connect)]);

    if FOFD.Host.IsEmpty or (FOFD.Port = 0) then
    begin
        Result.ResultCode := rc_invalid_kkm_ofd;
        exit;
    end;

    if DBRequestNumber <= 0 then
    begin
        inc(req_num);
        if req_num = 0 then
            req_num := 1;
    end;

// {$IFDEF DEBUG}
    WriteLog('DBRequestNumber: %d, REQ_NUM: %d', [DBRequestNumber, req_num]);
// {$ENDIF} //

{ если касса находится в автономном режиме, то нельзя пропускать чеки, отчёты, внесения/изъятия: }
    if is_offline AND (DBRequestNumber <= 0) then
        if Request.Command in [COMMAND_TICKET, COMMAND_CLOSE_SHIFT, COMMAND_REPORT, COMMAND_MONEY_PLACEMENT] then
        begin
            Result.ResultCode := rc_connection_error;
            exit;
        end;

{ добавляем к каждому запросу сервисную информацию (1, 2): }
    Request.FieldHasValue[Request.tag_service] := true;

{ 1 - RegInfo }
    if reg_info.IsAssigned then
// doSync(
// procedure
    begin
        Request.service.reg_info.kkm.AssignFromJSON(TJSON.SuperObject(reg_info.kkm));
        Request.service.reg_info.FieldHasValue[Request.service.reg_info.tag_kkm] := true;

        Request.service.reg_info.org.AssignFromJSON(TJSON.SuperObject(reg_info.org));
        Request.service.reg_info.FieldHasValue[Request.service.reg_info.tag_org] := true;
    end
// )
         ;
    Request.service.FieldHasValue[Request.service.tag_reg_info] := true;

{ 2 - время пребывания в автономном режиме }
    DateTimeToProto(Request.service.offline_period.begin_time, offline_start_date);
    Request.service.offline_period.FieldHasValue[Request.service.offline_period.tag_begin_time] := true;
    if not Request.service.offline_period.FieldHasValue[Request.service.offline_period.tag_end_time] then
    begin
        DateTimeToProto(Request.service.offline_period.end_time, offline_end_date);
        Request.service.offline_period.FieldHasValue[Request.service.offline_period.tag_end_time] := true;
    end;
    Request.service.FieldHasValue[Request.service.tag_offline_period] := true;

{ готовим заголовок запроса }
    Header.AppCode := $81A2;
    Header.version := proto_version;
    Header.ID := ofd_id;
    Header.Token := ofd_token;

    if DBRequestNumber > 0 then
        Header.ReqNum := DBRequestNumber
    else
        Header.ReqNum := req_num;

    st := TMemoryStream.Create;
    st.Write(Header, sizeof(Header));
    try
        Request.SaveToStream(st);
    except
        on E: Exception do
        begin
            WriteLog('TCashRegister.SendRequest -> Request.SaveToStream exception: [%s] %s', [E.ClassName, E.message], ltError);
            st.Destroy;
            Result.ResultCode := rc_protobuf_serialization_error;
            exit;
        end;
    end;
    st.Position := 0;
    Header.Size := st.Size;
    st.Write(Header, sizeof(Header));
    st.Position := 0;

{$IF defined(DEBUG) OR defined(CUSTOM_BUILD)}
    WriteLog('REQUEST HEADER: %s', [TJSON.Stringify(Header)]);
{$ENDIF} //

    TCPClient := TIdTCPClient.Create(nil);
    TCPClient.ConnectTimeout := cashbox_default_connect_timeout;
    TCPClient.ReadTimeout := cashbox_default_read_timeout;

    TCPClient.Host := TNetEncoding.Base64.decode(FOFD.Host);
    TCPClient.Port := FOFD.Port;

    IOHandler := TIdIOHandlerStack.Create;

    WriteLog('use_software_vpn = %s', [VarToStr(use_software_vpn)]);

    if use_software_vpn then
    begin
        if not FOFD.proxy.isActual then
            WriteLog('SoftwareVPN not defined!')
        else
        begin
            WriteLog('Used SoftwareVPN!');

            SocksInfo := TIdSocksInfo.Create;
            SocksInfo.IPVersion := TIdIPVersion.Id_IPv4;
            SocksInfo.version := TSocksVersion.svSocks5;
            SocksInfo.Authentication := TSocksAuthentication.saUsernamePassword;

            SocksInfo.Host := TNetEncoding.Base64.decode(FOFD.proxy.Host);
            SocksInfo.Port := FOFD.proxy.Port;
            SocksInfo.Username := TNetEncoding.Base64.decode(FOFD.proxy.Username);
            SocksInfo.Password := TNetEncoding.Base64.decode(FOFD.proxy.Password);
            IOHandler.TransparentProxy := SocksInfo;

        end;
    end;

    WriteLog('OFD: [%s/%s] %s', [FOFD.vendorIdPrefix, FOFD.name, {$IFDEF DEBUG}TCPClient.Host + ':' + TCPClient.Port.ToString{$ELSE}''{$ENDIF} ]);

    TCPClient.IOHandler := IOHandler;

{$IFDEF KKM_BINARY_LOG}
    FStream := nil;
    try
        FStream := TFileStream.Create(TPath.Combine(ExtractFilePath(ParamStr(0)), Format('%d-%s-%d-request.bin', [GetCommandTypeStr(Request.Command), MilliSecondsBetween(Now, UnixDateDelta)])), fmCreate);
        FStream.CopyFrom(st);
    except
    end;
    if Assigned(FStream) then
        FStream.Destroy;
{$ENDIF} //

    try
{$IFDEF KKM_EMULATE_RESPONSES}
        st.Size := 0;
        FStream := nil;
        try
            FStream := TFileStream.Create(TPath.Combine(TDirectory.GetCurrentDirectory, Format('%s-MOCK-response.bin', [GetCommandTypeStr(Request.Command)])), fmOpenRead);
            st.CopyFrom(FStream);
        except
            on E: Exception do
                WriteLog('MOCK load exception: [%s] %s', [E.ClassName, E.message], TLogType.ltError);
        end;
        if Assigned(FStream) then
            FStream.Destroy;
{$ELSE}
        WriteLog('Connecting...');
        TCPClient.Connect;
        WriteLog('Sending request [%d]...', [Header.ReqNum]);
        TCPClient.Socket.Write(st);
        st.Size := 0;

        WriteLog('Reading header...');
        TCPClient.Socket.ReadStream(st, sizeof(Header));

        st.Position := 0;
        st.Read(Header, sizeof(Header));

{$IF defined(DEBUG) OR defined(CUSTOM_BUILD)}
        WriteLog('RESPONSE HEADER: %s', [TJSON.Stringify(Header)]);
{$ENDIF} //

        if Header.Token <> ofd_token then
        begin
            WriteLog('Token updated!');

{$IFDEF DEBUG}
            WriteLog('OldToken: %s', [ofd_token.ToString]);
            WriteLog('NewToken: %s', [Header.Token.ToString]);
{$ENDIF DEBUG}
            ofd_token := Header.Token;

        end;
        st.Position := st.Size;

        WriteLog('Reading data...');
        TCPClient.Socket.ReadStream(st, Header.Size - sizeof(Header));

        TCPClient.Disconnect;
        last_success_connect := Now;
        WriteLog('Connection closed.');

{$IFDEF KKM_BINARY_LOG}
        FStream := nil;
        try
            FStream := TFileStream.Create(TPath.Combine(GetStreamsDirectory, Format('%d-%s-%d-response.bin', [GetCommandTypeStr(Request.Command), MilliSecondsBetween(Now, UnixDateDelta)])), fmCreate);
            FStream.CopyFrom(st);
        except
        end;
        if Assigned(FStream) then
            FStream.Destroy;
{$ENDIF KKM_BINARY_LOG} //

{$ENDIF KKM_EMULATE_RESPONSES} //

        st.Position := sizeof(Header);

        try
            Response.LoadFromStream(st);
        except
            on E: Exception do
            begin
                WriteLog('TCashRegister.SendRequest -> Response.LoadFromStream exception: [%s] %s', [E.ClassName, E.message], ltError);
                raise Exc(rc_protobuf_deserialization_error);
            end;
        end;
// Response.AsJSONObject.SaveTo(TPath.Combine(GetWorkDirectory, 'response.json'), true);

// Response.Result.result_code := byte(TResultTypeEnum.RESULT_TYPE_BLOCKED); { MOCK }
// Response.Result.result_text := 'KKM is blocked [ MOCK ]';                 { MOCK }

        if Response.FieldHasValue[Response.tag_service] and Response.service.FieldHasValue[Response.service.tag_ticket_adsList] then
        begin
            SetLength(ads_info, Length(Response.service.ticket_adsList));
            for var i := 0 to Length(Response.service.ticket_adsList) - 1 do
                ads_info[i] := TJSON.Parse<TSimpleTicketAD>(Response.service.ticket_adsList[i].AsJSONObject());
        end
        else
            SetLength(ads_info, 0);

        if Response.FieldHasValue[Response.tag_result] then
        begin
            WriteLog('OFD_RESULT: [%d] %s', [Response.Result.result_code, Response.Result.result_text]);

            is_invalid_token := TResultTypeEnum(Response.Result.result_code) = RESULT_TYPE_INVALID_TOKEN;
            is_blocked := TResultTypeEnum(Response.Result.result_code) = RESULT_TYPE_BLOCKED;

            WriteLog('is_invalid_token: %s', [VarToStr(is_invalid_token)]);
            WriteLog('is_blocked: %s', [VarToStr(is_blocked)]);

            case TResultTypeEnum(Response.Result.result_code) of

                RESULT_TYPE_OK:
                    begin
                    end;

                RESULT_TYPE_UNKNOWN_ID:
                    raise Exception.CreateHelp('Flag UNKNOWN_ID detected!', rc_invalid_kkm_ofd_id);

                RESULT_TYPE_INVALID_TOKEN:
                    raise Exception.CreateHelp('Flag INVALID_TOKEN detected!', rc_invalid_kkm_token);

                RESULT_TYPE_BLOCKED:
                    begin
                        blocked_info := Response.Result.result_text.Trim;
                        raise Exception.CreateHelp('Flag BLOCKED detected!', rc_kkm_is_blocked);
                    end;

                RESULT_TYPE_SAME_TAXPAYER_AND_CUSTOMER:
                    raise Exception.CreateHelp('Flag SAME_TAXPAYER_AND_CUSTOMER detected!', rc_same_taxpayer_and_customer);

                RESULT_TYPE_SERVICE_TEMPORARILY_UNAVAILABLE:
                    raise Exception.CreateHelp('Flag SERVICE_TEMPORARILY_UNAVAILABLE detected!', rc_connection_error);

                else
                    raise Exception.CreateHelp('Unhandled OFD response', rc_invalid_ofd_response);
            end;
        end

    except
        on E: Exception do
        begin
            WriteLog('SendRequest exception: [%d: %s] %s: %s', [E.HelpContext, ResponseText[E.HelpContext], E.ClassName, GetExceptionMessage(E)], ltError);
            Result.ResultCode := E.HelpContext;
            if Result.ResultCode = rc_ok then
                Result.ResultCode := rc_connection_error { или всё-таки rc_operation_failed ? };
        end;
    end;

    if Result.ResultCode in [0 .. byte(Length(ResponseText))] then
        Result.ResultText := ResponseText[Result.ResultCode]
    else
        Result.ResultText := 'unknown_result_text';

    if Result.ResultCode in [rc_connection_error, rc_invalid_kkm_token] then
        GoOffline;

// if Assigned(SocksInfo) then
// SocksInfo.Free; // вызывает AV в линуксе, поэтому отключено!

    if Assigned(IOHandler) then
        IOHandler.Free;

    if Assigned(TCPClient) then
        TCPClient.Free;

    if Assigned(st) then
        st.Free;
end;


procedure TCashRegister.SetCheckVendorIDProc(AValue: TCheckVendorIDProc);
begin
    FCheckVendorIDProc := AValue;
end;


function TCashRegister.isLongTimeDisconnected: boolean;
begin
    Result := (last_success_connect > 0) AND (SecondsBetween(last_success_connect, Now) > cashbox_maximum_offline_queue_duration);
end;


Function TCashRegister.NonNullableSumsEquals(zx_report: TZXReport): boolean;
begin
    Result := true;
    if zx_report.FieldHasValue[zx_report.tag_non_nullable_sumsList] then
        for var nns in zx_report.non_nullable_sumsList do
            if non_nullable_sums[byte(nns.operation)] <> ProtoToSum(nns.sum) then
                Result := false;
end;


function TCashRegister.GetOperator: TCashRegisterOperator;
begin
    Result := FOperator;
end;


Procedure TCashRegister.CheckOfflineQueue;
var
    RowCount: integer;
    Counter: integer;
begin
    if (not is_offline) OR (is_invalid_token) then
        exit;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;
    try
        DB_Open(FDQuery, Format('SELECT * FROM `%s` WHERE (`kkm_id` = %d) AND (`is_processed` = 0) AND (`is_offline` = 1)  ORDER BY `request_date`;', [CashRegisterOperationsTableName, ID]));
    except
        on E: Exception do
        begin
            WriteLog('[TCashRegister.CheckOfflineQueue] exception <query>: [%s] %s', [E.ClassName, E.message], ltError);
            FDQuery.SafeDestroy;
            exit;
        end;
    end;

    RowCount := FDQuery.RecordCount;
    Counter := 0;

    WriteLog('[TCashRegister.CheckOfflineQueue] KKM: %d, tran_count: %d', [ofd_id, RowCount]);

    FDQuery.First;

    while not FDQuery.Eof do
    begin
// sleep(100);

        if TThread.CurrentThread.CheckTerminated then
        begin
            WriteLog('[TCashRegister.CheckOfflineQueue] <break>: TThread.CurrentThread.CheckTerminated');
            break;
        end;

(*

ПРОРАБОТАТЬ ФУНКЦИОНАЛ (!):
    если кассе требуется пробить чек/отчёт/внесение/изъятие - наверное нужно остановить выгрузку автономки?
    иначе при плохой связи автономка будет выгружаться долго и чеки пробиваться не смогут, т.к. касса будет постоянно занята!

        if FOperationQueueCount > 1 then
        begin
            WriteLog('[CheckOfflineQueue] <break>: FOperationQueue.Count = %d', [FOperationQueueCount]);
            break;
        end;
*)
        var
        st := TMemoryStream.Create;
        var
        Request := TRequest.Create;
        var
        Response := TResponse.Create;
        try
            var
            LRequestID := FDQuery.FieldByName('ID').AsInteger;
            var
            LRequestNumber := FDQuery.FieldByName('req_num').AsInteger;
            var
            bytes := FDQuery.FieldByName('request_data').AsBytes;
            st.Write(bytes[0], Length(bytes));
            st.Position := 0;
            Request.LoadFromStream(st);

            DateTimeToProto(Request.service.offline_period.begin_time, offline_start_date);
            Request.service.offline_period.FieldHasValue[Request.service.offline_period.tag_begin_time] := true;

            DateTimeToProto(Request.service.offline_period.end_time, Now);
            Request.service.offline_period.FieldHasValue[Request.service.offline_period.tag_end_time] := true;

            Request.service.FieldHasValue[Request.service.tag_offline_period] := true;

            Request.FieldHasValue[Request.tag_service] := true;

            WriteLog('[TCashRegister.CheckOfflineQueue] ofd_id: %d, Transaction ID: %d, LRequestNumber: %d', [ofd_id, LRequestID, LRequestNumber]);

            var
            res := SendRequest(Request, Response, LRequestNumber);

            if res.ResultCode <> rc_ok then
                raise Exc(res.ResultCode);

            if not SaveResponse(Response, LRequestID) then
                raise Exc(rc_db_error);

            inc(Counter);
            FDQuery.Next;
        except
            on E: Exception do
            begin
                WriteLog('[TCashRegister.CheckOfflineQueue] exception <SendRequest> [%d %s]: %s', [E.HelpContext, E.ClassName, GetExceptionMessage(E)], ltError);
                FDQuery.Last;
            end;
        end;
        st.Destroy;
        Request.Destroy;
        Response.Destroy;

        if OneTransaction then
            break;
    end;

    FDQuery.SafeDestroy;

    if RowCount > 0 then
        WriteLog('[TCashRegister.CheckOfflineQueue] rows processed: %d / %d', [Counter, RowCount]);

    if (RowCount <= 0) OR (Counter >= RowCount) then
    begin
        WriteLog('[TCashRegister.CheckOfflineQueue] KKM [%d] returned from offline mode.', [ofd_id]);
        offline_start_date := 0;
        is_offline := false;
    end;
end;


Function PrepareOperationsTable(FDConnection: TFDConnection): boolean;
var
    strType_DateTime: string;
    strType_ID: string;
    strType_binary: string;
begin
    case GetDBDriverID(FDConnection) of
        diSQLite:
            begin
                strType_ID := 'INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL';
                strType_binary := 'BLOB';
                strType_DateTime := 'DATETIME';
            end;
        diPostgreSQL:
            begin
                strType_ID := 'BIGSERIAL PRIMARY KEY NOT NULL';
                strType_binary := 'BYTEA'; // bytea / oid
                strType_DateTime := 'TIMESTAMP';
            end;
        diMySQL:
            begin
                strType_ID := 'INT PRIMARY KEY AUTO_INCREMENT NOT NULL';
                strType_binary := 'BLOB';
                strType_DateTime := 'DATETIME';
            end;
    end;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;
    FDQuery.SQL.Clear;
    FDQuery.SQL.Add('CREATE TABLE IF NOT EXISTS `' + CashRegisterOperationsTableName + '` (');
    FDQuery.SQL.Add(Format('`ID` %s, ', [strType_ID]));
    FDQuery.SQL.Add(Format('`request_date` %s, ', [strType_DateTime]));
    FDQuery.SQL.Add(Format('`response_date` %s, ', [strType_DateTime]));
    FDQuery.SQL.Add('`command` INTEGER, ');
    FDQuery.SQL.Add('`operation` INTEGER, ');
    FDQuery.SQL.Add('`req_num` INTEGER DEFAULT 0, ');
    FDQuery.SQL.Add('`kkm_id` INTEGER, ');
    FDQuery.SQL.Add('`fr_shift_number` INTEGER, ');
    FDQuery.SQL.Add('`shift_document_number` INTEGER, ');
    FDQuery.SQL.Add('`is_offline` INTEGER, ');
    FDQuery.SQL.Add('`is_processed` INTEGER, ');
// FDQuery.SQL.Add('`request_uid` TEXT, ');
    FDQuery.SQL.Add(Format('`request_data` %s, ', [strType_binary]));
    FDQuery.SQL.Add(Format('`response_data` %s ', [strType_binary]));
    FDQuery.SQL.Add(');');
    try
        DB_ExecSQL(FDQuery);
        Result := true;
    except
        on E: Exception do
        begin
// WriteLog('PrepareOperationsTable error [%s]: %s', [E.ClassName, E.message], ltError);
            Result := false;
        end;
    end;

(*
    try
{ добавляем новые столбцы в уже существующую таблицу }
        DB_ExecSQL(FDQuery, 'ALTER TABLE `' + CashRegisterOperationsTableName + '` ADD COLUMN `request_uid` TEXT');
        WriteLog('Column `request_uid` added successfully', ltGeneral);
    except
        WriteLog('Column `request_uid` already exists', ltGeneral);
    end;
*)

    FDQuery.SafeDestroy;
end;


procedure TCashRegister.CheckLastSuccessConnect;
begin
    if (last_success_connect > 0) OR (not Assigned(FDConnection)) then
        exit;

    WriteLog('Method [CheckLastSuccessConnect] for kkm_ofd_id = %d', [ofd_id]);

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;
    try
        DB_Open(FDQuery, Format('SELECT * FROM `%s` WHERE (`kkm_id` = %d) ORDER BY `response_date` DESC LIMIT 1;', [CashRegisterOperationsTableName, ID]));
        FDQuery.First;
        if                                                        //
             (FDQuery.RecordCount > 0)                            //
             AND                                                  //
             (not FDQuery.FieldByName('response_date').IsNull)    //
             AND                                                  //
             (FDQuery.FieldByName('response_date').AsDateTime > 0)//
        then                                                      //
        begin
            last_success_connect := FDQuery.FieldByName('response_date').AsDateTime;
            WriteLog('TCashRegister.CheckLastSuccessConnect: last_success_connect changed to "%s"', [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', last_success_connect)]);
        end;
    except
        on E: Exception do
        begin
            WriteLog('[TCashRegister.CheckLastSuccessConnect] exception: [%s] %s', [E.ClassName, E.message], ltError);
            FDQuery.SafeDestroy;
            exit;
        end;
    end;

    FDQuery.SafeDestroy;
end;


Procedure TCashRegister.WriteLog(const Data: string; const Params: array of TVarRec; ALogType: TLogType = TLogType.ltInfo);
begin
    FLogger.LogPrefix := 'kkm_' + ofd_id.ToString;
    FLogger.WriteLog(Format('[%d] ', [FEventTimestamp]) + Data, Params, ALogType);
end;


Procedure TCashRegister.WriteLog(const Data: string; ALogType: TLogType = TLogType.ltInfo);
begin
    WriteLog(Data, [], ALogType);
end;


Function TCashRegister.IsAssigned: boolean;
begin
    Result := (ofd_id > 0);
end;


Function TCashRegister.AsJSON;
begin
    Result := TJSON.Stringify(self, Ident, UniversalTime, Visibilities);
end;


function TCashRegister.AsJSONObject_Public(const Visibilities: TMemberVisibilities): ISuperObject;
begin
    Result := TJSON.SuperObject(self, Visibilities);
    Result.Remove('ofd_token');
    Result.Remove('req_num');
end;


function TCashRegister.AsJSON_Public(const Ident, UniversalTime: boolean; const Visibilities: TMemberVisibilities): string;
begin
    Result := AsJSONObject_Public(Visibilities).AsJSON(Ident, UniversalTime, Visibilities);
end;


Procedure TCashRegister.AssignFrom(const Source: TCashRegisterRequest);
begin
    self.local_name := Source.local_name;
    self.use_software_vpn := Source.use_software_vpn;
    self.printer := Source.printer;
    self.auto_withdraw_money := Source.auto_withdraw_money;
    self.vat_certificate := Source.vat_certificate;
    self.custom_data := Source.custom_data;
    self.bindings := Source.bindings;
end;


Function TCashRegister.TradeOperation;
var
    totalSum: Currency;
    takenTotal: Currency;
    takenCash: Currency;
    takenCard: Currency;
    taken: Currency;
    paidCash: Currency;
    paidCard: Currency;
    changeSum: Currency;
    discountSum: Currency;
    markupSum: Currency;
    sumToPay: Currency;
    cash_sum_new: Currency;
    revenue_new: Currency;
    non_nullable_sums_new: Currency;
    itemDiscountSum: Currency;
    itemMarkupSum: Currency;
    itemTotalSum: Currency;

begin
    try
        WriteLog('[TCashRegister.TradeOperation] cash_sum BEFORE: %s', [FormatFloat('0.00', cash_sum)]);
{ проверка продолжительности оффлайн режима (72 часа) }
        doCheckOfflineQueueDuration;

{ контроль продолжительности смены (24 часа) }
        doCheckShiftDuration(Request.Command);

{ проверка на совпадение ИИН/БИН продавца и покупателя: }
        if                                                                                                           //
             (not reg_info.org.inn.IsEmpty)                                                                          //
             and                                                                                                     //
             Request.ticket.FieldHasValue[Request.ticket.tag_extension_options]                                      //
             and                                                                                                     //
             Request.ticket.extension_options.FieldHasValue[Request.ticket.extension_options.tag_customer_iin_or_bin]//
             and                                                                                                     //
             SameText(Request.ticket.extension_options.customer_iin_or_bin, reg_info.org.inn)                        //
        then
            raise Exc(rc_same_taxpayer_and_customer);

        takenCash := 0.00;
        takenCard := 0.00;
        takenTotal := 0.00;
        taken := 0.00;
        paidCash := 0.00;
        paidCard := 0.00;
        changeSum := 0.00;
        totalSum := 0.00;

        markupSum := ProtoToSum(Request.ticket.amounts.markup.sum);
        discountSum := ProtoToSum(Request.ticket.amounts.discount.sum);

        if discountSum < 0.00 then
            raise Exc(rc_discount_sum_is_negative);

        if markupSum < 0.00 then
            raise Exc(rc_markup_sum_is_negative);

        if (discountSum > 0.00) and (markupSum > 0.00) then
            raise Exc(rc_discount_and_markup_are_mutually_exclusive);

        cash_sum_new := cash_sum;
        revenue_new := revenue;

        itemDiscountSum := 0.00;
        itemMarkupSum := 0.00;
        itemTotalSum := 0.00;

        for var TicketItem in Request.ticket.itemsList do
        begin
            case TicketItem.&type of
                TItemTypeEnum.ITEM_TYPE_COMMODITY:
                    begin
                        itemTotalSum := ProtoToSum(TicketItem.commodity.sum);
                        totalSum := totalSum + itemTotalSum;
                        itemDiscountSum := 0.00;
                        itemMarkupSum := 0.00;
                    end;
                TItemTypeEnum.ITEM_TYPE_MARKUP:
                    begin
                        itemMarkupSum := itemMarkupSum + ProtoToSum(TicketItem.markup.sum);
                    end;
                TItemTypeEnum.ITEM_TYPE_DISCOUNT:
                    begin
                        itemDiscountSum := itemDiscountSum + ProtoToSum(TicketItem.discount.sum);
                    end;
            end;

            if (itemDiscountSum > 0.00) and (itemMarkupSum > 0.00) then
                raise Exc(rc_discount_and_markup_are_mutually_exclusive);

            if (itemTotalSum > 0.00) and (itemDiscountSum >= itemTotalSum) then
                raise Exc(rc_discount_sum_must_be_less_than_total);

            markupSum := markupSum + itemMarkupSum;
            discountSum := discountSum + itemDiscountSum;

        end;

{ итог по чеку должен быть больше нуля : }
        if totalSum <= 0.00 then
            raise Exc(rc_amounts_total_is_incorrect);

{ скидка должна быть меньше итоговой суммы: }
        if (totalSum > 0.00) and (discountSum >= totalSum) then
            raise Exc(rc_discount_sum_must_be_less_than_total);

        sumToPay := totalSum - discountSum + markupSum;

{ сумма к оплате должна быть больше нуля : }
        if (sumToPay <= 0.00) then
            raise Exc(rc_sum_to_pay_is_incorrect);

        SumToProto(Request.ticket.amounts.total, sumToPay); // с учётом ВСЕХ модификаторов! ( 30.05.2022 )
        Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_total] := true;
        Request.ticket.FieldHasValue[Request.ticket.tag_amounts] := true;

        for var payment in Request.ticket.paymentsList do
            case payment.&type of

                PAYMENT_CASH:
                    takenCash := takenCash + ProtoToSum(payment.sum);

                PAYMENT_CARD, PAYMENT_CREDIT, PAYMENT_TARE, PAYMENT_MOBILE:
                    takenCard := takenCard + ProtoToSum(payment.sum);
            end;

        if (takenCard > sumToPay) then
            raise Exc(rc_card_sum_is_greater_than_total);

        if Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_taken] then
            taken := ProtoToSum(Request.ticket.amounts.taken);

        takenCash := max(taken, takenCash);

        takenTotal := takenCash + takenCard;

        if takenTotal <= 0.00 then
            raise Exc(rc_paid_sum_is_incorrect);

        if takenTotal < sumToPay then
            raise Exc(rc_paid_sum_is_less_than_total);

        changeSum := max(0.00, takenTotal - sumToPay);

        paidCash := takenCash - changeSum;

        for var payment in Request.ticket.paymentsList do
            if payment.&type = PAYMENT_CASH then
                SumToProto(payment.sum, paidCash);

        if (takenCash > 0.00) then
        begin
            SumToProto(Request.ticket.amounts.taken, takenCash);
            Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_taken] := true;
        end
        else
        begin
            SumToProto(Request.ticket.amounts.taken, 0.00);
            Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_taken] := false;
        end;

        if changeSum > 0.00 then
        begin
            SumToProto(Request.ticket.amounts.change, changeSum);
            Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_change] := true;
        end
        else
        begin
            SumToProto(Request.ticket.amounts.change, 0.00);
            Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_change] := false;
        end;

        case Request.ticket.operation of

            OPERATION_BUY:
                begin
                    if cash_sum < paidCash then
                        raise Exc(rc_not_enough_cash);

                    cash_sum_new := cash_sum - paidCash;
                    revenue_new := revenue - sumToPay;
                end;

            OPERATION_BUY_RETURN:
                begin
                    cash_sum_new := cash_sum + paidCash;
                    revenue_new := revenue + sumToPay;
                end;

            OPERATION_SELL:
                begin
                    cash_sum_new := cash_sum + paidCash;
                    revenue_new := revenue + sumToPay;
                end;

            OPERATION_SELL_RETURN:
                begin
                    if cash_sum < paidCash then
                        raise Exc(rc_not_enough_cash);

                    cash_sum_new := cash_sum - paidCash;
                    revenue_new := revenue - totalSum;
                end;

        end;

        non_nullable_sums_new := non_nullable_sums[byte(Request.ticket.operation)] + sumToPay;

{ по решению Рустема отключаем отправку этого поля : }
        Request.ticket.FieldHasValue[Request.ticket.tag_printed_ticket] := false;

{ контроль состояния смены }
        DoOpenShift;

        DateTimeToProto(Request.ticket.date_time, Now);
        Request.ticket.FieldHasValue[Request.ticket.tag_date_time] := true;

        Request.ticket.fr_shift_number := fr_shift_number;
        Request.ticket.shift_document_number := shift_document_number;

        var
        Response := proto.message.TResponse.Create;

        Result := SendRequest(Request, Response);

        if Result.isPositive then
        begin
            Result.ResultCode := rc_ok;

{ если касса в автономном режиме, значит надо сформировать автономный чек : }
            if is_offline then
                BuildOfflineTicket(Request, Response);

            if Response.FieldHasValue[Response.tag_ticket] then
            begin
                Request.ticket.printed_document_number_old := Response.ticket.ticket_number;
                Request.ticket.printed_ticket := BytesToString(TIdBytes(Response.ticket.qr_code));
            end;

{ сохраняем запрос и ответ: }

            if is_offline then
                SaveRequest(Request, nil, req_num)
            else
                SaveRequest(Request, Response, req_num);

{ актуализируем счётчики: }
            cash_sum := cash_sum_new;
            revenue := revenue_new;
            non_nullable_sums[byte(Request.ticket.operation)] := non_nullable_sums_new;
            SetLastShiftNumber(fr_shift_number);
            SetLastDocumentNumber(shift_document_number);
            inc(shift_document_number);
            WriteLog('[TCashRegister.TradeOperation] cash_sum AFTER: %s', [FormatFloat('0.00', cash_sum)]);
        end;

// Request.Destroy; - это делает инициатор!
        Response.Destroy;
    except
        on E: Exception do
        begin
            if E.HelpContext > 0 then
                Result.ResultCode := E.HelpContext
            else
                Result.ResultCode := rc_operation_failed;
            WriteLog('TCashRegister.TradeOperation exception [%d]: [%s] %s', [Result.ResultCode, E.ClassName, GetExceptionMessage(E)], ltError);
        end;
    end;
end;


procedure TCashRegister.BuildOfflineTicket;
begin
    if offline_ticket_number < 1000 then
        offline_ticket_number := 1000;
    inc(offline_ticket_number);

    Request.ticket.offline_ticket_number := offline_ticket_number;

    Response.Command := Request.Command;

    Response.ticket.ticket_number := offline_ticket_number.ToString;

    Response.ticket.qr_code := TBytes(ToBytes(Format('%s/?&i=%s&f=%s&s=%s&t=%sT%s', [//
         GetOFD.consumerAddress,                                                     // http://consumer.oofd.kz
         Response.ticket.ticket_number,                                              // i
         reg_info.kkm.fns_kkm_id,                                                    // f
         FormatFloat('0.00', ProtoToSum(Request.ticket.amounts.total)),              // s
         FormatDateTime('yyyymmdd', ProtoToDateTime(Request.ticket.date_time)),      // t - дата
         FormatDateTime('hhnnss', ProtoToDateTime(Request.ticket.date_time))         // t - время
         ]), IndyTextEncoding_UTF8));
    Response.FieldHasValue[Response.tag_ticket] := true;

    Response.Result.result_code := byte(TResultTypeEnum.RESULT_TYPE_OK);
    Response.Result.result_text := 'ok(offline)';

    Response.FieldHasValue[Response.tag_result] := true;
end;


function TCashRegister.BuildZXReport(report: TZXReport; const report_type: TReportTypeEnum): TResultRecord;
var
    operations: TSimpleOperations;
    discounts: TSimpleOperations;
    markups: TSimpleOperations;
    total_result: TSimpleOperations;
    ticket_operations: TSimpleTicketOperations;
    money_placements: TSimpleReportMoneyPlacements;
    section_name: string;
    section_code_hash: string;
begin
    WriteLog('Method [BuildZXReport] for kkm_ofd_id = %d', [ofd_id]);
    WriteLog('[TCashRegister.BuildZXReport] cash_sum = %s', [FormatFloat('0.00', cash_sum)]);

    if not(report_type in [LOW(TReportTypeEnum) .. HIGH(TReportTypeEnum)]) then
        raise Exc(rc_invalid_report_type);

    SetLastShiftNumber(fr_shift_number);
    SetLastDocumentNumber(shift_document_number);

    report.shift_number := fr_shift_number;

    DateTimeToProto(report.date_time, Now);
    report.FieldHasValue[report.tag_date_time] := true;

    DateTimeToProto(report.open_shift_time, shift_open_date);
    report.FieldHasValue[report.tag_open_shift_time] := true;

    DateTimeToProto(report.close_shift_time, Now);
    report.FieldHasValue[report.tag_close_shift_time] := true;

    SumToProto(report.cash_sum, cash_sum);
    report.FieldHasValue[report.tag_cash_sum] := true;

    SumToProto(report.revenue.sum, abs(revenue));
    report.revenue.FieldHasValue[report.revenue.tag_sum] := true;
    report.revenue.is_negative := revenue < 0;

    report.FieldHasValue[report.tag_revenue] := true;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := GetFDConnection;
    try
        DB_Open(FDQuery, Format('SELECT * FROM `%s` WHERE (`kkm_id` = %d) AND (`fr_shift_number` = %d)', [CashRegisterOperationsTableName, ID, report.shift_number]));
    except
        FDQuery.SafeDestroy;
        Result.ResultCode := rc_db_error;
        exit;
    end;

    FillChar(operations, sizeof(operations), 0);
    FillChar(discounts, sizeof(discounts), 0);
    FillChar(markups, sizeof(markups), 0);
    FillChar(total_result, sizeof(total_result), 0);
    FillChar(ticket_operations, sizeof(ticket_operations), 0);
    FillChar(money_placements, sizeof(money_placements), 0);

    var
    Sections := SO();

    var
    Taxes := SO();

    FDQuery.First;

    while not FDQuery.Eof do
    begin
        var
        st := TMemoryStream.Create;

        var
        Request := TRequest.Create;

        try
            var
            bytes := FDQuery.FieldByName('request_data').AsBytes;
            st.Write(bytes[0], Length(bytes));
            bytes := nil;
            st.Position := 0;
            Request.LoadFromStream(st);
        except
            on E: Exception do
                WriteLog('BuildZXReport deserialization error [%s]: %s', [E.ClassName, E.message], ltError);
        end;
        st.Destroy;

        try
            if Request.AllRequiredFieldsValid then
            begin
                case Request.Command of
                    COMMAND_TICKET:
                        begin
                            var
                            operation_int := byte(Request.ticket.operation);
                            if operation_int IN [0 .. byte(high(TOperationTypeEnum))] then
                            begin
                                if Request.ticket.FieldHasValue[Request.ticket.tag_itemsList] then
                                    for var TicketItem in Request.ticket.itemsList do
                                    begin
                                        case TicketItem.&type of
                                            TItemTypeEnum.ITEM_TYPE_COMMODITY:
                                                begin
                                                    inc(operations[operation_int].Count);
                                                    operations[operation_int].sum := operations[operation_int].sum + ProtoToSum(TicketItem.commodity.sum);

                                                    inc(total_result[operation_int].Count);
                                                    total_result[operation_int].sum := total_result[operation_int].sum + ProtoToSum(TicketItem.commodity.sum);

                                                    if report_type = TReportTypeEnum.REPORT_OPERATORS then
                                                        section_name := Format('[%d] %s', [Request.ticket.&operator.code, Request.ticket.&operator.name])
                                                    else
                                                        section_name := TicketItem.commodity.section_code;

                                                    section_code_hash := MD5(section_name);

                                                    Sections.O[section_code_hash].O[operation_int.ToString].S['section_code'] := section_name;
                                                    Sections.O[section_code_hash].O[operation_int.ToString].i['count'] := Sections.O[section_code_hash].O[operation_int.ToString].i['count'] + 1 { trunc(TicketItem.commodity.quantity / 1000) };
                                                    Sections.O[section_code_hash].O[operation_int.ToString].F['sum'] := Sections.O[section_code_hash].O[operation_int.ToString].F['sum'] + ProtoToSum(TicketItem.commodity.sum);

                                                    try
                                                        if TicketItem.commodity.FieldHasValue[TicketItem.commodity.tag_TaxesList] then
                                                            for var tax in TicketItem.commodity.taxesList do
                                                            begin
                                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['tax_type'] := integer(tax.tax_type);
                                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['taxation_type'] := integer(tax.taxation_type);
                                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] + ProtoToSum(tax.sum);
                                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] + ProtoToSum(TicketItem.commodity.sum) { + ProtoToSum(tax.sum) };
                                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] + ProtoToSum(TicketItem.commodity.sum) - ProtoToSum(tax.sum);
                                                            end;
                                                    except
                                                        on E: Exception do
                                                            WriteLog('TicketItem.commodity.taxesList exception: [%s] %s', [E.ClassName, E.message], ltError);
                                                    end;
                                                end;
                                            TItemTypeEnum.ITEM_TYPE_MARKUP:
                                                begin
                                                    inc(markups[operation_int].Count);
                                                    markups[operation_int].sum := markups[operation_int].sum + ProtoToSum(TicketItem.markup.sum);
                                                    total_result[operation_int].sum := total_result[operation_int].sum + ProtoToSum(TicketItem.markup.sum);
// ticket_operations[operation_int].markup_sum := ticket_operations[operation_int].markup_sum + ProtoToSum(TicketItem.markup.sum);
                                                    if TicketItem.markup.FieldHasValue[TicketItem.markup.tag_TaxesList] then
                                                        for var tax in TicketItem.markup.taxesList do
                                                        begin
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['tax_type'] := integer(tax.tax_type);
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['taxation_type'] := integer(tax.taxation_type);
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] + ProtoToSum(tax.sum);
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] + ProtoToSum(TicketItem.markup.sum) { + ProtoToSum(tax.sum) };
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] + ProtoToSum(TicketItem.markup.sum) - ProtoToSum(tax.sum);
                                                        end;
                                                end;
                                            TItemTypeEnum.ITEM_TYPE_DISCOUNT:
                                                begin
                                                    inc(discounts[operation_int].Count);
                                                    discounts[operation_int].sum := discounts[operation_int].sum + ProtoToSum(TicketItem.discount.sum);
                                                    total_result[operation_int].sum := total_result[operation_int].sum - ProtoToSum(TicketItem.discount.sum);
// ticket_operations[operation_int].discount_sum := ticket_operations[operation_int].discount_sum + ProtoToSum(TicketItem.discount.sum);
                                                    if TicketItem.discount.FieldHasValue[TicketItem.discount.tag_TaxesList] then
                                                        for var tax in TicketItem.discount.taxesList do
                                                        begin
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['tax_type'] := integer(tax.tax_type);
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['taxation_type'] := integer(tax.taxation_type);
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] - ProtoToSum(tax.sum);
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] - ProtoToSum(TicketItem.discount.sum) { - ProtoToSum(tax.sum) };
                                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] - ProtoToSum(TicketItem.discount.sum) - ProtoToSum(tax.sum);
                                                        end;
                                                end;
                                        end;
                                    end;

                                if Request.ticket.FieldHasValue[Request.ticket.tag_amounts] then
                                begin
                                    if Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_markup] then
                                    begin
                                        inc(markups[operation_int].Count);
                                        markups[operation_int].sum := markups[operation_int].sum + ProtoToSum(Request.ticket.amounts.markup.sum);
                                        total_result[operation_int].sum := total_result[operation_int].sum + ProtoToSum(Request.ticket.amounts.markup.sum);
                                        ticket_operations[operation_int].markup_sum := ticket_operations[operation_int].markup_sum + ProtoToSum(Request.ticket.amounts.markup.sum);
                                        for var tax in Request.ticket.amounts.markup.taxesList do
                                        begin
                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['tax_type'] := integer(tax.tax_type);
                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['taxation_type'] := integer(tax.taxation_type);
                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] + ProtoToSum(tax.sum);
                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] + ProtoToSum(Request.ticket.amounts.markup.sum) { + ProtoToSum(tax.sum) };
                                            Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] + ProtoToSum(Request.ticket.amounts.markup.sum) - ProtoToSum(tax.sum);
                                        end;
                                    end;

                                    if Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_discount] then
                                    begin
                                        inc(discounts[operation_int].Count);
                                        discounts[operation_int].sum := discounts[operation_int].sum + ProtoToSum(Request.ticket.amounts.discount.sum);
                                        total_result[operation_int].sum := total_result[operation_int].sum - ProtoToSum(Request.ticket.amounts.discount.sum);
                                        ticket_operations[operation_int].discount_sum := ticket_operations[operation_int].discount_sum + ProtoToSum(Request.ticket.amounts.discount.sum);
                                        if Request.ticket.amounts.discount.FieldHasValue[Request.ticket.amounts.discount.tag_TaxesList] then
                                            for var tax in Request.ticket.amounts.discount.taxesList do
                                            begin
                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['tax_type'] := integer(tax.tax_type);
                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['taxation_type'] := integer(tax.taxation_type);
                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] - ProtoToSum(tax.sum);
                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] - ProtoToSum(Request.ticket.amounts.discount.sum) { - ProtoToSum(tax.sum) };
                                                Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] - ProtoToSum(Request.ticket.amounts.discount.sum) - ProtoToSum(tax.sum);
                                            end;
                                    end;
                                end;

                                if Request.ticket.FieldHasValue[Request.ticket.tag_TaxesList] then
                                    for var tax in Request.ticket.taxesList do
                                    begin
                                        Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['tax_type'] := integer(tax.tax_type);
                                        Taxes.O[tax.percent.ToString].O[operation_int.ToString].i['taxation_type'] := integer(tax.taxation_type);
                                        Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['sum'] + ProtoToSum(tax.sum);
                                        Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover'] + ProtoToSum(Request.ticket.amounts.total) { + ProtoToSum(tax.sum) };
                                        Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] := Taxes.O[tax.percent.ToString].O[operation_int.ToString].F['turnover_without_tax'] + ProtoToSum(Request.ticket.amounts.total) - ProtoToSum(tax.sum);
                                    end;

                                inc(ticket_operations[operation_int].tickets_count);
                                ticket_operations[operation_int].tickets_sum := ticket_operations[operation_int].tickets_sum + ProtoToSum(Request.ticket.amounts.total);
                                if Request.ticket.FieldHasValue[Request.ticket.tag_offline_ticket_number] then
                                    inc(ticket_operations[operation_int].offline_count);

                                if Request.ticket.amounts.FieldHasValue[Request.ticket.amounts.tag_change] then
                                    ticket_operations[operation_int].change_sum := ticket_operations[operation_int].change_sum + ProtoToSum(Request.ticket.amounts.change);

                                if Request.ticket.FieldHasValue[Request.ticket.tag_paymentsList] then
                                    for var payment in Request.ticket.paymentsList do
                                    begin
                                        inc(ticket_operations[operation_int].payments[byte(payment.&type)].Count);
                                        ticket_operations[operation_int].payments[byte(payment.&type)].sum := ticket_operations[operation_int].payments[byte(payment.&type)].sum + ProtoToSum(payment.sum);
                                    end;
                            end;
                        end;
                    COMMAND_MONEY_PLACEMENT:
                        begin
                            var
                            payment_int := byte(Request.money_placement.operation);
                            if payment_int IN [0 .. byte(high(TMoneyPlacementEnum))] then
                            begin
                                inc(money_placements[payment_int].operations_count);
                                money_placements[payment_int].operations_sum := money_placements[payment_int].operations_sum + ProtoToSum(Request.money_placement.sum);
                                if Request.money_placement.is_offline then
                                    inc(money_placements[payment_int].offline_count);
                            end;
                        end;
                end;
            end;
        except
            on E: Exception do
                WriteLog('Main block exception: [%s] %s', [E.ClassName, GetExceptionMessage(E)], ltError);
        end;

        Request.Destroy;

        FDQuery.Next;
    end;

    FDQuery.Close;

    FDQuery.SQL.Clear;
    FDQuery.SQL.Add('SELECT ');
    FDQuery.SQL.Add(Format('(SELECT count(*) FROM `%s` WHERE `kkm_id` = %d AND `command` = %d AND `operation` = %d) as OPERATION_BUY, ', [CashRegisterOperationsTableName, ID, byte(TCommandTypeEnum.COMMAND_TICKET), byte(TOperationTypeEnum.OPERATION_BUY)]));
    FDQuery.SQL.Add(Format('(SELECT count(*) FROM `%s` WHERE `kkm_id` = %d AND `command` = %d AND `operation` = %d) as OPERATION_BUY_RETURN, ', [CashRegisterOperationsTableName, ID, byte(TCommandTypeEnum.COMMAND_TICKET), byte(TOperationTypeEnum.OPERATION_BUY_RETURN)]));
    FDQuery.SQL.Add(Format('(SELECT count(*) FROM `%s` WHERE `kkm_id` = %d AND `command` = %d AND `operation` = %d) as OPERATION_SELL, ', [CashRegisterOperationsTableName, ID, byte(TCommandTypeEnum.COMMAND_TICKET), byte(TOperationTypeEnum.OPERATION_SELL)]));
    FDQuery.SQL.Add(Format('(SELECT count(*) FROM `%s` WHERE `kkm_id` = %d AND `command` = %d AND `operation` = %d) as OPERATION_SELL_RETURN, ', [CashRegisterOperationsTableName, ID, byte(TCommandTypeEnum.COMMAND_TICKET), byte(TOperationTypeEnum.OPERATION_SELL_RETURN)]));
    FDQuery.SQL.Add(Format('(SELECT count(*) FROM `%s` WHERE `kkm_id` = %d AND `command` = %d AND `operation` = %d) as MONEY_PLACEMENT_DEPOSIT, ', [CashRegisterOperationsTableName, ID, byte(TCommandTypeEnum.COMMAND_MONEY_PLACEMENT), byte(TMoneyPlacementEnum.MONEY_PLACEMENT_DEPOSIT)]));
    FDQuery.SQL.Add(Format('(SELECT count(*) FROM `%s` WHERE `kkm_id` = %d AND `command` = %d AND `operation` = %d) as MONEY_PLACEMENT_WITHDRAWAL ', [CashRegisterOperationsTableName, ID, byte(TCommandTypeEnum.COMMAND_MONEY_PLACEMENT), byte(TMoneyPlacementEnum.MONEY_PLACEMENT_WITHDRAWAL)]));

    try
        DB_Open(FDQuery);
    except
        on E: Exception do
        begin
            FDQuery.SafeDestroy;
            raise Exception.CreateHelp(Format('BuldZXReport DB exception: [%s] %s', [E.ClassName, E.message]), rc_db_error);
        end;
    end;

    FDQuery.First;

    ticket_operations[byte(TOperationTypeEnum.OPERATION_BUY)].tickets_total_count := FDQuery.FieldByName('OPERATION_BUY').AsInteger;
    ticket_operations[byte(TOperationTypeEnum.OPERATION_BUY_RETURN)].tickets_total_count := FDQuery.FieldByName('OPERATION_BUY_RETURN').AsInteger;
    ticket_operations[byte(TOperationTypeEnum.OPERATION_SELL)].tickets_total_count := FDQuery.FieldByName('OPERATION_SELL').AsInteger;
    ticket_operations[byte(TOperationTypeEnum.OPERATION_SELL_RETURN)].tickets_total_count := FDQuery.FieldByName('OPERATION_SELL_RETURN').AsInteger;

    money_placements[byte(TMoneyPlacementEnum.MONEY_PLACEMENT_DEPOSIT)].operations_total_count := FDQuery.FieldByName('MONEY_PLACEMENT_DEPOSIT').AsInteger;
    money_placements[byte(TMoneyPlacementEnum.MONEY_PLACEMENT_WITHDRAWAL)].operations_total_count := FDQuery.FieldByName('MONEY_PLACEMENT_WITHDRAWAL').AsInteger;

    FDQuery.SafeDestroy;

{ ЗАПОЛНЕНИЕ ТЕЛА ОТЧЁТА СОБРАННЫМИ ДАННЫМИ : }

    SetLength(report.sectionsList, 0);
    SetLength(report.operationsList, 0);

    Sections.First;
    while not Sections.Eof do
    begin
        var
        X := SO(Sections.O[Sections.CurrentKey].AsJSON());
        X.First;
        while not X.Eof do
        begin
            var
            operation_int := X.CurrentKey.ToInteger();
            var
            section := TSection.Create;
            section.section_code := X.O[X.CurrentKey].S['section_code'];

            var
            operation := proto.report.TOperation.Create;
            operation.operation := TOperationTypeEnum(operation_int);
            operation.Count := X.O[X.CurrentKey].i['count'];
            SumToProto(operation.sum, X.O[X.CurrentKey].F['sum']);
            operation.FieldHasValue[operation.tag_sum] := true;

            SetLength(section.operationsList, Length(section.operationsList) + 1);
            section.operationsList[Length(section.operationsList) - 1] := operation;
            section.FieldHasValue[section.tag_operationsList] := true;

            SetLength(report.sectionsList, Length(report.sectionsList) + 1);
            report.sectionsList[Length(report.sectionsList) - 1] := section;
            report.FieldHasValue[report.tag_sectionsList] := true;

            X.Next;
        end;
        Sections.Next;
    end;

    for var operation_int := 0 to byte(HIGH(TOperationTypeEnum)) do
        if (operations[operation_int].Count > 0) or (operations[operation_int].sum > 0) then
        begin
            var
            operation := proto.report.TOperation.Create;
            operation.operation := TOperationTypeEnum(operation_int);
            operation.Count := operations[operation_int].Count;
            SumToProto(operation.sum, operations[operation_int].sum);
            operation.FieldHasValue[operation.tag_sum] := true;
            SetLength(report.operationsList, Length(report.operationsList) + 1);
            report.operationsList[Length(report.operationsList) - 1] := operation;
            report.FieldHasValue[report.tag_operationsList] := true;
        end;

    SetLength(report.markupsList, 0);
    for var operation_int := 0 to byte(HIGH(TOperationTypeEnum)) do
        if (markups[operation_int].Count > 0) or (markups[operation_int].sum > 0) then
        begin
            var
            operation := proto.report.TOperation.Create;
            operation.operation := TOperationTypeEnum(operation_int);
            operation.Count := markups[operation_int].Count;
            SumToProto(operation.sum, markups[operation_int].sum);
            operation.FieldHasValue[operation.tag_sum] := true;
            SetLength(report.markupsList, Length(report.markupsList) + 1);
            report.markupsList[Length(report.markupsList) - 1] := operation;
            report.FieldHasValue[report.tag_markupsList] := true;
        end;

    SetLength(report.discountsList, 0);
    for var operation_int := 0 to byte(HIGH(TOperationTypeEnum)) do
        if (discounts[operation_int].Count > 0) or (discounts[operation_int].sum > 0) then
        begin
            var
            operation := proto.report.TOperation.Create;
            operation.operation := TOperationTypeEnum(operation_int);
            operation.Count := discounts[operation_int].Count;
            SumToProto(operation.sum, discounts[operation_int].sum);
            operation.FieldHasValue[operation.tag_sum] := true;
            SetLength(report.discountsList, Length(report.discountsList) + 1);
            report.discountsList[Length(report.discountsList) - 1] := operation;
            report.FieldHasValue[report.tag_discountsList] := true;
        end;

    SetLength(report.total_resultList, 0);
    for var operation_int := 0 to byte(HIGH(TOperationTypeEnum)) do
        if (total_result[operation_int].Count > 0) or (total_result[operation_int].sum > 0) then
        begin
            var
            operation := proto.report.TOperation.Create;
            operation.operation := TOperationTypeEnum(operation_int);
            operation.Count := total_result[operation_int].Count;
            SumToProto(operation.sum, total_result[operation_int].sum);
            operation.FieldHasValue[operation.tag_sum] := true;
            SetLength(report.total_resultList, Length(report.total_resultList) + 1);
            report.total_resultList[Length(report.total_resultList) - 1] := operation;
            report.FieldHasValue[report.tag_total_resultList] := true;
        end;

    SetLength(report.taxesList, 0);
    Taxes.First;
    while not Taxes.Eof do
    begin
        var
        X := SO(Taxes.O[Taxes.CurrentKey].AsJSON());
        X.First;
        while not X.Eof do
        begin
            var
            operation_int := X.CurrentKey.ToInteger();

            var
            report_tax := proto.report.TTax.Create;

            report_tax.tax_type := TTaxTypeEnum(X.O[X.CurrentKey].i['tax_type']);
            report_tax.percent := Taxes.CurrentKey.ToInteger();

            var
            tax_operation := TTaxOperation.Create;

            tax_operation.operation := TOperationTypeEnum(operation_int);

            SumToProto(tax_operation.turnover, X.O[X.CurrentKey].F['turnover']);
            tax_operation.FieldHasValue[tax_operation.tag_turnover] := true;

            SumToProto(tax_operation.turnover_without_tax, X.O[X.CurrentKey].F['turnover_without_tax']);
            tax_operation.FieldHasValue[tax_operation.tag_turnover_without_tax] := true;

            SumToProto(tax_operation.sum, X.O[X.CurrentKey].F['sum']);
            tax_operation.FieldHasValue[tax_operation.tag_sum] := true;

            SetLength(report_tax.operationsList, Length(report_tax.operationsList) + 1);
            report_tax.operationsList[Length(report_tax.operationsList) - 1] := tax_operation;
            report_tax.FieldHasValue[report_tax.tag_operationsList] := true;

            SetLength(report.taxesList, Length(report.taxesList) + 1);
            report.taxesList[Length(report.taxesList) - 1] := report_tax;
            report.FieldHasValue[report.tag_TaxesList] := true;

            X.Next;
        end;
        Taxes.Next;
    end;

    SetLength(report.ticket_operationsList, 0);
    for var operation_int := 0 to byte(HIGH(TOperationTypeEnum)) do
        if (ticket_operations[operation_int].tickets_total_count > 0) or (ticket_operations[operation_int].tickets_count > 0) or (ticket_operations[operation_int].tickets_sum > 0) or (ticket_operations[operation_int].offline_count > 0) then
        begin
            var
            TicketOperation := TTicketOperation.Create;
            SetLength(TicketOperation.paymentsList, 0);
            TicketOperation.operation := TOperationTypeEnum(operation_int);

            TicketOperation.tickets_total_count := ticket_operations[operation_int].tickets_total_count;
            TicketOperation.tickets_count := ticket_operations[operation_int].tickets_count;
            TicketOperation.offline_count := ticket_operations[operation_int].offline_count;

            SumToProto(TicketOperation.tickets_sum, ticket_operations[operation_int].tickets_sum);
            TicketOperation.FieldHasValue[TicketOperation.tag_tickets_sum] := true;

            SumToProto(TicketOperation.discount_sum, ticket_operations[operation_int].discount_sum);
            TicketOperation.FieldHasValue[TicketOperation.tag_discount_sum] := true;

            SumToProto(TicketOperation.markup_sum, ticket_operations[operation_int].markup_sum);
            TicketOperation.FieldHasValue[TicketOperation.tag_markup_sum] := true;

            SumToProto(TicketOperation.change_sum, ticket_operations[operation_int].change_sum);
            TicketOperation.FieldHasValue[TicketOperation.tag_change_sum] := true;

            for var payment_int := 0 to byte(HIGH(TPaymentTypeEnum)) do
                if (ticket_operations[operation_int].payments[payment_int].Count > 0) or (ticket_operations[operation_int].payments[payment_int].sum > 0) then
                begin
                    var
                    report_payment := proto.report.TPayment.Create;
                    report_payment.payment := TPaymentTypeEnum(payment_int);
                    report_payment.Count := ticket_operations[operation_int].payments[payment_int].Count;
                    SumToProto(report_payment.sum, ticket_operations[operation_int].payments[payment_int].sum);
                    report_payment.FieldHasValue[report_payment.tag_sum] := true;

                    SetLength(TicketOperation.paymentsList, Length(TicketOperation.paymentsList) + 1);
                    TicketOperation.paymentsList[Length(TicketOperation.paymentsList) - 1] := report_payment;
                    TicketOperation.FieldHasValue[TicketOperation.tag_paymentsList] := true;
                end;

            SetLength(report.ticket_operationsList, Length(report.ticket_operationsList) + 1);
            report.ticket_operationsList[Length(report.ticket_operationsList) - 1] := TicketOperation;
            report.FieldHasValue[report.tag_ticket_operationsList] := true;
        end;

    SetLength(report.money_placementsList, 0);
    for var MP := 0 to byte(high(TMoneyPlacementEnum)) do
        if (money_placements[MP].operations_total_count > 0) or (money_placements[MP].operations_count > 0) or (money_placements[MP].operations_sum > 0) or (money_placements[MP].offline_count > 0) then
        begin
            var
            money_placement := proto.report.TMoneyPlacement.Create;
            money_placement.operation := TMoneyPlacementEnum(MP);
            money_placement.operations_total_count := money_placements[MP].operations_total_count;
            money_placement.operations_count := money_placements[MP].operations_count;
            money_placement.offline_count := money_placements[MP].offline_count;
            SumToProto(money_placement.operations_sum, money_placements[MP].operations_sum);
            money_placement.FieldHasValue[money_placement.tag_operations_sum] := true;
            SetLength(report.money_placementsList, Length(report.money_placementsList) + 1);
            report.money_placementsList[Length(report.money_placementsList) - 1] := money_placement;
            report.FieldHasValue[report.tag_money_placementsList] := true;
        end;

    SetLength(report.non_nullable_sumsList, 0);
    SetLength(report.start_shift_non_nullable_sumsList, 0);

    for var operation_int := 0 to byte(HIGH(TOperationTypeEnum)) do
    begin
        if non_nullable_sums[operation_int] > 0 then
        begin
            var
            nns := TNonNullableSum.Create;
            nns.operation := TOperationTypeEnum(operation_int);
            SumToProto(nns.sum, non_nullable_sums[operation_int]);
            nns.FieldHasValue[nns.tag_sum] := true;
            SetLength(report.non_nullable_sumsList, Length(report.non_nullable_sumsList) + 1);
            report.non_nullable_sumsList[Length(report.non_nullable_sumsList) - 1] := nns;
            report.FieldHasValue[report.tag_non_nullable_sumsList] := true;
        end;

        if start_shift_non_nullable_sums[operation_int] > 0 then
        begin
            var
            nns := TNonNullableSum.Create;
            nns.operation := TOperationTypeEnum(operation_int);
            SumToProto(nns.sum, start_shift_non_nullable_sums[operation_int]);
            nns.FieldHasValue[nns.tag_sum] := true;
            SetLength(report.start_shift_non_nullable_sumsList, Length(report.start_shift_non_nullable_sumsList) + 1);
            report.start_shift_non_nullable_sumsList[Length(report.start_shift_non_nullable_sumsList) - 1] := nns;
            report.FieldHasValue[report.tag_start_shift_non_nullable_sumsList] := true;
        end;
    end;

    report.checksum := MD5(Format('REPORT / type=%d / kkm_id=%d / shift_number=%d / %s', [ID, byte(report_type), report.shift_number, FormatDateTime('yyyy-mm-dd hh:nn:ss', ProtoToDateTime(report.date_time))]));
    Result.ResultCode := rc_ok;
end;


function TCashRegister.ZXReport(const AReportType: proto.report.TReportTypeEnum; AResultReport: proto.report.TZXReport): TResultRecord;
var
    Request: proto.message.TRequest;
    Response: proto.message.TResponse;
begin
    Result.Clear;
    Request := nil;
    Response := nil;
    try
{ проверка продолжительности оффлайн режима (72 часа) }
        doCheckOfflineQueueDuration;

        Request := TRequest.Create;
        Response := TResponse.Create;

        case AReportType of

            REPORT_Z:
                begin
                    Result := DoCloseShift(Request, Response);
                    if Result.isPositive then
                        try
                            AResultReport.Assign(Response.report.zx_report);
                        except
                            on E: Exception do
                                WriteLog('ZXReport -> DoCloseShift exception [kkm = %d]: [%s] %s', [ofd_id, E.ClassName, E.message], ltError);
                        end;
                end;

            REPORT_X:
                begin
                    Request.Command := TCommandTypeEnum.COMMAND_REPORT;
                    try
                        Result := BuildZXReport(Request.report.zx_report, AReportType);
                    except
                        on E: Exception do
                        begin
                            WriteLog('ZXReport -> BuildZXReport exception [%d / %s]: %s', [E.HelpContext, E.ClassName, GetExceptionMessage(E)], ltError);
                            if E.HelpContext > 0 then
                                Result.ResultCode := E.HelpContext;
                            if Result.ResultCode = 0 then
                                Result.ResultCode := rc_operation_failed;
                        end;
                    end;
                    if not Result.isPositive then
                        exit;

                    Request.report.FieldHasValue[Request.report.tag_zx_report] := true;
                    Request.report.report := AReportType;
                    Request.report.date_time.Assign(Request.report.zx_report.date_time);
                    Request.report.FieldHasValue[Request.report.tag_date_time] := true;
                    Request.FieldHasValue[Request.tag_report] := true;

                    Result := SendRequest(Request, Response);

                    if not Result.isPositive then
                    begin
                        Result.ResultCode := Result.ResultCode;
                        exit;
                    end;

                    Result.ResultCode := rc_ok;

{ если касса в автономном режиме, то заполняем ответ локально: }
                    if is_offline then
                    begin
                        Request.report.is_offline := true;

                        Response.report.report := Request.report.report;

                        Response.report.zx_report.Assign(Request.report.zx_report);
                        Response.report.FieldHasValue[Response.report.tag_zx_report] := true;
                        Response.FieldHasValue[Response.tag_report] := true;

                        Response.Result.result_code := byte(TResultTypeEnum.RESULT_TYPE_OK);
                        Response.Result.result_text := 'ok(offline)';

                        Response.FieldHasValue[Response.tag_result] := true;
                    end;

                    if is_offline then
                        SaveRequest(Request, nil, req_num)
                    else
                        SaveRequest(Request, Response, req_num);

                    AResultReport.Assign(Response.report.zx_report);

                    inc(shift_document_number);
                end;

            REPORT_SECTIONS, REPORT_OPERATORS:
                begin
                    Request.Command := TCommandTypeEnum.COMMAND_REPORT_CUSTOM;
                    Result := BuildZXReport(Request.report.zx_report, AReportType);
                    if Result.ResultCode = rc_ok then
                    begin
                        Request.report.FieldHasValue[Request.report.tag_zx_report] := true;
                        try
                            AResultReport.Assign(Request.report.zx_report);
                        except
                            on E: Exception do
                                WriteLog('ZXReport ->  report.Assign exception: [%s] %s', [E.ClassName, E.message], ltError);
                        end;

                        Request.report.report := AReportType;
                        Request.report.date_time.Assign(Request.report.zx_report.date_time);
                        Request.report.FieldHasValue[Request.report.tag_date_time] := true;

                        Request.FieldHasValue[Request.tag_report] := true;

                        AResultReport.Assign(Request.report.zx_report);

                        inc(shift_document_number);
                    end
                end;
        end;

    except
        on E: Exception do
        begin
            if E.HelpContext > 0 then
                Result.ResultCode := E.HelpContext
            else
                Result.ResultCode := rc_operation_failed;
            WriteLog('TCashRegister.ZXReport exception [%d]: [%s] %s', [Result.ResultCode, E.ClassName, GetExceptionMessage(E)], ltError);
        end;
    end;

    if Assigned(Request) then
        Request.Destroy;
    if Assigned(Response) then
        Response.Destroy;
end;


function TCashRegister.MoneyPlacement;
const
    OperationTypeStr: TArray<string> = ['MONEY_PLACEMENT_DEPOSIT', 'MONEY_PLACEMENT_WITHDRAWAL'];
var
    cash_sum_new: Currency;
    Request: TRequest;
    Response: TResponse;
begin
    Result.Clear;
    Request := nil;
    Response := nil;
    cash_sum_new := 0;

    try
{ проверка корректности типа операции }
        if (not(OperationType IN [LOW(TMoneyPlacementEnum) .. HIGH(TMoneyPlacementEnum)])) OR (OperationSum <= 0) then
            raise Exc(rc_invalid_fields);

        WriteLog('[TCashRegister.DoMoneyPlacement] OperationSum: %s ([%d] %s)', [FormatFloat('0.00', OperationSum), byte(OperationType), OperationTypeStr[byte(OperationType)]]);
        WriteLog('[TCashRegister.DoMoneyPlacement] cash_sum BEFORE: %s', [FormatFloat('0.00', cash_sum)]);

{ проверка достаточности наличных в кассе }
        if (OperationType = TMoneyPlacementEnum.MONEY_PLACEMENT_WITHDRAWAL) and (OperationSum > cash_sum) then
            raise Exc(rc_not_enough_cash);

{ проверка продолжительности оффлайн режима (72 часа) }
        doCheckOfflineQueueDuration;

        Request := TRequest.Create;
        Request.Command := TCommandTypeEnum.COMMAND_MONEY_PLACEMENT;

        Request.money_placement.operation := OperationType;
        Request.money_placement.fr_shift_number := fr_shift_number;

        DateTimeToProto(Request.money_placement.datetime, Now);
        Request.money_placement.FieldHasValue[Request.money_placement.tag_datetime] := true;

        SumToProto(Request.money_placement.sum, OperationSum);
        Request.money_placement.FieldHasValue[Request.money_placement.tag_sum] := true;

        Request.FieldHasValue[Request.tag_money_placement] := true;

        Request.money_placement.operator.code := FOperator.ID;
        Request.money_placement.operator.name := FOperator.name;
        Request.money_placement.FieldHasValue[Request.money_placement.tag_operator] := true;

        DateTimeToProto(Request.money_placement.datetime, Now);
        Request.money_placement.FieldHasValue[Request.money_placement.tag_datetime] := true;

        Request.money_placement.fr_shift_number := fr_shift_number;
        Request.money_placement.printed_document_number := shift_document_number;

        case Request.money_placement.operation of
            MONEY_PLACEMENT_DEPOSIT:
                cash_sum_new := cash_sum + ProtoToSum(Request.money_placement.sum);
            MONEY_PLACEMENT_WITHDRAWAL:
                cash_sum_new := cash_sum - ProtoToSum(Request.money_placement.sum);
        end;

        Response := TResponse.Create;

        Result := SendRequest(Request, Response);

        if not Result.isPositive then
            WriteLog('[TCashRegister.DoMoneyPlacement] Result is not positive: [%d] %s', [Result.ResultCode, ResponseText[Result.ResultCode]])
        else
        begin
            Result.ResultCode := rc_ok;

            if is_offline then
            begin
                Request.money_placement.is_offline := true;
                Response.Result.result_code := byte(TResultTypeEnum.RESULT_TYPE_OK);
                Response.Result.result_text := 'ok(offline)';
                Response.FieldHasValue[Response.tag_result] := true;
            end;

            if is_offline then
                SaveRequest(Request, nil, req_num)
            else
                SaveRequest(Request, Response, req_num);

            Result.ResultText := Request.money_placement.AsJSON();

            cash_sum := cash_sum_new;
            SetLastShiftNumber(fr_shift_number);
            SetLastDocumentNumber(shift_document_number);
            inc(shift_document_number);

            WriteLog('[TCashRegister.DoMoneyPlacement] cash_sum AFTER: %s', [FormatFloat('0.00', cash_sum)]);
        end;
    except
        on E: Exception do
        begin
            if E.HelpContext > 0 then
                Result.ResultCode := E.HelpContext
            else
                Result.ResultCode := rc_operation_failed;
            WriteLog('[TCashRegister.DoMoneyPlacement] exception [%d]: [%s] %s', [Result.ResultCode, E.ClassName, GetExceptionMessage(E)], ltError);
        end;
    end;

    if Assigned(Request) then
        Request.Destroy;
    if Assigned(Response) then
        Response.Destroy;
end;

end.
