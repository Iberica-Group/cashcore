unit proto.common.lists; { 202 }

interface

uses
    SysUtils,
    Classes,
    pbInput,
    pbOutput,
    pbPublic,
    proto.common,
    proto.ticket,
    proto.report,
    proto.service,
    uAbstractProtoBufClasses;

{ ticket }
function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.ticket.TItem>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.ticket.TItem>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.ticket.TTax>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.ticket.TTax>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.common.TKeyValuePair>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.common.TKeyValuePair>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.common.TTicketAdInfo>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.common.TTicketAdInfo>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.ticket.TPayment>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.ticket.TPayment>); overload;
{ ticket }

{ report }
function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TTaxOperation>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TTaxOperation>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TSection>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TSection>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TOperation>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TOperation>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TTax>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TTax>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TNonNullableSum>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TNonNullableSum>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TTicketOperation>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TTicketOperation>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TMoneyPlacement>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TMoneyPlacement>); overload;

function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TPayment>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TPayment>); overload;
{ report }

{ service }
function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.common.TTicketAd>): Boolean; overload;
procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.common.TTicketAd>); overload;
{ service }

implementation


{ ticket }


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.ticket.TItem>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.ticket.TItem.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.ticket.TItem>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.ticket.TTax>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.ticket.TTax.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.ticket.TTax>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<TKeyValuePair>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := TKeyValuePair.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<TKeyValuePair>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<TTicketAdInfo>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := TTicketAdInfo.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<TTicketAdInfo>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.ticket.TPayment>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.ticket.TPayment.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.ticket.TPayment>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;

{ ticket }


{ report }
function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TTaxOperation>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.report.TTaxOperation.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TTaxOperation>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TSection>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.report.TSection.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TSection>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TOperation>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.report.TOperation.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TOperation>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TTax>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.report.TTax.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TTax>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TNonNullableSum>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.report.TNonNullableSum.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TNonNullableSum>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TTicketOperation>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.report.TTicketOperation.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TTicketOperation>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TMoneyPlacement>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.report.TMoneyPlacement.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TMoneyPlacement>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<proto.report.TPayment>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := proto.report.TPayment.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<proto.report.TPayment>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;

{ report }

{ service }


function AddFromBufL(ProtoBuf: TProtoBufInput; FieldNum: Integer; var List: TArray<TTicketAd>): Boolean; overload;
var
    tmpBuf: TProtoBufInput;
begin
    Result := false;
    if ProtoBuf.LastTag <> makeTag(FieldNum, WIRETYPE_LENGTH_DELIMITED) then
        Exit;
    tmpBuf := ProtoBuf.ReadSubProtoBufInput;
    try
        SetLength(List, length(List) + 1);
        List[length(List) - 1] := TTicketAd.Create;
        List[length(List) - 1].LoadFromBuf(tmpBuf);
        Result := true;
    except
        List[length(List) - 1].Free;
        SetLength(List, length(List) - 1);
    end;
    tmpBuf.Free;
end;


procedure SaveToBufL(ProtoBuf: TProtoBufOutput; FieldNumForItems: Integer; List: TArray<TTicketAd>); overload;
var
    i: Integer;
    tmpBuf: TProtoBufOutput;
begin
    tmpBuf := TProtoBufOutput.Create;
    try
        for i := 0 to length(List) - 1 do
        begin
            tmpBuf.Clear;
            List[i].SaveToBuf(tmpBuf);
            ProtoBuf.writeMessage(FieldNumForItems, tmpBuf);
        end;
    finally
        tmpBuf.Free;
    end;
end;

{ service }
end.
