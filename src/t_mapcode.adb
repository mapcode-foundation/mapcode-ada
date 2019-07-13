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
with As_U, Str_Tools, Mapcodes, Ctrynams;
procedure T_Mapcode is
  use Mapcodes;

  Argument_Error : exception;

  procedure Usage is
  begin
    Ada.Text_Io.Put_Line (
      "Usage: " & Ada.Command_Line.Command_Name & " <command>");
    Ada.Text_Io.Put_Line (
      "  -h                                             // This help");
    Ada.Text_Io.Put_Line (
      "  -t <territory>                                 // Territory info");
    Ada.Text_Io.Put_Line (
      "  -s <name>                                      // Search territory");
    Ada.Text_Io.Put_Line (
      "  -d  <territory_mapcode>                        // Decode");
    Ada.Text_Io.Put_Line (
      "  -c <lat> <lon> [ <options> ]                   // Encode");
    Ada.Text_Io.Put_Line (
      "  -a  <territory_mapcode> [ <options> ]          // Alternative mapcodes");
    Ada.Text_Io.Put_Line (
      "  <territory_mapcode> ::= <territory>:<mapcode> | [ <territory> ] <mapcode>");
    Ada.Text_Io.Put_Line (
      "  <options>           ::= [ <territory> ] [ <selection> ] [ <precision> ]");
    Ada.Text_Io.Put_Line (
      "  <selection>         ::= [ all | local | short] // Default short");
    Ada.Text_Io.Put_Line (
      "                      // Default: one mapcode (the shortest) of each territory");
    Ada.Text_Io.Put_Line (
      "                      // all: all the mapcodes of all territories");
    Ada.Text_Io.Put_Line (
      "                      // local: the shortest among all the mapcodes");
    Ada.Text_Io.Put_Line (
      "  <precision>         ::= P0 | P1 | P2       // Default P0");
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
    (Arg = "-h" or else Arg = "-t" or else Arg = "-c" or else Arg = "-d"
     or else Arg = "-a");

  function Image (F : Mapcodes.Real) return String is
  begin
    return F'Img;
  end Image;

  function Image (I : Natural) return String is
    Str : constant String := I'Img;
  begin
    return Str(Natural'Succ(Str'First) .. Str'Last);
  end Image;

  function Quote (Str : String) return String is
    (''' & Str & ''');

  function Get (Str : String) return Mapcodes.Real is
  begin
    return Mapcodes.Real'Value (Str);
  end Get;

  I : Positive;
  Command, Arg1, Arg2, Tmp : As_U.Asu_Us;

  Coord : Mapcodes.Coordinate;
  Territory : As_U.Asu_Us;
  Shortest : Boolean;
  Sorted : Boolean;
  Precision : Precisions;

  -- If Arg2 is a mapcde then parse Arg1=Ctx and Arg2=Map
  --  otherwise parse Arg1=[Ctx:]Map
  procedure Parse_Mapcode is
    Index : Natural;
  begin
    I := I + 1;
    Arg1 := As_U.Tus (Ada.Command_Line.Argument (I));
    Arg2.Set_Null;
    Tmp.Set_Null;
    if I < Ada.Command_Line.Argument_Count then
      Tmp := As_U.Tus (Ada.Command_Line.Argument (I + 1));
    end if;
    if Tmp.Locate (".") /= 0 then
      -- Arg2 is a mapcode
      Arg2 := Arg1;
      Arg1 := Tmp;
      I := I + 1;
    end if;
    -- Split <territory>:<mapcode> in Arg1
    if Arg2.Is_Null then
      Index := Arg1.Locate (":");
      if Index > 1 then
        Arg2 :=  Arg1.Head (Index - 1);
        Arg1.Delete (1, Index);
      end if;
    end if;
    Ada.Text_Io.Put_Line (Arg1.Image & " " & Arg2.Image);
  end Parse_Mapcode;

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
      -- Display territory info of next argument(s)
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
    elsif Command.Image = "-s" then
      -- Search contry names
      I := I + 1;
      Territory.Set (Str_Tools.Upper_Str (Ada.Command_Line.Argument (I)));
      for J in Ctrynams.Isofullname'Range loop
        if Str_Tools.Locate (Str_Tools.Upper_Str
                               (Ctrynams.Isofullname(J).Image),
                             Territory.Image) /= 0 then
          Put_Territory (Image (J-1), "");
        end if;
      end loop;
    elsif Command.Image = "-c"
    or else Command.Image = "-a" then
      if Command.Image = "-c" then
        -- Encode a lat lon
        -- Get coord lat and lon
        I := I + 1;
        Arg1 := As_U.Tus (Ada.Command_Line.Argument (I));
        Coord.Lat := Get (Arg1.Image);
        I := I + 1;
        Arg2 := As_U.Tus (Ada.Command_Line.Argument (I));
        Coord.Lon := Get (Arg2.Image);
        Ada.Text_Io.Put_Line (Image (Coord.Lat)
                      & " " & Image (Coord.Lon));
      else
        -- Alternative mapcodes
        Parse_Mapcode;
        Coord := Decode (Arg1.Image, Arg2.Image);
      end if;
      -- Parse options: Territory, selection and precsion
      Territory := As_U.Asu_Null;
      -- Default selection: One (shortest) mapcode for each territory,
      --  not sorted
      Shortest := True;
      Sorted := False;
      Precision := 0;
      for J in I + 1 .. Ada.Command_Line.Argument_Count loop
        Arg1 := As_U.Tus (Ada.Command_Line.Argument (J));
        exit when Is_Command (Arg1.Image);
        I := J;
        if Lower_Str (Arg1.Image) = "all" then
          -- All mapcodes for each territory, not sorted
          Shortest := False;
        elsif Lower_Str (Arg1.Image) = "local" then
          -- One (shortest) mapcode for each territory,
          --  sorted i.o. to put the first one
          Sorted := True;
        elsif Lower_Str (Arg1.Image) = "short" then
          null;
        elsif Arg1.Length = 2
        and then Arg1.Element (1) = 'P'
        and then Arg1.Element (2) >= '0'
        and then Arg1.Element (2) <= '2' then
          Precision := Precisions'Value (Arg1.Slice (2, 2));
        else
          Territory := Arg1;
        end if;
      end loop;
      -- Put mapcodes
      declare
        procedure Put_Code (Code : Mapcodes.Mapcode_Info) is
        begin
          Ada.Text_Io.Put_Line ("=> "
            & Code.Territory_Alpha_Code.Image
            & " " &  Code.Mapcode.Image
            & " " & Quote (Code.Full_Mapcode.Image)
            & " " & Integer_Image (Code.Territory_Number));
        end Put_Code;
        -- Sort if Local
        Codes : constant Mapcodes.Mapcode_Infos
              := Encode (Coord, Territory.Image, Shortest, Precision, Sorted);
      begin
        if Sorted then
          -- Local <=> Sorted, put the first one
          -- First mapcode is the shortest, and then others of the same
          --  territory and then others...
          if Codes'Length /= 0 then
            Put_Code (Codes(Codes'First));
          end if;
        else
          for Code of Codes loop
            Put_Code (Code);
          end loop;
        end if;
      end;
      Ada.Text_Io.New_Line;
    elsif Command.Image = "-d" then
      -- Decode: next argument is mapcode, optionally preceeded by a context
      Parse_Mapcode;
      -- Decode
      Coord := Decode (Arg1.Image, Arg2.Image);
      Ada.Text_Io.Put_Line ("=> " & Image (Coord.Lat)
                          & " " & Image (Coord.Lon));
    else
      raise Argument_Error;
    end if;
    I := I + 1;
  end loop;
  Ada.Command_Line.Set_Exit_Status (0);
exception
  when Mapcodes.Unknown_Territory =>
    Ada.Text_Io.Put_Line (Ada.Text_Io.Standard_Error,
                          "Raised Unknown_Territory");
    Ada.Command_Line.Set_Exit_Status (1);
  when Mapcodes.Decode_Error =>
    Ada.Text_Io.Put_Line (Ada.Text_Io.Standard_Error, "Raised Decode_Error");
    Ada.Command_Line.Set_Exit_Status (1);
  when Argument_Error =>
    Ada.Text_Io.Put_Line (Ada.Text_Io.Standard_Error, "Invalid Argument");
    Ada.Command_Line.Set_Exit_Status (2);
  when others =>
    Ada.Command_Line.Set_Exit_Status (2);
    raise;
end T_Mapcode;

