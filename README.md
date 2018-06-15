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

The following files, in directory `src`, provide utilities for mapcode
processing:

    as_u.ads as_u.adb               - Unbounded strings
    bits.ads bits.adb               - Bit operations
    str_tools.ads str_tools.adb     - String utilities

The following files provide the Ada interface for mapcodes:

    mapcode.ads mapcode.adb         - Key operations for mapcode support
    ndata.ads                       - Data table for mapcode support
    ctrynams.ads                    - Names of territories (in English)

The following file contains the main procedure for testing the interfaces:

    t_mapcode.adb                   - Command line tool to test Ada mapcodes


In directory `test`, the command `fulltest` launches a complete test of the
library.

# Using the Library

## Operations related to territories

A territory is identified by a code (an ISO 3166 code such as “NLD” or "US-DC"),
with some possible aliases (example "US" = "USA"), and a unique number, from 0
for "VAT" (Vatican), to 532 for "AAA" (International), defined as
`Territory_Range`.

Large territories (MX, IN, AU, BR, US, CA, RU and CN) are decomposed into
subdivisions.

`Get_Territory_Number` returns the territory number of a territory code. An
optional context helps to interpret ambiguous (abbreviated) alphacodes of
subdivisions, such as "AL". If several subdivisions match the specification (no
context provided) it returns the lowest number that matches.

Attribute | Description
--- | ---
`Territory` | string, mapcode to decode
`Context` | optional string, (an ISO code such as “US”) territory for a subdivision
return value | `Territory_Range`, territory number
exceptions | `Unknown_Territory` if the territory code is not known

Examples:

First territory matching an ambiguous code.

    Get_Territory_Number ("AR")
    -> 365              // US-AR/Arkansas

Non ambiguous code.

    Get_Territory_Number ("IN-AR")
    -> 285              // IN-AR/Arunachal Pradesh

Ambiguous code and context.

    Get_Territory_Number ("IN", "AR")
    -> 285              // IN-AR/Arunachal Pradesh

`Get_Territory_Alpha_Code` returns the territory ISO 3166 code of a territory.

Attribute | Description
--- | ---
`Territory_Number` | `Territory_Range`
`Format` | `Local` (often ambiguous), `International` (full and unambiguous, default), or `Shortest`
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

`Get_Territory_Fullname` returns the full common name of a territory

Attribute | Description
--- | ---
`Territory_Number` | `Territory_Range`
return value | string, territory name

Examples:

    Get_Territory_Fullname (391)
    -> California

`Get_Parent_Of` returns the parent territory number of a subdivision.

Attribute | Description
--- | ---
`Territory_Number` | `Territory_Range`
return value | `Territory_Range`, parent territory number
exceptions | `Not_A_Subdivision`, if the `Territory_Number` has no parent (i.e. is not a subdivision)

`Is_Subdivision` returns True if the provided territory is a subdivision.

attribute | description
--- | ---
`Territory_Number` | `Territory_Range`
return value | boolean, True if and only if the `Territory_Number` is a subdivision

`Has_Subdivision` returns True if the provided territory has subdivisions.

attribute | description
--- | ---
`Territory_Number` | `Territory_Range`
return value | boolean, True if and only if the `Territory_Number` has some subdivisions

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
`Territory` | optional string, (an ISO code such as “NLD”) territory for the scope of the mapcodes
`Shortest` | boolean, default True, to return only the shortest possible mapcode for the territory or each possible territory
`Precision` | 0, 1 or 2, default 0, precision of the mapcode to generate
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
order of Territory_Range (see package Ctrynams).  
As a consequence, if it appears, the international mapcode is always the last.

Examples:

With a`Territory` specified, and `Shortest` set, returns the default mapcode for this
territory.

    Encode ( (52.376514000, 4.908543375 40.786245000), "NLD")
    -> NLD 49.4V 'NLD 49.4V' 112

With a Territory set to Earth ("AAA"), returns the international mapcode,
(whatever Shortest)

    Encode ( (52.376514000, 4.908543375 40.786245000), "AAA")
    -> AAA VHXGB.1J9J 'VHXGB.1J9J' 532

With a `Territory` specified, and `Shortest`set to False, returns all the possible mapcodes
for this territory.

    Encode ( (52.376514000, 4.908543375 40.786245000), "NLD", Shortest => False)
    -> NLD 49.4V 'NLD 49.4V' 112
    -> NLD G9.VWG 'NLD G9.VWG' 112
    -> NLD DL6.H9L 'NLD DL6.H9L' 112
    -> NLD P25Z.N3Z 'NLD P25Z.N3Z' 112

With no limitation to a territory (and `Shortest` set), returns at least a
worldwide mapcode (territory AAA, code 532), and possibly some mapcodes in
territories.

    Encode ( (52.376514000, 4.908543375 40.786245000) )
    -> NLD 49.4V 'NLD 49.4V' 112
    -> AAA VHXGB.1J9J 'VHXGB.1J9J' 532

With Sort set, return the territory with shortest mapcode first.

    Encode ( (39.730409000, -79.954163500), "", Sortest => False, Sort => False)
    -> US-WV W2W2.Q41V 'US-WV W2W2.Q41V' 353
    -> US-PA BYLP.73 'US-PA BYLP.73' 361
    -> US-PA HDWQ.NZN 'US-PA HDWQ.NZN' 361
    -> US-PA W2W2.Q41V 'US-PA W2W2.Q41V' 361
    -> USA W2W2.Q41V 'USA W2W2.Q41V' 410
    -> AAA S8LY1.RD84 'S8LY1.RD84' 532

    Encode ( (39.730409000, -79.954163500), "", Sortest => False, Sort => True)
    -> US-PA BYLP.73 'US-PA BYLP.73' 361
    -> US-PA HDWQ.NZN 'US-PA HDWQ.NZN' 361
    -> US-PA W2W2.Q41V 'US-PA W2W2.Q41V' 361
    -> US-WV W2W2.Q41V 'US-WV W2W2.Q41V' 353
    -> USA W2W2.Q41V 'USA W2W2.Q41V' 410
    -> AAA S8LY1.RD84 'S8LY1.RD84' 532

With a`Precision` of 2, returns high precision mapcodes.

    Encode ( (52.376514000, 4.908543375 40.786245000), Precision => 2)
    -> NLD 49.4V-K3 'NLD 49.4V-K3' 112
    -> AAA VHXGB.1J9J-RD 'VHXGB.1J9J-RD' 532


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
`Context` | optional string, (an ISO code such as “NLD”) territory for the scope of the mapcode
return value | coordinate (latitude and longitude in degrees), reals
exceptions | `Decode_Error`, if the mapcode is invalid or ambiguous in the Context

Examples:

Without any `Context`, only accept a worldwide mapcode.

    Decode ("49.4V")
    Raises Decode_Error             // Ambiguous
 
    Decode ("VHXGB.1J9J")
    -> (52.376504000, 4.908535500)

With a `Context` set, decode a short mapcode.

    Decode ("49.4V", "NLD")
    -> (52.376514000, 4.908543375)

# Using the testing program

The command line testing tool `t_mapcode` can perform 3 actions:

* Display information on a territory number or territory ISO 3166 code

* Decode a mapcode (with an optional context) into a coordinate

* Encode a coordinate into mapcodes, according to options

Usage:

    t_mapcode <command>
      -h                                // This help
      -t <territory>                    // Territory info
      -d [ <territory> ] <mapcode>      // Decode
      -d  <territory>:<mapcode>         // Decode
      -c <lat> <lon> [ <options> ]      // Encode
      <options>   ::= [ <territory> ] [ <selection> ] [ <precision> ]
      <selection> ::= [ all | local ]   // Default shortest

Default selection leads to encode with Shortest => True, while `all` leads to
encode with Shortest => False, and 'local' leads to encode with Shortest => True
and Shortest => True and to display the first entry of the returnd array.

Examples:

Put information on a territory (providing ISO code or number). The information consists in the
territory number, followed by three possible mapcodes (Local, International and Shortest), followed by the territory full name.

    t_mapcode -t KIR
    -> KIR => 58: KIR/KIR/KIR/Kiribati

    t_mapcode -t CA
    -> CA => 391: CA/US-CA/CA/California
    -> Parent: USA

    t_mapcode -t 410
    -> USA => 410: USA/USA/USA/USA
    -> Has subdivisions

Encode a coordinate with a context and a precision, put information of the shortest mapcode.
Information is the mapcode, the territory context of the mapcode, the full mapcode (territory
and mapcode separated by a space and enclosed by quotes, except for international mapcodes) and territory number.

    t_mapcode -c 52.376482500 4.908511796 NLD 2
    ->   52.376482500    4.908511796
    -> => NLD 49.4V-V2 'NLD 49.4V-V2' 112

Put all shorters mapcodes of a coordinate (no context).

    t_mapcode -c 52.376482500 4.908511796 
    ->  52.376482500    4.908511796
    -> => NLD 49.4V 'NLD 49.4V' 112
    -> => AAA VHXGB.1J9J 'VHXGB.1J9J' 532

Put all mapcodes of a coordinate with a context.

    t_mapcode -c 52.376482500 4.908511796 NLD false
    ->  52.376482500    4.908511796
    -> => 49.4V NLD 'NLD 49.4V' 112
    -> => G9.VWG NLD 'NLD G9.VWG' 112
    -> => DL6.H9L NLD 'NLD DL6.H9L' 112
    -> => P25Z.N3Z NLD 'NLD P25Z.N3Z' 112

Put all mapcodes of a coordinate.

    t_mapcode -c 39.730409000  -79.954163500 all 
    -> 39.730409000  -79.954163500
    -> => US-WV W2W2.Q41V 'US-WV W2W2.Q41V' 353
    -> => US-PA BYLP.73 'US-PA BYLP.73' 361
    -> => US-PA HDWQ.NZN 'US-PA HDWQ.NZN' 361
    -> => US-PA W2W2.Q41V 'US-PA W2W2.Q41V' 361
    -> => USA W2W2.Q41V 'USA W2W2.Q41V' 410
    -> => AAA S8LY1.RD84 'S8LY1.RD84' 532

Put the local mapcode of a coordinate.

    t_mapcode -c 39.730409000  -79.954163500 local
    -> 39.730409000  -79.954163500
    -> => US-PA BYLP.73 'US-PA BYLP.73' 361

Decode a mapcode, no context.

    t_mapcode -d 49.4V
    -> 49.4V
    -> raised MAPCODES.DECODE_ERROR

    t_mapcode -d VHXGB.1J9J
    -> VHXGB.1J9J
    -> => 52.376504000 4.908535500

Decode a mapcode with context.

    t_mapcode -d NLD 49.4V 
    -> NLD 49.4V
    -> => 52.376514000 4.908543375

# Version History

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

