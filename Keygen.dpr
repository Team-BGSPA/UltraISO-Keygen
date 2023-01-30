program Keygen;

uses
windows, messages, MiniFMOD, SysUtils, FGint;

procedure FGIntToHexString(const FGInt: TFGInt; var HexStr: String);
var
  S: String;
begin
  FGIntToBase256String(FGInt, S);
  ConvertBase256StringToHexString(S, HexStr);
end;

procedure HexStringToFGInt(const HexStr : String; var FGInt: TFGInt);
var
  S: String;
begin
  ConvertHexStringToBase256String(HexStr, S);
  Base256StringToFGInt(S, FGInt);
end;

function gen(const Name: String): String;
var
  FGI1, FGI2, FGI3, FGI4: TFGInt;
  I: LongWord;
begin
  Result := Copy(Name + StringOfChar(' ', 8 - Length(Name)), 1, 8);
  I := PLongWord(@Result[1])^ xor PLongWord(@Result[5])^ xor Random(MaxInt);
  Result := Format('55%.4X2C53%.4X4F', [I shr 16, I and $FFFF]);
  
  HexStringToFGInt(Result, FGI1);
  HexStringToFGInt('A70F8F62AA6E97D1', FGI2);
  HexStringToFGInt('A7CAD9177AE95A9', FGI3);
  FGIntModExp(FGI1, FGI3, FGI2, FGI4);
  FGIntToHexString(FGI4, Result);

  FGIntDestroy(FGI1);
  FGIntDestroy(FGI2);
  FGIntDestroy(FGI3);
  FGIntDestroy(FGI4);

  Insert('-', Result, 5);
  Insert('-', Result, 10);
  Insert('-', Result, 15);
end;

{$R rsrc\rsrc.res}

function dialog(handle, Msg, wParam, lParam: integer): integer; stdcall;
var
name: array[0..255]of char;
serial: string;
begin

result:=1;
if wParam=sc_close then enddialog(handle, 1);
Case msg of

WM_INITDIALOG:
begin
SetWindowText(handle, 'Team BGSPA - UltraISO 9.x Retail');
SetDlgItemText(handle, 999, 'UltraISO 9.x Retail');
SetDlgItemText(handle, 1200, 'Keygenned by Bang1338');
SetDlgItemText(handle, 1212, 'Protection: Custom');
XMPlayFromRes('XM', 'MUSIC');
end;
WM_COMMAND:
begin
case wparam of



1002: begin
getdlgitemtext(handle, 1000, name, 30);
serial:=gen(name);
setdlgitemtext(handle, 1001, pchar(serial));
end;



1003: enddialog(handle, 0);

end;
end;
else  result:=0;
end;
end;

begin


dialogbox(hInstance, 'RC', 0, @Dialog);
end.

