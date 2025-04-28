unit uGraphics_CustomReport;

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

procedure BuildCustomReportImage(ResBitmap: TBitmap; report: TZXReport; const ReportType: TReportTypeEnum; bmpWidth: Cardinal; Reg_Info: TRegInfoRecord; Vat_Certificate: TVATCertificate);

implementation


procedure BuildCustomReportImage;
const
    TableBorderColor = TAlphaColorRec.Null;
var
    Row: TDrawableRow;
    r: TRect;
    Xoffset, YOffset: integer;
    fmxBitmap: TBitmap;
begin
    if bmpWidth <= 0 then
        bmpWidth := cDefaultImageWidth;

    fmxBitmap := TBitmap.Create;
    fmxBitmap.SetSize(min(bmpWidth, GetMaxBitmapHeight), GetMaxBitmapHeight);

    fmxBitmap.Canvas.BeginScene();
    fmxBitmap.Canvas.Clear(TAlphaColorRec.White);
    fmxBitmap.Canvas.EndScene;

    Xoffset := 1;
    YOffset := 5;

    SetLength(Row.Fields, 1);

    Row.Fields[0].TextSettings.Init;
    Row.Fields[0].TextSettings.HorzAlign := TTextAlign.Center;
    Row.Fields[0].TextSettings.VertAlign := TTextAlign.Center;
    Row.Fields[0].Width := trunc(99 * fmxBitmap.Width / 100);

    Row.Fields[0].Text := Reg_Info.org.title;
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    Row.Fields[0].Text := Translate('ИИН/БИН') + ': ' + Reg_Info.org.inn;
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    Row.Fields[0].Text := Translate('Сер. номер ККМ') + ': ' + Reg_Info.kkm.serial_number;
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    Row.Fields[0].Text := Translate('Рег. номер') + ': ' + Reg_Info.kkm.fns_kkm_id;
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 5);

    Row.Fields[0].Text := FormatDateTime('dd.mm.yyyy hh:nn:ss', ProtoToDateTime(report.date_time));
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    Row.Fields[0].Text := Translate('Номер смены') + ': ' + report.shift_number.ToString;
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 5);

    fmxBitmap.Canvas.BeginScene();
    fmxBitmap.Canvas.Stroke.Dash := TStrokeDash.Dash;
    fmxBitmap.Canvas.Stroke.Thickness := 2;
    fmxBitmap.Canvas.Stroke.Color := TAlphaColorRec.Black;
    fmxBitmap.Canvas.DrawLine(TPointF.Create(0, YOffset), TPointF.Create(bmpWidth, YOffset), 1);
    fmxBitmap.Canvas.EndScene;

    inc(YOffset, 5);

    SetLength(Row.Fields, 2);

    Row.Fields[0].Width := trunc(60 * fmxBitmap.Width / 100);
    Row.Fields[0].TextSettings.HorzAlign := TTextAlign.Leading;
    Row.Fields[0].TextSettings.VertAlign := TTextAlign.Trailing;

    Row.Fields[1].TextSettings.Init;
    Row.Fields[1].TextSettings.HorzAlign := TTextAlign.Trailing;
    Row.Fields[1].TextSettings.VertAlign := TTextAlign.Trailing;
    Row.Fields[1].Width := trunc(40 * fmxBitmap.Width / 100);

    case ReportType of
        REPORT_SECTIONS:
            Row.Fields[0].Text := Translate('Отчёт по секциям');
        REPORT_OPERATORS:
            Row.Fields[0].Text := Translate('Отчёт по кассирам');
    end;

    Row.Fields[1].Text := '';
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);

    inc(YOffset, 5);

    for var i := 0 to length(report.sectionsList) - 1 do
    begin
        case ReportType of
            REPORT_SECTIONS:
                Row.Fields[0].Text := Translate('Секция') + ': ' + report.sectionsList[i].section_code;
            REPORT_OPERATORS:
                Row.Fields[0].Text := Translate('Кассир') + ': ' + report.sectionsList[i].section_code;
        end;
        Row.Fields[1].Text := '';
        r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);

        for var Operation in report.sectionsList[i].operationsList do
        begin
            case Operation.Operation of
                OPERATION_BUY:
                    Row.Fields[0].Text := Format(Translate('Покупок: %d'), [Operation.count]);
                OPERATION_BUY_RETURN:
                    Row.Fields[0].Text := Format(Translate('Возвратов покупок: %d'), [Operation.count]);
                OPERATION_SELL:
                    Row.Fields[0].Text := Format(Translate('Продаж: %d'), [Operation.count]);
                OPERATION_SELL_RETURN:
                    Row.Fields[0].Text := Format(Translate('Возвратов продаж: %d'), [Operation.count]);
            end;
            Row.Fields[1].Text := FormatFloat('0.00', ProtoToSum(Operation.sum)) + ' ₸';
            r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
            inc(YOffset, r.Height);
        end;
        inc(YOffset, 5);
    end;

    fmxBitmap.Canvas.BeginScene();
    fmxBitmap.Canvas.Stroke.Dash := TStrokeDash.Dash;
    fmxBitmap.Canvas.Stroke.Thickness := 2;
    fmxBitmap.Canvas.Stroke.Color := TAlphaColorRec.Black;
    fmxBitmap.Canvas.DrawLine(TPointF.Create(0, YOffset), TPointF.Create(bmpWidth, YOffset), 1);
    fmxBitmap.Canvas.EndScene;

    inc(YOffset, 5);

    ResBitmap.SetSize(bmpWidth, min(YOffset, GetMaxBitmapHeight));
    ResBitmap.CopyFromBitmap(fmxBitmap, TRect.Create(0, 0, bmpWidth, YOffset), 0, 0);
    fmxBitmap.Free;
end;

end.
