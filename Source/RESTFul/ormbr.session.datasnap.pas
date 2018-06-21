{
      ORM Brasil � um ORM simples e descomplicado para quem utiliza Delphi

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Vers�o 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos � permitido copiar e distribuir c�pias deste documento de
       licen�a, mas mud�-lo n�o � permitido.

       Esta vers�o da GNU Lesser General Public License incorpora
       os termos e condi��es da vers�o 3 da GNU General Public License
       Licen�a, complementado pelas permiss�es adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(ORMBr Framework.)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @author(Skype : ispinheiro)

  ORM Brasil � um ORM simples e descomplicado para quem utiliza Delphi.
}

{$INCLUDE ..\ormbr.inc}

unit ormbr.session.datasnap;

interface

uses
  DB,
  Rtti,
  TypInfo,
  Classes,
  Variants,
  SysUtils,
  Generics.Collections,
  REST.Client,
  /// orm
  ormbr.mapping.explorerstrategy,
  ormbr.dataset.base.adapter,
  ormbr.session.abstract, 
  ormbr.session.baseurl;

type
  /// <summary>
  /// M - Sess�o RESTFull
  /// </summary>
  TSessionDataSnap<M: class, constructor> = class(TSessionAbstract<M>)
  private
    FOwner: TDataSetBaseAdapter<M>;
    FRESTResponse: TRESTResponse;
    FRESTRequest: TRESTRequest;
    FRESTClient: TRESTClient;
    FResource: String;
  public
    constructor Create(const AOwner: TDataSetBaseAdapter<M>); overload;
    destructor Destroy; override;
    procedure Insert(const AObject: M); overload; override;
    procedure Update(const AObjectList: TObjectList<M>); overload; override;
    procedure Delete(const AID: Integer); overload; override;
    procedure Open; override;
    procedure OpenID(const AID: Variant); override;
    procedure OpenWhere(const AWhere: string; const AOrderBy: string = ''); override;
    function Find: TObjectList<M>; overload; override;
    function Find(const AID: Integer): M; overload; override;
    function Find(const AID: String): M; overload; override;
    function FindWhere(const AWhere: string; const AOrderBy: string = ''): TObjectList<M>; override;
  end;

implementation

uses
  REST.Types,
  IPPeerClient,
  DBXJSONReflect,
  System.JSON,
  ormbr.rest.json,
  ormbr.objects.helper,
  ormbr.restdataset.adapter,
  ormbr.json.utils;

{ TSessionDataSnap<M> }

constructor TSessionDataSnap<M>.Create(const AOwner: TDataSetBaseAdapter<M>);
var
  LObject: TObject;
  ABaseURL: String;
begin
  inherited Create;
  FOwner := AOwner;
  /// <summary>
  ///  Verifica se foi informado a URL no Singleton
  /// </summary>
  ABaseURL := TSessionRESTBaseURL.GetInstance.BaseURL;
  if Length(ABaseURL) = 0 then
    raise Exception.Create('Defina a URL base na classe sington [TSessionRESTBaseURL.GetInstance.BaseURL := "http://127.0.0.1:211/datasnap/rest/tormbr"]');

  FRESTRequest := TRESTRequest.Create(nil);
  FRESTResponse := TRESTResponse.Create(nil);
  FRESTClient := TRESTClient.Create(ABaseURL);
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.Response := FRESTResponse;
  FRESTResponse.RootElement := 'result';
  /// <summary>
  ///  Pega o nome do recurso, caso n�o encontre o atributo Resource(),
  ///  internamente busca pelo atributo Table()
  /// </summary>
  LObject := TObject(M.Create);
  try
    FResource := LObject.GetResourceName;
  finally
    LObject.Free;
  end;
end;

destructor TSessionDataSnap<M>.Destroy;
begin
  FRESTClient.Free;
  FRESTResponse.Free;
  FRESTRequest.Free;
  inherited;
end;

procedure TSessionDataSnap<M>.Delete(const AID: Integer);
begin
  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/' + FResource + '/{ID}';
  FRESTRequest.Method := TRESTRequestMethod.rmDELETE;
  FRESTRequest.Params.AddUrlSegment('ID', IntToStr(AID));
  FRESTRequest.Execute;
end;

function TSessionDataSnap<M>.FindWhere(const AWhere, AOrderBy: string): TObjectList<M>;
var
  LJSON: string;
begin
  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/' + FResource + 'Where' + '/{WHERE}/{ORDERBY}';
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  FRESTRequest.Params.AddUrlSegment('WHERE', AWhere);
  FRESTRequest.Params.AddUrlSegment('ORDERBY', AOrderBy);
  FRESTRequest.Execute;

  LJSON := TJSONArray(FRESTRequest.Response.JSONValue).Items[0].ToJSON;
  /// <summary>
  /// Transforma o JSON recebido populando o objeto
  /// </summary>
  Result := TORMBrJson.JsonToObjectList<M>(LJSON);
end;

function TSessionDataSnap<M>.Find(const AID: Integer): M;
begin
  /// <summary>
  /// Transforma o JSON recebido populando o objeto
  /// </summary>
  Result := Find(IntToStr(AID));
end;

function TSessionDataSnap<M>.Find(const AID: string): M;
var
  LJSON: string;
begin
  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/' + FResource + '/{ID}';
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  FRESTRequest.Params.AddUrlSegment('ID', AID);
  FRESTRequest.Execute;

  LJSON := TJSONArray(TJSONArray(FRESTRequest.Response.JSONValue).Items[0]).Items[0].ToJSON;
  /// <summary>
  /// Transforma o JSON recebido populando o objeto
  /// </summary>
  Result := TORMBrJson.JsonToObject<M>(LJSON);
end;

function TSessionDataSnap<M>.Find: TObjectList<M>;
var
  LJSON: string;
begin
  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/' + FResource + '/{ID}';
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  FRESTRequest.Params.AddUrlSegment('ID', '0');
  FRESTRequest.Execute;

  LJSON := TJSONArray(FRESTRequest.Response.JSONValue).Items[0].ToJSON;
  /// <summary>
  /// Transforma o JSON recebido populando o objeto
  /// </summary>
  Result := TORMBrJson.JsonToObjectList<M>(LJSON);
end;

procedure TSessionDataSnap<M>.Insert(const AObject: M);
var
  FJSON: String;
begin
  FJSON := TORMBrJson.ObjectToJsonString(AObject);

  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/' + FResource;
  FRESTRequest.Method := TRESTRequestMethod.rmPUT;
  {$IFDEF DELPHI22_UP}
  FRESTRequest.AddBody(FJSON, ContentTypeFromString('application/json'));
  {$ELSE}
  FRESTRequest.Body.Add(FJSON, ContentTypeFromString('application/json'));
  {$ENDIF}
  FRESTRequest.Execute;
end;

procedure TSessionDataSnap<M>.Update(const AObjectList: TObjectList<M>);
var
  FJSON: TJSONArray;
begin
  FJSON := TORMBrJSONUtil.JSONStringToJSONArray<M>(AObjectList);
  try
    FRESTRequest.ResetToDefaults;
    FRESTRequest.Resource := '/' + FResource;
    FRESTRequest.Method := TRESTRequestMethod.rmPOST;
    {$IFDEF DELPHI22_UP}
    FRESTRequest.AddBody(FJSON.ToJSON, ContentTypeFromString('application/json'));
    {$ELSE}
    FRESTRequest.Body.Add(FJSON.ToJSON, ContentTypeFromString('application/json'));
    {$ENDIF}
    FRESTRequest.Execute;
  finally
    FJSON.Free;
  end;
end;

procedure TSessionDataSnap<M>.OpenID(const AID: Variant);
var
  LObject: M;
begin
  LObject := Find(Integer(AID));
  if LObject <> nil then
  begin
    try
      TRESTDataSetAdapter<M>(FOwner).PopularDataSet(LObject);
    finally
      LObject.Free;
    end;
  end;
end;

procedure TSessionDataSnap<M>.Open;
var
  LObjectList: TObjectList<M>;
begin
  LObjectList := Find;
  /// <summary>
  /// Popula do DataSet
  /// </summary>
  if LObjectList <> nil then
  begin
    try
      TRESTDataSetAdapter<M>(FOwner).PopularDataSetList(LObjectList);
    finally
      LObjectList.Clear;
      LObjectList.Free;
    end;
  end;
end;

procedure TSessionDataSnap<M>.OpenWhere(const AWhere, AOrderBy: string);
var
  LObjectList: TObjectList<M>;
begin
  LObjectList := FindWhere(AWhere, AOrderBy);
  /// <summary>
  /// Popula do DataSet
  /// </summary>
  if LObjectList <> nil then
  begin
    try
      TRESTDataSetAdapter<M>(FOwner).PopularDataSetList(LObjectList);
    finally
      LObjectList.Clear;
      LObjectList.Free;
    end;
  end;
end;

end.
