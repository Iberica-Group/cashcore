unit uGraphics_Ticket;

interface

uses
    proto.message,
    proto.ticket,
    proto.common,

    uMeasurement,
    uCashRegister,
    uCashRegisterTypes,

    uGraphicsUtils,
    uProtoUtils,
    DelphiZXIngQRCode,

    System.SysUtils,
    System.Types,
    System.UITypes,
    System.Math,

    FMX.Graphics,
    FMX.Types;

procedure BuildTicketImage(ResBitmap: TBitmap; Request: TRequest; isCopy: Boolean; bmpWidth: Cardinal; bmpScale: Single; cashBox: TCashRegister; const OFDRecord: TOfdRecord);

implementation


procedure BuildTicketImage;
const
    OperationTypeStr: TArray<String> = ['Сатып алу / Покупка', 'Сатып алу бойынша қайтарым / Возврат покупки', 'Сатылым / Продажа', 'Сату бойынша қайтарым / Возврат продажи'];
    FieldStrokeColor                 = TAlphaColorRec.Null; // } TAlphaColorRec.Red;
    FieldBrushColor                  = TAlphaColorRec.Null;
var
    r: TRect;
    Xoffset, YOffset: integer;
    s_fiscal: string;
    MeasureUnitStr: string;
    FieldLeft, FieldMid, FieldRight: PDrawableField;
begin
    if bmpScale <= 0 then
        bmpScale := 1.0;

    if bmpWidth <= 0 then
        bmpWidth := cDefaultImageWidth;

    var
    MaxBitmapHeight := GetMaxBitmapHeight;

    var
    fmxBitmap := TBitmap.Create;
    fmxBitmap.BitmapScale := bmpScale;

    fmxBitmap.SetSize(min(bmpWidth, MaxBitmapHeight), MaxBitmapHeight);

    fmxBitmap.Canvas.BeginScene();
    fmxBitmap.Canvas.Clear(TAlphaColorRec.White);
    fmxBitmap.Canvas.EndScene;

    Xoffset := 2;
    YOffset := 5;

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
    Row2.Fields[0].Width := fmxBitmap.GetWidth(60);
    Row2.Fields[1].Width := fmxBitmap.GetWidth(39);
    Row2.Fields[1].TextSettings.HorzAlign := TTextAlign.Trailing;

    var
    Row3 := TDrawableRow.Create(FieldBrushColor, FieldStrokeColor);
    Row3.AddField;
    Row3.AddField;
    Row3.AddField;

    FieldLeft := @Row3.Fields[0];
    FieldLeft.TextSettings.HorzAlign := TTextAlign.Center;
    FieldLeft.Width := fmxBitmap.GetWidth(10);

    FieldMid := @Row3.Fields[1];
    FieldMid.Width := fmxBitmap.GetWidth(59);
    FieldMid.TextSettings.HorzAlign := TTextAlign.Leading;

    FieldRight := @Row3.Fields[2];
    FieldRight.Width := fmxBitmap.GetWidth(30);
    FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;

    Row1.Fields[0].Text := cashBox.Reg_Info.org.title; // НАИМЕНОВАНИЕ ОРГАНИЗАЦИИ
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    Row1.Fields[0].Text := cashBox.Reg_Info.pos.address; // АДРЕС ТОРГОВОЙ ТОЧКИ
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    Row1.Fields[0].Text := 'ЖСН (БСН) / ИИН (БИН)' + #13 + cashBox.Reg_Info.org.inn; // ИИН/БИН ОРГАНИЗАЦИИ
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 15);

(*
{ БЛОК РЕКЛАМНОГО ТЕКСТА }
    Row1.Fields[0].Text := 'Мы рады видеть вас ежедневно 09:00-20:00.' + #13 + 'В выходные дни скидка до 10%'; // РЕКЛАМНЫЙ ТЕКСТ
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 15);
{ БЛОК РЕКЛАМНОГО ТЕКСТА }
*)//

    if cashBox.GetOperator.role = lrInspector then
    begin
        Row1.Fields[0].Text := '*** КОНТРОЛЬНЫЙ ЧЕК ***';
        r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
    end;

    if isCopy then
    begin
        Row1.Fields[0].Text := '*** КОПИЯ ДОКУМЕНТА ***';
        r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
    end;

    Row1.Fields[0].Text := OperationTypeStr[byte(Request.ticket.Operation)]; // ТИП ОПЕРАЦИИ
    Row1.Fields[0].TextSettings.Font.Style := [TFontStyle.fsBold];
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 5);

{ ПОЗИЦИИ }
    var
    itemIndex := 0;

    for var item in Request.ticket.itemsList do
    begin
        case item.&type of
            TItemTypeEnum.ITEM_TYPE_COMMODITY:
                begin
                    inc(itemIndex);

                    try
                        MeasureUnitStr := ' ' + GetCombinedShortMeasureNameByCode(item.commodity.measure_unit_code);
                    except
                        MeasureUnitStr := '';
                    end;

                    FieldLeft := @Row2.Fields[0];
                    FieldLeft.Width := fmxBitmap.GetWidth(10);
                    FieldLeft.Text := (itemIndex + 0).ToString; // НОМЕР ПОЗИЦИИ

                    FieldRight := @Row2.Fields[1];
                    FieldRight.Width := fmxBitmap.GetWidth(89);
                    FieldRight.TextSettings.HorzAlign := TTextAlign.Leading;
                    FieldRight.Text := item.commodity.name; // НАИМЕНОВАНИЕ ПОЗИЦИИ

                    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
                    inc(YOffset, r.Height);

                    FieldLeft := @Row3.Fields[0];
                    FieldLeft.Text := '';

                    FieldMid := @Row3.Fields[1];
                    FieldMid.Text := Format('%s%s x %s ₸', [FormatFloat('0.###', item.commodity.quantity / 1000), MeasureUnitStr, FormatFloat('0.##', ProtoToSum(item.commodity.price))]);

                    FieldRight := @Row3.Fields[2];
                    FieldRight.TextSettings.Font.Style := [TFontStyle.fsBold];
                    FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(item.commodity.sum)); // ИТОГО ЗА ТОВАР

                    r := Row3.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
                    inc(YOffset, r.Height);

                end;
            TItemTypeEnum.ITEM_TYPE_MARKUP:
                begin
                    FieldLeft := @Row3.Fields[0];
                    FieldLeft.Text := '';

                    FieldMid := @Row3.Fields[1];
                    FieldRight.TextSettings.Font.Style := [];
                    FieldMid.Text := item.markup.name; // НАИМЕНОВАНИЕ НАЦЕНКИ

                    FieldRight := @Row3.Fields[2];
                    FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(item.markup.sum)); // СУММА НАЦЕНКИ

                    r := Row3.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
                    inc(YOffset, r.Height);
                end;
            TItemTypeEnum.ITEM_TYPE_DISCOUNT:
                begin
                    FieldLeft := @Row3.Fields[0];
                    FieldLeft.Text := '';

                    FieldMid := @Row3.Fields[1];
                    FieldMid.Text := item.discount.name; // НАИМЕНОВАНИЕ СКИДКИ

                    FieldRight := @Row3.Fields[2];
                    FieldRight.TextSettings.Font.Style := [];
                    FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(item.discount.sum)); // СУММА СКИДКИ

                    r := Row3.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
                    inc(YOffset, r.Height);
                end;
        end;
    end;

{ --- ПОЗИЦИИ --- }

    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 15);

{ ИТОГИ ПО ЧЕКУ }

    if ProtoToSum(Request.ticket.amounts.discount.sum) > 0 then
    begin
        FieldLeft := @Row2.Fields[0];
        FieldLeft.Width := fmxBitmap.GetWidth(69);
        FieldLeft.Text := 'Жеңілдік / Скидка';

        FieldRight := @Row2.Fields[1];
        FieldRight.Width := fmxBitmap.GetWidth(30);
        FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;
        FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(Request.ticket.amounts.discount.sum));

        r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
    end;

    if ProtoToSum(Request.ticket.amounts.markup.sum) > 0 then
    begin
        FieldLeft := @Row2.Fields[0];
        FieldLeft.Width := fmxBitmap.GetWidth(69);
        FieldLeft.Text := 'Үстеме / Наценка';

        FieldRight := @Row2.Fields[1];
        FieldRight.Width := fmxBitmap.GetWidth(30);
        FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;
        FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(Request.ticket.amounts.markup.sum));

        r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
    end;

    FieldLeft := @Row2.Fields[0];
    FieldLeft.Width := fmxBitmap.GetWidth(50);
    FieldLeft.TextSettings.VertAlign := TTextAlign.Center;
    FieldLeft.Text := 'Барлығы / Итого';

    FieldRight := @Row2.Fields[1];
    FieldRight.Width := fmxBitmap.GetWidth(49);
    FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;
    FieldRight.TextSettings.Font.Style := [TFontStyle.fsBold];
    FieldRight.TextSettings.Font.Size := cDefaultFontSizeIncreased;
    FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(Request.ticket.amounts.total));

    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    FieldRight.TextSettings.Font.Style := [];
    FieldRight.TextSettings.Font.Size := cDefaultFontSize;
    Row1.Fields[0].TextSettings.Font.Style := [];

    inc(YOffset, 5);

    if length(Request.ticket.taxesList) > 0 then
    begin

        FieldLeft := @Row3.Fields[0];
        FieldLeft.TextSettings.HorzAlign := TTextAlign.Leading;
        FieldLeft.Width := fmxBitmap.GetWidth(40);
        FieldLeft.Text := 'Оның ішінде ҚҚС' + #13 + 'В том числе НДС';

        FieldMid := @Row3.Fields[1];
        FieldMid.Width := fmxBitmap.GetWidth(19);
        FieldMid.TextSettings.HorzAlign := TTextAlign.Trailing;
        FieldMid.TextSettings.VertAlign := TTextAlign.Center;

        FieldRight := @Row3.Fields[2];
        FieldRight.Width := fmxBitmap.GetWidth(40);
        FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;
        FieldRight.TextSettings.VertAlign := TTextAlign.Center;
        FieldRight.TextSettings.Font.Style := [];

        for var tax in Request.ticket.taxesList do
        begin
            FieldMid.Text := FormatFloat('0.## %', tax.percent / 1000);
            FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(tax.sum));
            r := Row3.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
            inc(YOffset, r.Height);
            FieldLeft.Text := '';
        end;
    end;

    inc(YOffset, 10);

    if length(Request.ticket.paymentsList) <= 0 then
    begin
        FieldLeft := @Row2.Fields[0];
        FieldLeft.Width := fmxBitmap.GetWidth(69);
        FieldLeft.TextSettings.HorzAlign := TTextAlign.Leading;
        FieldLeft.Text := 'Қолма-қол ақшамен / Наличными';

        FieldRight := @Row2.Fields[1];
        FieldRight.Width := fmxBitmap.GetWidth(30);
        FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;
        FieldRight.TextSettings.VertAlign := TTextAlign.Center;
        FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(Request.ticket.amounts.taken));

        r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
    end
    else
        for var payment in Request.ticket.paymentsList do
        begin
            FieldLeft := @Row2.Fields[0];
            FieldLeft.Width := fmxBitmap.GetWidth(69);
            FieldLeft.TextSettings.HorzAlign := TTextAlign.Leading;
            FieldLeft.Text := 'Қолма-қол ақшамен' + #13 + 'Наличными';

            case payment.&type of
                PAYMENT_CASH:
                    FieldLeft.Text := 'Қолма-қол ақшамен' + #13 + 'Наличными';
                PAYMENT_CARD:
                    FieldLeft.Text := 'Картамен / Картой';
                PAYMENT_CREDIT:
                    FieldLeft.Text := 'Кредитом';
                PAYMENT_TARE:
                    FieldLeft.Text := 'Тарой';
                PAYMENT_MOBILE:
                    FieldLeft.Text := 'Мобильді / Мобильный (QR)';
            end;

            FieldRight := @Row2.Fields[1];
            FieldRight.Width := fmxBitmap.GetWidth(30);
            FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;
            FieldRight.TextSettings.VertAlign := TTextAlign.Center;
// FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(Request.ticket.amounts.taken));
            FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(payment.sum));

            r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
            inc(YOffset, r.Height);
        end;

    if ProtoToSum(Request.ticket.amounts.change) > 0 then
    begin
        FieldLeft := @Row2.Fields[0];
        FieldLeft.Width := fmxBitmap.GetWidth(69);
        FieldLeft.Text := 'Қайтарым / Сдача';

        FieldRight := @Row2.Fields[1];
        FieldRight.Width := fmxBitmap.GetWidth(30);
        FieldRight.TextSettings.HorzAlign := TTextAlign.Trailing;
        FieldRight.Text := FormatFloat('0.00 ₸', ProtoToSum(Request.ticket.amounts.change));

        r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
    end;

{ --- ИТОГИ ПО ЧЕКУ --- }

    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    inc(YOffset, 15);

{ ИИН/БИН ПОКУПАТЕЛЯ }
    if                                                                                                           // если
         Request.ticket.extension_options.FieldHasValue[Request.ticket.extension_options.tag_customer_iin_or_bin]// есть ИИН/БИН
         AND                                                                                                     // и
         (NOT Request.ticket.extension_options.customer_iin_or_bin.IsEmpty)                                      // он не пустой
    then                                                                                                         // рисуем:
    begin
        Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Center;
        Row1.Fields[0].Text := 'Сатып алушының ЖСН (БСН)' + #13 + 'ИИН (БИН) покупателя' + #13 + Request.ticket.extension_options.customer_iin_or_bin;
        r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);

        r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
    end;
{ --- ИИН/БИН ПОКУПАТЕЛЯ --- }

{ ПРОВЕРКА ЧЕКА И QR }

    var
    QRCodeArea := TRectF.Create(                          //
         fmxBitmap.GetWidth(60) + 5,                      //
         YOffset + 5,                                     //
         fmxBitmap.GetWidth(100) { fmxBitmap.Width } - 5, //
         1                                                //
         );

    inc(YOffset, 15);

    Row1.Fields[0].Width := trunc(QRCodeArea.Left);
    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row1.Fields[0].Text := 'ФДО / ОФД' + #13 + OFDRecord.name;
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 15);

    Row1.Fields[0].Width := trunc(QRCodeArea.Left);
    Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row1.Fields[0].Text := 'Чекті тексеру' + #13 + 'Проверка чека' + #13 + OFDRecord.consumerAddress;
    r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    QRCodeArea.Bottom := YOffset - 5;

    var
    FQRCode := TDelphiZXingQRCode.Create; // генерация QR-кода
    with FQRCode do
    begin
        BeginUpdate;
        Data := Request.ticket.printed_ticket;
        Encoding := ENCODING_AUTO;
        ErrorCorrectionOrdinal := TErrorCorrectionOrdinal.ecoQ;
        QuietZone := 1;
        EndUpdate(true);
    end;

    var
    ratio := min(QRCodeArea.Width, QRCodeArea.Height) / FQRCode.Columns; // соотношение сторон картинки и QR-кода

    var
    QRCodeOffsetX := trunc((QRCodeArea.Width - FQRCode.Columns * ratio) / 2);

    var
    QRCodeOffsetY := trunc((QRCodeArea.Height - FQRCode.Rows * ratio) / 2);

    with fmxBitmap.Canvas do // отрисовка QR-кода на битмапе
    begin
        BeginScene();
        Stroke.Dash := TStrokeDash.Solid;
        Stroke.Kind := TBrushKind.Solid;
        Stroke.Thickness := 1;
        Stroke.Color := TAlphaColorRec.Black;
        Fill.Color := TAlphaColorRec.Black;
        Fill.Kind := TBrushKind.Solid;
        for var y := 0 to FQRCode.Rows - 1 do
            for var x := 0 to FQRCode.Columns - 1 do
                if FQRCode[y, x] then
                    FillRect(TRectF.Create(                                   //
                         QRCodeOffsetX + QRCodeArea.Left + x * ratio,         //
                         QRCodeOffsetY + QRCodeArea.Top + y * ratio,          //
                         QRCodeOffsetX + QRCodeArea.Left + x * ratio + ratio, //
                         QRCodeOffsetY + QRCodeArea.Top + y * ratio + ratio   //
                         ), 0, 0, [], 1);
        EndScene;
    end;

    FQRCode.Free;

    { --- ПРОВЕРКА ЧЕКА И QR --- } //

    inc(YOffset, 15);

    FieldLeft := @Row2.Fields[0];
    FieldLeft.Width := fmxBitmap.GetWidth(54);
    FieldLeft.TextSettings.HorzAlign := TTextAlign.Leading;
    FieldLeft.Text := 'Ауысым / Смена № ' + Request.ticket.fr_shift_number.ToString;

    FieldRight := @Row2.Fields[1];
    FieldRight.Width := fmxBitmap.GetWidth(45);
    FieldRight.TextSettings.HorzAlign := TTextAlign.Leading;
    FieldRight.Text := 'Оператор' + #13 + Request.ticket.operator.name;

    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 5);

    FieldLeft := @Row2.Fields[0];
    FieldLeft.Width := fmxBitmap.GetWidth(54);
    FieldLeft.TextSettings.HorzAlign := TTextAlign.Leading;
    FieldLeft.Text := 'Документ № ' + Request.ticket.shift_document_number.ToString;

    FieldRight := @Row2.Fields[1];
    FieldRight.Width := fmxBitmap.GetWidth(45);
    FieldRight.TextSettings.HorzAlign := TTextAlign.Leading;
    FieldRight.Text := FormatDateTime('dd.mm.yyyy, hh:nn:ss', ProtoToDateTime(Request.ticket.date_time));

    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 5);

    FieldLeft := @Row2.Fields[0];
    FieldLeft.Width := fmxBitmap.GetWidth(54);
    FieldLeft.TextSettings.HorzAlign := TTextAlign.Leading;
    FieldLeft.Text := 'МЗН / ЗНМ ' + #13 + Request.service.Reg_Info.kkm.serial_number;

    FieldRight := @Row2.Fields[1];
    FieldRight.Width := fmxBitmap.GetWidth(45);
    FieldRight.TextSettings.HorzAlign := TTextAlign.Leading;
    FieldRight.Text := 'МТН / РНМ ' + #13 + Request.service.Reg_Info.kkm.fns_kkm_id;

    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    if Request.ticket.offline_ticket_number > 0 then
        s_fiscal := Request.ticket.offline_ticket_number.ToString + #13 + 'автономный'
    else
        s_fiscal := Request.ticket.printed_document_number_old;

    inc(YOffset, 5);

    FieldLeft := @Row2.Fields[0];
    FieldLeft.Width := fmxBitmap.GetWidth(54);
    FieldLeft.TextSettings.HorzAlign := TTextAlign.Leading;
    FieldLeft.Text := 'ФБ / ФП ' + s_fiscal;

    FieldRight := @Row2.Fields[1];
    FieldRight.Width := fmxBitmap.GetWidth(45);
    FieldRight.TextSettings.HorzAlign := TTextAlign.Leading;
    if cashBox.Vat_Certificate.is_printable AND NOT cashBox.Vat_Certificate.series.IsEmpty AND NOT cashBox.Vat_Certificate.number.IsEmpty then
        FieldRight.Text := 'ҚҚС сериясы' + #13 + 'НДС серия ' + #13 + cashBox.Vat_Certificate.series + #13 + ' № ' + cashBox.Vat_Certificate.number;

    r := Row2.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 15);

    for var adsRecord in cashBox.ads_info do
// if adsRecord.info.&type = TTicketAdTypeEnum.TICKET_AD_INFO then
    begin
        Row1.Fields[0].Width := fmxBitmap.GetWidth(99);
        Row1.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
        Row1.Fields[0].Text := adsRecord.Text.Replace('${ticket_number}', s_fiscal);
{$IFDEF DEBUG}
        Row1.Fields[0].Text := Format('[%d] %s', [byte(adsRecord.info.&type), Row1.Fields[0].Text]);
{$ENDIF DEBUG}
        r := Row1.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);

        r := RowSeparator.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
    end;

    ResBitmap.SetSize(bmpWidth, min(trunc(YOffset * bmpScale), MaxBitmapHeight));
    ResBitmap.CopyFromBitmap(fmxBitmap, TRect.Create(0, 0, fmxBitmap.Width, fmxBitmap.Height), 0, 0);

    fmxBitmap.Destroy;

end;

end.
