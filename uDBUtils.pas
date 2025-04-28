unit uDBUtils;

{$I defines.inc}

interface

uses
    System.SysUtils,
{$REGION 'DB units'}
{$IFNDEF ANDROID}
    FireDAC.Phys.PG,
    FireDAC.Phys.PGDef,
    FireDAC.Phys.MySQL,
    FireDAC.Phys.MySQLDef,
{$ENDIF ANDROID}
    FireDAC.Phys.SQLite,
    FireDAC.Phys.SQLiteDef,
    FireDAC.Phys.SQLiteWrapper.Stat, // needs to build in Delphi 10.4.2 and higher!
    FireDAC.Phys.Intf,
    FireDAC.Comp.Client,
    FireDAC.Stan.Def,
    FireDAC.DApt,
    FireDAC.Stan.Async,
    FireDAC.Stan.Option,
    FireDAC.Stan.Intf,
    FireDAC.Stan.Pool,
{$ENDREGION}
    uTypes,
    uLogger,
    XSuperObject;

type
    TDBDriverID = (diSQLite, diPostgreSQL, diMySQL, diUnknown);

const
    DefaultAttemptsLeft  = 3;
    DefaultAttemptsDelay = 100;

type
    TFDQueryHelper = class helper for TFDQuery
        procedure SafeDestroy; overload;
        procedure SafeDestroy(var FDConnection: TFDConnection); overload;
    end;

type
    TFDConnectionHelper = class helper for TFDConnection
        function JSON_Object_Save(const obj: iSuperObject; const objClassName: string): boolean;
        function JSON_Object_Update(const obj: iSuperObject; const objClassName: string): boolean;
    end;

const
    DBVersion = 1;

    TDBDriverName: TArray<string>  = ['SQLite', 'PostgreSQL', 'MySQL', 'unknown'];
    TQuoteObjectChar: TArray<char> = ['"', '"', '`'];
    TQuoteValueChar: TArray<char>  = ['"', '"', '''', '"'];

procedure PrepareDBConnection_SQLite(const DBName: string; const ConnectionName: string; const PasswordPrefix: string = '');
procedure PrepareDBConnection_PG(const DBName: string; const ConnectionName: string; const DBHost: string; const DBPort: word; const username: string = ''; const password: string = '');
procedure PrepareDBConnection_MySQL(const DBName: string; const ConnectionName: string; const DBHost: string; const DBPort: word; const username: string = ''; const password: string = '');

function CreateTableForClass(var FDConnection: TFDConnection; ClassName: string; DoCloseConnection: boolean = false): boolean;

function DBObjectDelete(var FDConnection: TFDConnection; const objID: Cardinal; const objClassName: string; const DoCloseConnection: boolean = false): boolean; overload;

function DBObjectListLoad(var FDConnection: TFDConnection; ClassName: string; DoCloseConnection: boolean = false): ISuperArray; overload;
function DBObjectListLoad(var FDConnection: TFDConnection; ClassName: string; var list: ISuperArray; DoCloseConnection: boolean = false): boolean; overload;

procedure GetDBConnection(const ConnectionName: string; var FDConnection: TFDConnection); overload;
function GetDBConnection(const ConnectionName: string): TFDConnection; overload;
procedure FreeDBConnection(var FDConnection: TFDConnection);

function GetDBDriverID(const Value: string): TDBDriverID; overload;
function GetDBDriverID(var FDConnection: TFDConnection): TDBDriverID; overload;
function PrepareSQL(const SRC: string): string;

function DB_ExecSQL(FDQuery: TFDQuery; const SQL: string): integer; overload;
procedure DB_ExecSQL(FDQuery: TFDQuery); overload;

procedure DB_Open(FDQuery: TFDQuery; const SQL: string); overload;
procedure DB_Open(FDQuery: TFDQuery; const SQL: string; const aParams: array of Variant); overload;
procedure DB_Open(FDQuery: TFDQuery); overload;

Procedure SetLogProc(AValue: TLogProc);

var
    DefaultDBDriver: TDBDriverID = diMySQL;

implementation

uses
    uUtils,
    System.Generics.Collections,
    System.Generics.Defaults,
    System.DateUtils,
    System.Variants,
    System.Classes,
    System.IOUtils;

var
    FWriteLog: TLogProc;


Procedure SetLogProc(AValue: TLogProc);
begin
    FWriteLog := AValue;
end;


procedure WriteLog(const Data: string; const Params: array of const; const LogType: TLogType = ltInfo);
begin
    if Assigned(FWriteLog) then
        FWriteLog(Data, Params, LogType);
end;


function PrepareSQL(const SRC: string): string;
begin
    Result := SRC.Replace('`', TQuoteObjectChar[Byte(DefaultDBDriver)]);
end;


function DB_ExecSQL(FDQuery: TFDQuery; const SQL: string): integer;
begin
    Result := FDQuery.ExecSQL(PrepareSQL(SQL));
end;


procedure DB_ExecSQL(FDQuery: TFDQuery);
begin
    if not Assigned(FDQuery) then
        exit;
    if not Assigned(FDQuery.SQL) then
        exit;
    FDQuery.SQL.Text := PrepareSQL(FDQuery.SQL.Text);
    FDQuery.ExecSQL;
end;


procedure DB_Open(FDQuery: TFDQuery; const SQL: string);
begin
    if Assigned(FDQuery) AND (not SQL.IsEmpty) then
        FDQuery.Open(PrepareSQL(SQL));
end;


procedure DB_Open(FDQuery: TFDQuery; const SQL: string; const aParams: array of Variant);
begin
    if Assigned(FDQuery) AND (not SQL.IsEmpty) then
        FDQuery.Open(PrepareSQL(SQL), aParams);
end;


procedure DB_Open(FDQuery: TFDQuery);
begin
    FDQuery.SQL.Text := PrepareSQL(FDQuery.SQL.Text);
    FDQuery.Open;
end;


procedure FreeDBConnection(var FDConnection: TFDConnection);
begin
    try
        if Assigned(FDConnection) then
        begin
            FDConnection.Close;
            FDConnection.Destroy;
            FDConnection := NIL;
        end;
    except
    end;
end;


function GetDBDriverID(const Value: string): TDBDriverID; overload;
begin
    Result := diUnknown;
    if SameText(Value, 'SQLite') then
        Result := diSQLite;
    if SameText(Value, 'PG') then
        Result := diPostgreSQL;
    if SameText(Value, 'MySQL') then
        Result := diMySQL;
    if Result = diUnknown then
        raise Exception.CreateHelp('Unknown DBDriverID', rc_db_error);
end;


function GetDBDriverID(var FDConnection: TFDConnection): TDBDriverID; overload;
begin
    Result := GetDBDriverID(FDConnection.ActualDriverID);
end;


procedure PrepareDBConnection_SQLite(const DBName: string; const ConnectionName: string; const PasswordPrefix: string = '');
var
    oParams: TFDPhysSQLiteConnectionDefParams;
    password: string;
    fdc: TFDConnection;
begin

    FDManager.SilentMode := true;
    var
    oDef := FDManager.ConnectionDefs.AddConnectionDef;
    oDef.Name := ConnectionName;

    oParams := TFDPhysSQLiteConnectionDefParams(oDef.Params);
    oParams.DriverID := 'SQLITE';
    oParams.Database := DBName;
    oParams.BusyTimeout := 5000;
    oParams.CacheSize := 20000;
    oParams.SharedCache := false;
    oParams.LockingMode := TFDSQLiteLockingMode.lmNormal;
    oParams.Synchronous := TFDSQLiteSynchronous.snFull;
    oParams.JournalMode := TFDSQLiteJournalMode.jmWAL;
    password := TPath.GetFileName(DBName).Substring(5);
    password := password.Substring(0, Length(password) - 3);
    password := PasswordPrefix + password;
    password := md5(password);

    oParams.Encrypt := TFDSQLiteEncrypt.enAes_256;
    oParams.password := { 'aes-256:' + } password;

// oParams.Pooled := true;

    oDef.Apply;
end;


procedure PrepareDBConnection_PG(const DBName: string; const ConnectionName: string; const DBHost: string; const DBPort: word; const username: string = ''; const password: string = '');
begin
{$IFNDEF ANDROID}
    FDManager.SilentMode := true;
    var
    oDef := FDManager.ConnectionDefs.AddConnectionDef;
    oDef.Name := ConnectionName;

    var
    oParams := TFDPhysPGConnectionDefParams(oDef.Params);
    oParams.DriverID := 'PG';
    oParams.Database := DBName;
    oParams.username := username;
    oParams.password := password;
    oParams.Server := DBHost;
    oParams.Port := DBPort;
    oParams.Pooled := true;
    oParams.PoolMaximumItems := 5000;

    oDef.Apply;
{$ENDIF ANDROID}
end;


procedure PrepareDBConnection_MySQL(const DBName: string; const ConnectionName: string; const DBHost: string; const DBPort: word; const username: string = ''; const password: string = '');
begin
{$IFNDEF ANDROID}
    FDManager.SilentMode := true;

    var
    oDef := FDManager.ConnectionDefs.AddConnectionDef;
    oDef.Name := ConnectionName;

    var
    oParams := TFDPhysMySQLConnectionDefParams(oDef.Params);
    oParams.DriverID := 'MySQL';
    oParams.Database := DBName;
    oParams.username := username;
    oParams.password := password;
    oParams.Server := DBHost;
    oParams.Port := DBPort;
    oParams.Pooled := true;
    oParams.PoolMaximumItems := 5000;

    oDef.Apply;
{$ENDIF ANDROID}
end;


procedure GetDBConnection(const ConnectionName: string; var FDConnection: TFDConnection); overload;
begin
    FDConnection := TFDConnection.Create(nil);
    FDConnection.ConnectionDefName := ConnectionName;
end;


function GetDBConnection(const ConnectionName: string): TFDConnection; overload;
begin
    GetDBConnection(ConnectionName, Result);
end;


function CreateTableForClass;
begin
    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;
    try
        case GetDBDriverID(FDConnection) of
            diSQLite:
                Result := FDQuery.ExecSQL(Format('CREATE TABLE IF NOT EXISTS "%s" ("ID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "Object" TEXT)', [ClassName])) <> -1;
            diPostgreSQL:
                Result := FDQuery.ExecSQL(Format('CREATE TABLE IF NOT EXISTS "%s" ("ID" BIGSERIAL PRIMARY KEY NOT NULL, "Object" JSON)', [ClassName])) <> -1;
            diMySQL:
                Result := FDQuery.ExecSQL(Format('CREATE TABLE IF NOT EXISTS `%s` (`ID` INT NOT NULL AUTO_INCREMENT, `Object` JSON, PRIMARY KEY (`ID`))', [ClassName])) <> -1;
        end;
    except
        on E: Exception do
        begin
            Result := false;
            WriteLog('CreateTableForClass exception [%s]: %s', [E.ClassName, E.Message], ltError);
        end;
    end;
    if DoCloseConnection then
        FreeDBConnection(FDConnection);
    FDQuery.SafeDestroy;
end;


function DBObjectDelete(var FDConnection: TFDConnection; const objID: Cardinal; const objClassName: string; const DoCloseConnection: boolean = false): boolean; overload;
begin
    if not Assigned(FDConnection) then
        exit;

    if objID <= 0 then
        exit;

    if objClassName.IsEmpty then
        exit;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;
    FDQuery.SQL.Text := Format('DELETE FROM `%s` WHERE `ID` = %d;', [objClassName, objID]);

    var
    attemptsLeft := DefaultAttemptsLeft; // делаем несколько попыток - это нужно для обхода временных ошибок вроде "Database is locked"
    while attemptsLeft > 0 do
        try
            DB_ExecSQL(FDQuery);
            Result := true;
            attemptsLeft := 0;
        except
            on E: Exception do
            begin
                WriteLog('DBObjectDelete exception [%s]: %s', [E.ClassName, E.Message], ltError);
                dec(attemptsLeft);
                sleep(DefaultAttemptsDelay);
            end;
        end;

    if DoCloseConnection then
        FreeDBConnection(FDConnection);
    FDQuery.SafeDestroy;
end;


function DBObjectListLoad(var FDConnection: TFDConnection; ClassName: string; DoCloseConnection: boolean = false): ISuperArray; overload;
begin
    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := FDConnection;

    try
        try
            DB_Open(FDQuery, Format('SELECT * FROM `%s`;', [ClassName]));
        except
            on E: Exception do
            begin
                WriteLog('DBObjectListLoad exception [%s]: %s', [E.ClassName, E.Message], ltError);
                raise Exc(rc_db_error);
            end;
        end;

        Result := SA;

        FDQuery.First;
        while not FDQuery.Eof do
        begin
            try
                var
                X := SO(FDQuery.FieldByName('Object').AsString);
                X.I['ID'] := FDQuery.FieldByName('ID').AsInteger;
                Result.Add(X);
            except
                on E: Exception do
                begin
                    WriteLog('DBObjectListLoad exception [%s]: %s', [E.ClassName, E.Message], ltError);
                    raise Exc(rc_source_object_deserialization_error);
                end;
            end;
            FDQuery.Next;
        end;

    except
        on E: Exception do
        begin
            WriteLog('DBObjectListLoad exception [%s]: %s', [E.ClassName, E.Message], ltError);
            if DoCloseConnection then
                FreeDBConnection(FDConnection);
            FDQuery.SafeDestroy;
            raise;
        end;
    end;

    if DoCloseConnection then
        FreeDBConnection(FDConnection);
    FDQuery.SafeDestroy;
end; //


function DBObjectListLoad(var FDConnection: TFDConnection; ClassName: string; var list: ISuperArray; DoCloseConnection: boolean = false): boolean;
begin
    list.Clear;
    try
        for var item in DBObjectListLoad(FDConnection, ClassName, DoCloseConnection) do
            list.Add(item.AsObject);
        Result := true;
    except
        Result := false;
    end;
end; //

{ TFDQueryHelper }


procedure TFDQueryHelper.SafeDestroy;
begin
    if Assigned(Self) then
        try
            Self.Connection := nil;
            Self.Destroy;
            Self := nil;
        except
        end;
end;


procedure TFDQueryHelper.SafeDestroy(var FDConnection: TFDConnection);
begin
    SafeDestroy;
    FreeDBConnection(FDConnection);
end;

{ TFDConnectionHelper }


function TFDConnectionHelper.JSON_Object_Save;
var
    last_id_selector: string;
begin
    Result := false;

    if not Assigned(Self) then
        exit;

    if obj.Contains('ID') then
    begin
        if obj.I['ID'] > 0 then
        begin
            Result := JSON_Object_Update(obj, objClassName);
            exit;
        end
        else
            obj.Remove('ID');
    end;

    case GetDBDriverID(Self) of
        diSQLite:
            last_id_selector := 'last_insert_rowid';
        diPostgreSQL:
            last_id_selector := 'LASTVAL';
        diMySQL:
            last_id_selector := 'LAST_INSERT_ID';
    end;

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := Self;

// DoSync(procedure begin
    FDQuery.SQL.Text := Format('INSERT INTO `%s` (`Object`) VALUES (:p0);', [objClassName]);
    FDQuery.Params[0].AsString := obj.AsJSON();
// end);

    var
    attemptsLeft := DefaultAttemptsLeft; // делаем несколько попыток - это нужно для обхода временных ошибок вроде "Database is locked"
    while attemptsLeft > 0 do
        try
            DB_ExecSQL(FDQuery);
            DB_Open(FDQuery, Format('SELECT %s() as inserted_id;', [last_id_selector]));
            obj.I['ID'] := FDQuery.FieldByName('inserted_id').AsLargeInt; // int64(FDConnection.GetLastAutoGenValue(''));
            Result := true;
            attemptsLeft := 0;
        except
            on E: Exception do
            begin
                WriteLog('TFDConnectionHelper.JSON_Object_Save exception [%s]: %s', [E.ClassName, E.Message], ltError);
                dec(attemptsLeft);
                sleep(DefaultAttemptsDelay);
            end;
        end;

    FDQuery.Connection := nil;
    FDQuery.Destroy;
end;


function TFDConnectionHelper.JSON_Object_Update;
var
    objID: Cardinal;
begin
    Result := false;

    if not Assigned(Self) then
        exit;

    if not obj.Contains('ID') then
        exit;

    objID := obj.I['ID'];

    var
    FDQuery := TFDQuery.Create(nil);
    FDQuery.Connection := Self;
    FDQuery.SQL.Text := Format('UPDATE `%s` SET `Object` = :p0 WHERE `ID` = :p1 ;', [objClassName]);
    FDQuery.Params[1].AsInteger := objID;

    if obj.Contains('ID') then
        obj.Remove('ID');

    var
    attemptsLeft := DefaultAttemptsLeft; // делаем несколько попыток - это нужно для обхода временных ошибок вроде "Database is locked"
    while attemptsLeft > 0 do
        try
            FDQuery.Params[0].AsString := obj.AsJSON();
            DB_ExecSQL(FDQuery);
            Result := true;
            attemptsLeft := 0;
        except
            on E: Exception do
            begin
                WriteLog('TFDConnectionHelper.JSON_Object_Update exception [%s]: %s', [E.ClassName, E.Message], ltError);
                dec(attemptsLeft);
                sleep(DefaultAttemptsDelay);
            end;
        end;

    FDQuery.Connection := nil;
    FDQuery.Destroy;
end;

initialization

(*
var
path := '/lib64/mysql/';
WriteLog(path, [], TLogType.ltGeneral);
for var s in TDirectory.GetFiles(path) do DO NOT USE "TDirectory.GetFiles" IN LINUX!
    WriteLog(s, [], TLogType.ltGeneral);

path := '/usr/lib64/mysql/';
WriteLog(path, [], TLogType.ltGeneral);
for var s in TDirectory.GetFiles(path) do DO NOT USE "TDirectory.GetFiles" IN LINUX!
    WriteLog(s, [], TLogType.ltGeneral);

FDPhysMySQLDriverLink := TFDPhysMySQLDriverLink.Create(nil);
// WriteLog('FDPhysMySQLDriverLink.VendorLib: %s', [FDPhysMySQLDriverLink.VendorLib], TLogType.ltGeneral);
// WriteLog('FDPhysMySQLDriverLink.VendorHome: %s', [FDPhysMySQLDriverLink.VendorHome], TLogType.ltGeneral);
FDPhysMySQLDriverLink.VendorLib := '/lib64/mysql/libmysqlclient.so.21.2.33';
*)

FDManager.ConnectionDefFileAutoLoad := false;

// FDManager.Close;
// while FDManager.State <> dmsInactive do
// Sleep(0);
// FDManager.Open;
// FDManager.ConnectionDefs.ConnectionDefByName(DBConnectionName).Params.Pooled := true;

// FDManager.Close;
// while FDManager.State <> TFDPhysManagerState.dmsInactive do
// Sleep(0);

// FDManager.Open;
// FDManager.ConnectionDefs.Clear;
// with FDManager.ConnectionDefs.AddConnectionDef do
// begin
// Params.ConnectionDef := DBConnectionName;
// Params.Pooled := true;
// end;
// FDManager.ConnectionDefs.ConnectionDefByName(DBConnectionName).Params.pooled := true;

end.
