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

-- Various utilities on strings
package Mapcode_Utils.Str_Tools is

  -- Convert the characters of Str into upper char
  function Upper_Str (Str : String) return String;

  -- Convert the characters of Str:
  -- Any letter that follows a letter is lower char
  -- Any other  letter (including the first letter) is UPPER char
  function Mixed_Str (Str : String) return String;

  -- Locate the Nth occurence of a fragment within a string,
  --  between a given index (first/last if 0) and the end/beginning of the
  --  string, searching forward or backward
  -- Return the index in Within of the char matching the start of Fragment
  -- Return 0 if Index not in Within, if Within or Fragment is empty,
  --  or if not found
-- Locate Nth occurence of a fragment within a string,
  --  between a given index (first/last if 0) and the end/beginning of string,
  --  searching forward or backward
  -- Returns index in Within of char matching start of Fragment
  --  or 0 if not found or if Within or Fragment is empty
  function Locate (Within     : String;
                   Fragment   : String;
                   From_Index : Natural := 0;
                   Forward    : Boolean := True;
                   Occurence  : Positive := 1)
           return Natural;

end Mapcode_Utils.Str_Tools;

