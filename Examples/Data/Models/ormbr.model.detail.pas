unit ormbr.model.detail;

interface

uses
  Classes,
  DB,
  SysUtils,
  Generics.Collections,
  /// orm
  ormbr.mapping.attributes,
  ormbr.types.mapping,
  ormbr.types.lazy,
  ormbr.types.nullable,
  ormbr.model.lookup,
  ormbr.mapping.register,
  nivel3.model;

type
  [Entity]
  [Table('detail','')]
  [PrimaryKey('detail_id', AutoInc, NoSort, True, 'Chave prim�ria')]
  [Sequence('detail')]
  [AggregateField('AGGPRICE', 'SUM(PRICE)', taRightJustify, '#,###,##0.00')]
  Tdetail = class
  private
    { Private declarations }
    Fdetail_id: Integer;
    Fmaster_id: Integer;
    Flookup_id: Integer;
    Flookup_description: String;
    Fprice: Double;
    Flevel3: TObjectList<TLevel_3>;
  public
    { Public declarations }
    constructor Create;
    destructor Destroy; override;

    [Restrictions([NoUpdate, NotNull])]
    [Column('detail_id', ftInteger)]
    [Dictionary('ID Detalhe','Mensagem de valida��o','','','',taCenter)]
    property detail_id: Integer read Fdetail_id write Fdetail_id;

    [Restrictions([NotNull])]
    [Column('master_id', ftInteger)]
    [ForeignKey('FK_IDMASTER', 'master_id', 'master', 'master_id', Cascade, Cascade)]
    [Dictionary('ID Mestre','Mensagem de valida��o','','','',taCenter)]
    property master_id: Integer read Fmaster_id write Fmaster_id;

    [Restrictions([NotNull])]
    [Column('lookup_id', ftInteger)]
    [ForeignKey('FK_IDLOOKUP', 'lookup_id', 'lookup', 'lookup_id', None, None)]
    [Dictionary('ID Lookup','Mensagem de valida��o','0','','',taCenter)]
    property lookup_id: Integer read Flookup_id write Flookup_id;

    [Column('lookup_description', ftString, 30)]
    [Dictionary('Descri��o Lookup','Mensagem de valida��o','','','',taLeftJustify)]
    property lookup_description: String read Flookup_description write Flookup_description;

    [Restrictions([NotNull])]
    [Column('price', ftFloat, 18, 3)]
    [Dictionary('Pre�o Unit�rio','Mensagem de valida��o','','#,###,##0.00','',taRightJustify)]
    property price: Double read Fprice write Fprice;

    [Association(OneToMany, 'detail_id', 'level_3', 'detail_id')]
    [CascadeActions([CascadeAutoInc, CascadeInsert, CascadeUpdate, CascadeDelete])]
    property level3: TObjectList<TLevel_3> read Flevel3 write Flevel3;
  end;

implementation

{ Tdetail }

constructor Tdetail.Create;
begin
  FLevel3 := TObjectList<TLevel_3>.Create;
end;

destructor Tdetail.Destroy;
begin
  FLevel3.Free;
  inherited;
end;

initialization
  TRegisterClass.RegisterEntity(Tdetail);

end.
