unit uFrmPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMXDelphiZXIngQRCode,
  Winapi.Windows,System.Math;

type
  TFrmPrincipal = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    edtChave: TEdit;
    edtCodTrans: TEdit;
    edtValor: TEdit;
    edtCidade: TEdit;
    edtBeneficiario: TEdit;
    edtPayLoad: TEdit;
    Button1: TButton;
    Image1: TImage;
    procedure Button1Click(Sender: TObject);
  private
    function PayLoad(ChavePIX, Beneficiario, Cidade, CodTransferencia: String;Valor: Real): String;
    procedure QrCodeMobile(imgQRCode: TImage; texto: string);
    procedure QRCodeWin(imgQRCode: TImage; texto: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.fmx}

function CRC16CCITT(texto: string): WORD;
 const
  polynomial = $1021;
 var
 crc: WORD;
 i, j: Integer;
 b: Byte;
 bit, c15: Boolean;
 begin
  crc := $FFFF;
   for i := 1 to length(texto) do
   begin
   b := Byte(texto[i]);
   for j := 0 to 7 do
    begin
    bit := (((b shr (7 - j)) and 1) = 1);
    c15 := (((crc shr 15) and 1) = 1);
    crc := crc shl 1;
    if (c15 xor bit) then
    crc := crc xor polynomial;
    end;
   end;
   Result := crc and $FFFF;
end;

function TFrmPrincipal.PayLoad(ChavePIX: String;Beneficiario: String;Cidade: String;CodTransferencia: String;Valor: Real): String;
const Payload_Format_Indicator       : String = '000201';
const Merchant_Account_Information   : String = '26';
const Merchant_Category_Code         : String = '52040000';
const Transaction_Currency           : String = '530398654';
const Country_Code                   : String = '5802BR';
const Merchant_Name                  : String = '59';
const Merchant_City                  : String = '60';
const Additional_Data_Field_Template : String = '62';
const CRC162                         : String = '6304';
Var
 CODPayLoad,Merchant_Account_Information_String,Valor_Total,txid,CRC: String;
begin
  Merchant_Account_Information_String:= '0014BR.GOV.BCB.PIX01'+Length(ChavePIX).ToString+
  ChavePIX;

  Valor_Total := FormatFloat('#####0.00;00.00',Valor);
  Valor_Total := StringReplace(Valor_Total,',','.',[]);

  txid:='05'+FormatFloat('00',LengTh(CodTransferencia))+CodTransferencia;

  CODPayLoad:=Payload_Format_Indicator+
  Merchant_Account_Information+Length(Merchant_Account_Information_String).ToString+
  Merchant_Account_Information_String+Merchant_Category_Code+Transaction_Currency+
  FormatFloat('00',Length(Valor_Total))+Valor_Total+Country_Code+Merchant_Name+
  FormatFloat('00',LengTh(Beneficiario))+Beneficiario+Merchant_City+FormatFloat('00',Length(Cidade))+
  cidade+Additional_Data_Field_Template+FormatFloat('00',LengTh(txid))+txid+'6304';

  CRC := inttohex(CRC16CCITT(CODPayLoad), 4);
  result := CODPayLoad+CRC;
end;

procedure TFrmPrincipal.QrCodeMobile(imgQRCode: TImage; texto: string);
const
    downsizeQuality: Integer = 2; // bigger value, better quality, slower rendering
var
    QRCode: TDelphiZXingQRCode;
    Row, Column: Integer;
    pixelColor : TAlphaColor;
    vBitMapData : TBitmapData;
    pixelCount, y, x: Integer;
    columnPixel, rowPixel: Integer;

    function GetPixelCount(AWidth, AHeight: Single): Integer;
    begin
        if QRCode.Rows > 0 then
          Result := Trunc(Min(AWidth, AHeight)) div QRCode.Rows
        else
          Result := 0;
    end;
begin
    // Not a good idea to stretch the QR Code...
    if imgQRCode.WrapMode = TImageWrapMode.Stretch then
        imgQRCode.WrapMode := TImageWrapMode.Fit;


    QRCode := TDelphiZXingQRCode.Create;

    try
        QRCode.Data := '  ' + texto;
        QRCode.Encoding := TQRCodeEncoding.qrAuto;
        QRCode.QuietZone := 4;
        pixelCount := GetPixelCount(imgQRCode.Width, imgQRCode.Height);

        case imgQRCode.WrapMode of
            TImageWrapMode.Original,
            TImageWrapMode.Tile,
            TImageWrapMode.Center:
            begin
                if pixelCount > 0 then
                    imgQRCode.Bitmap.SetSize(QRCode.Columns * pixelCount,
                    QRCode.Rows * pixelCount);
            end;

            TImageWrapMode.fit:
            begin
                if pixelCount > 0 then
                begin
                    imgQRCode.Bitmap.SetSize(QRCode.Columns * pixelCount * downsizeQuality,
                        QRCode.Rows * pixelCount * downsizeQuality);
                    pixelCount := pixelCount * downsizeQuality;
                end;
            end;

            //TImageWrapMode.iwStretch:
            //    raise Exception.Create('Not a good idea to stretch the QR Code');
        end;
        if imgQRCode.Bitmap.Canvas.BeginScene then
        begin
            try
                imgQRCode.Bitmap.Canvas.Clear(TAlphaColors.White);
                if pixelCount > 0 then
                begin
                      if imgQRCode.Bitmap.Map(TMapAccess.Write, vBitMapData)  then
                      begin
                            try
                                 For Row := 0 to QRCode.Rows - 1 do
                                 begin
                                    for Column := 0 to QRCode.Columns - 1 do
                                    begin
                                        if (QRCode.IsBlack[Row, Column]) then
                                            pixelColor := TAlphaColors.Black
                                        else
                                            pixelColor := TAlphaColors.White;

                                        columnPixel := Column * pixelCount;
                                        rowPixel := Row * pixelCount;

                                        for x := 0 to pixelCount - 1 do
                                            for y := 0 to pixelCount - 1 do
                                                vBitMapData.SetPixel(columnPixel + x,
                                                    rowPixel + y, pixelColor);
                                    end;
                                 end;
                            finally
                              imgQRCode.Bitmap.Unmap(vBitMapData);
                            end;
                      end;
                end;
            finally
                imgQRCode.Bitmap.Canvas.EndScene;
          end;
        end;
    finally
        QRCode.Free;
    end;
end;

procedure TFrmPrincipal.QRCodeWin(imgQRCode: TImage; texto: string);
var
  QRCode: TDelphiZXingQRCode;
  Row, Column: Integer;
  pixelColor : TAlphaColor;
  vBitMapData : TBitmapData;
begin
    imgQRCode.DisableInterpolation := true;
    imgQRCode.WrapMode := TImageWrapMode.Stretch;

    QRCode := TDelphiZXingQRCode.Create;
    try
        QRCode.Data := texto;
        QRCode.Encoding := TQRCodeEncoding.qrAuto;
        QRCode.QuietZone := 4;
        imgQRCode.Bitmap.SetSize(QRCode.Rows, QRCode.Columns);

        for Row := 0 to QRCode.Rows - 1 do
        begin
            for Column := 0 to QRCode.Columns - 1 do
            begin
                if (QRCode.IsBlack[Row, Column]) then
                    pixelColor := TAlphaColors.Black
                else
                    pixelColor := TAlphaColors.White;

                if imgQRCode.Bitmap.Map(TMapAccess.Write, vBitMapData)  then
                try
                    vBitMapData.SetPixel(Column, Row, pixelColor);
                finally
                    imgQRCode.Bitmap.Unmap(vBitMapData);
                end;
            end;
        end;

    finally
        QRCode.Free;
    end;

end;

procedure TFrmPrincipal.Button1Click(Sender: TObject);
begin
  edtPayLoad.Text := '';
  edtPayLoad.Text:=PayLoad(edtChave.Text,edtBeneficiario.Text,edtCidade.Text,edtCodTrans.Text,StrToFloat(edtValor.Text));

  {$IFDEF MSWINDOWS}
  QRCodeWin(Image1, edtPayLoad.text);
  {$ELSE}
  QRCodeMobile(Image1, edtPayLoad.text);
  {$ENDIF}
 end;

end.
