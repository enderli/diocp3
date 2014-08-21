(*
  每个客户端一个实例, 在线程中运行
  
*)
unit udmMain;


interface

uses
  SysUtils, Classes, DB, ADODB, Provider, IniFiles;

type
  TdmMain = class(TDataModule)
    conMain: TADOConnection;
    dspMain: TDataSetProvider;
    qryMain: TADOQuery;
    procedure DataModuleCreate(Sender: TObject);
  public
    /// <summary>
    /// 客户端调用
    //     执行入口函数
    //  对vData所做的修改将会返回到客户端
    /// </summary>
    function Execute(pvCmdIndex: Integer; var vData: OleVariant): Boolean;
  end;

var
  dmMain: TdmMain;

implementation

{$R *.dfm}

procedure TdmMain.DataModuleCreate(Sender: TObject);
var
  lvINI:TIniFile;
  lvStr:String;
  lvFile:String;
begin
  lvFile := ChangeFileExt(ParamStr(0), '.db.ini');
  lvINI := TIniFile.Create(lvFile);
  try
    lvStr := lvINI.ReadString('main', 'connectionString', '');
    if lvStr <> '' then
    begin
      dmMain.conMain.ConnectionString := lvStr;
    end else
    begin
      lvINI.WriteString('main', 'connectionString', dmMain.conMain.ConnectionString);
    end;                                       
  finally
    lvINI.Free;
  end;
end;

function TdmMain.Execute(pvCmdIndex: Integer; var vData: OleVariant): Boolean;
begin
  case pvCmdIndex of
    0:
      begin
        // 返回服务端时间给客户端
        vData := Now();
      end;
    1:  // 查询数据
      begin
        // vData 认为是传入的SQL语句
        //   执行后, vData为查询的数据，可以用于对ClientData.Data的赋值
        qryMain.Close;
        qryMain.SQL.Add(vData);
        qryMain.Open;

        Result := dspMain.Data;
      end;
    2:
      begin
        // vData 为执行的语句
        conMain.BeginTrans;
        try
          qryMain.Close;
          qryMain.SQL.Clear;
          qryMain.SQL.Add(vData);
          qryMain.ExecSQL;
          conMain.CommitTrans;
        except
          conMain.RollbackTrans;
          raise;
        end;
      end;
  end; 
end;

end.
