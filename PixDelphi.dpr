program PixDelphi;

uses
  System.StartUpCopy,
  FMX.Forms,
  uFrmPrincipal in 'uFrmPrincipal.pas' {FrmPrincipal},
  FMXDelphiZXIngQRCode in 'FMXDelphiZXIngQRCode.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
