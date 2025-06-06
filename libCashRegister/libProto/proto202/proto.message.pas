unit proto.message; { 202 }

interface

// ***********************************
// classes for proto.message.proto
// generated by ProtoBufGenerator
// kami-soft 2016-2017
// ***********************************

uses
    SysUtils,
    Classes,
    pbInput,
    pbOutput,
    pbPublic,
    uAbstractProtoBufClasses,
    proto.common,
    proto.ticket,
    proto.report,
    proto.nomenclature,
    proto.reginfo,
    proto.bind_taxation,
    proto.service,
    proto.auth;

type
    TCommandTypeEnum = (
         COMMAND_SYSTEM = 0,
         COMMAND_TICKET = 1,
         COMMAND_CLOSE_SHIFT = 2,
         COMMAND_REPORT = 3,
         COMMAND_NOMENCLATURE = 4,
         COMMAND_INFO = 5,
         COMMAND_MONEY_PLACEMENT = 6,
         COMMAND_CANCEL_TICKET = 7,
         COMMAND_AUTH = 8,
         COMMAND_RESERVED = 127,
         COMMAND_REPORT_CUSTOM = 128
         );

    TResultTypeEnum = (
  // ������� ��������� �������.
  // ����� �������� � ������� ������.
         RESULT_TYPE_OK = 0,

  // ����������� ID ����������
  // ������� �� ��������������� � �������.
         RESULT_TYPE_UNKNOWN_ID = 1,

  // �������� �����.
  // �������� ������ ����������, ���������� ���������� ����� ������.
         RESULT_TYPE_INVALID_TOKEN = 2,

  // ������ ���������.
  // ����� ���������� � ������� � ����������� �������������� ��������.
  // ����� ���������, ��������, ��� ��������������� ������ ����������.
         RESULT_TYPE_PROTOCOL_ERROR = 3,

  // ����������� �������.
  // ��� ��������� � ����� �������, ����������� �������.
         RESULT_TYPE_UNKNOWN_COMMAND = 4,

  // ������� �� ��������������.
  // ��� ��������� � ����� �������, ���������������� ������� ����������
  // �������.
         RESULT_TYPE_UNSUPPORTED_COMMAND = 5,

  // �������� ��������� ����������.
  // � ��������� ����� �� ��������������.
         RESULT_TYPE_INVALID_CONFIGURATION = 6,

  // ������������� SSL �� ���������.
  // ������������� ����������� ���������� ���������. ���������� ����������
  // ������ ��� ������������ �������� ����� �����.
         RESULT_TYPE_SSL_IS_NOT_ALLOWED = 7,

  // ������������ ����� �������.
  // ���������� ����� ������� @link headers_subsec REQNUM @endlink ��� ��, ���
  // � � ���������� �������, �� @link headers_subsec TOKEN @endlink ������.
         RESULT_TYPE_INVALID_REQUEST_NUMBER = 8,

  // ������������ ������� �������� ���������� �������.
  // @link headers_subsec REQNUM @endlink � @link headers_subsec TOKEN @endlink
  // ����� �� �� ��������, ��� � � ���������� �������, �� ��� �������
  // ����������.
         RESULT_TYPE_INVALID_RETRY_REQUEST = 9,

  // ���������� ������� ������ ����.
  // ����� �������� ������ ��������� ���, � ��� ���� ����� ����� ���� �� ����
  // ���������� �� ����� �������, ����� ���������.
  // @deprecated
         RESULT_TYPE_CANT_CANCEL_TICKET = 10,

  // ����� �������� ����� �������.
  // ���� ����� ������, � ������� �������� ����� ����� ���� �������, �� ������
  // ����� ���������� ��� ������, ���� �� ��������� �����.
         RESULT_TYPE_OPEN_SHIFT_TIMEOUT_EXPIRED = 11,

  // ������������ ��� ��� ������.
  // @deprecated ����������� AuthResponse.
         RESULT_TYPE_INVALID_LOGIN_PASSWORD = 12,

  // �������� ������� ������.
  // ��� �������, ����� ������ ��������� � ����� ������ ���������, �� �� �����
  // � ���������� ���������.
         RESULT_TYPE_INCORRECT_REQUEST_DATA = 13,

  // ������������ ��������.
  // ��������� �� ��������������� �������� � ����� �� ����� ��������� ��������.
         RESULT_TYPE_NOT_ENOUGH_CASH = 14,

  // ����� �������������.
         RESULT_TYPE_BLOCKED = 15,

  // ����� ��� ���� �������
         RESULT_TYPE_SHIFT_ALREADY_OPENED = 16,

  // ��������� �������� ���/��� ���������� � ��������
         RESULT_TYPE_SAME_TAXPAYER_AND_CUSTOMER = 17,

  // ������ �������� ����������.
  // ����� ������ ��������� ����������, � ����� �������� ����������� �
  // ���������� ������ � ������� @link comm_subsec ������ ������� �� ���������
  // ���������� @endlink, �� ��������� �������� ���������� ������ ���������
  // ����������, ������� � ��������� ����� � ������ ��������������� ���������.
         RESULT_TYPE_SERVICE_TEMPORARILY_UNAVAILABLE = 254,

  // ����������� ������.
  // ����� ������ ��������� ���������� � ����� �������� ����������� � ����������
  // ������ � ������� @link comm_subsec ������ ������� �� ���������
  // ���������� @endlink, �� ��������� �������� ���������� ������ ���������
  // ���������� � ������ ��������������� ���������.
         RESULT_TYPE_UNKNOWN_ERROR = 255
         );


    TResult = class(TAbstractProtoBufClass)
    public
         const
        tag_result_code = 1;
        tag_result_text = 2;
    strict private
        Fresult_code: Cardinal;
        Fresult_text: string;

        procedure Setresult_code(Tag: Integer; const Value: Cardinal);
        procedure Setresult_text(Tag: Integer; const Value: string);
    strict protected
        function LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: Integer; WireType: Integer): Boolean; override;
        procedure SaveFieldsToBuf(ProtoBuf: TProtoBufOutput); override;
    public
        constructor Create; override;
        destructor Destroy; override;

        property result_code: Cardinal index tag_result_code read Fresult_code write Setresult_code;
        property result_text: string index tag_result_text read Fresult_text write Setresult_text;
    end;


    TRequest = class(TAbstractProtoBufClass)
    public
         const
        tag_command         = 1;
        tag_ticket          = 2;
        tag_close_shift     = 3;
        tag_report          = 4;
        tag_nomenclature    = 5;
        tag_service         = 6;
        tag_money_placement = 7;
        tag_auth            = 8;

    strict private
        Fcommand: TCommandTypeEnum;
        Fticket: TTicketRequest;
        Fclose_shift: TCloseShiftRequest;
        Freport: TReportRequest;
        Fnomenclature: TNomenclatureRequest;
        Fservice: TServiceRequest;
        Fmoney_placement: TMoneyPlacementRequest;
        Fauth: TAuthRequest;

        procedure Setcommand(Tag: Integer; const Value: TCommandTypeEnum);
    strict protected
        function LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: Integer; WireType: Integer): Boolean; override;
        procedure SaveFieldsToBuf(ProtoBuf: TProtoBufOutput); override;
    public
        constructor Create; override;
        destructor Destroy; override;

        property command: TCommandTypeEnum index tag_command read Fcommand write Setcommand;
        property ticket: TTicketRequest read Fticket;
        property close_shift: TCloseShiftRequest read Fclose_shift;
        property report: TReportRequest read Freport;
        property nomenclature: TNomenclatureRequest read Fnomenclature;
        property service: TServiceRequest read Fservice;
        property money_placement: TMoneyPlacementRequest read Fmoney_placement;
        property auth: TAuthRequest read Fauth;
    end;


    TResponse = class(TAbstractProtoBufClass)
    public
         const
        tag_command      = 1;
        tag_result       = 2;
        tag_ticket       = 3;
        tag_report       = 4;
        tag_nomenclature = 5;
        tag_service      = 6;
        tag_auth         = 7;

    strict private
        Fcommand: TCommandTypeEnum;
        Fresult: TResult;
        Fticket: TTicketResponse;
        Freport: TReportResponse;
        Fnomenclature: TNomenclatureResponse;
        Fservice: TServiceResponse;
        Fauth: TAuthResponse;

        procedure Setcommand(Tag: Integer; const Value: TCommandTypeEnum);
    strict protected
        function LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: Integer; WireType: Integer): Boolean; override;
        procedure SaveFieldsToBuf(ProtoBuf: TProtoBufOutput); override;
    public
        constructor Create; override;
        destructor Destroy; override;

        property command: TCommandTypeEnum index tag_command read Fcommand write Setcommand;
        property result: TResult read Fresult;
        property ticket: TTicketResponse read Fticket;
        property report: TReportResponse read Freport;
        property nomenclature: TNomenclatureResponse read Fnomenclature;
        property service: TServiceResponse read Fservice;
        property auth: TAuthResponse read Fauth;
    end;

implementation

{ TResult }


constructor TResult.Create;
begin
    inherited;
    RegisterRequiredField(tag_result_code);
end;


destructor TResult.Destroy;
begin
    inherited;
end;


function TResult.LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: Integer; WireType: Integer): Boolean;
begin
    result := inherited;
    if result then
        Exit;
    result := True;
    case FieldNumber of
        tag_result_code:
            result_code := ProtoBuf.readUInt32;
        tag_result_text:
            result_text := ProtoBuf.readString;
        else
            result := False;
    end;
end;


procedure TResult.SaveFieldsToBuf(ProtoBuf: TProtoBufOutput);
begin
    inherited;
    if FieldHasValue[tag_result_code] then
        ProtoBuf.writeUInt32(tag_result_code, Fresult_code);
    if FieldHasValue[tag_result_text] then
        ProtoBuf.writeString(tag_result_text, Fresult_text);
end;


procedure TResult.Setresult_code(Tag: Integer; const Value: Cardinal);
begin
    Fresult_code := Value;
    FieldHasValue[Tag] := True;
end;


procedure TResult.Setresult_text(Tag: Integer; const Value: string);
begin
    Fresult_text := Value;
    FieldHasValue[Tag] := True;
end;

{ TRequest }


constructor TRequest.Create;
begin
    inherited;
    RegisterRequiredField(tag_command);
    Fticket := TTicketRequest.Create;
    Fclose_shift := TCloseShiftRequest.Create;
    Freport := TReportRequest.Create;
    Fnomenclature := TNomenclatureRequest.Create;
    Fservice := TServiceRequest.Create;
    Fmoney_placement := TMoneyPlacementRequest.Create;
    Fauth := TAuthRequest.Create;
end;


destructor TRequest.Destroy;
begin
    Fticket.Free;
    Fclose_shift.Free;
    Freport.Free;
    Fnomenclature.Free;
    Fservice.Free;
    Fmoney_placement.Free;
    Fauth.Free;
    inherited;
end;


function TRequest.LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: Integer; WireType: Integer): Boolean;
var
    tmpBuf: TProtoBufInput;
begin
    result := inherited;
    if result then
        Exit;
    result := True;
    tmpBuf := nil;
    try
        case FieldNumber of
            tag_command:
                command := TCommandTypeEnum(ProtoBuf.readEnum);
            tag_ticket:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fticket.LoadFromBuf(tmpBuf);
                end;
            tag_close_shift:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fclose_shift.LoadFromBuf(tmpBuf);
                end;
            tag_report:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Freport.LoadFromBuf(tmpBuf);
                end;
            tag_nomenclature:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fnomenclature.LoadFromBuf(tmpBuf);
                end;
            tag_service:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fservice.LoadFromBuf(tmpBuf);
                end;
            tag_money_placement:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fmoney_placement.LoadFromBuf(tmpBuf);
                end;
            tag_auth:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fauth.LoadFromBuf(tmpBuf);
                end;
            else
                result := False;
        end;
    finally
        tmpBuf.Free
    end;
end;


procedure TRequest.SaveFieldsToBuf(ProtoBuf: TProtoBufOutput);
var
    tmpBuf: TProtoBufOutput;
begin
    inherited;
    tmpBuf := TProtoBufOutput.Create;
    try
        if FieldHasValue[tag_command] then
            ProtoBuf.writeInt32(tag_command, Integer(Fcommand));
        if FieldHasValue[tag_ticket] then
            SaveMessageFieldToBuf(Fticket, tag_ticket, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_close_shift] then
            SaveMessageFieldToBuf(Fclose_shift, tag_close_shift, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_report] then
            SaveMessageFieldToBuf(Freport, tag_report, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_nomenclature] then
            SaveMessageFieldToBuf(Fnomenclature, tag_nomenclature, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_service] then
            SaveMessageFieldToBuf(Fservice, tag_service, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_money_placement] then
            SaveMessageFieldToBuf(Fmoney_placement, tag_money_placement, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_auth] then
            SaveMessageFieldToBuf(Fauth, tag_auth, tmpBuf, ProtoBuf);
    finally
        tmpBuf.Free
    end;
end;


procedure TRequest.Setcommand(Tag: Integer; const Value: TCommandTypeEnum);
begin
    Fcommand := Value;
    FieldHasValue[Tag] := True;
end;

{ TResponse }


constructor TResponse.Create;
begin
    inherited;
    RegisterRequiredField(tag_command);
    Fresult := TResult.Create;
    RegisterRequiredField(tag_result);
    Fticket := TTicketResponse.Create;
    Freport := TReportResponse.Create;
    Fnomenclature := TNomenclatureResponse.Create;
    Fservice := TServiceResponse.Create;
    Fauth := TAuthResponse.Create;
end;


destructor TResponse.Destroy;
begin
    Fresult.Free;
    Fticket.Free;
    Freport.Free;
    Fnomenclature.Free;
    Fservice.Free;
    Fauth.Free;
    inherited;
end;


function TResponse.LoadSingleFieldFromBuf(ProtoBuf: TProtoBufInput; FieldNumber: Integer; WireType: Integer): Boolean;
var
    tmpBuf: TProtoBufInput;
begin
    result := inherited;
    if result then
        Exit;
    result := True;
    tmpBuf := nil;
    try
        case FieldNumber of
            tag_command:
                command := TCommandTypeEnum(ProtoBuf.readEnum);
            tag_result:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fresult.LoadFromBuf(tmpBuf);
                end;
            tag_ticket:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fticket.LoadFromBuf(tmpBuf);
                end;
            tag_report:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Freport.LoadFromBuf(tmpBuf);
                end;
            tag_nomenclature:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fnomenclature.LoadFromBuf(tmpBuf);
                end;
            tag_service:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fservice.LoadFromBuf(tmpBuf);
                end;
            tag_auth:
                begin
                    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
                    Fauth.LoadFromBuf(tmpBuf);
                end;
            else
                result := False;
        end;
    finally
        tmpBuf.Free
    end;
end;


procedure TResponse.SaveFieldsToBuf(ProtoBuf: TProtoBufOutput);
var
    tmpBuf: TProtoBufOutput;
begin
    inherited;
    tmpBuf := TProtoBufOutput.Create;
    try
        if FieldHasValue[tag_command] then
            ProtoBuf.writeInt32(tag_command, Integer(Fcommand));
        if FieldHasValue[tag_result] then
            SaveMessageFieldToBuf(Fresult, tag_result, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_ticket] then
            SaveMessageFieldToBuf(Fticket, tag_ticket, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_report] then
            SaveMessageFieldToBuf(Freport, tag_report, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_nomenclature] then
            SaveMessageFieldToBuf(Fnomenclature, tag_nomenclature, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_service] then
            SaveMessageFieldToBuf(Fservice, tag_service, tmpBuf, ProtoBuf);
        if FieldHasValue[tag_auth] then
            SaveMessageFieldToBuf(Fauth, tag_auth, tmpBuf, ProtoBuf);
    finally
        tmpBuf.Free
    end;
end;


procedure TResponse.Setcommand(Tag: Integer; const Value: TCommandTypeEnum);
begin
    Fcommand := Value;
    FieldHasValue[Tag] := True;
end;

end.
