unit uTypes;

interface

const // Result Codes
(* устаревшие коды:
    rc_settings_save_error                                 = 6;
    rc_kkm_save_error                                      = 7;  // ошибка сохранения кассы
    rc_operator_update_error                               = 14; // ошибка обновления оператора
    rc_save_error                                          = 22;
    rc_send_error                                          = 23;
    rc_receive_error                                       = 24;
    rc_kkm_vendor_id_mismatch                              = 25;
    rc_kkm_shift_state_is_opened                           = 26;
    rc_kkm_status_is_ready_to_use                          = 27;
    rc_forced_offline_mode                                 = 30;
    rc_shift_duration_is_too_long                          = 31; // смена длится слишком долго
    rc_invalid_shift_number                                = 32;
    rc_report_not_found                                    = 33;
    rc_kkm_shift_state_is_not_opened                       = 35;
    rc_kkm_address_is_already_in_use                       = 38;
    rc_invalid_operator_role                               = 39;
    rc_kkm_ofd_id_is_already_in_use                        = 40;
    rc_kkm_vendor_id_is_already_in_use                     = 41;
    rc_items_list_undefined                                = 44; // список товаров отсутствует
    rc_amounts_undefined                                   = 51; // сумма не указана
    rc_operation_in_progress                               = 66;
    rc_kkm_locked_due_to_values_conflict                   = 68; // касса заблокирована из-за расхождения счётчиков
    rc_kkm_is_not_initialized                              = 70; // касса не инициализирована
    rc_license_activation_error                            = 80; // ошибка активации лицензии
    rc_invalid_license_file                                = 85; // лицензионный файл повреждён
*)
    rc_ok                                                  = 0;  // операция выполнена успешно
    rc_unknown_result                                      = 1;  // неизвестная ошибка
    rc_invalid_fields                                      = 2;  // поля запроса заполнены некорректно
    rc_method_not_found                                    = 3;  // метод не существует
    rc_method_execution_exception                          = 4;  // неизвестная ошибка при выполнении метода
    rc_invalid_access_code                                 = 5;  // некорректный пин-код или токен
    rc_kkm_reginfo_request_error                           = 8;  // ошибка запроса рег.данных кассы
    rc_invalid_kkm_vendor_id                               = 9;  // некорректный ЗНМ (серийный номер кассы)
    rc_kkm_delete_error                                    = 10; // ошибка удаления кассы
    rc_access_code_incorrect                               = 11; // задан некорректный пин-код
    rc_access_code_already_used                            = 12; // пин-код / email уже используется
    rc_operator_save_error                                 = 13; // ошибка сохранения оператора
    rc_invalid_operator_code                               = 15; // некорректный ID оператора
    rc_operator_delete_error                               = 16; // ошибка удаления оператора
    rc_invalid_kkm_credentials                             = 17; // некорректные рег.данные кассы
    rc_kkm_in_offline_mode_too_long                        = 18; // касса слишком долго находится в автономном режиме
    rc_db_error                                            = 19; // внутреннняя ошибка БД
    rc_connection_error                                    = 20; // ошибка связи с сервером ОФД
    rc_protobuf_serialization_error                        = 21; // ошибка сериализации данных
    rc_protobuf_deserialization_error                      = 28; // ошибка десериализации данных
    rc_operation_failed                                    = 29; // операция завершилась неудачей
    rc_invalid_report_type                                 = 34; // некооректный тип отчёта
    rc_invalid_local_date                                  = 36; // установлена некорректная дата
    rc_operation_not_found                                 = 37; // операция не найдена
    rc_invalid_kkm_token                                   = 42; // некорректный токен кассы
    rc_transaction_not_found                               = 43; // транзакция не найдена
    rc_items_list_is_empty                                 = 45; // список товаров пуст
    rc_item_commodity_undefined                            = 46; // товар не указан
    rc_item_quantity_is_incorrect                          = 47; // значение количества указано некорректно
    rc_item_discount_undefined                             = 48; // скидка на позицию не описана
    rc_item_markup_undefined                               = 49; // наценка на позицию не описана
    rc_unknown_item_type                                   = 50; // неизвестный тип элемента
    rc_amounts_total_is_incorrect                          = 52; // итоговая сумма некорректна
    rc_money_value_is_negative                             = 53; // сумма наличных отрицательна
    rc_sum_to_pay_is_incorrect                             = 54; // сумма к оплате некорректна
    rc_card_sum_is_greater_than_total                      = 55; // сумма оплаты картой больше итоговой
    rc_paid_sum_is_incorrect                               = 56; // оплаченная сумма некорректна
    rc_paid_sum_is_less_than_total                         = 57; // оплаченная сумма меньше итоговой
    rc_not_enough_cash                                     = 58; // недостаточно наличных в кассе
    rc_discount_sum_must_be_less_than_total                = 59; // сумма скидки должна быть меньше итоговой суммы
    rc_taxation_type_is_incorrect                          = 60; // некорректный вид налогообложения
    rc_invalid_kkm_ofd_id                                  = 61; // некорректный ID кассы из ОФД
    rc_kkm_is_blocked                                      = 62; // касса заблокирована
    rc_discount_sum_is_negative                            = 63; // сумма скидки отрицательна
    rc_markup_sum_is_negative                              = 64; // сумма наценки отрицательна
    rc_discount_and_markup_are_mutually_exclusive          = 65; // скидка и наценка являются взаимоисключающими
    rc_kkm_has_offline_queue                               = 67; // касса содержит автономную очередь
    rc_kkm_is_busy_too_long                                = 69; // Касса до сих пор выполняет предыдущую операцию
    rc_kkm_access_denied                                   = 71; // у пользователя нет доступа к кассе
    rc_kkm_invalid_bindings                                = 72; // у пользователя нет прав на использование кассы
    rc_source_object_deserialization_error                 = 73; // ошибка десериализации объекта из запроса
    rc_kkm_per_owner_limit_exceed                          = 74; // превышен лимит количества касс для пользователя
    rc_kkm_operators_limit_exceed                          = 75; // превышен лимит количества пользователей на кассу
    rc_kkm_shift_is_not_closed                             = 76; // касса с незакрытой сменой
    rc_same_taxpayer_and_customer                          = 77; // ИИН (БИН) продавца и покупателя одинаковые
    rc_invalid_ofd_uid                                     = 78; // некорректный идентификатор ОФД
    rc_license_period_expired                              = 79; // срок действия лицензии истёк
    rc_measure_unit_code_is_empty                          = 81; // код единицы измерения не может быть пустым
    rc_section_code_is_empty                               = 82; // код секции (номер отдела) не может быть пустым
    rc_invalid_kkm_ofd                                     = 83; // задан некорректный ОФД для кассы
    rc_invalid_ofd_response                                = 84; // ОФД вернул сообщение об ошибке
    rc_db_error_duplicates                                 = 86; // найдено больше одной записи
    rc_invalid_activation_code                             = 87; // некорректный код активации
    rc_items_taxes_and_ticket_taxes_are_mutually_exclusive = 88; // НДС на позицию и на весь чек являются взаимоисключающими
    rc_tax_percentage_is_already_present                   = 89; // Налог с определённым процентом может встречаться не более одного раза
    rc_invalid_license_key                                 = 90; // некорректный лицензионный ключ
    rc_ofd_list_is_empty                                   = 91; // лицензия не содержит ни одного ОФД
    rc_license_suspended                                   = 92; // действие лицензии приостановлено
    rc_license_online_check_error                          = 93; // ошибка онлайн-проверки лицензии
    rc_item_price_is_incorrect                             = 94; // значение цены для позиции указано некорректно
    rc_item_sum_is_incorrect                               = 95; // значение суммы для позиции указано некорректно

const
    ResponseText: TArray<string> = [
{ 00 } 'ok',                                                  // операция выполнена успешно
{ 01 } 'unknown_result',                                      // неизвестная ошибка
{ 02 } 'invalid_fields',                                      // поля запроса заполнены некорректно
{ 03 } 'method_not_found',                                    // метод не существует
{ 04 } 'method_execution_exception',                          // неизвестная ошибка при выполнении метода
{ 05 } 'invalid_access_code',                                 // некорректный пин-код или токен
{ 06 } 'settings_save_error',                                 //
{ 07 } 'kkm_save_error',                                      //
{ 08 } 'kkm_reginfo_request_error',                           // ошибка запроса рег.данных кассы
{ 09 } 'invalid_kkm_vendor_id',                               // некорректный ЗНМ (серийный номер кассы)
{ 10 } 'kkm_delete_error',                                    // ошибка удаления кассы
{ 11 } 'access_code_incorrect',                               // задан некорректный пин-код
{ 12 } 'access_code_already_used',                            // пин-код / email уже используется
{ 13 } 'operator_save_error',                                 // ошибка сохранения оператора
{ 14 } 'operator_update_error',                               //
{ 15 } 'invalid_operator_code',                               // некорректный ID оператора
{ 16 } 'operator_delete_error',                               // ошибка удаления оператора
{ 17 } 'invalid_kkm_credentials',                             // некорректные рег.данные кассы
{ 18 } 'kkm_in_offline_mode_too_long',                        // касса слишком долго находится в автономном режиме
{ 19 } 'db_error',                                            // внутреннняя ошибка БД
{ 20 } 'connection_error',                                    // ошибка связи с сервером ОФД
{ 21 } 'protobuf_serialization_error',                        // ошибка сериализации данных
{ 22 } 'save_error',                                          //
{ 23 } 'send_error',                                          //
{ 24 } 'receive_error',                                       //
{ 25 } 'kkm_vendor_id_mismatch',                              //
{ 26 } 'kkm_shift_state_is_opened',                           //
{ 27 } 'kkm_status_is_ready_to_use',                          //
{ 28 } 'protobuf_deserialization_error',                      // ошибка десериализации данных
{ 29 } 'operation_failed',                                    // операция завершилась неудачей
{ 30 } 'forced_offline_mode',                                 //
{ 31 } 'shift_duration_is_too_long',                          //
{ 32 } 'invalid_shift_number',                                //
{ 33 } 'report_not_found',                                    //
{ 34 } 'invalid_report_type',                                 // некооректный тип отчёта
{ 35 } 'kkm_shift_state_is_not_opened',                       //
{ 36 } 'invalid_local_date',                                  // установлена некорректная дата
{ 37 } 'operation_not_found',                                 // операция не найдена
{ 38 } 'kkm_address_is_already_in_use',                       //
{ 39 } 'invalid_operator_role',                               //
{ 40 } 'kkm_ofd_id_is_already_in_use',                        //
{ 41 } 'kkm_vendor_id_is_already_in_use',                     //
{ 42 } 'invalid_kkm_token',                                   // некорректный токен кассы
{ 43 } 'transaction_not_found',                               // транзакция не найдена
{ 44 } 'items_list_undefined',                                //
{ 45 } 'items_list_is_empty',                                 // список товаров пуст
{ 46 } 'item_commodity_undefined',                            // товар не указан
{ 47 } 'item_quantity_is_incorrect',                          // значение количества указано некорректно
{ 48 } 'item_discount_undefined',                             // скидка на позицию не описана
{ 49 } 'item_markup_undefined',                               // наценка на позицию не описана
{ 50 } 'unknown_item_type',                                   // неизвестный тип элемента
{ 51 } 'amounts_undefined',                                   //
{ 52 } 'amounts_total_is_incorrect',                          // итоговая сумма некорректна
{ 53 } 'money_value_is_negative',                             // сумма наличных отрицательна
{ 54 } 'sum_to_pay_is_incorrect',                             // сумма к оплате некорректна
{ 55 } 'card_sum_is_greater_than_total',                      // сумма оплаты картой больше итоговой
{ 56 } 'paid_sum_is_incorrect',                               // оплаченная сумма некорректна
{ 57 } 'paid_sum_is_less_than_total',                         // оплаченная сумма меньше итоговой
{ 58 } 'not_enough_cash',                                     // недостаточно наличных в кассе
{ 59 } 'discount_sum_must_be_less_than_total',                // сумма скидки должна быть меньше итоговой суммы
{ 60 } 'taxation_type_is_incorrect',                          // некорректный вид налогообложения
{ 61 } 'invalid_kkm_ofd_id',                                  // некорректный ID кассы из ОФД
{ 62 } 'kkm_is_blocked',                                      // касса заблокирована
{ 63 } 'discount_sum_is_negative',                            // сумма скидки отрицательна
{ 64 } 'markup_sum_is_negative',                              // сумма наценки отрицательна
{ 65 } 'discount_and_markup_are_mutually_exclusive',          // скидка и наценка являются взаимоисключающими
{ 66 } 'operation_in_progress',                               //
{ 67 } 'kkm_has_offline_queue',                               // касса содержит автономную очередь
{ 68 } 'kkm_locked_due_to_values_conflict',                   //
{ 69 } 'kkm_is_busy_too_long',                                // Касса до сих пор выполняет предыдущую операцию
{ 70 } 'kkm_is_not_initialized',                              //
{ 71 } 'kkm_access_denied',                                   // у пользователя нет доступа к кассе
{ 72 } 'kkm_invalid_bindings',                                // у пользователя нет прав на использование кассы
{ 73 } 'source_object_deserialization_error',                 // ошибка десериализации объекта из запроса
{ 74 } 'kkm_per_owner_limit_exceed',                          // превышен лимит количества касс для пользователя
{ 75 } 'kkm_operators_limit_exceed',                          // превышен лимит количества пользователей на кассу
{ 76 } 'kkm_shift_is_not_closed',                             // касса с незакрытой сменой
{ 77 } 'same_taxpayer_and_customer',                          // ИИН (БИН) продавца и покупателя одинаковые
{ 78 } 'invalid_ofd_uid',                                     // некорректный идентификатор ОФД
{ 79 } 'license_period_expired',                              // срок действия лицензии истёк
{ 80 } 'license_activation_error',                            //
{ 81 } 'measure_unit_code_is_empty',                          // код единицы измерения не может быть пустым
{ 82 } 'section_code_is_empty',                               // код секции (номер отдела) не может быть пустым
{ 83 } 'invalid_kkm_ofd',                                     // задан некорректный ОФД для кассы
{ 84 } 'invalid_ofd_response',                                // ОФД вернул сообщение об ошибке
{ 85 } 'invalid_license_file',                                //
{ 86 } 'db_error_duplicates',                                 // найдено больше одной записи
{ 87 } 'invalid_activation_code',                             // некорректный код активации
{ 88 } 'items_taxes_and_ticket_taxes_are_mutually_exclusive', // НДС на позицию и на весь чек являются взаимоисключающими
{ 89 } 'tax_percentage_is_already_present',                   // Налог с определённым процентом может встречаться не более одного раза
{ 90 } 'invalid_license_key',                                 // некорректный лицензионный ключ
{ 91 } 'ofd_list_is_empty',                                   // лицензия не содержит ни одного ОФД
{ 92 } 'license_suspended',                                   // действие лицензии приостановлено
{ 93 } 'license_online_check_error',                          // ошибка онлайн-проверки лицензии
{ 94 } 'item_price_is_incorrect',                             // значение цены для позиции указано некорректно
{ 95 } 'item_sum_is_incorrect',                               // значение суммы для позиции указано некорректно
{ -- } ''];

type
    TResultRecord = record
        ResultCode: byte;
        ResultText: string;
        procedure Clear;
        function isPositive: boolean;
    end;

type
    TProxyRecord = record
        host: string;
        port: word;
        username: string;
        password: string;
        function isActual: boolean;
        constructor Create(const host: string; const port: word; const username, password: string);
    end;

implementation

uses
    System.SysUtils;


procedure TResultRecord.Clear;
begin
    self := Default (TResultRecord);
end;


function TResultRecord.isPositive: boolean;
begin
    Result := ResultCode in [rc_ok, rc_connection_error, rc_invalid_kkm_token];
end;


constructor TProxyRecord.Create(const host: string; const port: word; const username, password: string);
begin
    self.host := host;
    self.port := port;
    self.username := username;
    self.password := password;
end;


function TProxyRecord.isActual: boolean;
begin
    Result :=                             // если
         (not host.IsEmpty) and (port > 0)// задан адрес:порт
// and (not username.IsEmpty) and (not password.IsEmpty)// и логин/пароль
         ;
end;

end.
