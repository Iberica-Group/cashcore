unit uGraphics_KKMInfo;

interface

uses
    uTypes,
    uCashRegisterTypes,

    uGraphicsUtils,

    System.SysUtils,
    System.Types,
    System.UITypes,
    System.Math,
    System.Variants,

    XSuperObject,

    FMX.Graphics,
    FMX.Types;

procedure BuildKKMInfoImage(ResBitmap: TBitmap; bmpWidth: Cardinal; Reg_Info: TRegInfoRecord);

implementation


procedure BuildKKMInfoImage;
const
    TableBorderColor = TAlphaColorRec.Null;
var
    i: integer;
    Row: TDrawableRow;
    r: TRect;
    Xoffset, YOffset: integer;
    fmxBitmap: TBitmap;
// x: ISuperObject;
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

    i := 0;
    SetLength(Row.Fields, 1);

    Row.Fields[0].TextSettings.Init;
    Row.Fields[0].Width := trunc(99 * fmxBitmap.Width / 100);

    Row.Fields[0].Text := 'KKM';
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    var
    x := TJSON.SuperObject(Reg_Info.kkm); // SO(Reg_Info.AsJSON(true)).O['kkm'];
    x.First;
    while not x.Eof do
    begin
        Row.Fields[0].Text := Format('%s: %s', [x.CurrentKey, VarToStr(x.V[x.CurrentKey])]);
        r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        x.Next;
    end;
    inc(YOffset, 15);

    Row.Fields[0].Text := 'POS';
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    x := TJSON.SuperObject(Reg_Info.pos); // SO(Reg_Info.AsJSON(true)).O['pos'];
    x.First;
    while not x.Eof do
    begin
        Row.Fields[0].Text := Format('%s: %s', [x.CurrentKey, VarToStr(x.V[x.CurrentKey])]);
        r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        x.Next;
    end;
    inc(YOffset, 15);

    Row.Fields[0].Text := 'ORG';
    r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
    inc(YOffset, r.Height);
    x := TJSON.SuperObject(Reg_Info.org); // SO(Reg_Info.AsJSON(true)).O['org'];
    x.First;
    while not x.Eof do
    begin
        Row.Fields[0].Text := Format('%s: %s', [x.CurrentKey, VarToStr(x.V[x.CurrentKey])]);
        r := Row.Draw(fmxBitmap.Canvas, TRect.Create(Xoffset, YOffset, fmxBitmap.Width - Xoffset, fmxBitmap.Height));
        inc(YOffset, r.Height);
        x.Next;
    end;
    inc(YOffset, 15);

    ResBitmap.SetSize(bmpWidth, min(YOffset, GetMaxBitmapHeight));
    ResBitmap.CopyFromBitmap(fmxBitmap, TRect.Create(0, 0, bmpWidth, YOffset), 0, 0);
    fmxBitmap.Free;
end;

end.
