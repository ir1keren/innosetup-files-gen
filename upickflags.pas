unit upickflags;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  EditBtn, StdCtrls, Buttons, umainform;

type

  { TFPickFlags }

  TFPickFlags = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    CheckGroup1: TCheckGroup;
    CheckGroup2: TCheckGroup;
    ComboBox1: TComboBox;
    DirectoryEdit1: TDirectoryEdit;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    ListBox1: TListBox;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;

    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure DirectoryEdit1AcceptDirectory(Sender: TObject; var Value: String);
    procedure Edit1KeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBox1SelectionChange(Sender: TObject; User: boolean);
  private
    FisNew:boolean;
    FTargetEdit:TEdit;
    procedure OpenPickFiles(DialogTitle:string;TargetEdit:TEdit;InitialDir:string;
      Callback:TNotifyEvent);
    procedure OnExcludedFilesPicker(Sender:TObject);
    procedure OnSourceFilesPicked(Sender:TObject);
  public
    class procedure PickFlags(TheOwner:TFMainForm;IsCreateNew:boolean=False);
  end;

var
  FPickFlags: TFPickFlags;

implementation
uses usetupfile,RegExpr;
{$R *.lfm}

var
  AOwner:TFMainForm;

{ TFPickFlags }

procedure TFPickFlags.FormShow(Sender: TObject);
var
  tif:TInnoSetupFile;
  i:Cardinal;
  m:TFileAttrib;
  n:TInnoFileFlag;
  re:TRegExpr;
  s:string;
begin
  PageControl1.PageIndex:=0;

  if (not FisNew)and(Assigned(AOwner.ListView1.Selected)) then begin
    tif:=TInnoSetupFile(AOwner.ListView1.Selected.Data);
    ComboBox1.Text:=tif.Destination;

    if tif.IsFile then begin
      ListBox1.Clear;
    end else begin
      re:=TRegExpr.Create('\\([^\\]+)$');
      s:=tif.Source;

      if re.Exec(s) then begin
        DirectoryEdit1.Directory:=Copy(s,1,re.MatchPos[1]-1);
      end else
      begin
        DirectoryEdit1.Directory:=s;

        if s[Length(s)]<>'\' then s:=s+'\';
      end;

      if tif.ExcludedFiles.Count>0 then ListBox1.Items.AddStrings(tif.ExcludedFiles);
    end;

    Edit2.Enabled:=not tif.IsFile;
    BitBtn2.Enabled:=Edit2.Enabled;
    ListBox1.Enabled:=not tif.IsFile;

    for i:=0 to CheckGroup1.Items.Count-1 do begin
        n:=StringToInnoFileFlag(CheckGroup1.Items[i]);
        CheckGroup1.Checked[i]:=n in tif.Flags;
    end;

    for i:=0 to CheckGroup2.Items.Count-1 do begin
        m:=StringToFileAttrib(CheckGroup2.Items[i]);
        CheckGroup2.Checked[i]:=m in tif.Attribs;
    end;
  end;
end;

procedure TFPickFlags.FormCreate(Sender: TObject);
begin
  ListBox1.Items.Delimiter:=',';
end;

procedure TFPickFlags.BitBtn1Click(Sender: TObject);
begin
  OpenPickFiles('Pick files as source',Edit1,DirectoryEdit1.Directory,@OnSourceFilesPicked);
end;

procedure TFPickFlags.BitBtn2Click(Sender: TObject);
begin
  OpenPickFiles('Pick files to excluded list',Edit2,DirectoryEdit1.Directory,@OnExcludedFilesPicker);
end;

procedure TFPickFlags.Button1Click(Sender: TObject);
begin
  if ListBox1.SelCount<1 then Exit;

  ListBox1.Items.BeginUpdate;
  ListBox1.DeleteSelected;
  ListBox1.Items.EndUpdate;
  Button1.Enabled:=ListBox1.SelCount>0;
end;

procedure TFPickFlags.DirectoryEdit1AcceptDirectory(Sender: TObject;
  var Value: String);
begin
  if DirectoryExists(Value) then
  begin
    Edit1.Clear;
    Edit2.Enabled:=True;
    BitBtn2.Enabled:=True;
    ListBox1.Enabled:=True;
  end;
end;

procedure TFPickFlags.Edit1KeyPress(Sender: TObject; var Key: char);
begin
  if Key=#13 then
  begin
    if Sender=Edit1 then OnSourceFilesPicked(Sender)
    else if Sender=Edit2 then OnExcludedFilesPicker(Sender);
  end;
end;

procedure TFPickFlags.ListBox1SelectionChange(Sender: TObject; User: boolean);
begin
  Button1.Enabled:=ListBox1.SelCount>0;
end;

procedure TFPickFlags.OpenPickFiles(DialogTitle: string; TargetEdit: TEdit;
  InitialDir: string; Callback: TNotifyEvent);
var
  files:TStringList;
begin
  FTargetEdit:=TargetEdit;
  OpenDialog1.Files.Clear;

  if FTargetEdit.Text<>'' then
  begin
    files:=GetFilesFromString(FTargetEdit.Text,',');

    if files.Count>0 then
    begin
      if FileExists(files[0]) then begin
         InitialDir:=ExtractFileDir(files[0]);

        if files.Count>1 then OpenDialog1.Files.AddStrings(files)
        else OpenDialog1.FileName:=files[0];
      end;
    end;
  end;

  OpenDialog1.Title:=DialogTitle;
  OpenDialog1.InitialDir:=InitialDir;

  if OpenDialog1.Execute then
  begin
    if OpenDialog1.Files.Count>1 then
    begin
      OpenDialog1.Files.Delimiter:=',';
      FTargetEdit.Text:=OpenDialog1.Files.DelimitedText;
    end else FTargetEdit.Text:=OpenDialog1.FileName;

    if Assigned(Callback) then Callback(FTargetEdit);
  end;
end;

procedure TFPickFlags.OnExcludedFilesPicker(Sender: TObject);
var
  files:TStringList;
  sf,s:string;
begin
  files:=GetFilesFromString(Edit2.Text,',');

  for sf in files do
  begin
      if not FileExists(sf) then Continue;

      s:=ExtractFileName(sf);

      if ListBox1.Items.IndexOf(s)>=0 then Continue;

      ListBox1.Items.Add(s);
  end;
end;

procedure TFPickFlags.OnSourceFilesPicked(Sender: TObject);
var
  files:TStringList;
  bValid:boolean;
  s:string;
begin
  if Edit1.Text='' then Exit;

  files:=GetFilesFromString(Edit1.Text,',');
  bValid:=True;

  for s in files do
      bValid:=(bValid)and(FileExists(s));

  if bValid then begin
    DirectoryEdit1.Directory:='';
    Edit2.Enabled:=False;
    BitBtn2.Enabled:=False;
    ListBox1.Enabled:=False;
  end;
end;

class procedure TFPickFlags.PickFlags(TheOwner: TFMainForm; IsCreateNew: boolean=False);
var
  isSetup:TInnoSetupFile;
  s,sDir:string;
  sources,excludes:TStringList;
  flags:TInnoFileFlags;
  attrs:TFileAttribs;
  i:Cardinal;
  liItem:TListItem;
begin
  if (not IsCreateNew)and(not Assigned(TheOwner.ListView1.Selected)) then Exit;

  AOwner:=TheOwner;
  FPickFlags:=TFPickFlags.Create(TheOwner);
  FPickFlags.FisNew:=IsCreateNew;
  sources:=nil;excludes:=nil;isSetup:=nil;liItem:=nil;

  if FPickFlags.ShowModal=mrOK then begin
    if FPickFlags.DirectoryEdit1.Directory<>'' then begin
      if DirectoryExists(FPickFlags.DirectoryEdit1.Directory) then begin
        sDir:=FPickFlags.DirectoryEdit1.Directory;

        if sDir[Length(sDir)]<>'\' then sDir:=sDir+'\';

        if (FPickFlags.ListBox1.Count>0)and(FPickFlags.ListBox1.Enabled) then begin
          excludes:=TStringList.Create;

          for s in FPickFlags.ListBox1.Items do
            if FileExists(sDir+s) then excludes.Add(s);
        end;
      end;
    end else if FPickFlags.Edit1.Text<>'' then begin
      sources:=GetFilesFromString(FPickFlags.Edit1.Text,',');
    end;

    flags:=[];

    for i:=0 to FPickFlags.CheckGroup1.Items.Count-1 do
      if FPickFlags.CheckGroup1.Checked[i] then
        flags:=flags+[StringToInnoFileFlag(FPickFlags.CheckGroup1.Items[i])];

    attrs:=[];

    for i:=0 to FPickFlags.CheckGroup2.Items.Count-1 do
      if FPickFlags.CheckGroup2.Checked[i] then
        attrs:=attrs+[StringToFileAttrib(FPickFlags.CheckGroup2.Items[i])];

    if Assigned(sources) then begin
      if sources.Count>0 then begin
        i:=TheOwner.ListView1.Items.Count;

        if (not IsCreateNew)and(Assigned(TheOwner.ListView1.Selected)) then begin
          i:=TheOwner.ListView1.Selected.Index;
          isSetup:=TInnoSetupFile(TheOwner.ListView1.Selected.Data);
          FreeAndNil(isSetup);
          TheOwner.ListView1.Items.Delete(i);
        end;

        for s in sources do
        begin
            if not FileExists(s) then continue;

            isSetup:=TInnoSetupFile.Create(s,FPickFlags.ComboBox1.Text);
            isSetup.Flags:=flags;
            isSetup.Attribs:=attrs;
            liItem:=isSetup.ToListItem(TheOwner.ListView1.Items);

            if liItem.Index<>i then TheOwner.ListView1.Items.Move(liItem.Index,i);

            Inc(i);
        end;
      end;
    end else begin
        s:=FPickFlags.DirectoryEdit1.Directory;

        if (s<>'')and(DirectoryExists(s)) then begin
          if s[Length(s)]<>'\' then s:=s+'\';

          s:=s+'*.*';

          if (not IsCreateNew)and(Assigned(TheOwner.ListView1.Selected)) then
          begin
            liItem:=TheOwner.ListView1.Selected;
            isSetup:=TInnoSetupFile(liItem.Data);
          end else
          begin
            isSetup:=TInnoSetupFile.Create(s,FPickFlags.ComboBox1.Text);
            liItem:=nil;
          end;

          if isSetup.Source<>s then isSetup.Source:=s;
          if isSetup.Destination<>FPickFlags.ComboBox1.Text then isSetup.Destination:=FPickFlags.ComboBox1.Text;

          if Assigned(excludes) then
          begin
            if excludes.Count>0 then begin
              isSetup.ExcludedFiles.Clear;
              isSetup.ExcludedFiles.AddStrings(excludes);
            end;
          end;

          isSetup.Flags:=flags;
          isSetup.Attribs:=attrs;

          if Assigned(liItem) then isSetup.SetListItemText(liItem)
          else isSetup.ToListItem(TheOwner.ListView1.Items);
        end;
    end;
  end;

  if Assigned(sources) then FreeAndNil(sources);
  if Assigned(excludes) then FreeAndNil(excludes);

  s:='';
  FreeAndNil(FPickFlags);
end;

end.

