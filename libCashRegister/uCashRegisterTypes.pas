unit uCashRegisterTypes;

interface

uses
    System.Generics.Collections,
    System.SysUtils,

    proto.common,
    proto.report,
    proto.service,

    uUtils,
    uTypes,
    FireDAC.Comp.Client,

    XSuperObject;

const
    proto_version     = 202;
    proto_version_str = '2.0.2';

const
    cashbox_default_connect_timeout               = 1000 * 4;     // 4 секунды в миллисекундах!
    cashbox_default_read_timeout                  = 1000 * 8;     // 8 секунд в миллисекундах!
    cashbox_default_offline_queue_upload_interval = 60;           // 60 секунд
    cashbox_maximum_offline_queue_duration        = 72 * 60 * 60; // 72 часа в секундах!
    cashbox_maximum_operation_duration            = 20;           // 20 секунд

    cashbox_vendor_id_begin_date    = '2021-01-01';
    cashbox_vendor_id_suffix_length = 13;

type
    TCheckVendorIDProc = function(const AValue, APrefix: string): boolean of object;

type
    TPrinterType = (ptUnknown, ptCOM, ptVCL, ptBluetooth);

type
    TPrinterEntity = record
        id: integer;
        name: string;
        &type: TPrinterType;
    end;

type
    TVATCertificate = record
        series: string;
        number: string;
        is_printable: boolean;
    end;

type
    TSimpleTicketAdInfo = record
        &type: TTicketAdTypeEnum;
        version: UInt64;
    end;

type
    TSimpleTicketAD = record
        info: TSimpleTicketAdInfo;
        Text: string;
    end;

type
    TSimpleNonNullableSum = TArray<Currency> { array [0 .. byte(HIGH(TOperationTypeEnum))] of Double - json-парсер даже Currency из такого массива некорректно извлекает! };

type
    TSimpleOperation = record
        count: integer;
        sum: Currency;
    end;

type
    TSimpleTicketOperationPayment = record
        count: integer;
        sum: Currency;
    end;

type
    TSimpleTicketOperationPayments = array [0 .. byte(HIGH(TPaymentTypeEnum))] of TSimpleTicketOperationPayment;

type
    TSimpleTicketOperation = record
        tickets_total_count: integer;
        tickets_count: integer;
        tickets_sum: Currency;
        payments: TSimpleTicketOperationPayments;
        offline_count: integer;
        discount_sum: Currency;
        markup_sum: Currency;
        change_sum: Currency;
    end;

type
    TSimpleOperations = array [0 .. byte(HIGH(TOperationTypeEnum))] of TSimpleOperation;

type
    TSimpleTicketOperations = array [0 .. byte(HIGH(TOperationTypeEnum))] of TSimpleTicketOperation;

type
    TSimpleReportMoneyPlacement = record
        operations_total_count: Cardinal;
        operations_count: Cardinal;
        operations_sum: Currency;
        offline_count: Cardinal;
    end;

type
    TSimpleReportMoneyPlacements = array [0 .. byte(HIGH(TMoneyPlacementEnum))] of TSimpleReportMoneyPlacement;

const
    TShiftStateStr: TArray<string> = ['Closed', 'Opened'];

type
    TShiftState = (ssClosed, ssOpened);

type
    THeader = packed record
        AppCode: word;
        version: word;
        Size: Cardinal;
        id: Cardinal;
        token: Cardinal;
        ReqNum: word;
    end;

type
    TBindings = TArray<int64>;

type
    TBindingsHelper = record helper for TBindings
    private
        function GetLength: integer;
        procedure SetLength(const Value: integer);
    public
        procedure Add(const Value: int64);
        procedure Delete(const Value: int64);
        function Sort(const AddList: TBindings = []; const ExcludeList: TBindings = []): boolean;
        property Length: integer read GetLength write SetLength;
    end;

type
    TRegInfoRecord_org = record
        title: string;
        address: string;
        inn: string;
        okved: string;
        function isAssigned: boolean;
    end;

type
    TRegInfoRecord_pos = record
        title: string;
        address: string;
        function isAssigned: boolean;
    end;

type
    TRegInfoRecord_kkm = record
        point_of_payment_number: string;
        terminal_number: string;
        fns_kkm_id: string;
        serial_number: string;
        kkm_id: string;
        function isAssigned: boolean;
    end;

type
    TRegInfoRecord = record
        org: TRegInfoRecord_org;
        pos: TRegInfoRecord_pos;
        kkm: TRegInfoRecord_kkm;
        function isAssigned: boolean;
        procedure Assign(Source: TRegInfo);
    end;

type
    TOfdRecord = record
        uid: string;
        name: string;
        host: string;
        port: word;
        vendorIdPrefix: string;
        consumerAddress: string;
        proxy: TProxyRecord;
    end;

type
    TCashRegisterOperatorRole = (lrUnknown, lrAdministrator, lrSeniorCashier, lrCashier, lrInspector);

type
    TCashRegisterOperator = record
        id: Cardinal;
        name: string;
        access_pin: string;
        role: TCashRegisterOperatorRole;
        email: string;
        owner_id: Cardinal;
        bindings: TBindings;
        custom_data: ISuperObject;
        function Save(var FDConnection: TFDConnection; DoCloseConnection: boolean = false): boolean;
        function Update(var FDConnection: TFDConnection; DoCloseConnection: boolean = false): boolean;
        function Delete(var FDConnection: TFDConnection; DoCloseConnection: boolean = false): boolean;
        function GetByField(var FDConnection: TFDConnection; const FieldName: string; const FieldValue: Variant; DoCloseConnection: boolean = false): boolean;
    end;

type
    TCashRegisterRequest = record
        ofd_id: Cardinal;
        ofd_token: Cardinal;
        ofd_uid: string;
        local_name: string;
        use_software_vpn: boolean;
        printer: TPrinterEntity;
        auto_withdraw_money: boolean;
        vat_certificate: TVATCertificate;
        custom_data: ISuperObject;
        bindings: TBindings;
    end;

var
    CashRegisterTableName: string = 'cr_objects';
    CashRegisterOperatorTableName: string = 'cr_operators';
    CashRegisterOperationsTableName: string = 'cr_operations';

implementation

uses
    System.Variants,
    uDBUtils;


{ TBindingsHelper }
procedure TBindingsHelper.Add(const Value: int64);
begin
    if IntInArrayB(Value, Self) then
        exit;

    Self.Length := Self.Length + 1;
    Self[Self.Length - 1] := Value;
end;


procedure TBindingsHelper.Delete(const Value: int64);
begin
    for var i := Self.Length - 1 downto 0 do
        if Self[i] = Value then
        begin
            Self[i] := Self[Self.Length - 1];
            Self.Length := Self.Length - 1;
        end;
end;


function TBindingsHelper.GetLength: integer;
begin
    Result := System.Length(Self);
end;


procedure TBindingsHelper.SetLength(const Value: integer);
begin
    System.SetLength(Self, Value);
end;


function TBindingsHelper.Sort(const AddList, ExcludeList: TBindings): boolean;
begin
    Result := false;

    if (Self.Length <= 0) AND (AddList.Length <= 0) then
        exit;

    var
    oldLen := Self.Length;

    Self := TArray.Concat<int64>([AddList, Self]);

    Result := Result OR (oldLen <> Self.Length);

    for var i := Self.Length - 1 downto 0 do
        if IntInArrayB(Self[i], ExcludeList) OR IntInArrayB(Self[i], Self, i + 1) then
        begin
            Result := true;
            Self[i] := Self[Self.Length - 1];
            Self.Length := Self.Length - 1;
        end;

    Result := Result OR (oldLen <> Self.Length);

    if Result then
        TArray.Sort<int64>(Self);
end;


procedure TRegInfoRecord.Assign(Source: TRegInfo);
var
    res: TRegInfoRecord;
begin
    DoSync(
        procedure
        begin
            res := TJSON.Parse<TRegInfoRecord>(Source.AsJSONObject());
        end);
    Self := res;
end;


function TRegInfoRecord.isAssigned: boolean;
begin
    Result := kkm.isAssigned or pos.isAssigned or org.isAssigned;
end;

{ TRegInfoRecord_org }


function TRegInfoRecord_org.isAssigned: boolean;
begin
    Result := (not title.IsEmpty) or (not address.IsEmpty) or (not inn.IsEmpty) or (not okved.IsEmpty);
end;

{ TRegInfoRecord_pos }


function TRegInfoRecord_pos.isAssigned: boolean;
begin
    Result := (not title.IsEmpty) or (not address.IsEmpty);
end;

{ TRegInfoRecord_kkm }


function TRegInfoRecord_kkm.isAssigned: boolean;
begin
    Result := (not point_of_payment_number.IsEmpty) or (not terminal_number.IsEmpty) or (not fns_kkm_id.IsEmpty) or (not serial_number.IsEmpty) or (not kkm_id.IsEmpty);
end;

{ TCashRegisterOperator }


function TCashRegisterOperator.GetByField(var FDConnection: TFDConnection; const FieldName: string; const FieldValue: Variant; DoCloseConnection: boolean): boolean;
var
    res: TCashRegisterOperator;
begin
    Result := false;
    Self := Default (TCashRegisterOperator);
    res := Default (TCashRegisterOperator);

    if not Assigned(FDConnection) then
        exit;

    var
    list := SA;

    if DBObjectListLoad(FDConnection, CashRegisterOperatorTableName, list, DoCloseConnection) then
        for var obj in list do
            if obj.AsObject.Contains(FieldName) AND SameText(VarToStr(obj.AsObject.V[FieldName]), VarToStr(FieldValue)) then
            begin
                DoSync(
                    procedure
                    begin
                        res := TJSON.Parse<TCashRegisterOperator>(obj.AsObject);
                    end);
                Self := res;
                Result := true;
                break;
            end;
end;


function TCashRegisterOperator.Save(var FDConnection: TFDConnection; DoCloseConnection: boolean): boolean;
begin
    Result := false;
    if not Assigned(FDConnection) then
        exit;

    if Self.id > 0 then
    begin
        Result := Update(FDConnection, DoCloseConnection);
        exit;
    end;

    var
    X := TJSON.SuperObject(Self);
    Result := FDConnection.JSON_Object_Save(X, CashRegisterOperatorTableName);
    if Result and X.Contains('ID') then
        Self.id := X.i['ID'];

    if DoCloseConnection then
        FreeDBConnection(FDConnection);
end;


function TCashRegisterOperator.Update(var FDConnection: TFDConnection; DoCloseConnection: boolean): boolean;
begin
    Result := false;
    if not Assigned(FDConnection) then
        exit;

    Result := FDConnection.JSON_Object_Update(TJSON.SuperObject(Self), CashRegisterOperatorTableName);

    if DoCloseConnection then
        FreeDBConnection(FDConnection);
end;


function TCashRegisterOperator.Delete(var FDConnection: TFDConnection; DoCloseConnection: boolean): boolean;
begin

end;

end.
