unit uGraphicsUtils;

interface

uses
    System.Types,
    System.UITypes,
    System.SysUtils,
    System.Math,
    FMX.Types,
    FMX.Graphics,
{$IFDEF MSWINDOWS}
    VCL.Graphics,
{$ENDIF MSWINDOWS}
    XSuperObject;

const
    cMaxLinesPerField  = 20;
    cDefaultImageWidth = 384;

    cDefaultFontSize          = 18;
    cDefaultFontSizeIncreased = 24;

    cDefaultPixelDrawThreshold = 128; // } 192;

type

    tagRGBTRIPLE = record
        rgbtBlue: Byte;
        rgbtGreen: Byte;
        rgbtRed: Byte;
        rgbtAlpha: Byte;
    end;


    TRGBTriple = tagRGBTRIPLE;

type
    TRGBTripleArray = ARRAY [word] of TRGBTriple;
    pRGBTripleArray = ^TRGBTripleArray;


    TCustomBitmapData = record
        Dots: array of boolean;
        Height: integer;
        Width: integer;
    end;

type
    TCustomFont = record
        Family: TFontName;
        Size: integer;
        Style: TFontStyles;
    end;

type
    TCustomTextSettings = record
        HorzAlign: TTextAlign;
        VertAlign: TTextAlign;
        Font: TCustomFont;
        FontColor: TAlphaColor;
        WordWrap: boolean;
    public
        procedure Init;
    end;

type
    TDrawableField = record
        BrushColor: TAlphaColor;
        GridRect: TRect;
        Margins: TRectF;
        StrokeColor: TAlphaColor;
        Text: string;
        TextRect: TRectF;
        TextSettings: TCustomTextSettings;
        Width: integer;
    end;

type
    PDrawableField = ^TDrawableField;

type
    TDrawableRow = record
    private
        FBrushColor, FStrokeColor: TAlphaColor;
    public
        Width: integer;
        Fields: TArray<TDrawableField>;
        function AddField: PDrawableField; overload;
        function AddField(const Source: TDrawableField): PDrawableField; overload;
        function Height: integer;
        function Draw(const Canvas: FMX.Graphics.TCanvas; const Bounds: TRectF): TRect;
        constructor Create(const BrushColor, StrokeColor: TAlphaColor);
    end;

type
    TBitmapHelper = class helper for FMX.Graphics.TBitmap
        function GetWidth(APercent: Byte): integer;
    end;


function GetMaxBitmapHeight: integer;

function RenderBitmapToBytes(ABitmap: FMX.Graphics.TBitmap; APixelDrawThreshold: Byte): TBytes;
{$IFDEF MSWINDOWS}
function ConvertFmxBitmapToVclBitmap(const src: FMX.Graphics.TBitmap; MaxHeight: integer = 0; FreeSRC: boolean = false): VCL.Graphics.TBitmap;
{$ENDIF MSWINDOWS}

implementation


function RGB(R, G, B: Byte): Cardinal;
begin
    Result := (R or (G shl 8) or (B shl 16));
end;

{$IFDEF MSWINDOWS}


function ConvertFmxBitmapToVclBitmap(const src: FMX.Graphics.TBitmap; MaxHeight: integer = 0; FreeSRC: boolean = false): VCL.Graphics.TBitmap;
var
    Data: FMX.Graphics.TBitmapData;
    i, j: integer;
    AlphaColor: TAlphaColor;
begin
    if MaxHeight = 0 then
        MaxHeight := src.Height;

    Result := VCL.Graphics.TBitmap.Create;
    Result.SetSize(src.Width, min(src.Height, MaxHeight));

    Result.PixelFormat := pf32bit;

    if (src.Map(TMapAccess.ReadWrite, Data)) then
        try
            for i := 0 to min(MaxHeight, Data.Height) - 1 do
            begin
                for j := 0 to Data.Width - 1 do
                begin
                    AlphaColor := Data.GetPixel(j, i);
                    Result.Canvas.Pixels[j, i] := RGB(TAlphaColorRec(AlphaColor).R, TAlphaColorRec(AlphaColor).G, TAlphaColorRec(AlphaColor).B);
                end;
            end;
        finally
            src.Unmap(Data);
        end;
    if FreeSRC then
        src.Destroy;
end;
{$ENDIF MSWINDOWS}


function GetMaxBitmapHeight: integer;
begin
{$IFDEF LINUX}
    Result := 8192;
{$ELSE}
    Result := TCanvasManager.DefaultCanvas.GetAttribute(TCanvasAttribute.MaxBitmapSize);
{$ENDIF}
end;


procedure WriteBytes(var ATo: TBytes; const AFrom: TBytes);
begin
    for var B in AFrom do
    begin
        SetLength(ATo, Length(ATo) + 1);
        ATo[Length(ATo) - 1] := B;
    end;
end;


function RenderBitmapToBytes(ABitmap: FMX.Graphics.TBitmap; APixelDrawThreshold: Byte): TBytes;
var
    LLine: pRGBTripleArray;
    LPixel: TRGBTriple;
    FBitmapData: TCustomBitmapData;
    BMPData: TBitmapData;
begin
    var
    LIndex := 0;

    if APixelDrawThreshold <= 0 then
        APixelDrawThreshold := cDefaultPixelDrawThreshold;

    ABitmap.Map(TMapAccess.Read, BMPData);

    FBitmapData.Height := ABitmap.Height;
    FBitmapData.Width := ABitmap.Width;
    SetLength(FBitmapData.Dots, ABitmap.Width * ABitmap.Height);

    for var LY := 0 to ABitmap.Height - 1 do
    begin
        LLine := BMPData.GetScanline(LY);
        for var LX := 0 to ABitmap.Width - 1 do
        begin
            LPixel := LLine[LX];
            var
            LLum := trunc((LPixel.rgbtRed * 0.3) + (LPixel.rgbtGreen * 0.59) + (LPixel.rgbtBlue * 0.11));
            FBitmapData.Dots[LIndex] := (LLum < APixelDrawThreshold);
            inc(LIndex);
        end;
    end;

    ABitmap.Unmap(BMPData);

    SetLength(Result, 0);

// *** Set the line spacing to 24 dots, the height of each "stripe" of the image that we're drawing
    WriteBytes(Result, [//
         $1B,           // 27
         $33,           // 51  Установка межстрочного интервала в n/216 дюйма
         $18            // 24  Значение
         ]);

    var
    LOffset := 0;
    while (LOffset < FBitmapData.Height) do
    begin
        WriteBytes(Result, [        //
             $1B,                   // 27
             $2A,                   // 42  Bit image mode (Режим графики)
             $21,                   // 33  24-dot double density
             Lo(FBitmapData.Width), // xx  Ширина изображения
             Hi(FBitmapData.Width)  // yy  Высота изображения
             ]);

        for var LX := 0 to FBitmapData.Width - 1 do
        begin
            for var LK := 0 to 2 do
            begin
                var
                LSlice := 0;
                for var LB := 0 to 7 do
                begin
                    var
                    LY := (((LOffset div 8) + LK) * 8) + LB;
                    var
                    LI := (LY * FBitmapData.Width) + LX;

                    var
                    LV := false;
                    if (LI < Length(FBitmapData.Dots)) then
                        LV := FBitmapData.Dots[LI];

                    var
                    LVI := IfThen(LV, 1, 0);

                    LSlice := LSlice or (LVI shl (7 - LB));
                end;
                WriteBytes(Result, [LSlice]);
            end;
        end;

        LOffset := LOffset + 24;
        WriteBytes(Result, [$0A { 10 } ]);
    end;

  // *** Restore the line spacing to the default of 30 dots
    WriteBytes(Result, [//
         $1B,           // 27
         $33,           // 51  Установка межстрочного интервала в n/216 дюйма
         $1E            // 30  Значение
         ]);

    WriteBytes(Result, [$0A, $0A { 10, 10 } ]);
end;


procedure TCustomTextSettings.Init;
begin
    Self.HorzAlign := TTextAlign.Leading;
    Self.VertAlign := TTextAlign.Leading;
    Self.FontColor := TAlphaColorRec.Black;
    Self.WordWrap := true;
    Self.Font.Style := [];
    Self.Font.Size := cDefaultFontSize;
    Self.Font.Family := 'Roboto';
{$IFDEF MSWINDOWS}
    Self.Font.Family := 'Consolas';
{$ENDIF}
{$IFDEF LINUX}
    Self.Font.Family := 'Ubuntu Mono';
{$ENDIF}
end;

{ TDrawableRow }


function TDrawableRow.AddField: PDrawableField;
begin
    SetLength(Fields, Length(Fields) + 1);
    FillChar(Fields[Length(Fields) - 1], sizeof(Fields[Length(Fields) - 1]), 0);
    Result := @Fields[Length(Fields) - 1];
    Result.TextSettings.Init;
    Result.Margins := TRectF.Create(2, 2, 2, 2);
    Result.BrushColor := FBrushColor;
    Result.StrokeColor := FStrokeColor;
end;


function TDrawableRow.AddField(const Source: TDrawableField): PDrawableField;
begin
    SetLength(Fields, Length(Fields) + 1);
    Fields[Length(Fields) - 1] := Source;
    Result := @Fields[Length(Fields) - 1];
end;


constructor TDrawableRow.Create(const BrushColor, StrokeColor: TAlphaColor);
begin
    FBrushColor := BrushColor;
    FStrokeColor := StrokeColor;
    SetLength(Fields, 0);
end;


function TDrawableRow.Draw(const Canvas: FMX.Graphics.TCanvas; const Bounds: TRectF): TRect;
var
    MaxHeight: integer;
    Xoffset: integer;
    R: TRectF;
    Value: string;
begin
    MaxHeight := 0;

    for var Field in Fields do
    begin
        Canvas.Font.AssignFromJSON(TJSON.SuperObject(Field.TextSettings.Font));
        MaxHeight := max(MaxHeight, round(Canvas.TextHeight('W') * cMaxLinesPerField + Field.Margins.Top + Field.Margins.Bottom));
    end;

    Result := TRect.Create(trunc(Bounds.Left), trunc(Bounds.Top), trunc(Bounds.Right), trunc(Bounds.Top));

    Xoffset := 0;
    for var i := 0 to Length(Fields) - 1 do
    begin
        Value := Fields[i].Text.Trim;
        Canvas.Font.AssignFromJSON(TJSON.SuperObject(Fields[i].TextSettings.Font));
        R := TRect.Create(trunc(Bounds.Left + Xoffset + Fields[i].Margins.Left), trunc(Bounds.Top + Fields[i].Margins.Top), trunc(Bounds.Left + Xoffset + Fields[i].Width - Fields[i].Margins.Right - Fields[i].Margins.Left), trunc(Bounds.Top + MaxHeight));
        Canvas.MeasureText(R, Value, Fields[i].TextSettings.WordWrap, [], Fields[i].TextSettings.HorzAlign, TTextAlign.Leading);
        Result.Height := min(MaxHeight, max(Result.Height, round(R.Height + Fields[i].Margins.Bottom + Fields[i].Margins.Top)));
        R.Height := Result.Height;
        Fields[i].TextRect := R;
        inc(Xoffset, trunc(Fields[i].Width));
    end;

    Canvas.BeginScene();

    Xoffset := 0;

    for var Field in Fields do
    begin
        Value := Field.Text.Trim;
        Canvas.Stroke.Color := Field.StrokeColor;
        Canvas.DrawRect(TRectF.Create(Bounds.Left + Xoffset, Bounds.Top, Bounds.Left + Xoffset + Field.Width, Bounds.Top + Result.Height), 0, 0, [], 1);
        Canvas.Font.AssignFromJSON(TJSON.SuperObject(Field.TextSettings.Font));
        Canvas.Fill.Color := Field.TextSettings.FontColor;
        Canvas.FillText(Field.TextRect, Value, Field.TextSettings.WordWrap, 1, [], Field.TextSettings.HorzAlign, Field.TextSettings.VertAlign);

        inc(Xoffset, trunc(Field.Width));
    end;

    Canvas.EndScene;
end;


function TDrawableRow.Height: integer;
begin
    Result := 0;
end;

{ TDrawableRow }

{ TBitmapHelper }


function TBitmapHelper.GetWidth(APercent: Byte): integer;
begin
    Result := trunc(APercent * Canvas.Width / Canvas.Scale / 100);
end;

end.
