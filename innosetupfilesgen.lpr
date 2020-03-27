program innosetupfilesgen;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, umainform, upickflags, usetupfile, usetflags
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFMainForm, FMainForm);
  Application.CreateForm(TFPickFlags, FPickFlags);
  Application.CreateForm(TFSetFlags, FSetFlags);
  Application.Run;
end.

