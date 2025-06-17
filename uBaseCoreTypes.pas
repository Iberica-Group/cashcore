unit uBaseCoreTypes;
{$I defines.inc}

interface

uses
    uCashRegisterTypes,
    uCashRegister,
    uTypes,
    uLogger,
    uLicense,
    proto.common,
    proto.report,
    proto.ticket,
    proto.message,
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
    private
        procedure ValidateTaxes(taxesList: TArray<proto.ticket.TTax>);
        procedure AppendItem_Commodity(const commodity: TSimpleCommodity; var items: TArray<proto.ticket.TItem>);
        procedure AppendItem_Markup(const markup: TSimpleModifier; var items: TArray<proto.ticket.TItem>);
        procedure AppendItem_Discount(const discount: TSimpleModifier; var items: TArray<proto.ticket.TItem>);
    public
        procedure ToProto(AResult: TTicketRequest);
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
    TFiscalReportRequest = record
        kkm_ofd_id: Cardinal;
        period_start: System.TDateTime;
        period_end: System.TDateTime;
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
    TExtendedResponse = record
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
        is_dummy: boolean;
{ ticket }
        fiscal_id: string;
        qr_code: string;
        ofd_name: string;
        ofd_url: string;
{ report }
        report_type: byte;
        total_payments: TArray<Currency>;

        function asString(Indent: boolean = true): string;
        function asTicket(Indent: boolean = true): string;
        function asReport(Indent: boolean = true): string;
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


function BuildTicketResponse(cashBox: TCashRegister; ticket: TTicketRequest; ofdList: TArray<TOfdRecord>): string;
function BuildReportResponse(cashBox: TCashRegister; const command: TCommandTypeEnum; report: TZXReport; const report_type: TReportTypeEnum): string;
function BuildExtendedResponse(cashBox: TCashRegister; const command: TCommandTypeEnum; const body_data: string): string;

implementation

uses
    uProtoUtils,
    uUtils;


function TicketToJSON(ticket: TTicketRequest): ISuperObject;
begin
    Result := SO(ticket.AsJSON());
    if ticket.domain.&type <> TDomainTypeEnum.DOMAIN_SERVICES then
        Result.O['domain'].Remove('services');
    if ticket.domain.&type <> TDomainTypeEnum.DOMAIN_GASOIL then
        Result.O['domain'].Remove('gasoil');
    if ticket.domain.&type <> TDomainTypeEnum.DOMAIN_TAXI then
        Result.O['domain'].Remove('taxi');
    if ticket.domain.&type <> TDomainTypeEnum.DOMAIN_PARKING then
        Result.O['domain'].Remove('parking');
    for var i := 0 to Length(ticket.itemsList) - 1 do
    begin
        var
        item := ticket.itemsList[i];
        if item.&type <> TItemTypeEnum.ITEM_TYPE_COMMODITY then
            Result.A['itemsList'].O[i].Remove('commodity');
        if item.&type <> TItemTypeEnum.ITEM_TYPE_STORNO_COMMODITY then
            Result.A['itemsList'].O[i].Remove('storno_commodity');
        if item.&type <> TItemTypeEnum.ITEM_TYPE_MARKUP then
            Result.A['itemsList'].O[i].Remove('Markup');
        if item.&type <> TItemTypeEnum.ITEM_TYPE_STORNO_MARKUP then
            Result.A['itemsList'].O[i].Remove('storno_markup');
        if item.&type <> TItemTypeEnum.ITEM_TYPE_DISCOUNT then
            Result.A['itemsList'].O[i].Remove('Discount');
        if item.&type <> TItemTypeEnum.ITEM_TYPE_STORNO_DISCOUNT then
            Result.A['itemsList'].O[i].Remove('storno_discount');
    end;
end;


function BuildTicketResponse(cashBox: TCashRegister; ticket: TTicketRequest; ofdList: TArray<TOfdRecord>): string;
begin
    var
    res := Default (TExtendedResponse);
    res.command_type := byte(TCommandTypeEnum.COMMAND_TICKET);
    res.is_offline := cashBox.is_offline;
    res.is_invalid_token := cashBox.is_invalid_token;
    res.kkm_local_name := cashBox.local_name;
    res.operator_name := ticket.operator.name;
    res.fr_shift_number := cashBox.GetLastShiftNumber;
    res.shift_document_number := cashBox.GetLastDocumentNumber;
    res.shift_state := cashBox.shift_state;
    res.fiscal_id := ticket.printed_document_number_old;
    res.qr_code := ticket.printed_ticket;
    res.body := TicketToJSON(ticket);
    res.reg_info := cashBox.reg_info;
    res.vat_certificate := cashBox.vat_certificate;
    res.ads_info := cashBox.ads_info;
    res.is_dummy := cashBox.GetOperator.role = lrInspector;
    for var ofd in ofdList do
        if SameText(cashBox.ofd_uid, ofd.uid) then
        begin
            res.ofd_name := ofd.name;
            res.ofd_url := ofd.consumerAddress;
        end;
    Result := res.asTicket;
end;


function BuildReportResponse(cashBox: TCashRegister; const command: TCommandTypeEnum; report: TZXReport; const report_type: TReportTypeEnum): string;
const
    TOperationValue: TArray<integer> = [-1, 1, 1, -1];
begin
    var
    res := Default (TExtendedResponse);
    res.command_type := byte(command);
    res.is_offline := cashBox.is_offline;
    res.is_invalid_token := cashBox.is_invalid_token;
    res.kkm_local_name := cashBox.local_name;
    res.operator_name := cashBox.GetOperator.name;
    res.fr_shift_number := cashBox.GetLastShiftNumber;
    res.shift_document_number := cashBox.GetLastDocumentNumber;
    res.shift_state := cashBox.shift_state;
    res.reg_info := cashBox.reg_info;
    res.vat_certificate := cashBox.vat_certificate;
    res.report_type := byte(report_type);
    res.ads_info := cashBox.ads_info;
    res.is_dummy := cashBox.GetOperator.role = lrInspector;
    try
        res.body := report.AsJSONObject;
    except
        on E: Exception do
// WriteLogE('BuildReportResponse body deserialization exception: [%s] %s', [E.ClassName, E.message]);
    end;
    SetLength(res.total_payments, 5);
    for var i := 0 to Length(res.total_payments) - 1 do
        res.total_payments[i] := 0;
    if report.FieldHasValue[report.tag_ticket_operationsList] then
        for var operation in report.ticket_operationsList do
            if operation.FieldHasValue[operation.tag_paymentsList] then
                for var Payment in operation.paymentsList do
                    try
                        res.total_payments[byte(Payment.Payment)] := res.total_payments[byte(Payment.Payment)] + prototosum(Payment.sum) * TOperationValue[byte(operation.operation)];
                    except
                        on E: Exception do
// WriteLogE('BuildReportResponse payments exception: payment: %d, operation: %d, [%s] %s', [byte(Payment.Payment), byte(operation.operation), E.ClassName, E.message]);
                    end;

    Result := res.asReport;
end;


function BuildExtendedResponse(cashBox: TCashRegister; const command: TCommandTypeEnum; const body_data: string): string;
begin
    var
    res := Default (TExtendedResponse);
    res.command_type := byte(command);
    res.is_offline := cashBox.is_offline;
    res.is_invalid_token := cashBox.is_invalid_token;
    res.kkm_local_name := cashBox.local_name;
    res.operator_name := cashBox.GetOperator.name;
    res.fr_shift_number := cashBox.GetLastShiftNumber;
    res.shift_document_number := cashBox.GetLastDocumentNumber;
    res.shift_state := cashBox.shift_state;
    res.reg_info := cashBox.reg_info;
    res.ads_info := cashBox.ads_info;
    res.vat_certificate := cashBox.vat_certificate;
    res.is_dummy := cashBox.GetOperator.role = lrInspector;
    if SO().Check(body_data) then
        res.body := SO(body_data)
    else
        res.body := nil;

    Result := res.asString;
end;


function TProductSettings.LoadFromFile(const aFileName: string): boolean;
begin
    Result := FileExists(aFileName);
    if Result then
        try
            var
            X := SO(TFile.ReadAllText(aFileName, TEncoding.UTF8));
{$IF NOT defined(CUSTOM_BUILD)}
            X.Remove('auth_service_url');
            X.Remove('max_users_per_kkm');
            X.Remove('max_kkms_per_owner');
{$ENDIF}
            self := TJSON.Parse<TProductSettings>(X);
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
        X := TJSON.SuperObject(self);
{$IF NOT defined(CUSTOM_BUILD)}
        X.Remove('auth_service_url');
        X.Remove('max_users_per_kkm');
        X.Remove('max_kkms_per_owner');
{$ENDIF}
        TFile.WriteAllText(aFileName, X.AsJSON(true));
    except
        Result := false;
    end;
end;

{ TSimpleTicketRequest }


procedure TSimpleTicketRequest.ValidateTaxes(taxesList: TArray<proto.ticket.TTax>);
var
    PercentList: TArray<Int64>;
begin
    SetLength(PercentList, 0);
    for var tax in taxesList do
        if IntInArrayB(tax.percent, PercentList) then
            raise Exc(rc_tax_percentage_is_already_present)
        else
        begin
            SetLength(PercentList, Length(PercentList) + 1);
            PercentList[Length(PercentList) - 1] := tax.percent;
        end;
end;


procedure TSimpleTicketRequest.AppendItem_Commodity(const commodity: TSimpleCommodity; var items: TArray<proto.ticket.TItem>);
begin
    if commodity.name.IsEmpty then                // обязательное
        raise Exc(rc_item_commodity_undefined);   //
    if commodity.measure_unit_code.IsEmpty then   // обязательное
        raise Exc(rc_measure_unit_code_is_empty); //
    if commodity.section_code.IsEmpty then        // обязательное
        raise Exc(rc_section_code_is_empty);      //
    if commodity.quantity <= 0.000 then           // обязательное
        raise Exc(rc_item_quantity_is_incorrect); //
    if commodity.price <= 0.00 then               // обязательное
        raise Exc(rc_item_price_is_incorrect);    //
    if commodity.sum <= 0.00 then                 // обязательное
        raise Exc(rc_item_sum_is_incorrect);      //
    var
    item := TItem.Create;
    item.&type := TItemTypeEnum.ITEM_TYPE_COMMODITY;
    item.commodity.measure_unit_code := commodity.measure_unit_code; // обязательное
    item.commodity.section_code := commodity.section_code;           // обязательное
    if not commodity.physical_label.IsEmpty then
        item.commodity.physical_label := commodity.physical_label;
    if not commodity.product_id.IsEmpty then
        item.commodity.product_id := commodity.product_id;
    if not commodity.barcode.IsEmpty then
        item.commodity.barcode := commodity.barcode;
    if not commodity.excise_stamp.IsEmpty then
        item.commodity.excise_stamp := commodity.excise_stamp;
    if not commodity.name.IsEmpty then
        item.commodity.name := commodity.name;
    SumToProto(item.commodity.price, commodity.price);
    item.commodity.FieldHasValue[item.commodity.tag_price] := true;
    item.commodity.quantity := round(commodity.quantity * 1000);
    SumToProto(item.commodity.sum, commodity.sum);
    item.commodity.FieldHasValue[item.commodity.tag_sum] := true;
    for var simpleTax in commodity.taxes do
        if simpleTax.taxation_type IN [byte(LOW(TTaxationTypeEnum)) .. byte(HIGH(TTaxationTypeEnum))] then
        begin
            SetLength(item.commodity.taxesList, Length(item.commodity.taxesList) + 1);
            item.commodity.taxesList[Length(item.commodity.taxesList) - 1] := PrepareTax(simpleTax);
        end;
    item.commodity.FieldHasValue[item.commodity.tag_taxesList] := Length(item.commodity.taxesList) > 0;
    ValidateTaxes(item.commodity.taxesList);
    for var pair in commodity.auxiliary do
        if (not pair.key.IsEmpty) AND (not pair.value.IsEmpty) then
        begin
            SetLength(item.commodity.auxiliaryList, Length(item.commodity.auxiliaryList) + 1);
            item.commodity.auxiliaryList[Length(item.commodity.auxiliaryList) - 1] := TKeyValuePair.FromJSON(TJSON.Stringify(pair, false, false));
        end;
    item.commodity.FieldHasValue[item.commodity.tag_auxiliaryList] := Length(item.commodity.auxiliaryList) > 0;
    item.FieldHasValue[item.tag_commodity] := true;
    SetLength(items, Length(items) + 1);
    items[Length(items) - 1] := item;
end;


procedure TSimpleTicketRequest.AppendItem_Markup(const markup: TSimpleModifier; var items: TArray<proto.ticket.TItem>);
begin
    if markup.sum <= 0.00 then
        raise Exc(rc_item_markup_undefined);
    var
    item := TItem.Create;
    item.&type := TItemTypeEnum.ITEM_TYPE_MARKUP;
    item.markup.name := markup.name;
    SumToProto(item.markup.sum, markup.sum);
    item.markup.FieldHasValue[item.markup.tag_sum] := true;
    for var simpleTax in markup.taxes do
        if (simpleTax.taxation_type in [byte(LOW(TTaxationTypeEnum)) .. byte(HIGH(TTaxationTypeEnum))]) then
        begin
            SetLength(item.markup.taxesList, Length(item.markup.taxesList) + 1);
            item.markup.taxesList[Length(item.markup.taxesList) - 1] := PrepareTax(simpleTax);
        end;
    item.markup.FieldHasValue[item.markup.tag_taxesList] := Length(item.markup.taxesList) > 0;
    ValidateTaxes(item.markup.taxesList);
    for var pair in markup.auxiliary do
        if (not pair.key.IsEmpty) AND (not pair.value.IsEmpty) then
        begin
            SetLength(item.markup.auxiliaryList, Length(item.markup.auxiliaryList) + 1);
            item.markup.auxiliaryList[Length(item.markup.auxiliaryList) - 1] := TKeyValuePair.FromJSON(TJSON.Stringify(pair, false, false));
        end;
    item.markup.FieldHasValue[item.markup.tag_auxiliaryList] := Length(item.markup.auxiliaryList) > 0;
    item.FieldHasValue[item.tag_markup] := true;
    SetLength(items, Length(items) + 1);
    items[Length(items) - 1] := item;
end;


procedure TSimpleTicketRequest.AppendItem_Discount(const discount: TSimpleModifier; var items: TArray<proto.ticket.TItem>);
begin
    if discount.sum <= 0.00 then
        raise Exc(rc_item_discount_undefined);
    var
    item := TItem.Create;
    item.&type := TItemTypeEnum.ITEM_TYPE_DISCOUNT;
    item.discount.name := discount.name;
    SumToProto(item.discount.sum, discount.sum);
    item.discount.FieldHasValue[item.discount.tag_sum] := true;
    for var simpleTax in discount.taxes do
        if (simpleTax.taxation_type in [byte(LOW(TTaxationTypeEnum)) .. byte(HIGH(TTaxationTypeEnum))]) then
        begin
            SetLength(item.discount.taxesList, Length(item.discount.taxesList) + 1);
            item.discount.taxesList[Length(item.discount.taxesList) - 1] := PrepareTax(simpleTax);
        end;
    item.discount.FieldHasValue[item.discount.tag_taxesList] := Length(item.discount.taxesList) > 0;
    ValidateTaxes(item.discount.taxesList);
    for var pair in discount.auxiliary do
        if (not pair.key.IsEmpty) AND (not pair.value.IsEmpty) then
        begin
            SetLength(item.discount.auxiliaryList, Length(item.discount.auxiliaryList) + 1);
            item.discount.auxiliaryList[Length(item.discount.auxiliaryList) - 1] := TKeyValuePair.FromJSON(TJSON.Stringify(pair, false, false));
        end;
    item.discount.FieldHasValue[item.discount.tag_auxiliaryList] := Length(item.discount.auxiliaryList) > 0;
    item.FieldHasValue[item.tag_discount] := true;
    SetLength(items, Length(items) + 1);
    items[Length(items) - 1] := item;
end;


procedure TSimpleTicketRequest.ToProto(AResult: TTicketRequest);
begin
    if not(byte(self.operation) in [byte(LOW(TOperationTypeEnum)) .. byte(HIGH(TOperationTypeEnum))]) then
        raise Exc(rc_invalid_fields);
    if (self.items = nil) OR (Length(self.items) = 0) then
        raise Exc(rc_items_list_is_empty);
    if (self.items[0].&type <> TItemTypeEnum.ITEM_TYPE_COMMODITY) then
        raise Exc(rc_item_commodity_undefined);
    AResult.operation := self.operation;
    if not self.customer_iin_or_bin.IsEmpty then
    begin
        AResult.FieldHasValue[AResult.tag_extension_options] := true;
        AResult.extension_options.customer_iin_or_bin := self.customer_iin_or_bin;
    end;
    if Length(self.auxiliary) > 0 then
    begin
        AResult.FieldHasValue[AResult.tag_extension_options] := true;
        AResult.extension_options.FieldHasValue[AResult.extension_options.tag_auxiliaryList] := true;
        for var pair in self.auxiliary do
        begin
            SetLength(AResult.extension_options.auxiliaryList, Length(AResult.extension_options.auxiliaryList) + 1);
            AResult.extension_options.auxiliaryList[Length(AResult.extension_options.auxiliaryList) - 1] := TKeyValuePair.FromJSON(TJSON.Stringify(pair, false, false));
        end;
    end;
    DateTimeToProto(AResult.date_time, self.date_time);
    AResult.FieldHasValue[AResult.tag_date_time] := true;
    AResult.&operator.code := self.&operator.id;
    AResult.&operator.name := self.&operator.name;
    AResult.FieldHasValue[AResult.tag_operator] := AResult.&operator.FieldHasValue[AResult.&operator.tag_code] and AResult.&operator.FieldHasValue[AResult.&operator.tag_name];
    AResult.domain.&type := self.domain.&type;
    AResult.FieldHasValue[AResult.tag_domain] := AResult.domain.FieldHasValue[AResult.domain.tag_type];
{ подготовка позиций: скидки и наценки переносим внутрь позиции с товаром }
    for var i := 0 to Length(self.items) - 2 do
        if self.items[i].&type = TItemTypeEnum.ITEM_TYPE_COMMODITY then
            for var j := i + 1 to Length(self.items) - 1 do
                case self.items[j].&type of
                    TItemTypeEnum.ITEM_TYPE_MARKUP:
                        self.items[i].markup := self.items[j].markup;
                    TItemTypeEnum.ITEM_TYPE_DISCOUNT:
                        self.items[i].discount := self.items[j].discount;
                    else
                        break;
                end;
    for var simpleItem in self.items do
        case simpleItem.&type of
            TItemTypeEnum.item_type_unset:
                raise Exc(rc_unknown_item_type);
            TItemTypeEnum.ITEM_TYPE_COMMODITY:
                begin
                    AppendItem_Commodity(simpleItem.commodity, AResult.itemsList);
                    if simpleItem.markup.sum > 0.00 then
                        AppendItem_Markup(simpleItem.markup, AResult.itemsList);
                    if simpleItem.discount.sum > 0.00 then
                        AppendItem_Discount(simpleItem.discount, AResult.itemsList);
                end;
        end;
    AResult.FieldHasValue[AResult.tag_itemsList] := Length(AResult.itemsList) > 0;
    var
    ItemsHasTaxes := false;
    for var item in AResult.itemsList do
        case item.&type of
            TItemTypeEnum.ITEM_TYPE_COMMODITY:
                if Length(item.commodity.taxesList) > 0 then
                    ItemsHasTaxes := true;
            TItemTypeEnum.ITEM_TYPE_MARKUP:
                if Length(item.markup.taxesList) > 0 then
                    ItemsHasTaxes := true;
            TItemTypeEnum.ITEM_TYPE_DISCOUNT:
                if Length(item.discount.taxesList) > 0 then
                    ItemsHasTaxes := true;
        end;

    for var simplePayment in self.payments do
    begin
        SetLength(AResult.paymentsList, Length(AResult.paymentsList) + 1);
        AResult.paymentsList[Length(AResult.paymentsList) - 1] := PreparePayment(simplePayment);
    end;
    AResult.FieldHasValue[AResult.tag_paymentsList] := Length(AResult.paymentsList) > 0;

    for var simpleTax in self.taxes do
    begin
        SetLength(AResult.taxesList, Length(AResult.taxesList) + 1);
        AResult.taxesList[Length(AResult.taxesList) - 1] := PrepareTax(simpleTax);
    end;
    AResult.FieldHasValue[AResult.tag_taxesList] := Length(AResult.taxesList) > 0;

    ValidateTaxes(AResult.taxesList);
    if AResult.FieldHasValue[AResult.tag_taxesList] AND ItemsHasTaxes then
        raise Exc(rc_items_taxes_and_ticket_taxes_are_mutually_exclusive);
    if self.amounts.taken > 0.00 then
    begin
        SumToProto(AResult.amounts.taken, self.amounts.taken);
        AResult.amounts.FieldHasValue[AResult.amounts.tag_taken] := true;
    end;
    if self.amounts.markup.sum > 0.00 then
    begin
        AResult.amounts.markup.name := self.amounts.markup.name;
        SumToProto(AResult.amounts.markup.sum, self.amounts.markup.sum);
        AResult.amounts.markup.FieldHasValue[AResult.amounts.markup.tag_sum] := true;
        for var simpleTax in self.amounts.markup.taxes do
            if (simpleTax.taxation_type in [byte(LOW(TTaxationTypeEnum)) .. byte(HIGH(TTaxationTypeEnum))]) then
            begin
                SetLength(AResult.amounts.markup.taxesList, Length(AResult.amounts.markup.taxesList) + 1);
                AResult.amounts.markup.taxesList[Length(AResult.amounts.markup.taxesList) - 1] := PrepareTax(simpleTax);
            end;
        AResult.amounts.markup.FieldHasValue[AResult.amounts.markup.tag_taxesList] := Length(AResult.amounts.markup.taxesList) > 0;
        AResult.amounts.FieldHasValue[AResult.amounts.tag_markup] := true;
    end;
    if self.amounts.discount.sum > 0.00 then
    begin
        AResult.amounts.discount.name := self.amounts.discount.name;
        SumToProto(AResult.amounts.discount.sum, self.amounts.discount.sum);
        AResult.amounts.discount.FieldHasValue[AResult.amounts.discount.tag_sum] := AResult.amounts.discount.sum.FieldHasValue[AResult.amounts.discount.sum.tag_bills] and AResult.amounts.discount.sum.FieldHasValue[AResult.amounts.discount.sum.tag_coins];
        for var simpleTax in self.amounts.discount.taxes do
            if (simpleTax.taxation_type in [byte(LOW(TTaxationTypeEnum)) .. byte(HIGH(TTaxationTypeEnum))]) then
            begin
                SetLength(AResult.amounts.discount.taxesList, Length(AResult.amounts.discount.taxesList) + 1);
                AResult.amounts.discount.taxesList[Length(AResult.amounts.discount.taxesList) - 1] := PrepareTax(simpleTax);
            end;
        AResult.amounts.discount.FieldHasValue[AResult.amounts.discount.tag_taxesList] := Length(AResult.amounts.discount.taxesList) > 0;
        AResult.amounts.FieldHasValue[AResult.amounts.tag_discount] := true;
    end;
    AResult.FieldHasValue[AResult.tag_amounts] := AResult.amounts.FieldHasValue[AResult.amounts.tag_total];
end;

{ TExtendedResponse }


function TExtendedResponse.asString(Indent: boolean = true): string;
begin
    var
    X := TJSON.SuperObject(self);
    X.Remove('fiscal_id');
    X.Remove('qr_code');
    X.Remove('ofd_name');
    X.Remove('ofd_url');
    X.Remove('report_type');
    X.Remove('total_payments');

    Result := X.AsJSON(Indent);
end;


function TExtendedResponse.asTicket(Indent: boolean = true): string;
begin
    var
    X := TJSON.SuperObject(self);
    X.Remove('report_type');
    X.Remove('total_payments');

    Result := X.AsJSON(Indent);
end;


function TExtendedResponse.asReport(Indent: boolean = true): string;
begin
    var
    X := TJSON.SuperObject(self);
    X.Remove('fiscal_id');
    X.Remove('qr_code');
    X.Remove('ofd_name');
    X.Remove('ofd_url');

    Result := X.AsJSON(Indent);
end;

end.
