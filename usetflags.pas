unit usetflags;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  usetupfile;

type

  { TFSetFlags }

  TFSetFlags = class(TForm)
    Button2: TButton;
    Button3: TButton;
    CheckGroup1: TCheckGroup;
    procedure CheckGroup1ItemClick(Sender: TObject; Index: integer);
    procedure FormCreate(Sender: TObject);
  private
    FFlags:TInnoFileFlags;
  public
    class function GetFlags(TheOwner:TComponent;var Flags:TInnoFileFlags):boolean;virtual;
    class function GetFlags(TheOwner:TComponent;var Flags:string;
      const Delimiter:char):boolean;overload;
  end;

var
  FSetFlags: TFSetFlags;

implementation

{$R *.lfm}

{ TFSetFlags }

procedure TFSetFlags.CheckGroup1ItemClick(Sender: TObject; Index: integer);
var
  iff:TInnoFileFlag;
begin
  iff:=StringToInnoFileFlag(CheckGroup1.Items[index]);

  if CheckGroup1.Checked[index] then FFlags:=FFlags+[iff]
  else FFlags:=FFlags-[iff];
end;

procedure TFSetFlags.FormCreate(Sender: TObject);
begin
  FFlags:=[];
end;

class function TFSetFlags.GetFlags(TheOwner: TComponent; var Flags: TInnoFileFlags
  ): boolean;
var
  i:byte;
begin
  Result:=False;

  if not Assigned(TheOwner) then Exit;

  FSetFlags:=TFSetFlags.Create(TheOwner);

  with FSetFlags do
  begin
    for i:=0 to byte(CheckGroup1.Items.Count-1) do
    begin
      CheckGroup1.Checked[i]:=(StringToInnoFileFlag(CheckGroup1.Items[i]) in FFlags);
    end;

    Result:=FSetFlags.ShowModal=mrOK;

    if Result then Flags:=FFlags;
  end;
end;

class function TFSetFlags.GetFlags(TheOwner: TComponent; var Flags: string;
  const Delimiter:char): boolean;
var
  ffs:TInnoFileFlags;
begin
  ffs:=StringToInnoFileFlags(Flags,Delimiter);
  Result:=GetFlags(TheOwner,ffs);

  if Result then Flags:=InnoFileFlagsToString(ffs,Delimiter);
end;

end.

