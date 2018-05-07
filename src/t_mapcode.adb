-- -----------------------------------------------------------------------------
-- Copyright (C) 2003-2018 Stichting Mapcode Foundation (http://www.mapcode.com)
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--    http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- -----------------------------------------------------------------------------

-- Mapcode test main program
with Ada.Command_Line, Ada.Text_Io;
with As_U, Str_Tools, Mapcodes;
procedure T_Mapcode is
  use Mapcodes;

  procedure Usage is
  begin
    Ada.Text_Io.Put_Line (
      "Usage: " & Ada.Command_Line.Command_Name & " <command>");
    Ada.Text_Io.Put_Line (
      "  -h                            // This help");
    Ada.Text_Io.Put_Line (
      "  -t <territory>                // Territory info");
    Ada.Text_Io.Put_Line (
      "  -d <mapcode> [ <territory> ]  // Decode");
    Ada.Text_Io.Put_Line (
      "  -c <lat> <lon> [ <options> ]  // Encode");
    Ada.Text_Io.Put_Line (
      "  <options> ::= [ <territory> ] [ <shortest> ] [ <precision> ]");
  end Usage;

  function Integer_Image (I : Integer) return String is
    Str : constant String := I'Img;
  begin
    if Str(Str'First) /= ' ' then
      return Str;
    else
      return Str (Integer'Succ (Str'First) .. Str'Last);
    end if;
  end Integer_Image;

  function Lower_Str (Str : String) return String is
    Offset  : constant Integer   := Character'Pos('A') - Character'Pos('a');
    Result : String := Str;
  begin
    for C of Result loop
      C := (if C not in 'A' .. 'Z' then C
          else Character'Val (Character'Pos(C) - Offset));
    end loop;
    return Result;
  end Lower_Str;

  procedure Put_Territory (Territory, Context : in String) is
    Index : Mapcodes.Territory_Range;
  begin
    Ada.Text_Io.Put (Territory
                   & (if Context /= "" then " " else "")
                   & Context &  " ");
    Index := Get_Territory_Number (Territory, Context);
    Ada.Text_Io.Put_Line ("=> " & Integer_Image (Index)
      & ": " & Get_Territory_Alpha_Code (Index, Mapcodes.Local)
      & "/" & Get_Territory_Alpha_Code (Index, Mapcodes.International)
      & "/" & Get_Territory_Alpha_Code (Index, Mapcodes.Shortest)
      & "/" & Get_Territory_Fullname (Index) );
    if Is_Subdivision (Index) then
      Ada.Text_Io.Put_Line ("Parent: "
          & Get_Territory_Alpha_Code (Get_Parent_Of (Index)));
    end if;
    if Has_Subdivision (Index) then
      Ada.Text_Io.Put_Line ( "Has subdivisions");
    end if;
  end Put_Territory;

  function Is_Command (Arg : in String) return Boolean is
    (Arg = "-h" or else Arg = "-t" or else Arg = "-c" or else Arg = "-d");

  function Image (F : Mapcodes.Real) return String is
  begin
    return F'Img;
  end Image;

  function Quote (Str : String) return String is
    ( (if Str_Tools.Locate (Str, " ") = 0 then Str else ''' & Str & ''') );

  function Get (Str : String) return Mapcodes.Real is
  begin
    return Mapcodes.Real'Value (Str);
  end Get;

  I : Positive;
  Command, Arg1, Arg2 : As_U.Asu_Us;

  Coord : Mapcodes.Coordinate;
  Territory : As_U.Asu_Us;
  Shortest : Boolean;
  Precision : Precisions;
begin
  if Ada.Command_Line.Argument_Count = 0 then
    Usage;
  end if;
  I := 1;
  while I <= Ada.Command_Line.Argument_Count loop
    Command := As_U.Tus (Ada.Command_Line.Argument (I));
    if Command.Image = "-h" then
      Usage;
    elsif Command.Image = "-t" then
      -- Display territory info of next argument
      I := I + 1;
      Arg1 := As_U.Tus (Ada.Command_Line.Argument (I));
      if I < Ada.Command_Line.Argument_Count then
        Arg2 := As_U.Tus (Ada.Command_Line.Argument (I + 1));
        if Is_Command (Arg2.Image) then
          Arg2.Set_Null;
        else
          I := I + 1;
        end if;
      end if;
      Put_Territory (Arg1.Image, Arg2.Image);
    elsif Command.Image = "-c" then
      I := I + 1;
      Arg1 := As_U.Tus (Ada.Command_Line.Argument (I));
      Coord.Lat := Get (Arg1.Image);
      I := I + 1;
      Arg2 := As_U.Tus (Ada.Command_Line.Argument (I));
      Coord.Lon := Get (Arg2.Image);
      Territory := As_U.Asu_Null;
      Shortest := True;
      Precision := 0;
      for J in I + 1 .. Ada.Command_Line.Argument_Count loop
        Arg1 := As_U.Tus (Ada.Command_Line.Argument (J));
        exit when Is_Command (Arg1.Image);
        I := J;
        if Lower_Str (Arg1.Image) = "true"
        or else Lower_Str (Arg1.Image) = "false" then
          Shortest := Boolean'Value (Arg1.Image);
        elsif Arg1.Length = 1
        and then Arg1.Element (1) >= '0'
        and then Arg1.Element (1) <= '2' then
          Precision := Precisions'Value (Arg1.Image);
        else
          Territory := Arg1;
        end if;
      end loop;
      Ada.Text_Io.Put_Line (Image (Coord.Lat)
                                & " " & Image (Coord.Lon));
      declare
        Codes : constant Mapcodes.Mapcode_Infos
              := Encode (Coord, Territory.Image, Shortest, Precision);
      begin
        for J in Codes'Range loop
          Ada.Text_Io.Put_Line ("=> "
            &  Codes(J).Mapcode.Image
            & " " & Codes(J).Territory_Alpha_Code.Image
            & " " & Quote (Codes(J).Full_Mapcode.Image)
            & " " & Integer_Image (Codes(J).Territory_Number));
        end loop;
      end;
      Ada.Text_Io.New_Line;
    elsif Command.Image = "-d" then
      -- Decode next argument, optionally with context
      I := I + 1;
      Arg1 := As_U.Tus (Ada.Command_Line.Argument (I));
      Arg2.Set_Null;
      if I < Ada.Command_Line.Argument_Count then
        Arg2 := As_U.Tus (Ada.Command_Line.Argument (I + 1));
        if Is_Command (Arg2.Image) then
          Arg2.Set_Null;
        else
          I := I + 1;
        end if;
      end if;
      Coord := Decode (Arg1.Image, Arg2.Image);
      Ada.Text_Io.Put_Line ("=> " & Image (Coord.Lat)
                                & " " & Image (Coord.Lon));
    end if;
    I := I + 1;
  end loop;
  Ada.Command_Line.Set_Exit_Status (0);
exception
  when Mapcodes.Unknown_Territory =>
    Ada.Text_Io.Put_Line ("Raised Unknown_Territory");
    Ada.Command_Line.Set_Exit_Status (1);
  when Mapcodes.Decode_Error =>
    Ada.Text_Io.Put_Line ("Raised Decode_Error");
    Ada.Command_Line.Set_Exit_Status (1);
  when others =>
    Ada.Command_Line.Set_Exit_Status (2);
    raise;
end T_Mapcode;

