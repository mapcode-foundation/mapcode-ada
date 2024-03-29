-- -----------------------------------------------------------------------------
-- Copyright (C) 2003-2019 Stichting Mapcode Foundation (http://www.mapcode.com)
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

with Ada.Characters.Handling;
with Mapcode_Utils.Str_Tools, Mapcode_Utils.Bits;
use Mapcode_Utils;
with Mapcodes.Languages;
with Ndata;
package body Mapcodes is

  subtype Lint is Long_Long_Integer;

  -- All functions returning a Integer return a natural or Error
  Error : constant Integer := -1;

  -- All functions returning a string may return Undefined, on error
  Undefined : constant String := "";

  subtype Country_Range is Positive range Countries.Territories_Def'Range;
  function Iso3166Alpha_Of (Index : Natural) return String is
  begin
    if Index + 1 <= Country_Range'Last then
      return Countries.Territories_Def(Index + 1).Code.Image;
    else
      return Undefined;
    end if;
  end Iso3166Alpha_Of;

  Aliases : constant String :=
    "2UK=2UT,2CG=2CT,1GU=GUM,1UM=UMI,1VI=VIR,1AS=ASM,1MP=MNP,4CX=CXR,4CC=CCK,"
  & "4NF=NFK,4HM=HMD,COL=5CL,5ME=5MX,MEX=5MX,5AG=AGU,5BC=BCN,5BS=BCS,5CM=CAM,"
  & "5CS=CHP,5CH=CHH,5CO=COA,5DF=DIF,5DG=DUR,5GT=GUA,5GR=GRO,5HG=HID,5JA=JAL,"
  & "5MI=MIC,5MO=MOR,5NA=NAY,5NL=NLE,5OA=OAX,5PB=PUE,5QE=QUE,5QR=ROO,5SL=SLP,"
  & "5SI=SIN,5SO=SON,5TB=TAB,5TL=TLA,5VE=VER,5YU=YUC,5ZA=ZAC,811=8BJ,812=8TJ,"
  & "813=8HE,814=8SX,815=8NM,821=8LN,822=8JL,823=8HL,831=8SH,832=8JS,833=8ZJ,"
  & "834=8AH,835=8FJ,836=8JX,837=8SD,841=8HA,842=8HB,843=8HN,844=8GD,845=8GX,"
  & "846=8HI,850=8CQ,851=8SC,852=8GZ,853=8YN,854=8XZ,861=8SN,862=8GS,863=8QH,"
  & "864=8NX,865=8XJ,871=TWN,891=HKG,892=MAC,8TW=TWN,8HK=HKG,8MC=MAC,BEL=7BE,"
  & "KIR=7KI,PRI=7PO,CHE=7CH,KHM=7KM,PER=7PM,TAM=7TT,0US=USA,0AU=AUS,0RU=RUS,"
  & "0CN=CHN,TAA=SHN,ASC=SHN,DGA=IOT,WAK=MHL,JTN=UMI,MID=1HI,1PR=PRI,5TM=TAM,"
  & "TAM=TAM,2OD=2OR,";

  Usa_From : constant := 343;
  Usa_Upto : constant := 393;
  Ccode_Usa : constant := 410;
  Ind_From : constant := 271;
  Ind_Upto : constant := 306;
  Ccode_Ind : constant := 407;
  Can_From : constant := 394;
  Can_Upto : constant := 406;
  Ccode_Can : constant := 495;
  Aus_From : constant := 307;
  Aus_Upto : constant := 315;
  Ccode_Aus : constant := 408;
  Mex_From : constant := 233;
  Mex_Upto : constant := 264;
  Ccode_Mex : constant := 411;
  Bra_From : constant := 316;
  Bra_Upto : constant := 342;
  Ccode_Bra : constant := 409;
  Chn_From : constant := 497;
  Chn_Upto : constant := 527;
  Ccode_Chn : constant := 528;
  Rus_From : constant := 412;
  Rus_Upto : constant := 494;
  Ccode_Rus : constant := 496;
  Ccode_Earth : constant := 532;

  -- Parent territories
  Parent_Length : constant := 8;
  subtype String3 is String (1 .. 3);
  Parents3 : constant array (1 .. Parent_Length) of String3
           := ("USA", "IND", "CAN", "AUS", "MEX", "BRA", "RUS", "CHN");
  subtype String2 is String (1 .. 2);
  Parents2 : constant array (1 .. Parent_Length) of String2
           := ("US", "IN", "CA", "AU", "MX", "BR", "RU", "CN");

  -- Returns 2-letter parent country abbreviation (disam in range 1..8)
  function Parent_Name2 (Disam : Positive) return String is
    (Parents2 (Disam));

  -- Given a parent country abbreviation, return disam (in range 1-8) or
  --  Error
  function Parent_Letter (Territory_Alpha_Code : String) return Integer is
    Srch : constant String := Str_Tools.Upper_Str (Territory_Alpha_Code);
  begin
    if Srch'Length = 2 then
      for I in Parents2'Range loop
        if Srch = Parents2(I) then
          return I;
        end if;
      end loop;
    elsif Srch'Length = 3 then
      for I in Parents3'Range loop
        if Srch = Parents3(I) then
          return I;
        end if;
      end loop;
    end if;
   return Error;
  end Parent_Letter;

  function Image (I : Integer) return String is
    Str : constant String := I'Img;
  begin
    return (if Str(Str'First) /= ' ' then Str
            else Str (Integer'Succ(Str'First) .. Str'Last));
  end Image;

  -- Returns alias of ISO abbreviation (if any), or empty
  function Alias2Iso (Territory_Alpha_Code : String) return String is
    -- Look for "DigitCrit="
    function Match (Crit, Within : String) return Natural is
      Occ : Positive := 1;
      I : Natural;
    begin
      loop
        I := Str_Tools.Locate (Within, Crit, Occurence => Occ);
        exit when I = 0;
        if I > 1 and then Within(I - 1) >= '0'
        and then Within(I - 1) <= '9' then
          return I - 1;
        end if;
        Occ := Occ + 1;
      end loop;
      return 0;
    end Match;
    Index : Natural;
  begin
    Index := (if Territory_Alpha_Code'Length = 2 then
               Match (Territory_Alpha_Code & "=", Aliases)
              else Str_Tools.Locate (Aliases, Territory_Alpha_Code & "="));
    if Index /= 0 then
      return Aliases (Index + 4 .. Index + 6);
    else
      return Undefined;
     end if;
  end Alias2Iso;

  -- Given ISO code, return Territory_Number or Error
  function Find_Iso (Territory_Alpha_Code : String) return Integer is
  begin
    for I in Country_Range loop
      if Countries.Territories_Def(I).Code.Image = Territory_Alpha_Code then
        return I - 1;
      end if;
    end loop;
    return Error;
  end Find_Iso;

  -- Given ISO code, return territoryNumber or Error
  function Iso2Ccode (Alpha_Code : String;
                      Context : in String) return Integer is

    function Is_Digit (Char : Character) return Boolean is
      (Char >= '0' and then Char <= '9');
    function Is_Digits (Str : String) return Boolean is
    begin
      for I in Str'Range loop
        if not Is_Digit (Str(I)) then
          return False;
        end if;
      end loop;
      return Str /= "";
    end Is_Digits;

    N, Sep : Natural;
    P, Tmpp : Integer;
    Result, Index : Integer;
    Isoa : As_U.Asu_Us;
    Code2Search, Context2Search : As_U.Asu_Us;
    Hyphenated : As_U.Asu_Us;
    use all type As_U.Asu_Us;
  begin
    if Alpha_Code = Undefined then
      return Error;
    end if;
    P := Parent_Letter (Context);
    if P = Error and then Context /= "" and then Context /= "AAA" then
      return Error;
    end if;

    Sep := Str_Tools.Locate (Alpha_Code, "-");
    Code2Search := Tus (Str_Tools.Upper_Str (Alpha_Code));

    if P /= Error and then Sep /= 0 then
      -- Cannot provide a context together with territory-subdivision
      return Error;
    end if;

    -- Optims: direct number or code
    if P = Error and then Sep = 0 then
      -- Direct territory number
      if Is_Digits (Code2Search.Image) then
        N := Natural'Value (Code2Search.Image);
        if N <= Ccode_Earth then
          return N;
        end if;
      end if;

      -- Check if a simple territory
      if Code2Search.Length = 3 then
        Index := Find_Iso (Code2Search.Image);
        if Index /= Error then
          return Index;
        end if;
      end if;

      -- Find unique occurence of subdivision in ANY context
      if Code2Search.Length >= 2 then
        Hyphenated := Tus ("-") & Code2Search;
        Result := Error;
        for I in Country_Range loop
          Index := Str_Tools.Locate (Countries.Territories_Def(I).Code.Image,
                                     Hyphenated.Image);
          if Index > 0
          and then Index = Countries.Territories_Def(I).Code.Length
                         - Hyphenated.Length + 1 then
            -- iso3166alpha ends by Hyphenated
            if Result /= Error then
              -- Not unique
              return Error;
            else
              Result := I - 1;
            end if;
          end if;
        end loop;
        if Result /= Error then
          return Result;
        end if;
      end if;
    end if;

    -- Set Context and Code for search
    if Context /= "" then
      -- Context provided
      Context2Search.Set (Context);
    elsif Sep /= 0 then
      -- Code contains a prefix
      Context2Search := Code2Search.Uslice (1, Sep - 1);
      Code2Search.Delete (1, Sep);
      P := Parent_Letter (Context2Search.Image);
      if P = Error and then Context2Search.Image /= "AAA" then
        return Error;
      end if;
    end if;
    -- Sanity check
    if Code2Search.Length /= 2 and then Code2Search.Length /= 3 then
      return Error;
    end if;

    -- Optim: search this prefix and code
    if P /= Error then
      Index := Find_Iso (Parent_Name2 (P) & "-" & Code2Search.Image);
      if Index /= Error then
        return Index;
      end if;
    end if;

    -- Resolve alias
    if P /= Error then
      -- Alias for a subdivision with context
      Isoa := Tus (Alias2Iso (Image (P) & Code2Search.Image));
    end if;
    if Isoa.Is_Null and then Code2Search.Length = 3 then
      -- Alias for a territory or subdivision without context
      Isoa := Tus (Alias2Iso (Code2Search.Image));
    end if;
    if Isoa.Is_Null then
      Index := Error;
    else
      if Is_Digit (Isoa.Element (1)) then
        -- Alias is a subdivision
        Code2Search := Isoa.Uslice (2, Isoa.Length);
        Tmpp := Integer'Value (Isoa.Slice (1, 1));
        if P /= Error and then Tmpp /= P then
          -- Cannot change territory through aliasing
          return Error;
        end if;
        P := Tmpp;
        Index := Find_Iso (Parent_Name2 (P) & "-" & Code2Search.Image);
      else
        -- Alias is a subdivision or territory
        Code2Search := Isoa;
        -- Search for a territory
        Index := Find_Iso (Code2Search.Image);
        if Index = Error and then P /= Error then
          -- Search for a subdivision
          Index := Find_Iso (Parent_Name2 (P) & "-" & Code2Search.Image);
        end if;
      end if;
    end if;

    -- Return valid result
    if Index /= Error then
      return Index;
    end if;
    if P /= Error then
      -- With a context, the search shall have succeded
      return Error;
    end if;

    -- All else failed, try non-disambiguated alphacode
    Isoa := Tus (Alias2Iso (Code2Search.Image));
    if not Isoa.Is_Null then
      if Is_Digit (Isoa.Element (1)) then
        -- Starts with digit
        Code2Search := Tus (Parent_Name2 (Natural'Value (Isoa.Slice (1, 1)))
                     & "-" & Isoa.Slice (2, Isoa.Length));
      else
        Code2Search := Isoa;
      end if;
      return Iso2Ccode (Code2Search.Image, Context);
    end if;

    return Error;
  end Iso2Ccode;

  -- Image of a territory (index starting at 0 for VAT)
  function Get_Territory_Number (Territory : Territories) return String is
    (Image (Integer (Territory)));

  -- Given an alphacode (such As_US-AL), returns the territory number
  --  or Error.
  -- A context_Territory number helps to interpret ambiguous (abbreviated)
  --  AlphaCodes, such as "AL"
  function Get_Territory (Territory_Code : String;
                          Context : in String := "") return Territories is
    Num : Integer;
  begin
    Num := Iso2Ccode (Territory_Code, Context);
    if Num = Error then
      raise Unknown_Territory;
    end if;
    return Territories (Num);
  end Get_Territory;

  -- Return full name of territory
  function Get_Territory_Fullname (Territory: in Territories)
           return String is
    Name : As_U.Asu_Us;
    Index : Natural;
  begin
    Name := Countries.Territories_Def(Positive (Territory) + 1).Name;
    Index := Str_Tools.Locate (Name.Image, " (");
    if Index > 0 then
      return Name.Slice (1, Index - 1);
    else
      return Name.Image;
    end if;
  end Get_Territory_Fullname;

  -- Return the AlphaCode (usually an ISO 3166 code) of a territory
  -- Format: Local (often ambiguous), International (full and unambiguous,
  --  DEFAULT), or Shortest
  function Get_Territory_Alpha_Code (
    Territory : Territories;
    Format : Territory_Formats := International) return String is
    Full : constant String := Iso3166Alpha_Of (Natural (Territory));
    Iso : As_U.Asu_Us;
    Hyphen, Index : Natural;
    Short : As_U.Asu_Us;
    Count : Natural;
  begin
    Hyphen := Str_Tools.Locate (Full, "-");
    if Format = International or else Hyphen = 0 then
      -- Format full or no hyphen
      return Full;
    end if;
    Short := As_U.Tus (Full(Hyphen + 1 .. Full'Last));
    if Format = Local then
      -- Format local
      return Short.Image;
    end if;
    -- Shortest possible
    -- Keep parent if it has aliases or if territory occurs multiple times
    Count := 0;
    if Str_Tools.Locate (Aliases, Short.Image & "=") > 0 then
      Count := 2;
    else
      for I in Country_Range loop
        Iso := As_U.Tus (Iso3166Alpha_Of (I));
        Index := Str_Tools.Locate (Iso.Image, "-" & Short.Image);
        if Index > 0 and then Index + Short.Length = Iso.Length then
          Count := Count + 1;
          exit when Count = 2;
        end if;
      end loop;
    end if;
    return (if Count = 1 then Short.Image else Full);
  end Get_Territory_Alpha_Code;

  -- Return parent country of subdivision or error (if territory is not a
  --  subdivision)
  function Get_Parent (Territory : Territories)
           return Integer is
  begin
   return (case Territory is
     when Usa_From .. Usa_Upto => Ccode_Usa,
     when Ind_From .. Ind_Upto => Ccode_Ind,
     when Can_From .. Can_Upto => Ccode_Can,
     when Aus_From .. Aus_Upto => Ccode_Aus,
     when Mex_From .. Mex_Upto => Ccode_Mex,
     when Bra_From .. Bra_Upto => Ccode_Bra,
     when Rus_From .. Rus_Upto => Ccode_Rus,
     when Chn_From .. Chn_Upto => Ccode_Chn,
     when others               => Error);
  end Get_Parent;

  function Get_Parent_Of (Territory : Territories) return Territories is
    Code : constant Integer := Get_Parent (Territory);
  begin
    if Code = Error then
      raise Not_A_Subdivision;
    else
      return Territories (Code);
    end if;
  end Get_Parent_Of;

  -- Return True if Territory is a state
  function Is_Subdivision (Territory : Territories)
           return Boolean is
      (Get_Parent (Territory) /= Error);

  -- Return True if Territory is a country that has states
  function Has_Subdivision (Territory : Territories)
           return Boolean is
    Code : constant String := Get_Territory_Alpha_Code (Territory);
  begin
    for Parent of Parents3 loop
      if Code = Parent then
        return True;
      end if;
    end loop;
    return False;
  end Has_Subdivision;

  -- Given a subdivision, return the array of subdivisions with same name
  --  with various parents
  function Get_Subdivisions_With (Subdivision : String)
           return Territories_Array is
    Upper_Subd : constant String := Str_Tools.Upper_Str (Subdivision);
    Ccodes : array (1 .. Parent_Length) of Integer;
    Nb_Ok : Natural := 0;
  begin
    -- Count and store valid combinations of a Parent and this subdivision
    for I in Parents2'Range loop
      Ccodes(I) := Iso2Ccode (Upper_Subd, Parents2(I));
      if Ccodes(I) /= Error then
        Nb_Ok := Nb_Ok + 1;
      end if;
    end loop;
    -- Return array of valid combinations
    return Result : Territories_Array (1 .. Nb_Ok) do
      Nb_Ok := 0;
      for Ccode of Ccodes loop
        if Ccode /= Error then
          Nb_Ok := Nb_Ok + 1;
          Result(Nb_Ok) := Territories (Ccode);
        end if;
      end loop;
    end return;
  end Get_Subdivisions_With;

  -- Low-level routines for data access
  type Min_Max_Rec is record
     Minx, Miny, Maxx, Maxy : Lint;
  end record;

  function Data_First_Record (Territory_Number : Natural) return Integer is
  begin
    return Ndata.Data_Start(Territory_Number + 1);
  exception
    when others => return Error;
  end Data_First_Record;

  function Data_Last_Record (Territory_Number : Natural) return Integer is
  begin
    return Ndata.Data_Start(Territory_Number + 2) - 1;
  exception
    when others => return Error;
  end Data_Last_Record;

  function Min_Max_Setup (I : Natural) return Min_Max_Rec is
    Short_Maxy : constant array (Positive range <>) of Natural
               := (0, 122309, 27539, 27449, 149759, 2681190, 60119, 62099,
                  491040, 86489);
    D : Natural;
  begin
    D := Ndata.Data_Maxy(I + 1);
    if D < Short_Maxy'Last then
      D := Short_Maxy(D + 1);
    end if;
    return (Minx => Lint (Ndata.Data_Minx(I + 1)),
            Miny => Lint (Ndata.Data_Miny(I + 1)),
            Maxx => Lint (Ndata.Data_Minx(I + 1) + Ndata.Data_Maxx(I + 1)),
            Maxy => Lint (Ndata.Data_Miny(I + 1) + D));
  end Min_Max_Setup;
  Xdivider19 : constant array (Positive range <>) of Natural := (
    360, 360, 360, 360, 360, 360, 361, 361, 361, 361,    --  5.2429 degrees
    362, 362, 362, 363, 363, 363, 364, 364, 365, 366,    -- 10.4858 degrees
    366, 367, 367, 368, 369, 370, 370, 371, 372, 373,    -- 15.7286 degrees
    374, 375, 376, 377, 378, 379, 380, 382, 383, 384,    -- 20.9715 degrees
    386, 387, 388, 390, 391, 393, 394, 396, 398, 399,    -- 26.2144 degrees
    401, 403, 405, 407, 409, 411, 413, 415, 417, 420,    -- 31.4573 degrees
    422, 424, 427, 429, 432, 435, 437, 440, 443, 446,    -- 36.7002 degrees
    449, 452, 455, 459, 462, 465, 469, 473, 476, 480,    -- 41.9430 degrees
    484, 488, 492, 496, 501, 505, 510, 515, 520, 525,    -- 47.1859 degrees
    530, 535, 540, 546, 552, 558, 564, 570, 577, 583,    -- 52.4288 degrees
    590, 598, 605, 612, 620, 628, 637, 645, 654, 664,    -- 57.6717 degrees
    673, 683, 693, 704, 715, 726, 738, 751, 763, 777,    -- 62.9146 degrees
    791, 805, 820, 836, 852, 869, 887, 906, 925, 946,    -- 68.1574 degrees
    -- 73.4003 degrees
    968, 990, 1014, 1039, 1066, 1094, 1123, 1154, 1187, 1223,
    -- 78.6432 degrees
    1260, 1300, 1343, 1389, 1438, 1490, 1547, 1609, 1676, 1749,
    -- 83.8861 degrees
    1828, 1916, 2012, 2118, 2237, 2370, 2521, 2691, 2887, 3114,
    -- 89.1290 degrees
    3380, 3696, 4077, 4547, 5139, 5910, 6952, 8443, 10747, 14784,
    23681, 59485);

  Nc : constant array (Positive range <>) of Natural := (
    1, 31, 961, 29791, 923521, 28629151, 887503681);

  X_Side  : constant array (Positive range <>) of Natural := (
    0, 5, 31, 168, 961, 168 * 31, 29791, 165869, 923521, 5141947, 28629151);
  Y_Side : constant array (Positive range <>) of Natural := (
    0, 6, 31, 176, 961, 176 * 31, 29791, 165869, 923521, 5141947, 28629151);

  Decode_Char : constant array (Positive range <>) of Integer := (
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1, -1, -1,
    -1, -2, 10, 11, 12, -3, 13, 14, 15, 1, 16, 17, 18, 19, 20, 0,
    21, 22, 23, 24, 25, -4, 26, 27, 28, 29, 30, -1, -1, -1, -1, -1,
    -1, -2, 10, 11, 12, -3, 13, 14, 15, 1, 16, 17, 18, 19, 20, 0,
    21, 22, 23, 24, 25, -4, 26, 27, 28, 29, 30, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1);
  Encode_Char : constant array (Positive range <>) of Character := (
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
    'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z',
    'A', 'E', 'U');

  function Decode_A_Char (C : Natural) return Integer is (Decode_Char(C + 1));
  function Encode_A_Char (C : Natural) return Character is (Encode_Char(C + 1));

  -- Given a minimum and maximum latitude, returns a relative stretch factor
  --  (in 360th)  for the longitud
  function Xdivider4 (Miny, Maxy : Lint) return Natural is
    use Bits;
  begin
    if Miny >= 0 then
      return Xdivider19(Integer (Shr (Miny, 19)) + 1);
    end if;
    if Maxy >= 0 then
        return Xdivider19(1);
    end if;
    return Xdivider19(Integer (Shr (-Maxy, 19)) + 1);
  end Xdivider4;

  type Coord_Rec is record
     X, Y : Lint;
  end record;

  type Frac_Rec is record
    Fraclon, Fraclat : Integer;
    Coord32 : Coord_Rec;
  end record;

  -- Return True if x in range (all values in millionths)
  function Is_In_Range_X (X, Minx, Maxx : Lint) return Boolean is
    Lx : Lint;
  begin
    if Minx <= X and then X < Maxx then return True; end if;
    Lx := X;
    if Lx < Minx then
      Lx := Lx + 360000000;
    else
      Lx := Lx - 360000000;
    end if;
    return Minx <= Lx and then Lx < Maxx;
  end Is_In_Range_X;

  -- Return True if coordinate inside rectangle (all values in millionths)
  function Fits_Inside (Coord : Coord_Rec; Min_Max : Min_Max_Rec)
                       return Boolean is
    (Min_Max.Miny <= Coord.Y
     and then Coord.Y < Min_Max.Maxy
     and then Is_In_Range_X (Coord.X, Min_Max.Minx, Min_Max.Maxx));

  -- Mapcodezone
  type Mapcode_Zone_Rec is record
    Fminx, Fmaxx, Fminy, Fmaxy : Lint := 0;
  end record;

  -- Empty Mapcode_Zone
  Mz_Empty : constant Mapcode_Zone_Rec  := (others => <>);
  function Mz_Is_Empty (Zone : Mapcode_Zone_Rec) return Boolean is
    (Zone.Fmaxx <= Zone.Fminx or else Zone.Fmaxy <= Zone.Fminy);


  -- Construct MapcodeZone based on coordinate and deltas (in Fractions)
  function Mz_Set_From_Fractions (Y, X, Ydelta, Xdelta : Lint)
           return Mapcode_Zone_Rec is
    (if Ydelta < 0 then
      (Fminx => X,
       Fmaxx => X + Xdelta,
       Fminy => Y + 1 + Ydelta, -- y+yDelta can NOT be represented
       Fmaxy => Y + 1)          -- y CAN be represented
     else
      (Fminx => X,
       Fmaxx => X + Xdelta,
       Fminy => Y,
       Fmaxy => Y + Ydelta));

  function Mz_Mid_Point_Fractions (Zone : Mapcode_Zone_Rec) return Coord_Rec is
    ( (Y => (Zone.Fminy + Zone.Fmaxy) / 2,
       X => (Zone.Fminx + Zone.Fmaxx) / 2));

  function Convert_Fractions_To_Coord32 (P : Coord_Rec) return Coord_Rec is
    ( (Y => P.Y / 810000,
       X => P.X / 3240000) );

  function Wrap (P : Coord_Rec) return Coord_Rec is
    Res : Coord_Rec := P;
  begin
    if Res.X >= 180 * 3240000 * 1000000 then
      Res.X :=  Res.X - 360 * 3240000 * 1000000;
    end if;
    if Res.X < -180 * 3240000 * 1000000 then
      Res.X :=  Res.X + 360 * 3240000 * 1000000;
    end if;
    return Res;
  end Wrap;

  function Round (Val, Max : Real) return Real is
    Epsilon : constant Real := 0.0000005;
  begin
    if Val < 0.0 then
      if Val < -Max and then Val >= -Max - Epsilon then
        return -Max;
      end if;
    else
      if Val > Max and then Val <= Max + Epsilon then
        return Max;
      end if;
    end if;
    return Val;
  end Round;

  function Convert_Fractions_To_Degrees (P : Coord_Rec) return Coordinate is
  begin
    return (Lat => Round (Real (P.Y) /  810000.0 / 1000000.0, 90.0),
            Lon => Round (Real (P.X) / 3240000.0 / 1000000.0, 180.0) );
  end Convert_Fractions_To_Degrees;

  function Mz_Restrict_Zone_To (Zone : Mapcode_Zone_Rec; Mm : Min_Max_Rec)
           return Mapcode_Zone_Rec is
    Z : Mapcode_Zone_Rec := Zone;
    Miny : constant Lint := Mm.Miny * 810000;
    Maxy : constant Lint := Mm.Maxy * 810000;
    Minx : Lint;
    Maxx : Lint;
  begin
    if Z.Fminy < Miny then
      Z.Fminy := Miny;
    end if;
    if Z.Fmaxy > Maxy then
      Z.Fmaxy := Maxy;
    end if;
    if Z.Fminy < Z.Fmaxy then
      Minx := Mm.Minx * 3240000;
      Maxx := Mm.Maxx * 3240000;
      if Maxx < 0 and then Z.Fminx > 0 then
        Minx := Minx + 360000000 * 3240000;
        Maxx := Maxx + 360000000 * 3240000;
      elsif Minx > 1 and then Z.Fmaxx < 0 then
        Minx := Minx - 360000000 * 3240000;
        Maxx := Maxx - 360000000 * 3240000;
      end if;
      if Z.Fminx < Minx then
        Z.Fminx := Minx;
      end if;
      if Z.Fmaxx > Maxx then
        Z.Fmaxx := Maxx;
      end if;
    end if;
    return Z;
  end Mz_Restrict_Zone_To;

  -- High-precision extension routines
  function Max_Mapcode_Precision return Natural is (8);

  -- PRIVATE lowest-level data access
  function Header_Letter (I : Natural) return String is
    Flags : constant Integer := Ndata.Data_Flags(I + 1);
    use Bits;
  begin
    if (Shr (Flags, 7) and 3) = 1 then
      return Encode_Char((Shr (Flags, 11) and 31) + 1) & "";
    end if;
    return "";
  end Header_Letter;

  function Smart_Div (I : Natural) return Integer is
    (Ndata.Data_Special1(I + 1));

  function Is_Restricted (I : Natural) return Boolean is
    use Bits;
  begin
    return (Ndata.Data_Flags(I + 1) and 512) /= 0;
  end Is_Restricted;

  function Is_Nameless (I : Natural) return Boolean is
    use Bits;
  begin
    return (Ndata.Data_Flags(I + 1) and 64) /= 0;
  end Is_Nameless;

  function Is_Auto_Header (I : Natural) return Boolean is
    use Bits;
  begin
    return (Ndata.Data_Flags(I + 1) and Shl (8, 5)) /= 0;
  end Is_Auto_Header;

  function Codex_Len (I : Natural) return Integer is
    use Bits;
    Flags : constant Integer := Ndata.Data_Flags (I + 1) and 31;
  begin
    return Flags / 5 + Flags rem 5 + 1;
  end Codex_Len;

  function Co_Dex (I : Natural) return Integer is
    use Bits;
    Flags : constant Integer := Ndata.Data_Flags (I + 1) and 31;
  begin
    return 10 * (Flags / 5) + Flags rem 5 + 1;
  end Co_Dex;

  function Is_Special_Shape (I : Natural) return Boolean is
    use Bits;
  begin
    return (Ndata.Data_Flags(I + 1) and 1024) /= 0;
  end Is_Special_Shape;

  -- 1=pipe 2=plus 3=star
  function Rec_Type (I : Natural) return Integer is
    use Bits;
  begin
    return Shr (Ndata.Data_Flags(I + 1), 7) and 3;
  end Rec_Type;

  function First_Nameless_Record (Index : Natural; First_Code : Natural)
           return Natural is
    I : Integer := Index;
    Codex : constant Natural := Co_Dex (I);
  begin
    while I >= First_Code and then Co_Dex (I) = Codex
          and then Is_Nameless (I) loop
      I := I - 1;
    end loop;
    return I + 1;
  end First_Nameless_Record;

  function Count_Nameless_Records (Index : Natural; First_Code : Natural)
           return Natural is
    I : constant Natural := First_Nameless_Record (Index, First_Code);
    E : Natural := Index;
    Codex : constant Natural := Co_Dex (I);
  begin
    while Co_Dex(E) = Codex loop
      E := E + 1;
    end loop;
    return E - I;
  end Count_Nameless_Records;

  -- Return Lint immediately smaller than Real
  function Floor (X : Real) return Lint is
    Int : Lint;
  begin
    Int := Lint(X);

    if Real(Int) > X then
      Int := Int - 1;
    end if;
    return Int;
  end Floor;

  function Get_Encode_Rec(Lat, Lon : in Real) return Frac_Rec is
    Ilat : Real := Lat;
    Ilon : Real := Lon;
    D : Real;
    Fraclat, Fraclon : Lint;
    Lat32, Lon32 : Lint;
  begin

    if Ilat < -90.0 then
      Ilat := -90.0;
    elsif Ilat > 90.0 then
      Ilat := 90.0;
    end if;
    Ilat := Ilat + 90.0; -- Ilat now [0..180]
    Ilat := Ilat * 810000000000.0;
    Fraclat := Floor (Ilat + 0.1);
    D := Real (Fraclat) / 810000.0;
    Lat32 := Floor (D);
    Fraclat := Fraclat - Lat32 * 810000;
    Lat32 := Lat32 - 90000000;

    Ilon := Ilon - 360.0 * Real (Floor (Ilon / 360.0));
    -- Lon now in [0..360>
    Ilon := Ilon * 3240000000000.0;
    Fraclon := Floor (Ilon + 0.1);
    D := Real (Fraclon) / 3240000.0;
    Lon32 := Floor (D);
    Fraclon := Fraclon - Lon32 * 3240000;
    if Lon32 >= 180000000 then
      Lon32 := Lon32 - 360000000;
    end if;

    return (Coord32 =>  (Y => Lat32, X => Lon32),
            Fraclat => Integer (Fraclat),
            Fraclon => Integer (Fraclon) );
  end Get_Encode_Rec;

  function Encode_Base31 (Value : Lint; Nrchars : Natural) return String is
    Result : As_U.Asu_Us;
    Lv : Lint := Value;
    Ln : Natural := Nrchars;
    use type As_U.Asu_Us;
  begin
    while Ln > 0 loop
      Ln := Ln - 1;
      Result := Encode_Char(Integer (Lv rem 31) + 1)  & Result;
      Lv := Lv / 31;
    end loop;
    return Result.Image;
  end Encode_Base31;

  -- Lowest level encode/decode routines
  function Decode_Base31 (Str : String) return Integer is
    Value  : Integer := 0;
    C : Natural;
  begin
    for I in Str'Range loop
        C := Character'Pos (Str(I));
        if C = 46 then
          -- Dot!
            return Value;
        end if;
        if Decode_Char(C + 1) < 0 then
            return Error;
        end if;
        Value := Value * 31 + Decode_Char(C + 1);
    end loop;
    return Value;
  end Decode_Base31;

  function Encode_Triple (Difx, Dify : Lint) return String is
    Rx, Ry, Cx, Cy : Lint;
  begin
    if Dify < 4 * 34 then
      Rx := Difx / 28;
      Ry := Dify / 34;
      Cx := Difx rem 28;
      Cy := Dify rem 34;
      return Encode_Char(Integer (Rx + 6 * Ry + 1))
           & Encode_Base31 (Cx * 34 + Cy, 2);
    else
      Rx := Difx / 24;
      Cx := Difx rem 24;
      return Encode_Char(Integer (Rx + 25))
           & Encode_Base31 (Cx * 40 + (Dify - 136), 2);
    end if;
  end Encode_Triple;

  function Decode_Triple (Input : String) return Coord_Rec is
    Triplex, Tripley : Integer;
    C1  : constant Character := Input(Input'First);
    I1  : constant Integer := Decode_Char(Character'Pos(C1) + 1);
    X  : constant Integer
       := Decode_Base31 (Input(Positive'Succ(Input'First) .. Input'Last));
  begin
    if I1 < 24 then
      Triplex := (I1 rem 6) * 28 + X / 34;
      Tripley := (I1 / 6) * 34 + X rem  34;
    else
      Tripley := X rem 40 + 136;
      Triplex := X / 40 + 24 * (I1 - 24);
    end if;
    return (Y => Lint (Tripley), X => Lint (Triplex));
  end Decode_Triple;

  function Encode_Six_Wide (X, Y, Width, Height : in Integer) return Integer is
    D  : Integer := 6;
    Col  : Integer := X / 6;
    Maxcol : constant Integer := (Width - 4) / 6;
  begin
    if Col >= Maxcol then
      Col := Maxcol;
      D := Width - Maxcol * 6;
    end if;
    return Height * 6 * Col + (Height - 1 - Y) * D + X - Col * 6;
  end Encode_Six_Wide;

  function Decode_Six_Wide (V, Width, Height : in Integer) return Coord_Rec is
    D : Integer := 6;
    Col : Integer := V / (Height * 6);
    Maxcol : constant Integer := (Width - 4) / 6;
    W, X6, Y6 : Integer;
  begin
    if Col >= Maxcol then
      Col := Maxcol;
      D := Width - Maxcol * 6;
    end if;
    W := V - Col * Height * 6;
    X6 := Col * 6 + W rem D;
    Y6 := Height - 1 - W / D;
    return (Y => Lint (Y6), X => Lint (X6));
  end Decode_Six_Wide;

  function Encode_Extension (
      Input : String;
      Enc : Frac_Rec;
      Extrax4, Extray, Dividerx4, Dividery : Lint;
      Extradigits, Ydirection : Integer) return String is
    Factorx, Factory, Valx, Valy : Lint;
    Gx, Gy, Column1, Column2, Row1, Row2 : Integer;
    Digit : Integer := Extradigits;
    Result : As_U.Asu_Us;
  begin
    if Extradigits = 0 then
      return Input;
    end if;
    if Digit > Max_Mapcode_Precision then
      Digit := Max_Mapcode_Precision;
    end if;
    Result := As_U.Tus (Input);

    -- The following are all perfect integers
    --  810000 = 30^4
    Factorx := 810000 * Dividerx4;
    Factory := 810000 * Dividery;
    Valx := 810000 * Extrax4 + Lint (Enc.Fraclon);
    Valy := 810000 * Extray  + Lint (Enc.Fraclat) * Lint (Ydirection);

    -- Protect against floating point errors
    if Valx < 0 then
      Valx := 0;
    elsif Valx >= Factorx then
      Valx := Factorx - 1;
    end if;
    if Valy < 0 then
      Valy := 0;
    elsif Valy >= Factory then
      Valy := Factory - 1;
    end if;

    Result.Append ('-');
    loop
      Factorx := Factorx / 30;
        Gx := Integer (Valx / Factorx);

        Factory := Factory / 30;
        Gy := Integer (Valy / Factory);

        Column1 := Gx / 6;
        Row1 := Gy / 5;
        Result.Append (Encode_Char(Row1 * 5 + Column1 + 1));
        Digit := Digit - 1;
        exit when Digit = 0;

        Column2 := Gx rem 6;
        Row2 := Gy rem 5;
        Result.Append (Encode_Char(Row2 * 6 + Column2 + 1));
        Digit := Digit - 1;
        exit when Digit = 0;
        Valx := Valx - Factorx * Lint (Gx);
        Valy := Valy - Factory * Lint (Gy);
    end loop;
    return Result.Image;
  end Encode_Extension;

  -- Returns (possibly empty) MapcodeZone
  function Decode_Extension (
      Extension_Chars : String;
      Coord32 : Coord_Rec;
      Dividerx4, Dividery, Lon_Offset4,
      Extremelatmicrodeg, Maxlonmicrodeg : Lint)
  return Mapcode_Zone_Rec is
    Processor : Lint := 1;
    Lon32, Lat32 : Lint := 0;
    Odd : Boolean := False;
    Idx : Positive;
    Column1, Row1, Column2, Row2 : Lint;
    C1, C2 : Character;
    N1, N2 : Integer;
    Ldivx4, Ldivy : Lint;
    Lon4, Lat1: Lint;
    Mapcode_Zone : Mapcode_Zone_Rec;
  begin
    if Extension_Chars'Length > 8 then
      -- Too many digits
      return Mz_Empty;
    end if;
    Idx := Extension_Chars'First;
    while Idx <= Extension_Chars'Length loop
      C1 := Extension_Chars(Idx);
      N1 := Decode_Char(Character'Pos(C1) + 1);
      Idx := Idx + 1;
      if N1 < 0 or else N1 = 30 then
        return Mz_Empty;
      end if;
      Row1 := Lint (N1 / 5);
      Column1 := Lint (N1 rem 5);
      if Idx <= Extension_Chars'Length then
        C2 := Extension_Chars(Idx);
        N2 := Decode_Char(Character'Pos(C2) + 1);
        Idx := Idx + 1;
        if N2 < 0 or else N2 = 30 then
          return Mz_Empty;
        end if;
        Row2 := Lint (N2 / 6);
        Column2 := Lint (N2 rem 6);
      else
        Row2 := 0;
        Column2 := 0;
        Odd := True;
      end if;
      Processor :=  Processor * 30;
      Lon32 := Lon32 * 30 + Column1 * 6 + Column2;
      Lat32 := Lat32 * 30 + Row1 * 5 + Row2;
    end loop;

    Ldivx4 := Dividerx4;
    Ldivy := Dividery;
    while Processor < 810000 loop
      Ldivx4 := Ldivx4 * 30;
      Ldivy := Ldivy * 30;
      Processor := Processor * 30;
    end loop;

    Lon4 := Coord32.X * 3240000 + Lon32 * Ldivx4 + Lon_Offset4 * 810000;
    Lat1 := Coord32.Y * 810000 + Lat32 * Ldivy;

    if Odd then
      Mapcode_Zone := Mz_Set_From_Fractions (Lat1, Lon4, 5 * Ldivy,
                                             6 * Ldivx4);
    else
      Mapcode_Zone := Mz_Set_From_Fractions (Lat1, Lon4, Ldivy, Ldivx4);
    end if;

   -- FORCE_RECODE: restrict the coordinate range to the extremes that were
   --  provided
    if Mapcode_Zone.Fmaxx > Maxlonmicrodeg * 3240000 then
      Mapcode_Zone.Fmaxx := Maxlonmicrodeg * 3240000;
    end if;
    if Ldivy >= 0 then
      if Mapcode_Zone.Fmaxy > Extremelatmicrodeg * 810000 then
        Mapcode_Zone.Fmaxy := Extremelatmicrodeg * 810000;
      end if;
    else
      if Mapcode_Zone.Fminy < Extremelatmicrodeg * 810000 then
        Mapcode_Zone.Fminy := Extremelatmicrodeg * 810000;
      end if;
    end if;

    return Mapcode_Zone;
  end Decode_Extension;

  -- Add vowels to prevent a mapcode r from being all-digit
  function Aeu_Pack (R : As_U.Asu_Us; Short : Boolean) return String is
    Dotpos : Natural := 0;
    Result : As_U.Asu_Us := R;
    Rlen : Natural := Result.Length;
    Rest : As_U.Asu_Us;
    V : Integer;
    use type As_U.Asu_Us;
  begin
    for D in 1 .. Rlen loop
      if Result.Element (D) < '0' or else Result.Element (D) > '9' then
        -- Not digit?
        if Result.Element (D) = '.' and then Dotpos = 0 then
          -- First dot?
          Dotpos := D;
        elsif R.Element (D) = '-' then
          Rest := Result.Uslice (D, Result.Length);
          Result := Result.Uslice (1, D - 1);
          Rlen := D - 1;
          exit;
        else
          return Result.Image;
        end if;
      end if;
    end loop;

    -- Does Result have a dot, AND at least 2 chars before and after the dot?
    if Dotpos >= 3 and then Rlen - 2 >= Dotpos then
      if Short then
        -- v1.50 new way: use only A
        V := (Character'Pos(Result.Element (1)) - 48)  * 100
           + (Character'Pos(Result.Element (Rlen - 1)) - 48) * 10
           +  Character'Pos(Result.Element (Rlen))     - 48;
        Result := 'A' & Result.Uslice (2, Rlen - 2)
                & Encode_Char(V / 32 + 1) &  Encode_Char(V rem 32 + 1);
      else
        -- Old way: use A, E and U */
        V := (Character'Pos(Result.Element(Rlen - 1)) - 48) * 10
           +  Character'Pos(Result.Element(Rlen))     - 48;
        Result := Result.Uslice(1, Rlen - 2)
                & Encode_Char(V / 34 + 32)
                & Encode_Char(V rem 34 + 1);

      end if;
    end if;
    Result.Append (Rest);
    return Result.Image;
  end Aeu_Pack;

  -- Remove vowels from mapcode str into an all-digit mapcode
  --  (Assumes str is already uppercase!)
  function Aeu_Unpack (Str  : String) return String is
    Voweled, Has_Letters  : Boolean := False;
    Lastpos : constant Natural := Str'Length;
    Result : As_U.Asu_Us := As_U.Tus (Str);
    Dotpos : Natural := Result.Locate (".");
    V, V1, V2 : Integer;
    S : String (1 .. 4);
    C : Character;
    use type As_U.Asu_Us;
  begin
    if Dotpos < 3 or else Lastpos < Dotpos + 2 then
      -- No dot, or less than 2 letters before dot, or less than 2 letters
      --  after dot
      return Str;
    end if;

    if Result.Element(1) = 'A' then -- V1.50
      V1 := Decode_Char(Character'Pos(Result.Element(Lastpos)) + 1);
      if V1 < 0 then
        V1 := 31;
      end if;
      V2 := Decode_Char(Character'Pos(Result.Element(Lastpos - 1)) + 1);
      if V2 < 0 then
         V2 := 31;
      end if;
      S := Image (1000 + V1 + 32 * V2);
      Result := S(2) & Result.Uslice(2, Lastpos - 2) & S(3 .. 4);
      Voweled := True;
    elsif Result.Element(1) = 'U' then
      Result.Delete (1, 1);
      Dotpos := Dotpos - 1;
      Voweled := True;
    else
      C := Result.Element(Lastpos - 1);
      V := Character'Pos(C);
      if C = 'A' then
        V := 0;
      elsif C = 'E'then
        V := 34;
      elsif C = 'U' then
        V := 68;
      else
        V := -1;
      end if;
      if V >= 0 then
        C := Result.Element (Lastpos);
        if C = 'A' then
          V := V + 31;
        elsif C = 'E' then
          V := V + 32;
        elsif C = 'U' then
          V := V + 33;
        else
          V1 := Decode_Char(Character'Pos(Result.Element(Lastpos)) + 1);
          if V1 < 0 then
            return Undefined;
          end if;
          V := V + V1;
        end if;
        if V >= 100 then
          return Undefined;
        end if;
        Voweled := True;
        Result := Result.Uslice (1, Lastpos - 2)
                & Encode_Char(V / 10 + 1) & Encode_Char(V rem 10 + 1);
      end if;
    end if;

    if Dotpos < 3 or else Dotpos > 6 then
      return Undefined;
    end if;

    for I in 1 .. Lastpos  loop
      if I /= Dotpos then
        V := Decode_Char(Character'Pos(Result.Element(I)) + 1);
        if V < 0 then
          -- Bad char!
          return Undefined;
        elsif V > 9 then
          Has_Letters := True;
        end if;
      end if;
    end loop;
    if Voweled and then Has_Letters then
      return Undefined;
    end if;
    if not Voweled and then not Has_Letters then
      return Undefined;
    end if;
    return Result.Image;
  end Aeu_Unpack;

  -- Mid-level encode/decode
  function Encode_Nameless (Enc : Frac_Rec;
                            M : Natural;
                            First_Code : Natural;
                            Extra_Digits : Integer) return String is
    A : constant Natural := Count_Nameless_Records (M, First_Code);
    P : constant Natural := 31 / A;
    R : constant Natural := 31 rem A;
    Codex : constant Natural := Co_Dex (M);
    Codexlen : constant Natural := Codex_Len(M);
    X : Integer;
    Storage_Offset, Base_Power, Base_Power_A : Lint;
  begin
    if A < 1 then
      return Undefined;
    end if;

    X := M - First_Nameless_Record (M, First_Code);
    if Codex /= 21 and then A <= 31 then
      Storage_Offset := Lint (X * P + (if X < R then X else R)) * 961 * 961;
    elsif Codex /= 21 and then A < 62 then
      if X < 62 - A then
        Storage_Offset := Lint (X) * (961 * 961);
      else
        Storage_Offset := Lint (62 - A + (X - 62 + A) / 2) * 961 * 961;
        if (X + A) rem 2 = 1 then
          Storage_Offset := Storage_Offset + 16 * 961 * 31;
        end if;
      end if;
    else
      Base_Power := (if Codex = 21 then 961 * 961 else 961 * 961 * 31);
      Base_Power_A := Base_Power / Lint (A);
      if A = 62 then
        Base_Power_A := Base_Power_A + 1;
      else
        Base_Power_A := 961 * (Base_Power_A / 961);
      end if;
      Storage_Offset := Lint (X) * Base_Power_A;
    end if;

    declare
      Mm : constant Min_Max_Rec := Min_Max_Setup (M);
      Side : Integer := Smart_Div (M);
      Org_Side : constant Integer := Side;
      X_Side : Integer := Side;
      -- Note that xDivider4 is 4 times too large
      Dividerx4 : constant Lint := Lint (Xdivider4 (Mm.Miny, Mm.Maxy));
      Xfracture : constant Lint := Lint (Enc.Fraclon) / 810000;
      -- Dx is in millionths
      Dx : constant Lint := (4 * (Enc.Coord32.X - Mm.Minx) + Xfracture)
                             / Dividerx4;
      -- Extrax4 is in quarter-millionths
      Extrax4 : constant Lint := (Enc.Coord32.X - Mm.Minx) * 4
                               - Dx * Dividerx4;
      Dividery : constant Lint := 90;
      Dy : Lint := (Mm.Maxy - Enc.Coord32.Y) / Dividery;
      Extray : Lint := (Mm.Maxy - Enc.Coord32.Y) rem Dividery;
      V : Lint;
      Result : As_U.Asu_Us;
      use type As_U.Asu_Us;
    begin
      if Extray = 0 and then Enc.Fraclat > 0 then
        Dy := Dy - 1;
        Extray := Extray + Dividery;
      end if;

     V := Storage_Offset;
     if Is_Special_Shape (M) then
       X_Side := X_Side * Side;
       Side := Integer (1 + (Mm.Maxy - Mm.Miny) / 90);
       X_Side := X_Side / Side;
       V := V + Lint (Encode_Six_Wide (Integer (Dx), Side - 1 - Integer(Dy),
                                       X_Side, Side));
     else
       V := V + (Dx * Lint (Side) + Dy);
     end if;

     Result := As_U.Tus (Encode_Base31 (V, Codexlen + 1));

     if Codexlen = 3 then
       Result := Result.Uslice (1, 2) & '.' & Result.Uslice (3, Result.Length);
     elsif Codexlen = 4 then
       if Codex = 22 and then Org_Side = 961
       and then not Is_Special_Shape (M) then
         Result := As_U.Tus (Result.Element (1) & Result.Element (2)
                           & Result.Element (4) & '.' & Result.Element (3)
                           & Result.Element (5));
       elsif Codex = 13 then
         Result := Result.Uslice (1, 2) & '.' & Result.Uslice (3, Result.Length);
       else
         Result := Result.Uslice (1, 3) & '.' & Result.Uslice (4, Result.Length);
       end if;
     end if;

     return Encode_Extension (Result.Image, Enc, Extrax4, Extray, Dividerx4,
                              Dividery, Extra_Digits, -1);
    end;
  end Encode_Nameless;

  function Decode_Nameless (Input : String; Extension_Chars : String;
                            M : Natural; First_Index : Natural)
           return Mapcode_Zone_Rec is
    Codex : constant Natural := Co_Dex (M);
    Result : As_U.Asu_Us;
    A : constant Natural := Count_Nameless_Records (M, First_Index);
    F : constant Natural := First_Nameless_Record (M, First_Index);
    P : constant Natural := 31 / A;
    R : constant Natural := 31 rem A;
    X, V, Offset : Integer;
    Swap_Letters : Boolean := False;
    Base_Power, Base_Power_A : Integer;
    use type As_U.Asu_Us;
  begin
    Result := As_U.Tus (Input);
    if Codex = 22 then
      Result := Result.Uslice (1, 3) & Result.Uslice (5, Result.Length);
    else
      Result := Result.Uslice (1, 2) & Result.Uslice (4, Result.Length);
    end if;

    if Codex /= 21 and then A <= 31 then
      Offset := Decode_Char(Character'Pos (Result.Element(1)) + 1);
      if Offset < R * (P + 1) then
        X := Offset / (P + 1);
      else
        Swap_Letters := P = 1 and then Codex = 22;
        X := R + (Offset - R * (P + 1)) / P;
      end if;
    elsif Codex /= 21 and then A < 62 then
      X := Decode_Char(Character'Pos (Result.Element(1)) + 1);
      if X < 62 - A then
        Swap_Letters := Codex = 22;
      else
        X := X + X - (62 - A);
      end if;
    else
      -- codex = 21 or else A >= 62
      Base_Power := (if Codex = 21 then 961 * 961 else 961 * 961 * 31);
      Base_Power_A := Base_Power / A;
      if A = 62 then
        Base_Power_A := Base_Power_A + 1;
      else
        Base_Power_A := 961 * (Base_Power_A / 961);
      end if;

      -- Decode
      V := Decode_Base31 (Result.Image);

      X := V / Base_Power_A;
      V := V rem Base_Power_A;
    end if;

    if Swap_Letters then
      if not Is_Special_Shape (M + X) then
        Result := As_U.Tus (Result.Element (1) & Result.Element (2)
                          & Result.Element (4) & Result.Element (3)
                          & Result.Element (5));
      end if;
    end if;

    if Codex /= 21 and then A <= 31 then
      V := Decode_Base31 (Result.Image);
      if X > 0 then
        V := V - (X * P + (if X < R then X else R)) * (961 * 961);
      end if;
    elsif Codex /= 21 and then A < 62 then
      V := Decode_Base31 (Result.Slice (2, Result.Length));
      if X >= 62 - A then
        if V >= 16 * 961 * 31 then
          V := V - 16 * 961 * 31;
          X := X + 1;
        end if;
      end if;
    end if;

    if X > A then
      -- past end!
      return Mz_Empty;
    end if;

    declare
      Lm : constant Natural := F + X;
      Mm : constant Min_Max_Rec := Min_Max_Setup (Lm);
      Side : Integer := Smart_Div (Lm);
      X_Side : Integer := Side;
      D : Coord_Rec;

      Dividerx4 : constant Lint := Lint (Xdivider4 (Mm.Miny, Mm.Maxy));
      Dividery : constant Lint := 90;
      Corner : Coord_Rec;
    begin
      X_Side := Side;
      if Is_Special_Shape(Lm) then
        X_Side := X_Side * Side;
        Side := Integer (1 + (Mm.Maxy - Mm.Miny) / 90);
        X_Side := X_Side / Side;

        D := Decode_Six_Wide(V, X_Side, Side);
        D.Y := Lint (Side) - 1 - D.Y;
      else
        D.X := Lint (V / Side);
        D.Y := Lint (V rem  Side);
      end if;

      if D.X >= Lint (X_Side) then
        -- Out-of-range!
        return Mz_Empty;
      end if;

      Corner := (
        Y => Mm.Maxy - D.Y * Dividery,
        X => Mm.Minx + (D.X * Dividerx4) / 4);
      return Decode_Extension(Extension_Chars, Corner, Dividerx4, -Dividery,
                            (D.X * Dividerx4) rem 4, Mm.Miny, Mm.Maxx);
    end;
  end Decode_Nameless;

  function Encode_Auto_Header (Enc : Frac_Rec; M : Natural;
                               Extradigits : in Natural) return String is
    Codex : constant Integer := Co_Dex(M);
    Codexlen : constant Integer := Codex_Len (M);
    First_Index : Integer := M;
    I : Integer;
    Mm : Min_Max_Rec;
    H : Lint;
    Xdiv : Natural;
    W : Lint;
    Product : Lint;
    Good_Rounder : Lint;
    Storage_Start : Lint := 0;
    Dividerx, Dividery, Vx, Vy, Extrax, Extray, Spx, Spy, Value : Lint;
    Mapc : As_U.Asu_Us;
    use Bits;
  begin
    while Is_Auto_Header (First_Index - 1)
    and then Co_Dex (First_Index - 1) = Codex loop
        First_Index := First_Index - 1;
    end loop;

    I := First_Index;
    while Co_Dex (I) = Codex loop
      Mm := Min_Max_Setup (I);
      H := (Mm.Maxy - Mm.Miny + 89) / 90;
      Xdiv := Xdivider4 (Mm.Miny, Mm.Maxy);
      W := ((Mm.Maxx - Mm.Minx) * 4 + Lint (Xdiv) - 1) / Lint (Xdiv);
      H := 176 * ((H + 176 - 1) / 176);
      W := 168 * ((W + 168 - 1) / 168);
      Product := (W / 168) * (H / 176) * 961 * 31;
      if Rec_Type (I) = 2 then
        -- *+
        Good_Rounder := (if Codex >= 23 then 961 * 961 * 31 else 961 * 961);
        Product := (Storage_Start + Product + Good_Rounder - 1) / Good_Rounder
                   * Good_Rounder - Storage_Start;
      end if;
      if I = M and then Fits_Inside (Enc.Coord32, Mm) then
        Dividerx := (Mm.Maxx - Mm.Minx + W - 1) / W;
        Vx := (Enc.Coord32.X - Mm.Minx) / Dividerx;
        Extrax := (Enc.Coord32.X - Mm.Minx) rem Dividerx;
        Dividery := (Mm.Maxy - Mm.Miny + H - 1) / H;
        Vy := (Mm.Maxy - Enc.Coord32.Y) / Dividery;
        Extray := (Mm.Maxy - Enc.Coord32.Y) rem Dividery;
        Spx := Vx rem 168;
        Vx := Vx / 168;
        Value := Vx * (H / 176);
        if Extray = 0 and then Enc.Fraclat > 0 then
          Vy := Vy - 1;
          Extray := Extray + Dividery;
        end if;
        Spy := Vy rem 176;
        Vy := Vy / 176;
        Value := Value + Vy;

        Mapc := As_U.Tus (
            Encode_Base31 (Storage_Start / (961 * 31) + Value, Codexlen - 2)
          & "."
          & Encode_Triple (Spx, Spy));

        return Encode_Extension (Mapc.Image, Enc, Shl (Extrax, 2), Extray,
                                 Shl( Dividerx, 2), Dividery,
                                 Extradigits, -1);
      end if;
      Storage_Start := Storage_Start + Product;
      I := I + 1;
    end loop;
    return Undefined;
  end Encode_Auto_Header;

  function Decode_Auto_Header (Input : String; Extension_Chars : String;
                               M : Natural) return Mapcode_Zone_Rec is
    Storage_Start : Lint := 0;
    Codex : constant Integer := Co_Dex(M);
    -- Decode (before dot)
    Value : Lint := Lint (Decode_Base31 (Input));
    Triple : Coord_Rec;
    Lm : Natural;
    Mm : Min_Max_Rec;
    H : Lint;
    Xdiv : Lint;
    W : Lint;
    Product : Lint;
    Good_Rounder : Lint;
    Dividerx, Dividery, Vx, Vy : Lint;
    Corner : Coord_Rec;
    use Bits;
  begin
    Value := Value * (961 * 31);
    -- Decode bottom
    Triple := Decode_Triple (Input (Input'Last - 2 .. Input'Last));

    Lm := M;
    while Co_Dex (Lm) = Codex and then Rec_Type (Lm) > 1 loop
      Mm := Min_Max_Setup (Lm);
      H := (Mm.Maxy - Mm.Miny + 89) / 90;
      Xdiv := Lint (Xdivider4 (Mm.Miny, Mm.Maxy));
      W := ((Mm.Maxx - Mm.Minx) * 4 + (Xdiv - 1)) / Xdiv;
      H := 176 * ((H + 176 - 1) / 176);
      W := 168 * ((W + 168 - 1) / 168);
      Product := (W / 168) * (H / 176) * 961 * 31;

      if Rec_Type (Lm) = 2 then
        Good_Rounder := (if Codex >= 23 then 961 * 961 * 31 else 961 * 961);
        Product := ((Storage_Start + Product + Good_Rounder - 1)
                   / Good_Rounder) * Good_Rounder - Storage_Start;
      end if;

      if Value >= Storage_Start and then Value < Storage_Start + Product then
        -- Code belongs here?
        Dividerx := (Mm.Maxx - Mm.Minx + W - 1) / W;
        Dividery := (Mm.Maxy - Mm.Miny + H - 1) / H;
        Value := Value - Storage_Start;
        Value := Value / (961 * 31);
        Vx := Triple.X + 168 * (Value / (H / 176));
        Vy := Triple.Y + 176 * (Value rem (H / 176));
        Corner := (
          -- In microdegrees
          Y =>  Mm.Maxy - Vy * Dividery,
          X =>  Mm.Minx + Vx * Dividerx);
        if Corner.Y /= Mm.Maxy and then not Fits_Inside (Corner, Mm) then
          return Mz_Empty;
        end if;

        return Decode_Extension (Extension_Chars, Corner,
                                 Shl (Dividerx, 2), -Dividery,
                                 0, Mm.Miny, Mm.Maxx); -- autoheader
      end if;
      Storage_Start := Storage_Start + Product;
      Lm := Lm + 1;
    end loop;
    return Mz_Empty;

  end Decode_Auto_Header;

  function Encode_Grid (Enc : Frac_Rec; M : Natural; Mm : Min_Max_Rec;
                        Headerletter : in String; Extradigits : in Natural)
           return String is
    Orgcodex : constant Integer := Co_Dex(M);
    Codex : Integer := Orgcodex;
    Prefixlength, Postfixlength : Integer;
    Divx, Divy : Integer;
    Xgridsize, Ygridsize, X, Relx, Rely : Lint;
    V : Integer;
    Result, Postfix : As_U.Asu_Us;
    Dividery, Dividerx : Lint;
    Difx, Dify, Extrax, Extray : Lint;
    use Bits;
    use type As_U.Asu_Us;
  begin
    if Codex = 21 then
      Codex := 22;
    end if;
    if Codex = 14 then
      Codex := 23;
    end if;
    Prefixlength := Codex / 10;
    Postfixlength := Codex rem 10;

    Divy := Smart_Div(M);
    if Divy = 1 then
      Divx := X_Side(Prefixlength + 1);
      Divy := Y_Side(Prefixlength + 1);
    else
      Divx := Nc(Prefixlength + 1) / Divy;
    end if;

    Ygridsize := (Mm.Maxy - Mm.Miny + Lint (Divy) - 1) / Lint (Divy);
    Rely := Enc.Coord32.Y - Mm.Miny;
    Rely := Rely / Ygridsize;
    Xgridsize := (Mm.Maxx - Mm.Minx + Lint (Divx) - 1) / Lint (Divx);
    X := Enc.Coord32.X;
    Relx := X - Mm.Minx;
    if Relx < 0 then
      X := X + 360000000;
      Relx := Relx + 360000000;
    elsif Relx >= 360000000 then
      X := X - 360000000;
      Relx := Relx - 360000000;
    end if; -- 1.32 fix FIJI edge case
    if Relx < 0 then
        return "";
    end if;
    Relx := Relx / Xgridsize;
    if Relx >= Lint (Divx) then
        return "";
    end if;

    if Divx /= Divy and then Prefixlength > 2 then -- D = 6
      V := Encode_Six_Wide (Integer (Relx), Integer (Rely), Divx, Divy);
    else
      V := Integer (Relx) * Divy + (Divy - 1 - Integer (Rely));
    end if;
    Result := As_U.Tus (Encode_Base31 (Lint (V), Prefixlength));

    if Prefixlength = 4 and then Divx = 961 and then Divy = 961 then
      Result := As_U.Tus (Result.Element(1) & Result.Element(3)
                        & Result.Element(2) & Result.Element(4));
    end if;

    Rely := Mm.Miny + Rely * Ygridsize;
    Relx := Mm.Minx + Relx * Xgridsize;
    Dividery := (Ygridsize + Lint (Y_Side(Postfixlength + 1)) - 1)
                / Lint (Y_Side(Postfixlength + 1));
    Dividerx := (Xgridsize + Lint (X_Side(Postfixlength + 1)) - 1)
                / Lint (X_Side(Postfixlength + 1));
    Result.Append (".");

    -- Encoderelative
    Difx := X - Relx;
    Dify := Enc.Coord32.Y - Rely;
    Extrax := Difx rem Dividerx;
    Extray := Dify rem Dividery;
    Difx := Difx / Dividerx;
    Dify := Dify / Dividery;
    Dify := Lint (Y_Side(Postfixlength + 1)) - 1 - Dify;
    if Postfixlength = 3 then
      Result.Append (Encode_Triple (Difx, Dify));
    else
      Postfix := As_U.Tus (Encode_Base31 (
          Difx * Lint (Y_Side(Postfixlength + 1)) + Dify, Postfixlength));
      if Postfixlength = 4 then
        Postfix := As_U.Tus (Postfix.Element(1) & Postfix.Element(3)
                           & Postfix.Element(2) & Postfix.Element(4));
      end if;
        Result.Append (Postfix);
    end if;

    if Orgcodex = 14 then
      Result := Result.Element(1) & '.' & Result.Element(2)
              & Result.Uslice (4, Result.Length);
    end if;

    return Encode_Extension (Headerletter & Result.Image, Enc,
                             Shl (Extrax, 2), Extray,
                             Shl (Dividerx, 2), Dividery,
                             Extradigits, 1);
  end Encode_Grid;

  function Decode_Grid (Input, Extension_Chars : String; M : Natural)
           return Mapcode_Zone_Rec is
    Linput : As_U.Asu_Us := As_U.Tus (Input);
    Prefixlength, Postfixlength : Natural;
    Divx, Divy : Integer;
    V : Integer;
    Rel : Coord_Rec;
    Mm : Min_Max_Rec;
    Xgridsize, Ygridsize : Lint;
    Xp, Yp, Dividerx, Dividery : Lint;
    Rest : As_U.Asu_Us;
    Dif : Coord_Rec;
    Corner : Coord_Rec;
    Decodemaxx, Decodemaxy : Lint;
    use Bits;
    use type As_U.Asu_Us;
  begin
    Prefixlength := Linput.Locate (".") - 1;
    Postfixlength := Linput.Length - 1 - Prefixlength;
    if Prefixlength = 1 and then Postfixlength = 4 then
        Prefixlength := Prefixlength + 1;
        Postfixlength:= Postfixlength - 1;
        Linput := Linput.Element(1) & Linput.Element(3) & '.'
                & Linput.Uslice (4, Linput.Length);
    end if;

    Divy := Smart_Div(M);
    if Divy = 1 then
      Divx := X_Side(Prefixlength + 1);
      Divy := Y_Side(Prefixlength + 1);
    else
      Divx := Nc(Prefixlength + 1) / Divy;
    end if;
    if Prefixlength = 4 and then Divx = 961 and then Divy = 961 then
      Linput := Linput.Element(1) & Linput.Element(3) & Linput.Element(2)
              & Linput.Uslice (4, Linput.Length);
    end if;

    V := Decode_Base31 (Linput.Image);
    if Divx /= Divy and then Prefixlength > 2 then
      --  D = 6
      Rel := Decode_Six_Wide (V, Divx, Divy);
    else
      Rel.X := Lint (V / Divy);
      Rel.Y := Lint (Divy - 1 - V rem Divy);
    end if;

    Mm := Min_Max_Setup (M);
    Ygridsize := (Mm.Maxy - Mm.Miny + Lint (Divy) - 1) / Lint (Divy);
    Xgridsize := (Mm.Maxx - Mm.Minx + Lint (Divx) - 1) / Lint (Divx);
    Rel.Y := Mm.Miny + Rel.Y * Ygridsize;
    Rel.X := Mm.Minx + Rel.X * Xgridsize;
    Xp := Lint (X_Side(Postfixlength + 1));
    Dividerx := (Xgridsize + Xp - 1) / Xp;
    Yp := Lint (Y_Side(Postfixlength + 1));
    Dividery := (Ygridsize + Yp - 1) / Yp;

    Rest := Linput.Uslice(Prefixlength + 2, Linput.Length);

    if Postfixlength = 3 then
      Dif := Decode_Triple (Rest.Image);
    else
      if Postfixlength = 4 then
        Rest := As_U.Tus (Rest.Element (1) & Rest.Element(3) & Rest.Element(2)
              & Rest.Element(4));
      end if;
      V := Decode_Base31 (Rest.Image);
      Dif.X := Lint (V) / Yp;
      Dif.Y := Lint (V) rem Yp;
    end if;
    Dif.Y := Yp - 1 - Dif.Y;

    Corner := (Y => Rel.Y + Dif.Y * Dividery,
               X => Rel.X + Dif.X * Dividerx);
    if not Fits_Inside (Corner, Mm) then
      return Mz_Empty;
    end if;

    Decodemaxx := (if Rel.X + Xgridsize < Mm.Maxx then Rel.X + Xgridsize
                   else Mm.Maxx);
    Decodemaxy := (if Rel.Y + Ygridsize < Mm.Maxy then Rel.Y + Ygridsize
                   else Mm.Maxy);
    return Decode_Extension (Extension_Chars, Corner, Shl (Dividerx, 2),
                             Dividery, 0, Decodemaxy, Decodemaxx);
  end Decode_Grid;

  -- Mapcoder engine
  Max_Nr_Of_Mapcode_Results : constant := 22;
  function Mapcoder_Engine (Enc : Frac_Rec; Tn : in Integer;
                            Get_Shortest : Boolean; State_Override : Integer;
                            Extra_Digits : Integer) return Mapcode_Infos is
    Results : Mapcode_Infos (1 .. Max_Nr_Of_Mapcode_Results);
    Nb_Results : Natural := 0;
    From_Territory : Integer := 0;
    Upto_Territory  : Integer := Ccode_Earth;
    Original_Length : Natural;
    From, Upto : Integer;
    Store_Code : Integer;
    Mc_Info : Mapcode_Info;
    Go_On : Boolean;

    -- Scan a range of territories
    procedure Scan (Territory_Number : Integer) is
      Mm : Min_Max_Rec;
      R : As_U.Asu_Us;
      use type As_U.Asu_Us;
    begin
      for I in From .. Upto loop
      -- Exlude 54 and 55
      if Co_Dex(I) < 54 then
        Mm := Min_Max_Setup (I);
        if Fits_Inside (Enc.Coord32, Mm) then
          if Is_Nameless (I) then
            R := As_U.Tus (Encode_Nameless (Enc, I, From, Extra_Digits));
          elsif Rec_Type(I) > 1 then
            R := As_U.Tus (Encode_Auto_Header (Enc, I, Extra_Digits));
          elsif I = Upto
          and then Get_Parent (Territories (Territory_Number)) >= 0 then
            declare
              More_Results : constant Mapcode_Infos
                           := Mapcoder_Engine (Enc,
                                Get_Parent (Territories (Territory_Number)),
                                Get_Shortest,
                                Territory_Number,
                                Extra_Digits);
              T : constant Natural := Nb_Results;
              N : constant Natural := More_Results'Length;
            begin
              if N > 0 then
                Nb_Results := Nb_Results + N;
                if Nb_Results > Max_Nr_Of_Mapcode_Results then
                  Nb_Results := Max_Nr_Of_Mapcode_Results;
                end if;
                Results (T + 1 .. Nb_Results) := More_Results;
              end if;
              R.Set_Null;
            end;
          else
            if Is_Restricted (I)
            and then Nb_Results = Original_Length then
              --  Restricted, and no shorter mapcodes exist:
              --   do not generate mapcodes
              R.Set_Null;
            else
              R := As_U.Tus (Encode_Grid (Enc, I, Mm,
                    Header_Letter(I), Extra_Digits));
            end if;
          end if;

          if R.Length > 4 then
            R := As_U.Tus (Aeu_Pack (R, False));
            Store_Code := Territory_Number;
            if State_Override >= 0 then
              Store_Code := State_Override;
            end if;

            Mc_Info.Mapcode := R;
            Mc_Info.Territory_Alpha_Code :=
                As_U.Tus (Get_Territory_Alpha_Code (Territories (Store_Code)));
            Mc_Info.Full_Mapcode :=
                (if Store_Code = Ccode_Earth then As_U.Asu_Null
                 else Mc_Info.Territory_Alpha_Code & " ") & R;
            Mc_Info.Territory := Territories (Store_Code);
            Nb_Results := Nb_Results + 1;
            Results (Nb_Results) := Mc_Info;

            exit when Get_Shortest;
          end if;
        end if;
      end if;
      end loop;
    end Scan;

  begin
    if Tn in From_Territory .. Upto_Territory then
      From_Territory := Tn;
      Upto_Territory := Tn;
    end if;

    for Territory_Number in From_Territory .. Upto_Territory loop
      Go_On := True;
      Original_Length := Nb_Results;
      From := Data_First_Record (Territory_Number);
      if Ndata.Data_Flags(From + 1) = 0 then
        Go_On := False;
      end if;
      if Go_On then
        Upto := Data_Last_Record (Territory_Number);
        if Territory_Number /= Ccode_Earth
        and then not Fits_Inside (Enc.Coord32, Min_Max_Setup (Upto)) then
          Go_On := False;
        end if;
      end if;
      if Go_On then
        Scan (Territory_Number);
      end if;
    end loop;

    return Results (1 .. Nb_Results);
  end Mapcoder_Engine;

  function Master_Decode (Mapcode : String; Territory_Number : Natural)
           return Coordinate is
    Map_Code : As_U.Asu_Us := As_U.Tus (Mapcode);
    Extensionchars : As_U.Asu_Us;
    Minpos : constant Natural := Map_Code.Locate ("-");
    Mclen : Positive;
    Number : Natural;
    Parent : Integer;
    From, Upto : Integer;
    Prefixlength, Postfixlength, Incodex : Integer;
    Zone : Mapcode_Zone_Rec;
    Codex : Integer;
    Nr_Zone_Overlaps : Natural;
    Coord32 : Coord_Rec;
    Zfound, Z : Mapcode_Zone_Rec;

    procedure Try_Smaller (M : in Integer) is
    begin
      for J in From .. M - 1 loop
        -- Try all smaller rectangles j
        if not Is_Restricted (J) then
          Z := Mz_Restrict_Zone_To (Zone, Min_Max_Setup (J));
          if not Mz_Is_Empty (Z) then
            Nr_Zone_Overlaps := Nr_Zone_Overlaps + 1;
            if Nr_Zone_Overlaps = 1 then
               -- First fit! remember...
               Zfound := Z;
            else
              -- More than one hit, give up
              exit;
            end if;
          end if;
        end if;
      end loop;
    end Try_Smaller;

  begin
    if Minpos > 1 then
      Extensionchars := Map_Code.Uslice (Minpos + 1, Map_Code.Length);
      Map_Code := Map_Code.Uslice (1, Minpos - 1);
    end if;
    Map_Code := As_U.Tus (Aeu_Unpack (Map_Code.Image));
    if Map_Code.Is_Null then
      -- Failed to decode!
      raise Decode_Error;
    end if;

    Mclen := Map_Code.Length;
    Number := Territory_Number;
    if Mclen >= 10 then
      Number := Ccode_Earth;
    end if;

    -- Long codes in states are handled by the country
    Parent := Get_Parent (Territories (Number));
    if Parent >= 0 then
      if Mclen >= 9 or else
        (Mclen >= 8 and then
           (Parent = Ccode_Ind or else Parent = Ccode_Mex)) then
        Number := Parent;
      end if;
    end if;

    From := Data_First_Record (Number);
    if From < 0 or else Ndata.Data_Flags(From + 1) = 0 then
      raise Decode_Error;
    end if;
    Upto := Data_Last_Record (Number);

    Prefixlength := Map_Code.Locate (".") - 1;
    Postfixlength := Mclen - 1 - Prefixlength;
    Incodex := Prefixlength * 10 + Postfixlength;
    Zone := Mz_Empty;

    for M in From .. Upto loop
      Codex := Co_Dex (M);
      if Rec_Type (M) = 0
      and then not Is_Nameless(M)
      and then (Incodex = Codex or else (Incodex = 22 and then Codex = 21)) then
        Zone := Decode_Grid (Map_Code.Image, Extensionchars.Image, M);
        -- First of all, make sure the zone fits the country
        Zone := Mz_Restrict_Zone_To (Zone, Min_Max_Setup (Upto));
        if not Mz_Is_Empty (Zone) and then Is_Restricted (M) then
          Nr_Zone_Overlaps := 0;
          -- Get midpoint in microdegrees
          Coord32 := Convert_Fractions_To_Coord32 (
              Mz_Mid_Point_Fractions (Zone));
          for J in reverse M - 1 .. From loop
            -- Look in previous rects
            if not Is_Restricted (J) then
              if Fits_Inside (Coord32, Min_Max_Setup (J)) then
                Nr_Zone_Overlaps := Nr_Zone_Overlaps + 1;
                exit;
              end if;
            end if;
          end loop;

          if Nr_Zone_Overlaps = 0 then
            -- See if mapcode zone OVERLAPS any sub-area...
            Try_Smaller (M);

            if Nr_Zone_Overlaps = 1 then
              -- Intersected exactly ONE sub-area?
              -- Use the intersection found...
              Zone := Zfound;
            end if;
          end if;
          if Nr_Zone_Overlaps = 0 then
              Zone := Mz_Empty;
          end if;
        end if;
        exit;
      elsif Rec_Type(M) = 1 and then Codex + 10 = Incodex
      and then Header_Letter(M)'Length = 1
      and then Header_Letter(M)(1) = Map_Code.Element (1) then
        Zone := Decode_Grid (Map_Code.Slice(2, Map_Code.Length),
                             Extensionchars.Image, M);
        exit;
      elsif Is_Nameless (M) and then
            ((Codex = 21 and then Incodex = 22) or else
             (Codex = 22 and then Incodex = 32) or else
             (Codex = 13 and then Incodex = 23)) then
        Zone := Decode_Nameless (Map_Code.Image, Extensionchars.Image, M, From);
        exit;
      elsif Rec_Type(M) > 1 and then Postfixlength = 3
      and then Codex_Len(M) = Prefixlength + 2 then
        Zone := Decode_Auto_Header (Map_Code.Image, Extensionchars.Image, M);
        exit;
      end if;
    end loop;

    Zone := Mz_Restrict_Zone_To (Zone, Min_Max_Setup (Upto));
    if Mz_Is_Empty(Zone) then
      raise Decode_Error;
    end if;

    return Convert_Fractions_To_Degrees (Wrap (Mz_Mid_Point_Fractions (Zone)));

  end Master_Decode;

  -- Legacy interface
  function Encode (Coord : Coordinate;
                   Territory_Code : String := "";
                   Shortest : Boolean := False;
                   Precision : Precisions := 0;
                   Sort : Boolean := False) return Mapcode_Infos is
    Result : Mapcode_Infos := Mapcoder_Engine (
      Enc => Get_Encode_Rec (Coord.Lat, Coord.Lon),
      Tn => (if Territory_Code = "" then Error
             else Integer (Get_Territory (Territory_Code))),
      Get_Shortest => Shortest,
      State_Override => -1,
      Extra_Digits => Precision);
    -- First and last index of the mapcodes, of the same territory,
    --  producing the shortest mapcode
    First, Last : Natural := 0;
    Len : Positive := Positive'Last;
    use type As_U.Asu_Us;
  begin
    if not Sort then
      return Result;
    end if;
    -- Search shortest mapcode (First) and the last mapcode for the
    -- same territory as First
    for I in Result'Range loop
      if Result(I).Mapcode.Length < Len then
        First := I;
        Len := Result(I).Mapcode.Length;
      end if;
      if Result(I).Territory_Alpha_Code
       = Result(First).Territory_Alpha_Code then
        Last := I;
      end if;
    end loop;
    -- Move First .. Last at beginning of list
    if First /= Result'First then
      declare
         Slice : constant Mapcode_Infos := Result(First .. Last);
      begin
        Result(Last-First+2 .. Last) := Result(Result'First .. First-1);
        Result(Result'First .. Result'First+Last-First) := Slice;
      end;
    end if;
    return Result;
  end Encode;

  function Decode (Mapcode, Context : String) return Coordinate is
    Contextterritorynumber : Integer;
  begin
    -- Raise Decode error if Mapcode or Context is not in Roman
    declare
      Lm, Lc : Mapcodes.Languages.Language_List;
      use type Mapcodes.Languages.Language_List;
    begin
      Lm := Mapcodes.Languages.Get_Language (
              Ada.Characters.Handling.To_Wide_String (Mapcode));
      if Context /= "" then
        Lc := Mapcodes.Languages.Get_Language (
                Ada.Characters.Handling.To_Wide_String (Context));
      else
        Lc := Mapcodes.Languages.Default_Language;
      end if;
      if Lm /= Mapcodes.Languages.Default_Language
      or else Lc /= Mapcodes.Languages.Default_Language then
        raise Decode_Error;
      end if;
    exception
      when Mapcodes.Languages.Invalid_Text =>
        raise Decode_Error;
    end;
    -- Set context number
    if Context = Undefined then
      Contextterritorynumber := Ccode_Earth;
    else
      Contextterritorynumber := Integer (Get_Territory (Context));
    end if;
    -- Decode
    return Master_Decode (Mapcode, Contextterritorynumber);
  end Decode;

end Mapcodes;

