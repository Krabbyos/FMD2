unit XQueryEngineHTML;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, xquery, xquery_json, simplehtmltreeparser;

type

  { TXQueryEngineHTML }

  TXQueryEngineHTML = class
  private
    FEngine: TXQueryEngine;
    FTreeParser: TTreeParser;
    function Eval(const Expression: String; const isCSS: Boolean = False;
      const Tree: TTreeNode = nil): IXQValue;
  public
    constructor Create(const HTML: String = ''); overload;
    constructor Create(const HTMLStream: TStream); overload;
    destructor Destroy; override;
    procedure ParseHTML(const HTML: String); overload;
    procedure ParseHTML(const HTMLStream: TStream); overload;
    function XPath(const Expression: String; const Tree: TTreeNode = nil): IXQValue; inline;
    function XPathString(const Expression: String; const Tree: TTreeNode = nil): String; inline;
    function XPathStringAll(const Expression: String; const Tree: TTreeNode = nil;
      const Separator: String = ', '): String;
    function CSS(const Expression: String; const Tree: TTreeNode = nil): IXQValue; inline;
    function CSSString(const Expression: String; const Tree: TTreeNode = nil): String; inline;
    function CSSStringAll(const Expression: String; const Tree: TTreeNode = nil;
      const Separator: String = ', '): String;
    property Engine: TXQueryEngine read FEngine;
  end;

  IXQValue = xquery.IXQValue;

implementation

function StreamToString(const Stream: TStream): String;
var
  x: Integer;
begin
  Stream.Position := 0;
  Setlength(Result, Stream.Size);
  x := Stream.Read(PChar(Result)^, Stream.Size);
  SetLength(Result, x);
end;

procedure AddSeparatorString(var Dest: String; const S: String; const Separator: String = ', ');
begin
  if Trim(S) <> '' then
  begin
    if Trim(Dest) = '' then
      Dest := Trim(S)
    else
      Dest := Trim(Dest) + Separator + Trim(S);
  end;
end;

{ TXQueryEngineHTML }

function TXQueryEngineHTML.Eval(const Expression: String; const isCSS: Boolean;
  const Tree: TTreeNode): IXQValue;
var
  t: TTreeNode;
begin
  Result := xqvalue();
  t := Tree;
  if t = nil then
    t := FTreeParser.getLastTree;
  if Expression = '' then
    Exit;
  try
    if isCSS then
      Result := FEngine.evaluateCSS3(Expression, t)
    else
      Result := FEngine.evaluateXPath3(Expression, t);
  except
  end;
end;

constructor TXQueryEngineHTML.Create(const HTML: String);
begin
  FEngine := TXQueryEngine.Create;
  FTreeParser := TTreeParser.Create;
  with FTreeParser do
  begin
    parsingModel := pmHTML;
    repairMissingStartTags := True;
    repairMissingEndTags := True;
    trimText := False;
    readComments := False;
    readProcessingInstructions := False;
    autoDetectHTMLEncoding := False;
    if HTML <> '' then
      parseTree(HTML);
  end;
end;

constructor TXQueryEngineHTML.Create(const HTMLStream: TStream);
begin
  if Assigned(HTMLStream) then
    Create(StreamToString(HTMLStream))
  else
    Create('');
end;

destructor TXQueryEngineHTML.Destroy;
begin
  FEngine.Free;
  FTreeParser.Free;
  inherited Destroy;
end;

procedure TXQueryEngineHTML.ParseHTML(const HTML: String);
begin
  if HTML <> '' then
    FTreeParser.parseTree(HTML);
end;

procedure TXQueryEngineHTML.ParseHTML(const HTMLStream: TStream);
begin
  ParseHTML(StreamToString(HTMLStream));
end;

function TXQueryEngineHTML.XPath(const Expression: String; const Tree: TTreeNode): IXQValue;
begin
  Result := Eval(Expression, False, Tree);
end;

function TXQueryEngineHTML.XPathString(const Expression: String; const Tree: TTreeNode): String;
begin
  Result := Eval(Expression, False, Tree).toString;
end;

function TXQueryEngineHTML.XPathStringAll(const Expression: String;
  const Tree: TTreeNode; const Separator: String): String;
var
  v: IXQValue;
begin
  Result := '';
  for v in Eval(Expression, False, Tree) do
    AddSeparatorString(Result, v.toString, Separator);
end;

function TXQueryEngineHTML.CSS(const Expression: String; const Tree: TTreeNode): IXQValue;
begin
  Result := Eval(Expression, True, Tree);
end;

function TXQueryEngineHTML.CSSString(const Expression: String; const Tree: TTreeNode): String;
begin
  Result := Eval(Expression, True, Tree).toString;
end;

function TXQueryEngineHTML.CSSStringAll(const Expression: String; const Tree: TTreeNode;
  const Separator: String): String;
var
  v: IXQValue;
begin
  Result := '';
  for v in Eval(Expression, True, Tree) do
    AddSeparatorString(Result, v.toString, Separator);
end;

end.
