# Mapcode Library for Ada

[![License](http://img.shields.io/badge/license-APACHE2-blue.svg)]()
[![Release](https://img.shields.io/github/release/mapcode-foundation/mapcode-ada.svg?maxAge=3600)](https://github.com/mapcode-foundation/mapcode-ada/releases)


**Copyright (C) 2003-2018 Stichting Mapcode Foundation (http://www.mapcode.com)**

----

# License

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Original C library created by Pieter Geelen. Work on Java version
of the Mapcode library by Rijn Buve and Matthew Lowden. Port into Ada (except
multi-language support) by Pascal Malaise.

The original Ada port can be found at: 
https://github.com/malaise/ada/tree/master/usr/mapcode

# Ada Files for Mapcode Support

The following files, in directory `src`, provide utilities and data for mapcode
processing:

    mapcode-utils.ads             - Root package of the utilities:
    as_u.ads as_u.adb             - Unbounded strings
    bits.ads bits.adb             - Bit operations
    str_tools.ads str_tools.adb   - String utilities
	ndata.ads                     - Private data table for mapcode support

The following files provide the Ada interface for mapcodes:

    mapcode.ads mapcode.adb       - Key operations for mapcode support
	countries.ads                 - Nums, Codes and Names of territories
    

The following file contains the main procedure for testing the interfaces:

    t_mapcode.adb                   - Command line tool to test Ada mapcodes


In directory `test`, the command `fulltest` launches a complete test of the
library.

# Using the Library

## Operations related to territories

A territory is identified either by a number (a string of 1 to 3 digits such as "42"), or by a code (an ISO 3166 code such as “NLD” or "US-DC")
with some possible aliases (example "US" = "USA"). 

Large territories (MX, IN, AU, BR, US, CA, RU and CN) are decomposed into
subdivisions.

A territory is designated by a unique territory identifier of (a private) type  `Territories`. 

`Get_Territory` returns the territory identifier of a territory code. An
optional context helps to interpret ambiguous (abbreviated) alphacodes of
subdivisions, such as "AL". If the territory code is not known or if several
subdivisions match the specification (no context provided) it raises the exception `Unknown_Territory`. 

Note: The check for ambiguity is strict among subdivisions but does not apply to aliases. As a consequence, "TAM" corresponds to "MX-TAM" without error despite "RU-TAM is also an alias for "RU-TT". (Aliases are not ambiguous among them, but would it be the case then Get_Territory would return one of them without error).

Attribute | Description
--- | ---
`Territory_Code` | string, the ISO code such as “USA”, or number image such as "232" of the territory to search
`Context` | optional string, an ISO code such as “US” (but territory numbers are not accepted) indicating the territory when `Territory_Code` is a subdivision
return value | `Territories`, territory identifier
exceptions | `Unknown_Territory` if the territory code is not known or ambiguous

Examples:

Search a territory with an ambiguous code.

    Get_Territory ("AR")
    -> Unknown_Territory

Non ambiguous code.

    Get_Territory ("IN-AR")
    -> 285              // IN-AR/Arunachal Pradesh

Ambiguous code and context.

    Get_Territory ("IN", "AR")
    -> 285              // IN-AR/Arunachal Pradesh

`Get_Territory_Number` of a territory returns the string image of a territory, from "0" for "VAT" (Vatican), to "532" for "AAA" (International).

Attribute | Description
--- | ---
`Territory` | `Territories`, the identifier of the territory to get the number of
return value | string image of the number of `Territory`


`Get_Territory_Alpha_Code` returns the territory ISO 3166 code of a territory.

Attribute | Description
--- | ---
`Territory` | `Territories`
`Format` | either `Local` (often ambiguous), `International` (full and unambiguous, default), or `Shortest`
return value | string, territory ISO code

Examples:

    Get_Territory_Alpha_Code (365)
    -> "US-AR"

    Get_Territory_Alpha_Code (365, Local)
    -> "AR"

    Get_Territory_Alpha_Code (365, Shortest)
    -> "US-AR"        // Because AR is ambiguous (IN-AR)

    Get_Territory_Alpha_Code (391, Shortest)
    -> "CA"           // US-CA, not ambiguous

`Get_Territory_Fullname` returns the full common name of a territory. From the names defined in package Countries, this is the string up to the first ' (' if any.

Attribute | Description
--- | ---
`Territory` | `Territories`
return value | string, territory name

Example:

    Get_Territory_Fullname (391)
    -> California

`Get_Parent_Of` returns the parent territory of a subdivision.

Attribute | Description
--- | ---
`Territory` | `Territories`
return value | `Territories`, parent territory identifier
exceptions | `Not_A_Subdivision`, if the `Territory` has no parent (i.e. is not a subdivision)

`Is_Subdivision` returns True if the provided territory is a subdivision.

attribute | description
--- | ---
`Territory` | `Territories`
return value | boolean, True if and only if the `Territory` is a subdivision

`Has_Subdivision` returns True if the provided territory has subdivisions.

attribute | description
--- | ---
`Territory` | `Territories`
return value | boolean, True if and only if the `Territory` has some subdivisions

`Get_Subdivisions_With` returns the array (possibly empty) of territories with the same subdivision name (suffix) as the one provided.

attribute | description
--- | ---
`Subdivision` | String
return value | array of `Territories` that have the same subdivision name as `Subdivision`

Example:

    Get_Subdivisions_With ("AL")
	-> 364    // US-AL
       318    // BR-AL
       482    // RU-AL
 

## Converting a Coordinate into Mapcodes

In the mapcode system, territories are limited by rectangles, not by actual or
political borders. This means that a coordinate will often yield mapcode
possibilities in more than one territory. Each possibility correctly represents
the coordinate, but which one is *politically* correct is a choice that must be
made (in advance or afterwards) by the caller or user of the routines.

There is only one operation, `Encode`, which generates the possible mapcodes
for a coordinate. At least it takes as input a latitude in degrees (all values
allowed, maximized by routine to 90.0 and minimized to -90.0) and a longitude
in degrees (all values allowed, wrapped to -180.0 and +180.0).

The other arguments are options to be adapted to the situation.

The operation returns an array (possibly with only one element) of mapcodes.

attribute | description 
--- | --- 
`Coord` | coordinate (latitude and longitude in degrees, reals) to encode as mapcodes
`Territory` | optional string, an ISO code (such as “NLD”) or territory number (such as "112") to restrict the territory scope of the mapcodes
`Shortest` | boolean, default True, to return only the shortest possible mapcode for the territory or each possible territory
`Precision` | 0 to 8, default 0, precision of the mapcode to generate
`Sort` | sort the territories so that the shortest mapcode appears first
return value | array of mapcode informations (territory ISO code, mapcode, full mapcode, and territory number)

This function will return at least one result: the shortest mapcode (if any)
that exists for that coordinate within the specified territory. Such a mapcode
is also sometimes called the “default mapcode” for a particular territory.  
The resulting array is always organized by territories: all the mapcodes
of a territory follow each other and in order of increasing length.  
If Sort is set, then the returned array contains first the shortest
mapcode, then possibly the other mapcodes for the same territory,
then possibly mapcodes for other territories, then possibly the
international (Earth) mapcode, otherwise the territories appear in the crescent
order of Territories (see package Countries).  
As a consequence, if it appears, the international mapcode is always the last.

Examples:

With a `Territory` specified, and `Shortest` set, returns the default mapcode for this
territory.

    Encode ( (52.376514000001, 4.908543375000), "NLD")
    -> NLD 49.4V 'NLD 49.4V' 112

With a Territory set to Earth ("AAA"), returns the international mapcode,
(whatever Shortest)

    Encode ( (52.376514000001, 4.908543375000), "AAA")
    -> AAA VHXGB.1J9J 'VHXGB.1J9J' 532

With a `Territory` specified, and `Shortest`set to False, returns all the possible mapcodes
for this territory.

    Encode ( (52.376514000001, 4.908543375000), "NLD", Shortest => False)
    -> NLD 49.4V 'NLD 49.4V' 112
       NLD G9.VWG 'NLD G9.VWG' 112
       NLD DL6.H9L 'NLD DL6.H9L' 112
       NLD P25Z.N3Z 'NLD P25Z.N3Z' 112

With no limitation to a territory (and `Shortest` set), returns at least a
worldwide mapcode (territory AAA, code 532), and possibly some mapcodes in
territories.

    Encode ( (52.376514000001, 4.908543375000) )
    -> NLD 49.4V 'NLD 49.4V' 112
       AAA VHXGB.1J9J 'VHXGB.1J9J' 532

With Sort set, return the territory with shortest mapcode first.

    Encode ( (39.730409000, -79.954163500), "", Shortest => False, Sort => False)
    -> US-WV W2W2.Q41V 'US-WV W2W2.Q41V' 353
       US-PA BYLP.73 'US-PA BYLP.73' 361
       US-PA HDWQ.NZN 'US-PA HDWQ.NZN' 361
       US-PA W2W2.Q41V 'US-PA W2W2.Q41V' 361
       USA W2W2.Q41V 'USA W2W2.Q41V' 410
       AAA S8LY1.RD84 'S8LY1.RD84' 532

    Encode ( (39.730409000, -79.954163500), "", Shortest => False, Sort => True)
    -> US-PA BYLP.73 'US-PA BYLP.73' 361
       US-PA HDWQ.NZN 'US-PA HDWQ.NZN' 361
       US-PA W2W2.Q41V 'US-PA W2W2.Q41V' 361
       US-WV W2W2.Q41V 'US-WV W2W2.Q41V' 353
       USA W2W2.Q41V 'USA W2W2.Q41V' 410
       AAA S8LY1.RD84 'S8LY1.RD84' 532

With a `Precision` of 2, returns higher precision mapcodes.

    Encode ( (52.376514000001, 4.908543375000), Precision => 2)
    -> NLD 49.4V-K3 'NLD 49.4V-K3' 112
       AAA VHXGB.1J9J-RD 'VHXGB.1J9J-RD' 532


## Converting a Mapcode into a Coordinate

There is only one operation, `Decode`, which gives the coordinate of a
mapcode.  It accepts an optional argument to define the territory context of
the mapcode.

The operation returns the coordinate (latitude and longitude in degrees), or
raises the exception `Decode_Error` if the mapcode is not valid or ambiguous
(in the context).

Attribute | Description 
--- | --- 
`Mapcode` | string, mapcode to decode
`Context` | optional string, an ISO code (such as “NLD”) or territory number (such as "112") to indicate territory for the scope of the mapcode
return value | coordinate (latitude and longitude in degrees), reals
exceptions | `Decode_Error`, if the mapcode is invalid or ambiguous in the Context

Examples:

Without any `Context`, only accept a worldwide mapcode.

    Decode ("49.4V")
    Raises Decode_Error             // Ambiguous
 
    Decode ("VHXGB.1J9J")
    -> (52.376504000000, 4.908535500000)

With a `Context` set, decode a short mapcode.

    Decode ("49.4V", "NLD")
    -> (52.376514000001, 4.908543375000)

# Using the testing program

The command line testing tool `t_mapcode` can perform mainly three actions:

* Display information on a territory

* Decode a mapcode (with an optional context) into a coordinate

* Encode a coordinate into mapcodes, according to options

Usage:

    t_mapcode <command>
    -h                                             // This help
    -t <territory>                                 // Territory info
    -s <subdivision>                               // Same subdivisions
	-S <name>                                      // Search territory
    -d <territory_mapcode>                         // Decode
    -c <lat> <lon> [ <options> ]                   // Encode
    -a <territory_mapcode> [ <options> ]           // Alternative mapcodes
    <territory_mapcode> ::= <territory>:<mapcode> | [ <territory> ] <mapcode>
    <options>           ::= [ <territory> ] [ <selection> ] [ <precision> ]
    <selection>         ::= [ all | local | short] // Default short
                        // Default: one mapcode (the shortest) of each territory
                        // all: all the mapcodes of all territories
                        // local: the shortest among all the mapcodes
    <precision>         ::= P0 to P8               // Default P0


Default selection leads to encode with Shortest => True, while `all` leads to
encode with Shortest => False, and 'local' leads to encode with Shortest => True
and Shortest => True and to display the first entry of the returned array.

Examples:

Put information on a territory (providing ISO code or number). The information consists in the territory number, followed by three possible mapcodes (Local, International and Shortest), followed by the territory full name.

    t_mapcode -t KIR
    -> KIR => 58: KIR/KIR/KIR/Kiribati

    t_mapcode -t CA
    -> CA => 391: CA/US-CA/CA/California
         Parent: USA

    t_mapcode -t 410
    -> USA => 410: USA/USA/USA/USA
         Has subdivisions

List all subdivisions named "xx-AL".

	t_mapcode -s AL
	-> US-AL => 364: AL/US-AL/US-AL/Alabama
         Parent: USA
       BR-AL => 318: AL/BR-AL/BR-AL/Alagoas
         Parent: BRA
       RU-AL => 482: AL/RU-AL/RU-AL/Altai Republic
         Parent: RUS
		 Search a territory by name.

Search a territory by name containing "alabama" (case insensitive)

	t_mapcode -S alabama
    -> 364 => 364: AL/US-AL/US-AL/Alabama
	     Parent: USA

Encode a coordinate with a context and a precision, put information of the shortest mapcode.
Information is the territory context of the mapcode, then the mapcode, then the full mapcode (territory and mapcode separated by a space and enclosed by quotes, except for international mapcodes where there is no territory), and then the territory number.

    t_mapcode -c 52.376482500 4.908511796 NLD P2
    ->   52.376482500    4.908511796
       => NLD 49.4V-V2 'NLD 49.4V-V2' 112

Put all shorters mapcodes of a coordinate (no context).

    t_mapcode -c 52.376482500 4.908511796 
    ->  52.376482500    4.908511796
       => NLD 49.4V 'NLD 49.4V' 112
       => AAA VHXGB.1J9J 'VHXGB.1J9J' 532

Put all mapcodes of a coordinate with a context.

    t_mapcode -c 52.376482500 4.908511796 NLD false
    -> 52.376482500    4.908511796
       => 49.4V NLD 'NLD 49.4V' 112
       => G9.VWG NLD 'NLD G9.VWG' 112
       => DL6.H9L NLD 'NLD DL6.H9L' 112
       => P25Z.N3Z NLD 'NLD P25Z.N3Z' 112

Put all mapcodes of a coordinate.

    t_mapcode -c 39.730409000  -79.954163500 all 
    -> 39.730409000  -79.954163500
       => US-WV W2W2.Q41V 'US-WV W2W2.Q41V' 353
       => US-PA BYLP.73 'US-PA BYLP.73' 361
       => US-PA HDWQ.NZN 'US-PA HDWQ.NZN' 361
       => US-PA W2W2.Q41V 'US-PA W2W2.Q41V' 361
       => USA W2W2.Q41V 'USA W2W2.Q41V' 410
       => AAA S8LY1.RD84 'S8LY1.RD84' 532

Put the local mapcode of a coordinate.

    t_mapcode -c 39.730409000  -79.954163500 local
    -> 39.730409000  -79.954163500
       => US-PA BYLP.73 'US-PA BYLP.73' 361

Decode a mapcode, no context.

    t_mapcode -d 49.4V
    -> 49.4V
       raised MAPCODES.DECODE_ERROR

    t_mapcode -d VHXGB.1J9J
    -> VHXGB.1J9J
       => 52.376504000000 4.908535500000

Decode a mapcode with context.

    t_mapcode -d NLD 49.4V 
    -> NLD 49.4V
       => 52.376514000001 4.908543375000

Put alternative mapcodes for a mapcode (shortests).

    t_mapcode -a NLD 49.4V
    -> 49.4V NLD
       => NLD 49.4V 'NLD 49.4V' 112
       => AAA VHXGB.1J9J 'VHXGB.1J9J' 532

# Version History

### 1.1.4
* Find non ambiguous subdivision before alias

### 1.1.4
* Move apart the public characteristics of territories
* Rename Image into Get_Territory_Number

### 1.1.3
* Rename Get_Territory_Number into Get_Territory

### 1.1.2
* Make Territory_Number a private type and rename it
* Add the function Image of a territory
* Test with any precision (0 to 8)
* Swap options S and s
* Improve resolution to 12 digits
* Align length of country names and codes

### 1.0.12
* Support encoding precision up to 8

### 1.0.11
* Rewrite Iso2Ccode

### 1.0.10
* Resolve subdivision without territory only if unambiguous
* Reject subdivision with wrong territory
* Get_Subdivisions_With takes a subdivision simple code

### 1.0.9
* Add function Get_Subdivisions_With that lists subdivisions with same suffix

### 1.0.8
* Remove parsing of partial context in the mapcode to decode

### 1.0.7
* Add option -a of t_mapcode to list alternative mapcodes and improve parsing of arguments
* Add new points to the test
* Add option of fulltest to play only the scenario
* Size Territory_Range from Ctrynams.Isofullname length

### 1.0.6
* Add an option to sort the returned list of mapcodes
* Add to t_mapcode a "local/all" option and support for "\<territory\>:\<mapcode\>"

### 1.0.4
* Fix detection of invalid character in mapcode extension
* Improve comments
* In t_mapcode arguments and inputs, move the optional context before the mapcode
* Remove useless ctrynams_short.ads

### 1.0.0
* Update years of copyright
* Fix and improve accuracy
* Add automatic tests of territory, encoding and decoding, including expected
failures. Fix defects.
* Align max nr of mapcode results to C value, and check overflow
* Get rid of global variable (Disambiguate)
* Initial version  for public domain release.

