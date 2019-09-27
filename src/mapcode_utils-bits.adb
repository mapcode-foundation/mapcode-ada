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

with Ada.Unchecked_Conversion;

-- Suppress warning than System.Bit_Ops is an internal GNAT unit
--  thus not portable
pragma Warnings (Off, "* is an internal GNAT unit");
with System.Bit_Ops;
pragma Warnings (On,  "* is an internal GNAT unit");

with Interfaces;

package body Mapcode_Utils.Bits is


  function To_Unsigned_32 is new Ada.Unchecked_Conversion
    (Source => Integer, Target => Interfaces.Unsigned_32);
  function To_Integer is new Ada.Unchecked_Conversion
    (Source => Interfaces.Unsigned_32, Target => Integer);

  function To_Unsigned_64 is new Ada.Unchecked_Conversion
    (Source => Ll_Integer, Target => Interfaces.Unsigned_64);
  function To_Ll_Integer is new Ada.Unchecked_Conversion
    (Source => Interfaces.Unsigned_64, Target => Ll_Integer);

  -- Integer
  function "And" (Left, Right : Integer) return Integer is
    Res : Integer;
  begin
    System.Bit_Ops.Bit_And (Left'Address, Left'Size,
                            Right'Address, Right'Size,
                            Res'Address);
    return Res;
  end "And";

  function "Or"  (Left, Right : Integer) return Integer is
    Res : Integer;
  begin
    System.Bit_Ops.Bit_Or (Left'Address, Left'Size,
                           Right'Address, Right'Size,
                           Res'Address);
    return Res;
  end "Or";

  function "Xor" (Left, Right : Integer) return Integer is
    Res : Integer;
  begin
    System.Bit_Ops.Bit_Xor (Left'Address, Left'Size,
                            Right'Address, Right'Size,
                            Res'Address);
    return Res;
  end "Xor";

  function "Not" (Val : Integer) return Integer is
    Res : Integer;
  begin
    System.Bit_Ops.Bit_Not (Val'Address, Val'Size,
                            Res'Address);
    return Res;
  end "Not";

  function Shl (Val : Integer; Bits : Integer) return Integer is
    (To_Integer(Interfaces.Shift_Left(To_Unsigned_32(Val), Bits)));

  function Shr (Val : Integer; Bits : Integer) return Integer is
    (To_Integer(Interfaces.Shift_Right(To_Unsigned_32(Val), Bits)));

  -- Long_Long_Integer
  function "And" (Left, Right : Ll_Integer) return Ll_Integer is
    Res : Ll_Integer;
  begin
    System.Bit_Ops.Bit_And (Left'Address, Left'Size,
                            Right'Address, Right'Size,
                            Res'Address);
    return Res;
  end "And";

  function "Or"  (Left, Right : Ll_Integer) return Ll_Integer is
    Res : Ll_Integer;
  begin
    System.Bit_Ops.Bit_Or (Left'Address, Left'Size,
                           Right'Address, Right'Size,
                           Res'Address);
    return Res;
  end "Or";

  function "Xor" (Left, Right : Ll_Integer) return Ll_Integer is
    Res : Ll_Integer;
  begin
    System.Bit_Ops.Bit_Xor (Left'Address, Left'Size,
                            Right'Address, Right'Size,
                            Res'Address);
    return Res;
  end "Xor";

  function "Not" (Val : Ll_Integer) return Ll_Integer is
    Res : Ll_Integer;
  begin
    System.Bit_Ops.Bit_Not (Val'Address, Val'Size, Res'Address);
    return Res;
  end "Not";

  function Shl (Val : Ll_Integer; Bits : Integer) return Ll_Integer is
    (To_Ll_Integer(Interfaces.Shift_Left (To_Unsigned_64(Val), Bits)));

  function Shr (Val : Ll_Integer; Bits : Integer) return Ll_Integer is
    (To_Ll_Integer(Interfaces.Shift_Right (To_Unsigned_64(Val), Bits)));

end Mapcode_Utils.Bits;

