{
  FreePascal Component based on MsnPopup
  Email: solodyagin@gmail.com

  MsnPopup - using MSN-style popup windows in your Delphi programs
  Copyright (C) 2001-2003 JWB Software

  Web:   http://people.zeelandnet.nl/famboek/delphi/
  Email: jwbsoftware@zeelandnet.nl
}
unit umsnpopup;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, Graphics, StdCtrls, ExtCtrls, Controls, Forms, ShellAPI, Dialogs, SysUtils, Messages, LCLType;

type
  TMSNGradientOrientation = (goHorizontal, goVertical);
  TMSNScrollSpeed = 1..50;
  TMSNPopupOption = (msnSystemFont, msnCascadePopups, msnAllowScroll);
  TMSNPopupOptions = set of TMSNPopupOption;
  TMSNBackgroundDrawMethod = (dmActualSize, dmTile, dmFit);

  TMSNPopup = class(TComponent)
  private
    FTitle: String;
    FTitleFont: TFont;
    FMessage: String;
    FMessageFont: TFont;
    FTextAlignment: TAlignment;
    FWidth: Integer;
    FHeight: Integer;
    FTimeOut: Integer;
    FScrollSpeed: TMSNScrollSpeed;
    FGradientColor1: TColor;
    FGradientColor2: TColor;
    FGradientOrientation: TMSNGradientOrientation;
    FCursor: TCursor;
    FOptions: TMSNPopupOptions;
    FBackgroundDrawMethod: TMSNBackgroundDrawMethod;
    FPopupMarge, FPopupStartX, FPopupStartY: Integer;
    FDefaultMonitor: TDefaultMonitor;
    FBackground: TBitmap;
    FOnClick: TNotifyEvent;
    FOnMouseUp: TMouseEvent;
    PopupCount, NextPopupPos: Integer;
    LastBorder: Integer;
    function GetCaptionFont: TFont;
    procedure SetTitleFont(Value: TFont);
    procedure SetMessageFont(Value: TFont);
    procedure SetBackground(Value: TBitmap);
  public
    function ShowPopup: Boolean;
    procedure ClosePopups;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Title: String read FTitle write FTitle;
    property TitleFont: TFont read FTitleFont write SetTitleFont;
    property Message: String read FMessage write FMessage;
    property MessageFont: TFont read FMessageFont write SetMessageFont;
    property TextAlignment: TAlignment read FTextAlignment write FTextAlignment;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property TimeOut: Integer read FTimeOut write FTimeOut;
    property GradientColor1: TColor read FGradientColor1 write FGradientColor1;
    property GradientColor2: TColor read FGradientColor2 write FGradientColor2;
    property GradientOrientation: TMSNGradientOrientation read FGradientOrientation write FGradientOrientation;
    property ScrollSpeed: TMSNScrollSpeed read FScrollSpeed write FScrollSpeed;
    property Options: TMSNPopupOptions read FOptions write FOptions;
    property Background: TBitmap read FBackground write SetBackground;
    property BackgroundDrawMethod: TMSNBackgroundDrawMethod read FBackgroundDrawMethod write FBackgroundDrawMethod;
    property Cursor: TCursor read FCursor write FCursor;
    property PopupMarge: Integer read FPopupMarge write FPopupMarge;
    property PopupStartX: Integer read FPopupStartX write FPopupStartX;
    property PopupStartY: Integer read FPopupStartY write FPopupStartY;
    property DefaultMonitor: TDefaultMonitor read FDefaultMonitor write FDefaultMonitor;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
  end;

type
  TFrmMSNPopup = class(TCustomForm)
    PnlBorder: TPanel;
    ImgGradient: TImage;
    LblTitle: TLabel;
    LblMessage: TLabel;
    TmrExit: TTimer;
    TmrScroll: TTimer;
    TmrScrollDown: TTimer;
    procedure ControlClick(Sender: TObject);
    procedure ControlMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TmrExitTimer(Sender: TObject);
    procedure TmrScrollTimer(Sender: TObject);
    procedure TmrScrollDownTimer(Sender: TObject);
  private
    PopupPos: Integer;
    ParentMSNPopup: TMSNPopup;
    CanClose: Boolean;
    BackgroundDrawMethod: TMSNBackgroundDrawMethod;
    Title: String;
    TitleFont: TFont;
    Message: String;
    MessageFont: TFont;
    TimeOut: Integer;
    sWidth: Integer;
    sHeight: Integer;
    bScroll: Boolean;
    GradientColor1, GradientColor2: TColor;
    GradientOrientation: TMSNGradientOrientation;
    ScrollSpeed: TMSNScrollSpeed;
    StoredBorder: Integer;
    procedure Popup;
    function CalcColorIndex(StartColor, EndColor: TColor; Steps, ColorIndex: Integer): TColor;
  protected
    procedure DoClose(var CloseAction: TCloseAction); override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
  end;

function GetEdge: Integer;
{function GradientFill(DC: HDC; const ARect: TRect; StartColor, EndColor: TColor; Vertical: Boolean): Boolean; overload;}

implementation

{ TMSNPopup }

constructor TMSNPopup.Create(AOwner: TComponent);
begin
  inherited;
  FOptions := [msnAllowScroll, msnCascadePopups];
  FBackground := TBitmap.Create;
  FBackgroundDrawMethod := dmActualSize;
  FTitleFont := TFont.Create;
  FTitleFont.Style := [fsBold];
  FTitleFont.Size := 10;
  FTitleFont.Color := $745E41;
  FMessageFont := TFont.Create;
  FMessageFont.Style := [fsBold];
  FMessageFont.Size := 10;
  FMessageFont.Color := $745E41;
  if (msnSystemFont in FOptions) then
  begin
    FTitleFont.Name := GetCaptionFont.Name;
    FMessageFont.Name := GetCaptionFont.Name;
  end;
  FWidth := 280;
  FHeight := 100;
  FTimeOut := 20;
  FScrollSpeed := 9;
  FTitle := 'Title';
  FMessage := 'Message';
  FCursor := crHandPoint;
  FGradientColor1 := $FAF0E4;
  FGradientColor2 := $F0D5B8;
  FGradientOrientation := goVertical;
  FPopupMarge := 2;
  FPopupStartX := 16;
  FPopupStartY := 2;
  FTextAlignment := taCenter;
  PopupCount := 0;
  LastBorder := 0;
end;

destructor TMSNPopup.Destroy;
begin
  FTitleFont.Free;
  FMessageFont.Free;
  FBackground.Free;
  inherited;
end;

function TMSNPopup.ShowPopup: Boolean;
var
  R: TRect;
  FrmMSNPopup: TFrmMSNPopup;
begin
  if (GetEdge <> LastBorder) then
  begin
    LastBorder := GetEdge;
    PopupCount := 0;
  end;

  Result := True;

  SystemParametersInfo(SPI_GETWORKAREA, 0, @R, 0);
  if (PopupCount > 0) then
  begin
    case LastBorder of
      ABE_BOTTOM:
        if ((R.Bottom - (NextPopupPos + FHeight + PopupStartY)) < 0) then
        begin
          Result := False;
          Exit;
        end;
      ABE_LEFT:
        if ((NextPopupPos + FWidth + PopupStartX) > R.Right) then
        begin
          Result := False;
          Exit;
        end;
      ABE_RIGHT:
        if ((R.Right - (NextPopupPos + FHeight + PopupStartY)) < 0) then
        begin
          Result := False;
          Exit;
        end;
      ABE_TOP:
        if (((NextPopupPos + FHeight + PopupStartY)) > R.Bottom) then
        begin
          Result := False;
          Exit;
        end;
    end;
  end
  else
    NextPopupPos := 0;

  Inc(PopupCount);

  FrmMSNPopup := TFrmMSNPopup.CreateNew(Self.Owner);
  FrmMSNPopup.ParentMSNPopup := Self;
  FrmMSNPopup.DefaultMonitor := FDefaultMonitor;
  FrmMSNPopup.sWidth := FWidth;
  FrmMSNPopup.sHeight := FHeight;
  FrmMSNPopup.Title := FTitle;
  FrmMSNPopup.Message := FMessage;
  FrmMSNPopup.TimeOut := FTimeOut;
  FrmMSNPopup.bScroll := msnAllowScroll in FOptions;
  FrmMSNPopup.ScrollSpeed := FScrollSpeed;
  FrmMSNPopup.TitleFont := FTitleFont;
  FrmMSNPopup.MessageFont := FMessageFont;
  FrmMSNPopup.Cursor := FCursor;
  FrmMSNPopup.GradientColor1 := FGradientColor1;
  FrmMSNPopup.GradientColor2 := FGradientColor2;
  FrmMSNPopup.GradientOrientation := FGradientOrientation;
  FrmMSNPopup.LblMessage.Alignment := FTextAlignment;
  FrmMSNPopup.PnlBorder.Width := FWidth;
  FrmMSNPopup.PnlBorder.Height := FHeight;
  FrmMSNPopup.ImgGradient.Width := FWidth;
  FrmMSNPopup.ImgGradient.Height := FHeight;
  FrmMSNPopup.BackgroundDrawMethod := FBackgroundDrawMethod;
  FrmMSNPopup.Popup;
end;

procedure TMSNPopup.ClosePopups;
var
  Wnd: HWND;
begin
  repeat
    Wnd := FindWindow(nil, PChar('FrmMSNPopup'));
    if Wnd <> 0 then
    begin
      SendMessage(Wnd, WM_CLOSE, 0, 0);
      Application.ProcessMessages;
    end;
  until Wnd = 0;
end;

procedure TMSNPopup.SetTitleFont(Value: TFont);
begin
  if FTitleFont <> Value then
    FTitleFont.Assign(Value);
end;

procedure TMSNPopup.SetMessageFont(Value: TFont);
begin
  if FMessageFont <> Value then
    FMessageFont.Assign(Value);
end;

procedure TMSNPopup.SetBackground(Value: TBitmap);
begin
  if FBackground <> Value then
    FBackground.Assign(Value);
end;

function TMSNPopup.GetCaptionFont: TFont;
var
  ncMetrics: TNonClientMetrics;
begin
  ncMetrics.cbSize := SizeOf(TNonClientMetrics);
  SystemParametersInfo(SPI_GETNONCLIENTMETRICS, SizeOf(TNonClientMetrics), @ncMetrics, 0);
  Result := TFont.Create;
  Result.Handle := CreateFontIndirect(ncMetrics.lfMenuFont);
end;

{ TFrmMSNPopup }

constructor TFrmMSNPopup.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  inherited;

  Caption := 'FrmMSNPopup';
  BorderIcons := [];
  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;

  PnlBorder := TPanel.Create(Self);
  PnlBorder.Parent := Self;
  PnlBorder.BevelOuter := bvNone;
  PnlBorder.OnClick := @Self.ControlClick;

  ImgGradient := TImage.Create(Self);
  ImgGradient.Parent := PnlBorder;
  //ImgGradient.Align := alClient;
  //ImgGradient.Anchors := [akTop, akLeft, akRight, akBottom];
  ImgGradient.OnClick := @Self.ControlClick;
  ImgGradient.OnMouseUp := @Self.ControlMouseUp;

  LblTitle := TLabel.Create(Self);
  LblTitle.Parent := PnlBorder;
  LblTitle.ShowAccelChar := False;
  LblTitle.Transparent := True;
  LblTitle.Top := 8;
  LblTitle.Left := 48;
  LblTitle.OnClick := @Self.ControlClick;
  LblTitle.OnMouseUp := @Self.ControlMouseUp;

  LblMessage := TLabel.Create(Self);
  LblMessage.Parent := PnlBorder;
  LblMessage.ShowAccelChar := False;
  LblMessage.Layout := tlCenter;
  LblMessage.AutoSize := True;
  LblMessage.WordWrap := True;
  LblMessage.Transparent := True;
  LblMessage.Top := 49;
  LblMessage.Left := 9;
  LblMessage.Width := 3;
  LblMessage.Height := 13;
  LblMessage.OnClick := @Self.ControlClick;
  LblMessage.OnMouseUp := @Self.ControlMouseUp;

  TmrExit := TTimer.Create(Self);
  TmrExit.Enabled := False;
  TmrExit.Interval := 10000;
  TmrExit.OnTimer := @Self.TmrExitTimer;

  TmrScroll := TTimer.Create(Self);
  TmrScroll.Enabled := False;
  TmrScroll.Interval := 25;
  TmrScroll.OnTimer := @Self.TmrScrollTimer;

  TmrScrollDown := TTimer.Create(Self);
  TmrScrollDown.Enabled := False;
  TmrScrollDown.Interval := 25;
  TmrScrollDown.OnTimer := @Self.TmrScrollDownTimer;
end;

function GetEdge: Integer;
var
  AppBar: TAppbarData;
begin
  Result := -1;

  FillChar(AppBar, SizeOf(AppBar), 0);
  AppBar.cbSize := SizeOf(AppBar);

  if (ShAppBarMessage(ABM_GETTASKBARPOS, @AppBar) <> 0) then
    if ((AppBar.rc.Top = AppBar.rc.Left) and (AppBar.rc.bottom > AppBar.rc.right)) then
      Result := ABE_LEFT
    else if ((AppBar.rc.Top = AppBar.rc.Left) and (AppBar.rc.Bottom < AppBar.rc.Right)) then
      Result := ABE_TOP
    else if (AppBar.rc.Top > AppBar.rc.Left) then
      Result := ABE_BOTTOM
    else
      Result := ABE_RIGHT;
end;

procedure TFrmMSNPopup.Popup;
var
  R: TRect;
  Bmp: TBitmap;
  I: Integer;
  tileX, tileY: Integer;
begin
  Self.AutoScroll := False;
  Self.Height := sHeight;
  Self.Width := sWidth;

  PnlBorder.Cursor := Cursor;
  ImgGradient.Cursor := Cursor;
  LblTitle.Cursor := Cursor;
  LblMessage.Cursor := Cursor;

  CanClose := True;

  SystemParametersInfo(SPI_GETWORKAREA, 0, @R, 0);
  StoredBorder := GetEdge;
  case StoredBorder of
    ABE_LEFT:
    begin
      Self.Left := R.Left + ParentMSNPopup.PopupStartX;
      Self.Top := R.Bottom - ParentMSNPopup.PopupStartY - Self.Height - ParentMSNPopup.NextPopupPos;
    end;
    ABE_TOP:
    begin
      Self.Left := R.Right - Self.Width - ParentMSNPopup.PopupStartX;
      Self.Top := R.Top + ParentMSNPopup.PopupStartY + ParentMSNPopup.NextPopupPos;
    end;
    ABE_BOTTOM:
    begin
      Self.Left := R.Right - Self.Width - ParentMSNPopup.PopupStartX;
      Self.Top := R.Bottom - ParentMSNPopup.PopupStartY - Self.Height - ParentMSNPopup.NextPopupPos;
    end;
    ABE_RIGHT:
    begin
      Self.Left := R.Right - Self.Width - ParentMSNPopup.PopupStartX;
      Self.Top := R.Bottom - ParentMSNPopup.PopupStartY - Self.Height - ParentMSNPopup.NextPopupPos;
    end;
  end;

  PopupPos := ParentMSNPopup.NextPopupPos;
  if (msnCascadePopups in ParentMSNPopup.FOptions) then
  begin
    if (StoredBorder = ABE_BOTTOM) or (StoredBorder = ABE_TOP) then
      ParentMSNPopup.NextPopupPos := ParentMSNPopup.NextPopupPos + sHeight + ParentMSNPopup.FPopupMarge
    else if (StoredBorder = ABE_RIGHT) or (StoredBorder = ABE_LEFT) then
      ParentMSNPopup.NextPopupPos := ParentMSNPopup.NextPopupPos + sHeight + ParentMSNPopup.FPopupMarge;
  end
  else
    ParentMSNPopup.NextPopupPos := 0;

  LblTitle.Caption := Title;
  LblTitle.Font := TitleFont;

  if ParentMSNPopup.FBackground.Empty then
  begin
    //GradientFill(ImgGradient.Canvas.Handle, ImgGradient.ClientRect, GradientColor1, GradientColor2, True);
    Bmp := TBitmap.Create;
    Bmp.Width := ImgGradient.Width;
    Bmp.Height := ImgGradient.Height;
    case GradientOrientation of
      goVertical:
        for I := 0 to Bmp.Height do
        begin
          Bmp.Canvas.Pen.Color := CalcColorIndex(GradientColor1, GradientColor2, Bmp.Height + 1, I + 1);
          Bmp.Canvas.MoveTo(0, I);
          Bmp.Canvas.LineTo(Bmp.Width, I);
        end;
      goHorizontal:
        for I := 0 to Bmp.Width do
        begin
          Bmp.Canvas.Pen.Color := CalcColorIndex(GradientColor1, GradientColor2, Bmp.Height + 1, I + 1);
          Bmp.Canvas.MoveTo(I, 0);
          Bmp.Canvas.LineTo(I, Bmp.Height);
        end;
    end;
    ImgGradient.Canvas.Draw(0, 0, Bmp);
    Bmp.Free;

    ImgGradient.Canvas.Pen.Color := RGB(65, 94, 116);
    ImgGradient.Canvas.Pen.Width := 2;
    ImgGradient.Canvas.MoveTo(0, 1);
    ImgGradient.Canvas.LineTo(ImgGradient.Width - 1, 1);
    ImgGradient.Canvas.LineTo(ImgGradient.Width - 1, ImgGradient.Height - 1);
    ImgGradient.Canvas.LineTo(1, ImgGradient.Height - 1);
    ImgGradient.Canvas.LineTo(1, 0);
  end
  else
  begin
    ParentMSNPopup.FBackground.Transparent := True;

    case BackgroundDrawMethod of
      dmActualSize:
        ImgGradient.Canvas.Draw(0, 0, ParentMSNPopup.Background);
      dmTile:
      begin
        tileX := 0;
        while (tileX < ImgGradient.Width) do
        begin
          tileY := 0;
          while (tileY < ImgGradient.Height) do
          begin
            ImgGradient.Canvas.Draw(tileX, tileY, ParentMSNPopup.Background);
            tileY := tileY + ParentMSNPopup.Background.Height;
          end;
          tileX := tileX + ParentMSNPopup.Background.Width;
        end;
      end;
      dmFit:
        ImgGradient.Canvas.StretchDraw(Bounds(0, 0, ImgGradient.Width, ImgGradient.Height), ParentMSNPopup.Background);
    end;
  end;

  LblTitle.Left := 8;

  TmrExit.Interval := TimeOut * 1000;

  if bScroll then
  begin
    case GetEdge of
      ABE_TOP:
        Self.Height := 1;
      ABE_BOTTOM:
      begin
        Self.Top := Self.Top + Self.Height;
        Self.Height := 1;
      end;
      ABE_LEFT:
        Self.Width := 1;
      ABE_RIGHT:
      begin
        Self.Left := Self.Left + Self.Width;
        Self.Width := 1;
      end;
    end;
    TmrScroll.Enabled := True;
  end;

  if not bScroll then
    TmrExit.Enabled := True;

  ShowWindow(Self.Handle, SW_SHOWNOACTIVATE);
  Self.Visible := True;

  LblMessage.Caption := Message;
  LblMessage.Font := MessageFont;
  LblMessage.Width := PnlBorder.Width - 15;
  LblMessage.Left := Round((PnlBorder.Width - LblMessage.Width) / 2);
  LblMessage.Top := Round((PnlBorder.Height - LblMessage.Height) / 2);
end;

function TFrmMSNPopup.CalcColorIndex(StartColor, EndColor: TColor; Steps, ColorIndex: Integer): TColor;
var
  beginRGBValue: array[0..2] of Byte;
  RGBDifference: array[0..2] of Integer;
  Red, Green, Blue: Byte;
  NumColors: Integer;
begin
  // Initialize
  NumColors := Steps;
  Dec(ColorIndex);
  // Values are set
  beginRGBValue[0] := GetRValue(ColorToRGB(StartColor));
  beginRGBValue[1] := GetGValue(ColorToRGB(StartColor));
  beginRGBValue[2] := GetBValue(ColorToRGB(StartColor));
  RGBDifference[0] := GetRValue(ColorToRGB(EndColor)) - beginRGBValue[0];
  RGBDifference[1] := GetGValue(ColorToRGB(EndColor)) - beginRGBValue[1];
  RGBDifference[2] := GetBValue(ColorToRGB(EndColor)) - beginRGBValue[2];
  // Calculate the bands color
  Red := beginRGBValue[0] + MulDiv(ColorIndex, RGBDifference[0], NumColors - 1);
  Green := beginRGBValue[1] + MulDiv(ColorIndex, RGBDifference[1], NumColors - 1);
  Blue := beginRGBValue[2] + MulDiv(ColorIndex, RGBDifference[2], NumColors - 1);
  // The final color is returned
  Result := RGB(Red, Green, Blue);
end;

procedure TFrmMSNPopup.ControlClick(Sender: TObject);
begin
  CanClose := False;
  if Assigned(ParentMSNPopup.FOnClick) then
    ParentMSNPopup.FOnClick(Self);
  CanClose := True;
  Close;
end;

procedure TFrmMSNPopup.ControlMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(ParentMSNPopup.FOnMouseUp) then
    ParentMSNPopup.FOnMouseUp(Self, Button, Shift, X, Y);
  if (Button = mbRight) then
  begin
    CanClose := True;
    Self.Close;
  end;
end;

procedure TFrmMSNPopup.TmrExitTimer(Sender: TObject);
begin
  TmrExit.Enabled := False;
  TmrScrollDown.Enabled := True;
end;

procedure TFrmMSNPopup.TmrScrollDownTimer(Sender: TObject);
var
  R: TRect;
begin
  SystemParametersInfo(SPI_GETWORKAREA, 0, @R, 0);
  case StoredBorder of
    ABE_LEFT:
      if ((Self.Width - Scrollspeed) > 0) then
        Self.Width := Self.Width - ScrollSpeed
      else
        Self.Close;
    ABE_TOP:
      if ((Self.Height - ScrollSpeed) > 0) then
        Self.Height := Self.Height - ScrollSpeed
      else
        Self.Close;
    ABE_BOTTOM:
      if ((Self.Height - ScrollSpeed) > 0) then
      begin
        Self.Top := Self.Top + ScrollSpeed;
        Self.Height := Self.Height - ScrollSpeed;
      end
      else
        Self.Close;
    ABE_RIGHT:
      if ((Self.Width - ScrollSpeed) > 0) then
      begin
        Self.Left := Self.Left + ScrollSpeed;
        Self.Width := Self.Width - ScrollSpeed;
      end
      else
        Self.Close;
  end;
end;

procedure TFrmMSNPopup.TmrScrollTimer(Sender: TObject);
var
  R: TRect;
begin
  SystemParametersInfo(SPI_GETWORKAREA, 0, @R, 0);
  case StoredBorder of
    ABE_LEFT:
      if ((Self.Width + ScrollSpeed) < sWidth) then
        Self.Width := Self.Width + ScrollSpeed
      else
      begin
        Self.Width := sWidth;
        TmrScroll.Enabled := False;
        TmrExit.Enabled := True;
      end;
    ABE_TOP:
      if ((Self.Height + ScrollSpeed) < sHeight) then
        Self.Height := Self.Height + ScrollSpeed
      else
      begin
        Self.Height := sHeight;
        TmrScroll.Enabled := False;
        TmrExit.Enabled := True;
      end;
    ABE_BOTTOM:
      if ((Self.Height + ScrollSpeed) < sHeight) then
      begin
        Self.Top := Self.Top - ScrollSpeed;
        Self.Height := Self.Height + ScrollSpeed;
      end
      else
      begin
        Self.Height := sHeight;
        Self.Top := R.Bottom - ParentMSNPopup.PopupStartY - Self.Height - Self.PopupPos;
        TmrScroll.Enabled := False;
        TmrExit.Enabled := True;
      end;
    ABE_RIGHT:
      if ((Self.Width + ScrollSpeed) < sWidth) then
      begin
        Self.Left := Self.Left - ScrollSpeed;
        Self.Width := Self.Width + ScrollSpeed;
      end
      else
      begin
        Self.Width := sWidth;
        Self.Left := R.Right - ParentMSNPopup.PopupStartX - Self.Width;
        TmrScroll.Enabled := False;
        TmrExit.Enabled := True;
      end;
  end;
end;

procedure TFrmMSNPopup.DoClose(var CloseAction: TCloseAction);
begin
  if not CanClose then
    CloseAction := caHide
  else
  begin
    if ParentMSNPopup.PopupCount > 0 then
      Dec(ParentMSNPopup.PopupCount);
    CloseAction := caFree;
  end;
  inherited;
end;

{type
  PTriVertex = ^TTriVertex;

  TTriVertex = record
    X, Y: DWORD;
    Red, Green, Blue, Alpha: Word;
  end;

function GradientFill(DC: HDC; Vertex: PTriVertex; NumVertex: ULONG; Mesh: Pointer; NumMesh, Mode: ULONG): BOOL; stdcall; overload;
  external 'Msimg32.dll' Name 'GradientFill';

function GradientFill(DC: HDC; const ARect: TRect; StartColor, EndColor: TColor; Vertical: Boolean): Boolean; overload;
const
  Modes: array[Boolean] of ULONG = (GRADIENT_FILL_RECT_H, GRADIENT_FILL_RECT_V);
var
  Vertices: array[0..1] of TTriVertex;
  GRect: TGradientRect;
begin
  Vertices[0].X := ARect.Left;
  Vertices[0].Y := ARect.Top;
  Vertices[0].Red := GetRValue(ColorToRGB(StartColor)) shl 8;
  Vertices[0].Green := GetGValue(ColorToRGB(StartColor)) shl 8;
  Vertices[0].Blue := GetBValue(ColorToRGB(StartColor)) shl 8;
  Vertices[0].Alpha := 0;
  Vertices[1].X := ARect.Right;
  Vertices[1].Y := ARect.Bottom;
  Vertices[1].Red := GetRValue(ColorToRGB(EndColor)) shl 8;
  Vertices[1].Green := GetGValue(ColorToRGB(EndColor)) shl 8;
  Vertices[1].Blue := GetBValue(ColorToRGB(EndColor)) shl 8;
  Vertices[1].Alpha := 0;
  GRect.UpperLeft := 0;
  GRect.LowerRight := 1;
  Result := GradientFill(DC, @Vertices, 2, @GRect, 1, Modes[Vertical]);
end;}

end.
