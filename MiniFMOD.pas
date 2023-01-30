{
  MiniFMOD 1.7 is a free C library from Fairlight
  Technologies (http://www.fmod.org) which allows
  you to play .XM files. Compiled into a .OBJ,
  it is then possible to use it in any language
  that supports OMF .OBJ files.

  Here is the Delphi header I made for it.

  Twis (June 2004).
}

unit MiniFMOD;

interface

uses
  Windows;

type
  TMemoryFile = record
    Length: Cardinal;
    Position: Cardinal;
    Data: Pointer;
  end;
  PMemoryFile = ^TMemoryFile;
  PMUSICMODULE = Pointer;

const
  // this is for the callbacks
  SEEK_SET = 0;
  SEEK_CUR = 1;
  SEEK_END = 2;

var
  Module: PMUSICMODULE = nil;
  _ResName, _ResType: PChar;
  __turboFloat: Integer;

// functions from MiniFMOD

procedure _FSOUND_File_SetCallbacks(OpenCallback, CloseCallback, ReadCallback, SeekCallback, TellCallback: Pointer); cdecl;
function _FMUSIC_LoadSong(Name: PChar; SampleLoadCallback: Pointer): PMUSICMODULE; cdecl;
function _FMUSIC_FreeSong(Module: PMUSICMODULE): ByteBool; cdecl;
function _FMUSIC_PlaySong(Module: PMUSICMODULE): ByteBool; cdecl;
function _FMUSIC_StopSong(Module: PMUSICMODULE): ByteBool; cdecl;
function _FMUSIC_GetOrder(Module: PMUSICMODULE): Integer; cdecl;
function _FMUSIC_GetRow(Module: PMUSICMODULE): Integer; cdecl;
function _FMUSIC_GetTime(Module: PMUSICMODULE): Cardinal; cdecl;

// functions I added

procedure XMPlayFromRes(ResName, ResType: PChar);
procedure XMFree();
                                        
implementation

{$L MiniFMOD.obj}

{
  C functions which are not included in the .OBJ, so
  we need to reprogram them here.
}

function _memcpy(Destination: Pointer; Source: Pointer; Count: Cardinal): Pointer; cdecl;
begin
  CopyMemory(Destination, Source, Count);
  Result := Destination;
end;

function _memset(Destination: Pointer; C: Integer; Count: Cardinal): Pointer; cdecl;
begin
  FillMemory(Destination, Count, C);
  Result := Destination;
end;

function _calloc(Number: Cardinal; Size: Cardinal): Pointer; cdecl;
begin
  GetMem(Result, Number * Size);
  ZeroMemory(Result, Number * Size);
end;

procedure _free(Block: Pointer); cdecl;
begin
  FreeMem(Block);
end;

procedure __ftol;
asm
  push          eax
  fistp         dword ptr [esp]
  fwait
  pop           eax
end;

procedure _fabs;
asm
  fld           qword ptr [esp + 4]
  fabs
  fwait
end;

procedure _sin;
asm
  fld           qword ptr [esp + 4]
  fsin
  fwait
end;

procedure _abs;
asm
  mov           eax, dword ptr [esp + 4]
  test          eax, $80000000
  jz            @Exit
  neg           eax
  @Exit:
end;

procedure _pow;
asm
  fld           qword ptr [esp + 12]
  fld           qword ptr [esp + 4]
  fyl2x
  fld           ST(0)
  frndint
  fsub          ST(1), ST
  fxch          ST(1)
  f2xm1
  fld1
  fadd
  fscale
  fstp          ST(1)
  fwait
end;

{
  here comes the callback functions when playing from a resource
}

function MemFile_OpenCallback(Name: PChar): PMemoryFile; cdecl;
var
  ResParam: HRSRC;
  ResHandle: HGLOBAL;
begin
  New(Result);
  ResParam := FindResource(hInstance, Name, _ResType);
  ResHandle := LoadResource(hInstance, ResParam);
  Result.Length := SizeOfResource(hInstance, ResParam);
  Result.Data := LockResource(ResHandle);
  Result.Position := 0;
end;

procedure MemFile_CloseCallback(MemFile: PMemoryFile); cdecl;
begin
  Dispose(MemFile);
end;

function MemFile_ReadCallback(Buffer: Pointer; Size: Cardinal; MemFile: PMemoryFile): Integer; cdecl;
begin
  if MemFile.Position + Size >= MemFile.Length then
    Size := MemFile.Length - MemFile.Position;
  CopyMemory(Buffer, Pointer(Cardinal(MemFile.Data) + MemFile.Position), Size);
  MemFile.Position := MemFile.Position + Size;
  Result := Size;
end;

procedure MemFile_SeekCallback(MemFile: PMemoryFile; Position: Integer; Mode: Byte); cdecl;
begin
  case Mode of
    SEEK_SET: MemFile.Position := Position;
    SEEK_CUR: MemFile.Position := Integer(MemFile.Position) + Position;
    SEEK_END: MemFile.Position := Integer(MemFile.Length) + Position;
  end;
  if MemFile.Position > MemFile.Length then
    MemFile.Position := MemFile.Length;
end;

function MemFile_TellCallback(MemFile: PMemoryFile): Integer; cdecl;
begin
  Result := MemFile.Position;
end;

{
  some imports (waveout API)
}

function waveOutOpen: DWORD; stdcall; external 'winmm.dll';
function waveOutClose: DWORD; stdcall; external 'winmm.dll';
function waveOutPrepareHeader: DWORD; stdcall; external 'winmm.dll';
function waveOutUnprepareHeader: DWORD; stdcall; external 'winmm.dll';
function waveOutWrite: DWORD; stdcall; external 'winmm.dll';
function waveOutReset: DWORD; stdcall; external 'winmm.dll';
function waveOutGetPosition: DWORD; stdcall; external 'winmm.dll';

{
  functions from MiniFMOD
}

procedure _FSOUND_File_SetCallbacks; external;
function _FMUSIC_LoadSong; external;
function _FMUSIC_FreeSong; external;
function _FMUSIC_PlaySong; external;
function _FMUSIC_StopSong; external;
function _FMUSIC_GetOrder; external;
function _FMUSIC_GetRow; external;
function _FMUSIC_GetTime; external;

{
  here we go with the functions we will use
  from outside this unit
}

procedure XMPlayFromRes(ResName, ResType: PChar);
begin
  if Module <> nil then Exit;
  _ResName := ResName;
  _ResType := ResType;
  _FSOUND_File_SetCallbacks(@MemFile_OpenCallback, @MemFile_CloseCallback,
    @MemFile_ReadCallback, @MemFile_SeekCallback, @MemFile_TellCallback);
  Module := _FMUSIC_LoadSong(ResName, nil);
  _FMUSIC_PlaySong(Module);
end;

procedure XMFree();
begin
  _FMUSIC_FreeSong(Module);
  Module := nil;
end;

end.
