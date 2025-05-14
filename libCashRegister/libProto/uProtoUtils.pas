unit uProtoUtils;

interface

uses
    uTypes,
    FireDAC.Comp.Client,
    proto.common;

procedure DateTimeToProto(Result: proto.common.TDateTime; const Value: System.TDateTime);
procedure SumToProto(Result: proto.common.TMoney; const Value: Currency);
function ProtoToDateTime(const Value: proto.common.TDateTime): System.TDateTime;
function ProtoToSum(const Value: proto.common.TMoney; is_negative: boolean = false): Currency;

implementation

uses
    System.dateUtils,
    System.SysUtils,
    System.NetEncoding,
    XSuperObject,
    uUtils;


procedure DateTimeToProto;
begin
    if (Value <= 0) { AND correctTo1970 } then
    begin
        Result.date.year := 1970;
        Result.date.month := 1;
        Result.date.day := 1;

        Result.time.hour := 0;
        Result.time.minute := 0;
        Result.time.second := 0;
    end
    else
    begin
        Result.date.year := YearOf(Value);
        Result.date.month := MonthOf(Value);
        Result.date.day := DayOf(Value);

        Result.time.hour := HourOf(Value);
        Result.time.minute := MinuteOf(Value);
        Result.time.second := SecondOf(Value);
    end;
    Result.FieldHasValue[Result.tag_date] := true;
    Result.FieldHasValue[Result.tag_time] := true;
end;


procedure SumToProto;
var
    Coins: UInt64;
    Bills: UInt64;
begin
    if Value < 0.00 then
        raise Exc(rc_money_value_is_negative);

    Coins := Round(Value * 100);  // переводим сумму в монеты
    Bills := Trunc(Coins / 100);  // получаем сумму купюр (целое значение)
    Coins := Coins - Bills * 100; // получаем сумму монет (дробное значение)

    Result.Bills := Bills;
    Result.Coins := Coins;

(*
23.09.2024: Андрей Зинчеко - "Все суммы ( в т.ч. НДС) округляем по стандартному арифметическому правилу.
    Result.bills := trunc(Value);
    if IsTax then
        Result.coins := trunc(frac(Value) * 100)
    else
        Result.coins := Round(frac(Value) * 100);
*)
end;


function ProtoToDateTime;
begin
    if (Value.date.year > 0) AND (Value.date.month > 0) AND (Value.date.day > 0) then
        Result := EncodeDateTime(Value.date.year, Value.date.month, Value.date.day, Value.time.hour, Value.time.minute, Value.time.second, 0)
    else
        Result := 0;
end;


function ProtoToSum;
begin
    Result := Value.Bills + (Value.Coins / 100);
    if is_negative then
        Result := -Result;
end;

end.
