unit uBaseCoreTypes;
{$I defines.inc}

interface

uses
    uCashRegisterTypes,
    uTypes,
    uLogger,
    uLicense,
    proto.common,
    proto.report,
    proto.ticket,
    System.IOUtils,
    System.SysUtils,
    XSuperObject;

const
    kkm_activity_update_interval = cashbox_maximum_operation_duration div 2;


type
    TOfflineQueueUploadMethod = (// метод выгрузки автономной очереди
         umAuto,                 // 0 = Автоматичекий (по-умолчанию): если количество автономных касс превысит порог - будет включен Синхронный режим
         umAsync,                // 1 = Асинхронный: параллельная выгрузка для всех касс одновременно
         umSync                  // 2 = Синхронный: последовательная выгрузка для каждой кассы
         );

type
    TProductSettings = record
    public
        http_port: word;
        log_level_to_file: TLogLevel;
        log_level_to_screen: TLogLevel;
        log_level_to_graylog: TLogLevel;
        db_driver: string;
        db_host: string;
        db_port: word;
        db_username: string;
        db_password: string;
        db_name: string;
        auth_service_address: string;
        max_users_per_kkm: integer;
        max_kkms_per_owner: integer;
        graylog_host: string;
        graylog_port: word;
        graylog_stream_name: string;
        offline_queue_upload_method: TOfflineQueueUploadMethod;
        function LoadFromFile(const aFileName: string): boolean;
        function SaveToFile(const aFileName: string): boolean;
    end;

type
    TTokenInfo = record
        userId: Cardinal;
        username: string;
        email: string;
        created: System.TDateTime;
        is_valid: boolean;
    end;

type
    TVersionRecord = record
        versionName: string;
        versionCode: integer;
    end;

type
    TVersionRecordResponse = record
        current: TVersionRecord;
        actual: TVersionRecord;
        startTime: System.TDateTime;
        currentTime: System.TDateTime;
    end;

type
    TMethodExecutionResult = (erOk, erMethodNotFound, erMethodException);

type
    TUDPCommandType = (ctNotifyPacket, ctMasterRequest, ctMasterResponse);

type
    TUDPPacket = record
        command_type: TUDPCommandType;
        guid_sender: string;
        guid_receiver: string;
        body: string;
    end;

type
    TKKMStatusRecord = record
        ofd_id: Cardinal;
        status: byte;
    end;

type
    TMasterHostResponse = record
        Settings: TProductSettings;
        License: TLicenseRecord;
    end;

type
    TKKMBusyRecord = record
        ofd_id: Cardinal;
        handler_guid: string;
        handler_address: string;
        last_activity_date: System.TDateTime;
    end;

type
    TSimpleOFDRecord = record
        uid: string;
        name: string;
    end;

type
    TSimpleDomain = record
        &type: TDomainTypeEnum;
    end;

type
    TSimplePair = record
        key: string;
        value: string;
    end;

type
    TSimpleMoneyPlacementRequest = record
// request_uid: string;
        kkm_ofd_id: Cardinal;
        operation: TMoneyPlacementEnum;
        sum: Currency;
    end;

type
    TSimpleTax = record
        taxation_type: Cardinal;
        percent: Currency;
        sum: Currency;
        is_in_total_sum: boolean;
    end;

type
    TSimpleModifier = record
        name: string;
        sum: Currency;
        taxes: TArray<TSimpleTax>;
        auxiliary: TArray<TSimplePair>;
    end;

type
    TSimpleCommodity = record
        name: string;                   // наименование
        section_code: string;           // код секции или отдела
        quantity: Double;               // количество
        price: Currency;                // цена
        sum: Currency;                  // сумма
        taxes: TArray<TSimpleTax>;      // налоги
        excise_stamp: string;           // Код маркировки
        physical_label: string;         // Серия и номер акцизной марки
        product_id: string;             // Сквозной идентификатор товара
        barcode: string;                // Штрих-код
        measure_unit_code: string;      // Код единицы измерения
        auxiliary: TArray<TSimplePair>; // Дополнительная информация
    end;

type
    TSimpleItem = record
        &type: TItemTypeEnum;
        commodity: TSimpleCommodity;
        markup: TSimpleModifier;
        discount: TSimpleModifier;
    end;

type
    TSimplePayment = record
        &type: TPaymentTypeEnum;
        sum: Currency;
    end;

type
    TSimpleAmounts = record
        total: Currency;
        taken: Currency;
        change: Currency;
        markup: TSimpleModifier;
        discount: TSimpleModifier;
    end;

type
    TSimpleTicketRequest = record
// request_uid: string;
        kkm_ofd_id: Cardinal;
        is_printable: boolean;
        image_width: Cardinal;
        image_scale: Single;
        image_pixel_draw_threshold: byte;
        operation: TOperationTypeEnum;
        date_time: System.TDateTime;
        &operator: TCashRegisterOperator;
        domain: TSimpleDomain;
        items: TArray<TSimpleItem>;
        payments: TArray<TSimplePayment>;
        taxes: TArray<TSimpleTax>;
        amounts: TSimpleAmounts;
        customer_iin_or_bin: string;
        auxiliary: TArray<TSimplePair>;
    end;

type
    TSimpleReportOperation = record
        operation: TOperationTypeEnum;
        count: integer;
        sum: Currency;
    end;

type
    TSimpleReportSection = record
        section_code: string;
        operations: TArray<TSimpleReportOperation>;
    end;

type
    TSimpleReportTaxOperation = record
        operation: TOperationTypeEnum;
        turnover: Currency;
        sum: Currency;
    end;

type
    TSimpleReportTax = record
    const
        &type = 100 { 100 = VAT = НДС };

    var
        percent: integer;
        operations: TArray<TSimpleReportTaxOperation>;
    end;

type
    TSimpleReportNonNullableSum = record
        operation: TOperationTypeEnum;
        sum: Currency;
    end;

type
    TSimpleReportRequest = record
// request_uid: string;
        kkm_ofd_id: Cardinal;
        is_printable: boolean;
        image_width: Cardinal;
        image_scale: Single;
        image_pixel_draw_threshold: byte;
        report_type: TReportTypeEnum;
    end;

type
    TTransactionListRequest = record
        kkm_ofd_id: Cardinal;
        period_start: System.TDateTime;
        period_end: System.TDateTime;
        command_type_list: TArray<byte { TCommandTypeEnum } >;
        transaction_id: integer;
        shift_number: integer;
        shift_document_number: integer;
        fiscal_id: string;
    end;

type
    TTransactionRequest = record
        kkm_ofd_id: Cardinal;
        transaction_id: integer;
    end;

type
    TTransactionResponse = record
        id: integer;
        date: System.TDateTime;
        command: integer;
        fr_shift_number: integer;
        shift_document_number: integer;
        shift_state: TShiftState;
        is_offline: boolean;
        is_invalid_token: boolean;
        body: ISuperObject;
    end;

type
    TSimpleTicketTransactionResponse = record
        operation: TOperationTypeEnum;
        payments: TArray<TPaymentTypeEnum>;
        sum: Currency;
        fiscal_id: string;
    end;

type
    TSimpleMoneyPlacementTransactionResponse = record
        operation: TMoneyPlacementEnum;
        sum: Currency;
    end;

type
    TSimpleReportTransactionResponse = record
        &type: TReportTypeEnum;
        revenue: Currency;
        non_nullable_sums: TArray<TSimpleReportNonNullableSum>;
    end;

type
{ используем класс вместо record, чтобы можно было расширять его: }
    TExtendedResponse = class
        command_type: byte { TCommandTypeEnum };
        is_offline: boolean;
        is_invalid_token: boolean;
        kkm_local_name: string;
        operator_name: string;
        fr_shift_number: integer;
        shift_document_number: integer;
        shift_state: TShiftState;
        reg_info: TRegInfoRecord;
        vat_certificate: TVATCertificate;
        body: ISuperObject;
        ads_info: TArray<TSimpleTicketAD>;
    end;

type
{ наследуем класс: }
    TExtendedTicketResponse = class(TExtendedResponse)
        fiscal_id: string;
        qr_code: string;
        ofd_name: string;
        ofd_url: string;
    end;

type
{ наследуем класс: }
    TExtendedReportResponse = class(TExtendedResponse)
        report_type: byte;
        total_payments: TArray<Currency>;
    end;

type
    TSimpleReprintRequest = record
        kkm_ofd_id: Cardinal;
        is_printable: boolean;
        image_width: Cardinal;
        image_scale: Single;
        image_pixel_draw_threshold: byte;
        fr_shift_number: integer;
        shift_document_number: integer;
        is_original: boolean;
    end;

type
    TLicenseRecordResponse = record
        email: string;               // email владельца
        phone: string;               // номер телефона в формате (+7##########)
        owner: string;               // наименование владельца
        orgId: string;               // ИИН/БИН владельца
        licenseKey: string;          // лицензионный ключ
        activationCode: string;      // код активации
        validFrom: System.TDateTime; // дата активации лицензии
        validThru: System.TDateTime; // срок действия лицензии
        maxKKMCount: integer;        // максимально допустимое количество касс
        licenseType: TLicenseType;   // тип лицензии
    end;

implementation


function TProductSettings.LoadFromFile(const aFileName: string): boolean;
begin
    Result := FileExists(aFileName);
    if Result then
        try
            var
            x := SO(TFile.ReadAllText(aFileName, TEncoding.UTF8));
{$IF NOT defined(CUSTOM_BUILD)}
            x.Remove('auth_service_url');
            x.Remove('max_users_per_kkm');
            x.Remove('max_kkms_per_owner');
{$ENDIF}
            self := TJSON.Parse<TProductSettings>(x);
        except
            on E: Exception do
            begin
                Result := false;
// WriteLog('TProductSettingsHelper.LoadFromFile exception: [%s] %s', [E.ClassName, E.message], TLogType.ltError);
            end;
        end;
end;


function TProductSettings.SaveToFile(const aFileName: string): boolean;
begin
    Result := true;
    try
        var
        x := TJSON.SuperObject(self);
{$IF NOT defined(CUSTOM_BUILD)}
        x.Remove('auth_service_url');
        x.Remove('max_users_per_kkm');
        x.Remove('max_kkms_per_owner');
{$ENDIF}
        TFile.WriteAllText(aFileName, x.AsJSON(true));
    except
        Result := false;
    end;
end;




end.
