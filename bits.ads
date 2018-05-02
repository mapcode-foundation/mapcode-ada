--------------------------------------------------------------------------------
-- Copyright (C) 2014-2015 Stichting Mapcode Foundation (http://www.mapcode.com)
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--------------------------------------------------------------------------------

-- Bit operations
package Bits is

  -- Bit and, bit or, bit neg, shift left and shift right

  -- Operations on integers
  function "And" (Left, Right : Integer) return Integer with Inline => True;
  function "Or"  (Left, Right : Integer) return Integer with Inline => True;
  function "Xor" (Left, Right : Integer) return Integer with Inline => True;
  function "Not" (Val : Integer) return Integer with Inline => True;
  function Shl (Val : Integer; Bits : Integer) return Integer
    with Inline => True;
  function Shr (Val : Integer; Bits : Integer) return Integer
    with Inline => True;

  -- Operations on long long integers
  subtype Ll_Integer is Long_Long_Integer;
  function "And" (Left, Right : Ll_Integer) return Ll_Integer
    with Inline => True;
  function "Or"  (Left, Right : Ll_Integer) return Ll_Integer
    with Inline => True;
  function "Xor" (Left, Right : Ll_Integer) return Ll_Integer
    with Inline => True;
  function "Not" (Val : Ll_Integer) return Long_Long_Integer
    with Inline => True;
  function Shl (Val : Ll_Integer; Bits : Integer) return Ll_Integer
    with Inline => True;
  function Shr (Val : Ll_Integer; Bits : Integer) return Ll_Integer
    with Inline => True;

end Bits;

