unit uMeasurement;

interface

const


    JSON_MEASURE_LIST = '[{"name_ru": "Штука","name_kz": "Дана","short_name_kz": "дана", "short_name_ru": "шт","code": "796"},' +
                        ' {"name_ru": "Килограмм","name_kz": "Килограмм","short_name_kz": "кг", "short_name_ru": "кг","code": "116"},' +
                        ' {"name_ru": "Услуга","name_kz": "Қызмет", "short_name_kz": "қзм", "short_name_ru": "усл","code": "5114"},' +
                        ' {"name_ru": "Метр","name_kz": "Метр","short_name_kz": "м", "short_name_ru": "м","code": "006"},' +
                        ' {"name_ru": "Литр","name_kz": "Литр","short_name_kz": "л", "short_name_ru": "л","code": "112"},' +
                        ' {"name_ru": "Погонный метр","name_kz": "Өткел қума метр","short_name_kz": "өқм", "short_name_ru": "пог.м","code": "021"},' +
                        ' {"name_ru": "Тонна","name_kz": "Тонна","short_name_kz": "т", "short_name_ru": "т","code": "168"},' +
                        ' {"name_ru": "Час","name_kz": "Сағат","short_name_kz": "сағ", "short_name_ru": "ч","code": "356"},' +
                        ' {"name_ru": "Сутки","name_kz": "Тәулік","short_name_kz": "тлк", "short_name_ru": "с","code": "359"},' +
                        ' {"name_ru": "Неделя","name_kz": "Апта","short_name_kz": "апт", "short_name_ru": "нед","code": "360"},' +
                        ' {"name_ru": "Месяц","name_kz": "Ай","short_name_kz": "ай", "short_name_ru": "мес","code": "362"},' +
                        ' {"name_ru": "Миллиметр","name_kz": "Миллиметр","short_name_kz": "мм", "short_name_ru": "мм","code": "003"},' +
                        ' {"name_ru": "Сантиметр","name_kz": "Сантиметр","short_name_kz": "см", "short_name_ru": "см","code": "004"},' +
                        ' {"name_ru": "Дециметр","name_kz": "Дециметр","short_name_kz": "дм", "short_name_ru": "дм","code": "005"},' +
                        ' {"name_ru": "Единица","name_kz": "Бірлік","short_name_kz": "брл", "short_name_ru": "ед","code": "642"},' +
                        ' {"name_ru": "Километр","name_kz": "Километр","short_name_kz": "км", "short_name_ru": "км","code": "008"},' +
                        ' {"name_ru": "Гектограмм","name_kz": "Гектограмм","short_name_kz": "гг", "short_name_ru": "гг","code": "160"},' +
                        ' {"name_ru": "Миллиграмм","name_kz": "Миллиграмм","short_name_kz": "мг", "short_name_ru": "мг","code": "161"},' +
                        ' {"name_ru": "Метрический карат","name_kz": "Метрлік карат","short_name_kz": "мкар", "short_name_ru": "кар","code": "162"},' +
                        ' {"name_ru": "Грамм","name_kz": "Грамм","short_name_kz": "г", "short_name_ru": "г","code": "163"},' +
                        ' {"name_ru": "Микрограмм","name_kz": "Микрограмм","short_name_kz": "мкг", "short_name_ru": "мкг","code": "164"},' +
                        ' {"name_ru": "Кубический миллиметр","name_kz": "Куб миллиметр","short_name_kz": "мм³", "short_name_ru": "мм³","code": "110"},' +
                        ' {"name_ru": "Миллилитр","name_kz": "Миллилитр","short_name_kz": "мл", "short_name_ru": "мл","code": "111"},' +
                        ' {"name_ru": "Квадратный метр","name_kz": "Шаршы метр","short_name_kz": "м²", "short_name_ru": "м²","code": "055"},' +
                        ' {"name_ru": "Гектар","name_kz": "Гектар","short_name_kz": "га", "short_name_ru": "га","code": "059"},' +
                        ' {"name_ru": "Квадратный километр","name_kz": "Шаршы километр","short_name_kz": "км²", "short_name_ru": "км²","code": "061"},' +
                        ' {"name_ru": "Лист","name_kz": "Парақ","short_name_kz": "прқ", "short_name_ru": "лист","code": "625"},' +
                        ' {"name_ru": "Пачка","name_kz": "Бума","short_name_kz": "бм", "short_name_ru": "пач","code": "728"},' +
                        ' {"name_ru": "Рулон","name_kz": "Орам","short_name_kz": "орам", "short_name_ru": "рул","code": "736"},' +
                        ' {"name_ru": "Упаковка","name_kz": "Орама","short_name_kz": "орм", "short_name_ru": "упак","code": "778"},' +
                        ' {"name_ru": "Бутылка","name_kz": "Бөтелке","short_name_kz": "бөт", "short_name_ru": "бут","code": "868"},' +
                        ' {"name_ru": "Работа","name_kz": "Жұмыс","short_name_kz": "жұм", "short_name_ru": "раб","code": "931"},' +
                        ' {"name_ru": "Метр кубический","name_kz": "Куб метр","short_name_kz": "м³", "short_name_ru": "м³","code": "113"}]';


function GetMeasureNameByCode(const measureUnitCode: string; const fieldName: string = 'name_ru'): string;
function GetCombinedShortMeasureNameByCode(const measureUnitCode: string): string;

implementation

uses
    System.SysUtils,
    XSuperObject;


function GetMeasureNameByCode(const measureUnitCode: string; const fieldName: string = 'name_ru'): string;
var
    res, measureList: ISuperArray;
begin
    Result := '';

    measureList := SA(JSON_MEASURE_LIST);

    res := measureList.Where(function(Arg: IMember): Boolean
      begin
        with Arg.AsObject do
             Result := (S['code'] = measureUnitCode)
      end);

    if res.Length = 1 then
        Result := res.O[0].S[fieldName];
end;


function GetCombinedShortMeasureNameByCode(const measureUnitCode: string): string;
begin
    var
    ru := GetMeasureNameByCode(measureUnitCode, 'short_name_ru');
    var
    kz := GetMeasureNameByCode(measureUnitCode, 'short_name_kz');

    if SameText(ru, kz) then
        result := ru
    else
        result := kz + '/' + ru;
end;

end.
