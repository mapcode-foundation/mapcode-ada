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

with Language_Defs, Language_Utils;
package Mapcodes.Languages is

  -- The supported languages
  -- The language names in Roman are the Mixed_Str images of these enums
  type Language_List is new Language_Defs.Language_List;
  -- Roman, Greek, Cyrillic, Hebrew, Devanagari, Malayalam, Georgian, Katakana,
  -- Thai, Lao, Armenian, Bengali, Gurmukhi, Tibetan, Arabic, Korean, Burmese,
  --  Khmer, Sinhalese, Thaana, Chinese, Tifinagh, Tamil, Amharic, Telugu, Odia,
  --  Kannada, Gujarati

  -- The unicode sequence to provide a language name in its language
  subtype Unicode_Sequence is Language_Utils.Unicode_Sequence;

  -- Get the Language from its name in its language
  -- Raises, if the output language is not known:
  Unknown_Language : exception;
  function Get_Language (Name : Unicode_Sequence) return Language_List;

  -- Get the language of a text (territory name or mapcode)
  -- All the characters must be of the same language, otherwise raises
  Invalid_Text : exception;
  function Get_Language (Input : Wide_String) return Language_List;

  -- The default language
  Default_Language : constant Language_List := Roman;

  -- Conversion of a text (territory name or mapcode) into a given language
  -- The language of the input is detected automatically
  -- Raises Invalid_Text if the input is not valid
  function Convert (Input : Wide_String;
                    Output_Language : Language_List := Default_Language)
           return Wide_String;

end Mapcodes.Languages;

