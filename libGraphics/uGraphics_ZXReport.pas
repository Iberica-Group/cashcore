unit uGraphics_ZXReport;

interface

uses
    proto.report,
    proto.common,

    uCashRegisterTypes,
    uGraphicsUtils,
    uProtoUtils,

    System.SysUtils,
    System.Types,
    System.UITypes,
    System.Math,

    FMX.Graphics,
    FMX.Types;

procedure BuildZXReportImage(ResBitmap: TBitmap; report: TZXReport; const ReportType: TReportTypeEnum; isCopy: Boolean; bmpWidth: Cardinal; bmpScale: Single; Reg_Info: TRegInfoRecord; Vat_Certificate: TVATCertificate);

implementation


procedure BuildZXReportImage;
type
    TPaymentRecord = record
        sum: Currency;
        count: Cardinal;
    end;

type
    TOperationPaymentList = array [0 .. byte(HIGH(TPaymentTypeEnum))] of TPaymentRecord;

type
    TOperationPayments = array [0 .. byte(HIGH(TOperationTypeEnum))] of TOperationPaymentList;

const
    FieldStrokeColor              = TAlphaColorRec.Null; // } Red;
    FieldBrushColor               = TAlphaColorRec.Null;
    ReportTypeChr: TArray<string> = ['Z-есебі / Z-отчет', 'X-есебі / X-отчет'];
    ReportTypeStr: TArray<string> = ['Отчёт с гашением', 'Отчёт без гашения'];

var
    r: TRect;
    Xoffset, YOffset: integer;
    FieldLeft, FieldMid, FieldRight: PDrawableField;
    OperationPayments: TOperationPayments;
begin
    if bmpScale <= 0 then
        bmpScale := 1.0;

    var
    MaxBitmapHeight := GetMaxBitmapHeight;

// DoSync(
// procedure
// begin
    if bmpWidth <= 0 then
        bmpWidth := cDefaultImageWidth;

    var
    fmxBitmap := TBitmap.Create;
    fmxBitmap.BitmapScale := bmpScale;

    fmxBitmap.SetSize(min(bmpWidth, MaxBitmapHeight), MaxBitmapHeight);

    fmxBitmap.Canvas.BeginScene();
    fmxBitmap.Canvas.Clear(TAlphaColorRec.White);
    fmxBitmap.Canvas.EndScene;

    Xoffset := 1;
    YOffset := 10;

    var
    RowSeparator := TDrawableRow.Create(FieldBrushColor, FieldStrokeColor);
    RowSeparator.AddField;
    RowSeparator.Fields[0].Width := fmxBitmap.GetWidth(99);
    RowSeparator.Fields[0].Text := ''.PadRight(100, '_');
    RowSeparator.Fields[0].TextSettings.WordWrap := false;
    RowSeparator.Fields[0].TextSettings.FontColor := TAlphaColorRec.Gray;

    var
    Row1 := TDrawableRow.Create(FieldBrushColor, FieldStrokeColor);
    Row1.AddField;
    Row1.Fields[0].Width := fmxBitmap.GetWidth(99);
    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Center;

    var
    Row2 := TDrawableRow.Create(FieldBrushColor, FieldStrokeColor);
    Row2.AddField;
    Row2.AddField;
    FieldLeft := @Row2.Fields[0];
    FieldRight := @Row2.Fields[1];
    FieldLeft.Width := fmxBitmap.GetWidth(60);
    FieldRight.Width := fmxBitmap.GetWidth(39);
    FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;

// НАИМЕНОВАНИЕ ОРГАНИЗАЦИИ
    Row1.Fields[0].Text := Reg_Info.org.title;
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

// АДРЕС ТОРГОВОЙ ТОЧКИ
    Row1.Fields[0].Text := Reg_Info.pos.address;
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

// ИИН/БИН ОРГАНИЗАЦИИ
    Row1.Fields[0].Text := 'ЖСН (БСН) / ИИН (БИН)' + #13 + Reg_Info.org.inn;
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

// РАЗДЕЛИТЕЛЬ
    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

 // ТИП ОТЧЁТА
    Row1.Fields[0].Text := ReportTypeChr[byte(ReportType)];
    Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
// Row1.Fields[0].TextSettings.Font.Size := 16;
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    Row1.Fields[0].TextSettings.Font.Style := [];

    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 15);

{ ОТЧЁТ ПО СЕКЦИЯМ }
    var
    iSectionIndex := 0;

    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];

    for var section in report.sectionsList do
    begin
        inc(iSectionIndex);

        FieldLeft.Text := Format('№%0:d бөлім / Секция №%0:d', [iSectionIndex]); // + section.section_code;
        FieldLeft.TextSettings.Font.Style := [TFontStyle.fsBold];
        FieldRight.Text := section.section_code;
        r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);

        for var Operation in section.operationsList do
        begin
            inc(YOffset, 5);

            case Operation.Operation of

                OPERATION_BUY:
                    FieldLeft.Text := 'Сатып алу / Покупка';
                OPERATION_BUY_RETURN:
                    FieldLeft.Text := 'Сатып алуды қайтару / Возврат покупки';
                OPERATION_SELL:
                    FieldLeft.Text := 'Сатылым / Продажа';
                OPERATION_SELL_RETURN:
                    FieldLeft.Text := 'Сатуды қайтару / Возврат продажи';
            end;
            FieldLeft.Text := Format('%s [%d]', [FieldLeft.Text, Operation.count]);
            FieldLeft.TextSettings.Font.Style := [];
            FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(Operation.sum));
            r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
            inc(YOffset, r.Height);
            inc(YOffset, 10);

        end;
        r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        inc(YOffset, 5);
    end;

{ ОТЧЁТ ПО НАЛОГАМ }

    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
    Row1.Fields[0].Text := 'ҚҚС бойынша қорытынды / Итог по НДС';
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 10);

    for var tax in report.taxesList do
    begin
        Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
        Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
        Row1.Fields[0].Text := Format('ҚҚС %0:d%% / НДС %0:d%%', [trunc(tax.percent / 1000)]);
        r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        inc(YOffset, 10);

        for var Operation in tax.operationsList do
        begin
            Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
            Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
            case Operation.Operation of
                OPERATION_BUY:
                    Row1.Fields[0].Text := 'Сатып алу / Покупка';
                OPERATION_BUY_RETURN:
                    Row1.Fields[0].Text := 'Сатып алуды қайтару / Возврат покупки';
                OPERATION_SELL:
                    Row1.Fields[0].Text := 'Сатылым / Продажа';
                OPERATION_SELL_RETURN:
                    Row1.Fields[0].Text := 'Сатуды қайтару / Возврат продажи';
            end;
            r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
            inc(YOffset, r.Height);
            inc(YOffset, 10);

            FieldLeft.Text := 'ҚҚС бойынша айналым / Оборот по НДС';
            FieldRight.Text := FormatFloat('0.00', ProtoToSum(Operation.turnover)) + ' ₸';;
            r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
            inc(YOffset, r.Height);
            inc(YOffset, 10);

            FieldLeft.Text := 'ҚҚС / НДС';
            FieldRight.Text := FormatFloat('0.00', ProtoToSum(Operation.sum)) + ' ₸';
            r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
            inc(YOffset, r.Height);
            inc(YOffset, 10);
        end;
    end;

    inc(YOffset, 15);

{ ОТЧЁТ ПО ТИПАМ ПЛАТЕЖЕЙ }

    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
    Row1.Fields[0].Text := 'Төлемдер түрі бойынша барлығы / Итого по типам платежей';
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 10);

    FillChar(OperationPayments, sizeof(OperationPayments), 0);
    for var ticket in report.ticket_operationsList do
        for var payment in ticket.paymentsList do
        begin
            OperationPayments[byte(ticket.Operation)][byte(payment.payment)].sum := OperationPayments[byte(ticket.Operation)][byte(payment.payment)].sum + ProtoToSum(payment.sum);
            OperationPayments[byte(ticket.Operation)][byte(payment.payment)].count := OperationPayments[byte(ticket.Operation)][byte(payment.payment)].count + payment.count;
        end;

    for var iOperation := 0 to byte(HIGH(TOperationTypeEnum)) do
    begin
        var
        count := 0;
        for var iPayment := 0 to byte(HIGH(TPaymentTypeEnum)) do
            inc(count, OperationPayments[iOperation][iPayment].count);
        if count <= 0 then
            Continue;

        Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
        Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
        case TOperationTypeEnum(iOperation) of
            OPERATION_BUY:
                Row1.Fields[0].Text := 'Сатып алу / Покупка';
            OPERATION_BUY_RETURN:
                Row1.Fields[0].Text := 'Сатып алуды қайтару / Возврат покупки';
            OPERATION_SELL:
                Row1.Fields[0].Text := 'Сатылым / Продажа';
            OPERATION_SELL_RETURN:
                Row1.Fields[0].Text := 'Сатуды қайтару / Возврат продажи';
        end;
        r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        inc(YOffset, 10);

        for var iPayment := 0 to byte(HIGH(TPaymentTypeEnum)) do
            if (OperationPayments[iOperation][iPayment].count > 0) or (OperationPayments[iOperation][iPayment].sum > 0) then
            begin
                case TPaymentTypeEnum(iPayment) of
                    PAYMENT_CASH:
                        FieldLeft.Text := 'Қолма-қол ақшамен / Наличными';
                    PAYMENT_CARD:
                        FieldLeft.Text := 'Картамен / Картой';
                    PAYMENT_CREDIT:
                        FieldLeft.Text := 'CREDIT'; // нам же похуй на аналитику
                    PAYMENT_TARE:
                        FieldLeft.Text := 'TARE'; // нам же похуй на аналитику
                    PAYMENT_MOBILE:
                        FieldLeft.Text := 'Мобильді / Мобильный';
                end;
                FieldLeft.Text := Format('%s [%d]', [FieldLeft.Text, OperationPayments[iOperation][iPayment].count]);
                FieldRight.Text := FormatFloat('0.00 ₸', OperationPayments[iOperation][iPayment].sum);
                r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
                inc(YOffset, r.Height);
                inc(YOffset, 10);
            end;

    end;

    inc(YOffset, 15);

{ НЕОБНУЛЯЕМЫЕ СУММЫ }

    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
    Row1.Fields[0].Text := 'Ауысым басындағы қалпына келтірмейтін сома / Необнуляемые суммы на начало смены';
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 10);

    for var NSS in report.start_shift_non_nullable_sumsList do
    begin
        case NSS.Operation of
            OPERATION_BUY:
                FieldLeft.Text := 'Сатып алу / Покупка';
            OPERATION_BUY_RETURN:
                FieldLeft.Text := 'Сатып алуды қайтару / Возврат покупки';
            OPERATION_SELL:
                FieldLeft.Text := 'Сатылым / Продажа';
            OPERATION_SELL_RETURN:
                FieldLeft.Text := 'Сатуды қайтару / Возврат продажи';
        end;
        FieldRight.TextSettings.Font.Style := [];
        FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(NSS.sum));
        r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        inc(YOffset, 10);
    end;

    inc(YOffset, 15);

    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
    Row1.Fields[0].Text := 'Қалпына келтірмейтін сома / Необнуляемые суммы';
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 10);

    for var NSS in report.non_nullable_sumsList do
    begin
        case NSS.Operation of
            OPERATION_BUY:
                FieldLeft.Text := 'Сатып алу / Покупка';
            OPERATION_BUY_RETURN:
                FieldLeft.Text := 'Сатып алуды қайтару / Возврат покупки';
            OPERATION_SELL:
                FieldLeft.Text := 'Сатылым / Продажа';
            OPERATION_SELL_RETURN:
                FieldLeft.Text := 'Сатуды қайтару / Возврат продажи';
        end;
        FieldRight.TextSettings.Font.Style := [];
        FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(NSS.sum));
        r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        inc(YOffset, 10);
    end;

    inc(YOffset, 15);

{ ИТОГ ПО СМЕНЕ }

    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
    Row1.Fields[0].Text := 'Ауысым қорытындысы / Сменный итог';
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 10);

    for var total in report.total_resultList do
    begin
        case total.Operation of
            OPERATION_BUY:
                FieldLeft.Text := 'Сатып алу / Покупка';
            OPERATION_BUY_RETURN:
                FieldLeft.Text := 'Сатып алуды қайтару / Возврат покупки';
            OPERATION_SELL:
                FieldLeft.Text := 'Сатылым / Продажа';
            OPERATION_SELL_RETURN:
                FieldLeft.Text := 'Сатуды қайтару / Возврат продажи';
        end;
        FieldLeft.Text := Format('%s [%d]', [FieldLeft.Text, total.count]);
        FieldRight.TextSettings.Font.Style := [];
        FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(total.sum));
        r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        inc(YOffset, 10);
    end;

    FieldLeft.Text := 'Кассадағы қолма-қол ақша / Наличные в кассе';
    FieldRight.TextSettings.Font.Style := [TFontStyle.fsBold];
    FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(report.cash_sum));
    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 10);

    FieldLeft.Text := 'Кіріс / Выручка';
    FieldRight.TextSettings.Font.Style := [TFontStyle.fsBold];
    FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(report.revenue.sum));
    if report.revenue.is_negative then
        FieldRight.Text := '-' + FieldRight.Text;
    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 10);

    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 15);

{ НИЖНИЙ БЛОК }

    FieldLeft.Text := 'Ауысым / Смена ' + #13 + '№ ' + report.shift_number.ToString;
    FieldRight.Text := FormatDateTime('dd.mm.yyyy' + #13 + 'hh:nn:ss', ProtoToDateTime(report.date_time));
    FieldRight.TextSettings.Font.Style := [];
    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 15);

    FieldLeft.Text := 'МЗН / ЗНМ' + #13 + Reg_Info.kkm.serial_number;
    FieldRight.Text := 'МТН / РНМ' + #13 + Reg_Info.kkm.fns_kkm_id;
    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

{ ОТСТУП ОТ НИЖНЕГО КРАЯ }

    inc(YOffset, 15);

    ResBitmap.SetSize(bmpWidth, min(trunc(YOffset * bmpScale), MaxBitmapHeight));
    ResBitmap.CopyFromBitmap(fmxBitmap, TRect.Create(0, 0, fmxBitmap.Width, fmxBitmap.Height), 0, 0);

    fmxBitmap.Destroy;
// end);
end;

end.
