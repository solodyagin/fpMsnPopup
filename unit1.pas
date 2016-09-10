unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, umsnpopup;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { private declarations }
    fMSNPopup: TMSNPopup;
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  fMSNPopup.Title := 'Title';
  fMSNPopup.Message := 'Message';
  fMSNPopup.ShowPopup;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  fMSNPopup.ClosePopups;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  fMSNPopup := TMSNPopup.Create(Self);
  fMSNPopup.Options := [msnAllowScroll, msnCascadePopups];
  //fMSNPopup.TitleFont.Name := 'Tahoma';
  //fMSNPopup.GradientOrientation := goHorizontal;
  //fMSNPopup.OnClick := @Self.MSNPopupClick;
  //fMSNPopup.OnMouseUp := @Self.MSNPopupMouseUp;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  fMSNPopup.Free;
end;

end.

