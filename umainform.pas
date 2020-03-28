unit umainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, EditBtn, StdCtrls,
  ExtCtrls, ComCtrls, Buttons;

type

  { TFMainForm }

  TFMainForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    ComboBox1: TComboBox;
    DirectoryEdit1: TDirectoryEdit;
    Label1: TLabel;
    Label2: TLabel;
    ListView1: TListView;
    SaveDialog1: TSaveDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure ListView1ItemChecked(Sender: TObject; Item: TListItem);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private

  public

  end;

  TDirInfo=record
    FullPath:string;
    FilesCount:Cardinal;
  end;
  TDirInfos=array of TDirInfo;

var
  FMainForm: TFMainForm;

implementation
uses usetupfile,upickflags,RegExpr,usetflags;

var
  FFlags:TInnoFileFlags;
  DirInfos:TDirInfos;
{$R *.lfm}

{ TFMainForm }

procedure TFMainForm.Button1Click(Sender: TObject);
var
  sfItem:TInnoSetupFile;
  sDir:string;
  di:TDirInfo;
  n:Cardinal;

  procedure ScanDir(sDir:string);
  var
    n:Cardinal;
    srInfo:TSearchRec;
  begin
    if sDir[Length(sDir)]<>'\' then sDir:=sDir+'\';

    n:=Length(DirInfos);
    SetLength(DirInfos,n+1);
    FillChar(DirInfos[n],SizeOf(DirInfos[n]),0);
    DirInfos[n].FullPath:=sDir;

    if FindFirst(sDir+'*.*',faAnyFile and faDirectory,srInfo)=0 then begin
      repeat
        if (srInfo.Name<>'.')and(srInfo.Name<>'..') then begin
           if DirectoryExists(sDir+srInfo.Name) then ScanDir(sDir+srInfo.Name)
           else Inc(DirInfos[n].FilesCount);
        end;
      until FindNext(srInfo)<>0;
    end;
  end;

begin
  if (Trim(DirectoryEdit1.Directory)='')or(Trim(ComboBox1.Text)='') then Exit;

  while ListView1.Items.Count>0 do
  begin
    sfItem:=TInnoSetupFile(ListView1.Items[0].Data);
    sfItem.Destroy;
    ListView1.Items.Delete(0);
  end;

  sDir:=Trim(DirectoryEdit1.Directory);
  n:=Length(sDir);

  if sDir[n]<>'\' then begin
    sDir:=sDir+'\';
    Inc(n);
  end;

  ScanDir(sDir);

  if Length(DirInfos)<1 then Exit;

  ListView1.Items.BeginUpdate;

  for di in DirInfos do begin
    if di.FilesCount<1 then continue;

    sfItem:=TInnoSetupFile.Create(di.FullPath+'*.*',ComboBox1.Text+Copy(di.FullPath,n));
    sfItem.Flags:=FFlags;
    sfItem.ToListItem(ListView1.Items);
  end;

  ListView1.Items.EndUpdate;
  SetLength(DirInfos,0);
end;

procedure TFMainForm.Button2Click(Sender: TObject);
begin
  TFPickFlags.PickFlags(Self,True);
end;

procedure TFMainForm.Button3Click(Sender: TObject);
var
  tmp:TInnoFileFlag;
  i:Cardinal;
begin
  ListView1.BeginUpdate;

  repeat
    for i:=0 to ListView1.Items.Count-1 do
        if ListView1.Items[i].Selected then begin
           tmp:=TInnoFileFlag(ListView1.Items[i].Data);
           FreeAndNil(tmp);
           ListView1.Items.Delete(i);
           Break;
        end;
  until ListView1.SelCount=0;

  ListView1.EndUpdate;
end;

procedure TFMainForm.Button4Click(Sender: TObject);
var
  sf:string;
  bExist,bSourceFound:boolean;
  sfContents:TStringList;
  i:Cardinal;
  sLine:string;
  re1,re2:TRegExpr;
  iStartFiles,iEndFiles,iLastLine,iLen,iShift:integer;
begin
  if ListView1.Items.Count<1 then Exit;

  if SaveDialog1.Execute then begin
    sf:=SaveDialog1.FileName;
    bExist:=FileExists(sf);
    sfContents:=TStringList.Create;

    if bExist then begin
      sfContents.LoadFromFile(sf);
      re1:=TRegExpr.Create('\[(\w+)\]');
      re2:=TRegExpr.Create('Source\\s*\\:');
      iStartFiles:=-1;
      bSourceFound:=False; iLen:=0;
      iLastLine:=sfContents.Count-1; //last line number

      //Find start and end positions of [Files] block
      for i:=0 to sfContents.Count-1 do
      begin
        sLine:=Trim(sfContents[i]);

        if sLine='' then Continue;

        if re1.Exec(sLine) then begin
          sLine:=LowerCase(re1.Match[1]);

          if (sLine='files')then begin //found [Files] block
            if iStartFiles<0 then begin //if never found before
               iStartFiles:=i+1; //Block begins from next line
               Continue;
            end;
          end else if (iStartFiles>0)and(bSourceFound) then //[Files] block and Source line has been found and another block found
          begin
            iEndFiles:=i; //So, this line is the end of [Files] block
            iLen:=(i-iStartFiles)+1; //the lines count of previous files block
            Break;
          end;
        end else begin
          if (re2.Exec(sLine))and(not bSourceFound)and(iStartFiles>0) then begin //First source line found
            bSourceFound:=True;
            Continue;
          end;
        end;
      end;

      FreeAndNil(re1);FreeAndNil(re2);

      if (iStartFiles>0)and(iLen>0)and(ListView1.Items.Count>iLen) then
      begin
        iShift:=ListView1.Items.Count-iLen; //find out how much differnce between new lines and old lines

        for i:=1 to iShift do sfContents.Add(''); //add empty new lines
        for i:=iLastLine downto iEndFiles do  //move down old lines
          sfContents[i+iShift]:=sfContents[i]; //by iShift
      end else begin
        sfContents.Clear;
        bExist:=False;
      end;
    end;

    for i:=0 to ListView1.Items.Count-1 do
    begin
      if bExist then sfContents[i+iStartFiles]:=TInnoSetupFile(ListView1.Items[i].Data).ToString
      else sfContents.Add(TInnoSetupFile(ListView1.Items[i].Data).ToString);
    end;

    sfContents.SaveToFile(sf);
    FreeAndNil(sfContents);
  end;
end;

procedure TFMainForm.Button5Click(Sender: TObject);
var
  s:string;
  i:Cardinal;
  d:TInnoSetupFile;
begin
  if TFSetFlags.GetFlags(Self,FFlags) then begin
    s:=InnoFileFlagsToString(FFlags,', ');
    Button5.Hint:=s;
    Button5.ShowHint:=s<>'';

    if ListView1.SelCount>0 then begin
      for i:=0 to ListView1.Items.Count-1 do
          if ListView1.Items[i].Selected then begin
            d:=TInnoSetupFile(ListView1.Items[i].Data);
            d.Flags:=FFlags;
            ListView1.Items[i].SubItems[2]:=s;
          end;
    end;
  end;
end;

procedure TFMainForm.ListView1DblClick(Sender: TObject);
begin
  if Assigned(ListView1.Selected) then begin
    TFPickFlags.PickFlags(Self);
  end;
end;

procedure TFMainForm.ListView1ItemChecked(Sender: TObject; Item: TListItem);
begin
  Item.Selected:=Item.Checked;
end;

procedure TFMainForm.ListView1SelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  Button3.Enabled:=Selected;
end;

end.

