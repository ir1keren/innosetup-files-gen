unit usetupfile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ComCtrls;

type
  TInnoFileFlag=(iff32bit,iff64bit,iffallowunsafefiles,iffcomparetimestamp,
    iffconfirmoverwrite,iffcreateallsubdirs,iffdeleteafterinstall,iffdontcopy,
    iffdontverifychecksum,iffexternal,ifffontisnttruetype,iffgacinstall,iffignoreversion,
    iffisreadme,iffnocompression,iffnoencryption,iffnoregerror,iffonlyifdestfileexists,
    iffonlyifdoesntexist,iffoverwritereadonly,iffpromptifolder,iffrecursesubdirs,
    iffregserver,iffregtypelib,iffreplacesameversion,iffrestartreplace,
    iffsetntfscompression,iffsharedfile,iffsign,iffsignonce,iffskipifsourcedoesntexist,
    iffsolidbreak,iffsortfilesbyextension,sortfilesbyname,ifftouch,
    iffuninsnosharedfileprompt,iffuninsremovereadonly,iffuninsrestartdelete,
    iffuninsneveruninstall,iffunsetntfscompression
  );
  TInnoFileFlags=set of TInnoFileFlag;
  TFileAttrib=(fatreadonly,fathidden,fatsystem);
  TFileAttribs=set of TFileAttrib;

  { TInnoSetupFile }

  TInnoSetupFile=class
  private
    FSource,FDestination:string;
    FFlags:TInnoFileFlags;
    FExcludedFiles:TStringList;
    FAttribs:TFileAttribs;
    FIsFile:boolean;
    procedure SetSource(value:string);
  public
    property Attribs:TFileAttribs read FAttribs write FAttribs;
    property Destination:string read FDestination write FDestination;
    property ExcludedFiles:TStringList read FExcludedFiles;
    property Flags:TInnoFileFlags read FFlags write FFlags;
    property IsFile:boolean read FIsFile;
    property Source:string read FSource write SetSource;

    constructor Create(const Path:string;DestDir:string='{app}');overload;
    destructor Destroy;override;

    function AttributesToString(const c:string=' '):string;
    function Clone:TInnoSetupFile;
    procedure SetFileAttribs(s:string;c:char=' ');
    procedure SetFileFlags(s:string;c:char=' ');
    procedure SetListItemText(var Item:TListItem);
    function ToListItem(AOwner: TListItems):TListItem;
    function ToString:string;reintroduce;

    class function CreateFromString(s:string):TInnoSetupFile;
  end;

  function InnoFileFlagToString(const iff:TInnoFileFlag):string;
  function InnoFileFlagsToString(const iff:TInnoFileFlags;const Delimiter:string=','):string;
  function StringToInnoFileFlag(const str:string):TInnoFileFlag;
  function StringToInnoFileFlags(str:string;const Delimiter:char=','):TInnoFileFlags;

  function FileAttribToString(const iff:TFileAttrib):string;
  function StringToFileAttrib(const str:string):TFileAttrib;

  function CharPosEx(c: Char; const S: string; Offset: Integer = 1): Integer;
  function GetFilesFromString(s:string;Delimiter:char):TStringList;
implementation
uses TypInfo;

function CharPosEx(c: Char; const S: string; Offset: Integer = 1): Integer;
  var
    len: Integer;
    p, pStart, pStop: PChar;
    iStep:byte;
  label
    Loop0, Loop4,
    TestT, Test0, Test1, Test2, Test3, Test4,
    AfterTestT, AfterTest0,
    Ret;
begin;
    p := Pointer(S);

    if (p = nil) or (Offset < 1) then
    begin;
      Exit(0);
    end;

    {$ifdef CPU32}
    iStep:=4;
    {$endif}
    {$ifdef CPU64}
    iStep:=8;
    {$endif}

    len := PLongInt(PByte(p) - iStep)^; // <- Modified to fit 32/64 bit
    if (len < Offset) then
    begin;
      Exit(0);
    end;

    pStop := p + len;
    pStart := p;
    p := p + Offset + 3;

    if p < pStop then
      goto Loop4;
    p := p - 4;
    goto Loop0;

  Loop4:
    if c = p[-4] then
      goto Test4;
    if c = p[-3] then
      goto Test3;
    if c = p[-2] then
      goto Test2;
    if c = p[-1] then
      goto Test1;
  Loop0:
    if c = p[0] then
      goto Test0;
  AfterTest0:
    if c = p[1] then
      goto TestT;
  AfterTestT:
    p := p + 6;
    if p < pStop then
      goto Loop4;
    p := p - 4;
    if p < pStop then
      goto Loop0;
    Exit(0);

  Test3:
    p := p - 2;
  Test1:
    p := p - 2;
  TestT:
    p := p + 2;
    if p <= pStop then
      goto Ret;
    Exit(0);

  Test4:
    p := p - 2;
  Test2:
    p := p - 2;
  Test0:
    Inc(p);
  Ret:
    Result := p - pStart;
end;

function GetFilesFromString(s:string;Delimiter:char):TStringList;
var
  i:Cardinal;
begin
  Result:=TStringList.Create;
  Result.Delimiter:=Delimiter;
  Result.DelimitedText:=s;

  for i:=0 to Result.Count-1 do
  begin
      s:=Result[i];

      if s[1]='"' then s:=Copy(s,2);
      if s[Length(s)]='"' then s:=Copy(s,1,Length(s)-1);

      if Result[i]<>s then Result[i]:=s;
  end;
end;

function InnoFileFlagToString(const iff: TInnoFileFlag): string;
begin
  Result:=Copy(GetEnumName(TypeInfo(TInnoFileFlag),integer(iff)),4);
end;

function InnoFileFlagsToString(const iff: TInnoFileFlags; const Delimiter: string=','
  ): string;
var
  i:TInnoFileFlag;
begin
  Result:='';

  for i:=Low(TInnoFileFlag) to High(TInnoFileFlag) do
    if i in iff then begin
      if Result<>'' then Result:=Result+Delimiter;

      Result:=Result+InnoFileFlagToString(i);
    end;
end;

function StringToInnoFileFlag(const str: string): TInnoFileFlag;
var
  smt:string;
begin
  smt:=Copy(str,1,3);

  if smt<>'iff' then smt:='iff'+str
  else smt:=str;

  Result:=TInnoFileFlag(GetEnumValue(TypeInfo(TInnoFileFlag),smt));
end;

function StringToInnoFileFlags(str: string; const Delimiter: char=','
  ): TInnoFileFlags;
var
  n:integer;
begin
  Result:=[];

  repeat
    n:=CharPosEx(Delimiter,str);

    if n>0 then begin
      Result:=Result+[StringToInnoFileFlag(Copy(str,1,n-1))];
      str:=Copy(str,n+1);
    end else begin
      Result:=Result+[StringToInnoFileFlag(str)];
      str:='';
    end;
  until str='';
end;

function FileAttribToString(const iff: TFileAttrib): string;
begin
  Result:=Copy(GetEnumName(TypeInfo(TFileAttrib),integer(iff)),4);
end;

function StringToFileAttrib(const str: string): TFileAttrib;
var
  smt:string;
begin
  smt:=Copy(str,1,3);

  if smt<>'fat' then smt:='fat'+str
  else smt:=str;

  Result:=TFileAttrib(GetEnumValue(TypeInfo(TFileAttrib),smt));
end;

{ TInnoSetupFile }
procedure TInnoSetupFile.SetSource(value: string);
begin
  FSource:=value;
  FExcludedFiles.Clear;
  FFlags:=[];
  FAttribs:=[];
  FIsFile:=FileExists(value);
end;

constructor TInnoSetupFile.Create(const Path:string;DestDir:string='{app}');
begin
  inherited Create;
  FExcludedFiles:=TStringList.Create;
  FExcludedFiles.Delimiter:=',';
  FDestination:=DestDir;
  SetSource(Path);
end;

destructor TInnoSetupFile.Destroy;
begin
  FExcludedFiles.Clear;
  FExcludedFiles.Destroy;
  inherited Destroy;
end;

function TInnoSetupFile.AttributesToString(const c:string=' '): string;
var
  i:TFileAttrib;
begin
  Result:='';

  for i:=Low(TFileAttrib) to High(TFileAttrib) do
      if i in FAttribs then begin
        if Result<>'' then Result:=Result+c;

        Result:=Result+FileAttribToString(i);
      end;
end;

function TInnoSetupFile.Clone: TInnoSetupFile;
begin
  Result:=TInnoSetupFile.Create(FSource,FDestination);
  Result.FIsFile:=FIsFile;
  Result.FAttribs:=FAttribs;
  Result.FFlags:=FFlags;

  if FExcludedFiles.Count>0 then Result.FExcludedFiles.AddStrings(FExcludedFiles);
end;

procedure TInnoSetupFile.SetFileAttribs(s:string;c:char=' ');
var
  n:integer;
begin
  FAttribs:=[];

  repeat
    n:=CharPosEx(c,s);

    if n>0 then begin
      FAttribs:=FAttribs+[StringToFileAttrib(Copy(s,1,n-1))];
      s:=Copy(s,n+1);
    end else begin
      FAttribs:=FAttribs+[StringToFileAttrib(s)];
      s:='';
    end;
  until s='';
end;

procedure TInnoSetupFile.SetFileFlags(s:string;c:char=' ');
begin
  FFlags:=StringToInnoFileFlags(s,c);
end;

procedure TInnoSetupFile.SetListItemText(var Item: TListItem);
begin
  Item.Caption:=FSource;

  if Item.SubItems.Count>0 then
  begin
    Item.SubItems[0]:=FDestination;

    if FExcludedFiles.Count>0 then Item.SubItems[1]:=FExcludedFiles.DelimitedText
    else Item.SubItems[1]:='';

    Item.SubItems[2]:=InnoFileFlagsToString(FFlags,', ');
    Item.SubItems[3]:=AttributesToString(', ');
  end else begin
    Item.SubItems.Add(FDestination);

    if FExcludedFiles.Count>0 then Item.SubItems.Add(FExcludedFiles.DelimitedText)
    else Item.SubItems.Add('');

    Item.SubItems.Add(InnoFileFlagsToString(Flags,', '));
    Item.SubItems.Add(AttributesToString(', '));
  end;

  Item.Data:=Self;
end;

function TInnoSetupFile.ToListItem(AOwner: TListItems): TListItem;
begin
  Result:=nil;

  if not Assigned(AOwner) then exit;

  Result:=AOwner.Add;
  SetListItemText(Result);
end;

function TInnoSetupFile.ToString: string;
var
  temp:string;
begin
  Result:='Source: "'+FSource+'"; DestDir: "'+FDestination+'"';

  if FExcludedFiles.Count>1 then Result:=Result+'; Excludes: "'+FExcludedFiles.DelimitedText+'"';

  temp:=InnoFileFlagsToString(FFlags,' ');

  if temp<>'' then Result:=Result+'; Flags: '+temp;

  temp:=AttributesToString;

  if temp<>'' then Result:=Result+'; Attrib: '+temp;
end;

class function TInnoSetupFile.CreateFromString(s: string): TInnoSetupFile;
var
  n,i:integer;
  temp,skey,sval,src,dest,excludes,sflags,atts:string;
begin
  Result:=nil;src:='';dest:='';

  repeat
    n:=CharPosEx(';',s);
    skey:='';sval:='';temp:='';

    if n>0 then begin
      temp:=Trim(Copy(s,1,n-1));
      s:=Trim(Copy(s,n+1));
    end else begin
      if Trim(s)<>'' then temp:=Trim(s);

      s:='';
    end;

    if temp<>'' then begin
       i:=CharPosEx(':',temp);
       sKey:=Trim(Copy(temp,1,i-1));
       sval:=Trim(Copy(temp,i+1));
    end;

    if sval[1]='"' then sval:=Copy(sval,2);
    if sval[Length(sval)]='"' then sval:=Copy(sval,1,Length(sval)-1);

    case LowerCase(skey) of
    'source': src:=sval;
    'destdir': dest:=sval;
    'excludes': excludes:=sval;
    'flags': sflags:=sval;
    'attrib': atts:=sval;
    end;
  until s='';

  if (src<>'')and(dest<>'') then
  begin
    Result:=TInnoSetupFile.Create(src,dest);

    if excludes<>'' then Result.ExcludedFiles.DelimitedText:=excludes;
    if sflags<>'' then Result.SetFileFlags(sflags);
    if atts<>'' then Result.SetFileAttribs(atts);
  end;
end;

end.

