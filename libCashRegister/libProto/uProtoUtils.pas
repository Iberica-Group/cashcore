unit uProtoUtils;

interface

uses
    uTypes,
    FireDAC.Comp.Client,
    uBaseCoreTypes,
    proto.ticket,
    proto.common;

procedure DateTimeToProto(Result: proto.common.TDateTime; const Value: System.TDateTime);
procedure SumToProto(Result: proto.common.TMoney; const Value: Currency);
function ProtoToDateTime(const Value: proto.common.TDateTime): System.TDateTime;
function ProtoToSum(const Value: proto.common.TMoney; is_negative: boolean = false): Currency;
function PrepareTax(const Value: TSimpleTax): proto.ticket.TTax;
function PreparePayment(const Value: TSimplePayment): proto.ticket.TPayment;

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


function PrepareTax(const Value: TSimpleTax): proto.ticket.TTax;
begin
    if not(Value.taxation_type in [0, byte(LOW(TTaxationTypeEnum)) .. byte(HIGH(TTaxationTypeEnum))]) then
        raise Exc(rc_taxation_type_is_incorrect);

    if ((Value.percent <= 0) and (Value.sum > 0)) OR ((Value.percent > 0) and (Value.sum <= 0)) then
        raise Exc(rc_tax_value_is_incorrect);

    Result := TTax.Create;
    Result.tax_type := TTaxTypeEnum(100); // default;
    if Value.taxation_type > 0 then
        Result.taxation_type := TTaxationTypeEnum(Value.taxation_type);
    Result.percent := Trunc(Value.percent * 1000);
    SumToProto(Result.sum, Value.sum);
    Result.FieldHasValue[Result.tag_sum] := Result.sum.FieldHasValue[Result.sum.tag_bills] and Result.sum.FieldHasValue[Result.sum.tag_coins];
    Result.is_in_total_sum := Value.is_in_total_sum;
end;



function PreparePayment(const Value: TSimplePayment): proto.ticket.TPayment;
begin
        if NOT(Value.&type IN [LOW(TPaymentTypeEnum) .. HIGH(TPaymentTypeEnum)]) then
            raise Exc(rc_payment_type_is_incorrect);

        if Value.sum <= 0 then
            raise Exc(rc_payment_sum_is_incorrect);

        Result := TPayment.Create;
        Result.&type := Value.&type;
        SumToProto(Result.sum, Value.sum);
        Result.FieldHasValue[Result.tag_sum] := true;
end;

end.
