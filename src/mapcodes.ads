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

-- Mapcode management
with Mapcode_Utils.As_U;
private with Countries;
package Mapcodes is

  Mapcode_C_Version : constant String := "2.0.2";
  Mapcode_Data_Version : constant String := "2.3.0";
  Mapcode_Ada_Version  : constant String := "1.1.5/Data"
                                          & Mapcode_Data_Version;

  -- Real type (for latitude and longitude)
  type Real is digits 15 range -1.79E308 .. 1.79E308;

  -----------------
  -- TERRITORIES --
  -----------------
  -- Valid territory identifier
  type Territories is private;


  -- Given an ISO 3166 alphacode (such as "US-AL" or "FRA"), return the
  --  corresponding territory identifier or raise Unknown_Territory
  -- A Context territory helps to interpret ambiguous (abbreviated)
  --  alphacodes, such as "BR" or "US" for the subdivision "AL"
  -- Territory_Code can also be the number of the territory (ex "364" for US-AL)
  -- Raise, if Territory or Context is not known, or if Territory is ambiguous
  --  and no contextex is provided:
  Unknown_Territory : exception;
  function Get_Territory (Territory_Code : String;
                          Context : String := "") return Territories;
  -- Note about aliases and ambiguity: The check for ambiguity is strict among
  --      subdivisions but does not apply to aliases. As a consequence, "TAM"
  --      corresponds to "MX-TAM" without error despite "RU-TAM is also an alias
  --      for "RU-TT". (Aliases are not ambiguous among them, but would it be
  --      the case then Get_Territory would return one of them without error).

  -- Return the number of a territory ("0" for Vatican to "532" for
  --   International)
  -- See package Countries, field Num of the territory definition
  function Get_Territory_Number (Territory : Territories) return String;

  -- Return the alphacode (usually an ISO 3166 code) of a territory
  -- Format: Local (often ambiguous), International (full and unambiguous,
  --  DEFAULT), or Shortest
  type Territory_Formats is (Local, International, Shortest);
  function Get_Territory_Alpha_Code (
      Territory : Territories;
      Format : Territory_Formats := International) return String;

  -- Return the full readable name of a territory (e.g. "France")
  --   This is the first part of the Name (see package Countries), before the
  --   first " (" if any
  function Get_Territory_Fullname (Territory : Territories) return String;

  -- Return the parent country of a subdivision (e.g. "US" for "US-AL")
  -- Raise, if Territory is not a subdivision:
  Not_A_Subdivision : exception;
  function Get_Parent_Of (Territory : Territories) return Territories;

  -- Return True if Territory is a subdivision (state)
  function Is_Subdivision (Territory : Territories) return Boolean;

  -- Return True if Territory is a country that has states
  function Has_Subdivision (Territory : Territories) return Boolean;

  -- Given a subdivision name, return the array (possibly empty) of territory
  --  subdivisions with the same name
  -- Ex: given "AL" return the array (318 (BR-AL), 482 (RU-AL), 364 (US-AL))
  type Territories_Array is array (Positive range <>) of Territories;
  function Get_Subdivisions_With (Subdivision : String)
           return Territories_Array;

  --------------------------
  -- Encoding to mapcodes --
  --------------------------
  -- Coordinate in fraction of degrees
  subtype Lat_Range is Real range  -90.0 ..  90.0;
  subtype Lon_Range is Real range -180.0 .. 180.0;
  type Coordinate is record
    Lat : Lat_Range;
    Lon : Lon_Range;
  end record;

  -- One mapcode-related information bloc
  type Mapcode_Info is record
    -- Territory code (AAA for Earth)
    Territory_Alpha_Code : Mapcode_Utils.As_U.Asu_Us;
    -- Simple mapcode
    Mapcode : Mapcode_Utils.As_U.Asu_Us;
    -- Territory, then a space and the mapcode,
    --  or simple mapcode if it is valid on Earth
    Full_Mapcode : Mapcode_Utils.As_U.Asu_Us;
    -- Territory
    Territory : Territories;
  end record;
  type Mapcode_Infos is array (Positive range <>) of Mapcode_Info;

  -- Encode a coordinate
  -- Return an array of mapcodes, each representing the specified coordinate.
  -- If a Territory alphacode or num is specified, then only mapcodes (if any)
  --   within that territory are returned. If Earth is provided as territory,
  --   then only the 9-letter "international" mapcode is returned
  -- If Shortest is set, then at most one mapcode (the "default" and
  --   "shortest possible" mapcode) in any territory are returned
  -- The Precision option leads to produce mapcodes extended with high-precision
  --  letters (the parameter specifies how many letters, 0 to 8, after a '-')
  -- The resulting array is always organized by territories: all the mapcodes
  --  of a territory follow each other and in order of increasing length.
  --  If Sort is set, then the returned array contains first the shortest
  --   mapcode, then possibly the other mapcodes for the same territory,
  --   then possibly mapcodes for other territories, then possibly the
  --   international (Earth) mapcode
  --  Otherwise the territories appear in the crescent order of Territory_Range
  --   (see package Countries)
  --  As a consequence, if it appears then the international mapcode is always
  --   the last
  subtype Precisions is Natural range 0 .. 8;
  Earth : constant String := "AAA";
  function Encode (Coord : Coordinate;
                   Territory_Code : String := "";
                   Shortest : Boolean := False;
                   Precision : Precisions := 0;
                   Sort : Boolean := False) return Mapcode_Infos;

  ------------------------
  -- Decoding a mapcode --
  ------------------------
  -- Decode a string containing a mapcode
  -- The optional Context territory alphacode shall be set if the mapcode is
  --  ambiguous (not "international")
  -- Return a coordinate or, if the mapcode is incorrect or ambiguous, raise:
  Decode_Error : exception;
  function Decode (Mapcode, Context : String) return Coordinate;

private
  type Territories is new Natural range 0 .. Countries.Territories_Def'Last - 1;
  -- Operation exported to child package Languages
  -- Packing and unpacking to avoid full digits mapcodes
  function Aeu_Pack (R : Mapcode_Utils.As_U.Asu_Us;
                     Short : Boolean) return String;
  function Aeu_Unpack (Str  : String) return String;
  -- Decode and encode a char
  function Decode_A_Char (C : Natural) return Integer;
  function Encode_A_Char (C : Natural) return Character;
end Mapcodes;

