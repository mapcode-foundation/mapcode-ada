# Mapcode Library for Ada

[![License](http://img.shields.io/badge/license-APACHE2-blue.svg)]()
[![Release](https://img.shields.io/github/release/mapcode-foundation/mapcode-ada.svg?maxAge=3600)](https://github.com/mapcode-foundation/mapcode-ada/releases)


**Copyright (C) 2014-2017 Stichting Mapcode Foundation (http://www.mapcode.com)**

----

**Online documentation can be found at: http://mapcode-foundation.github.io/mapcode-ada/**

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

# Ada Files for Mapcode Support

The following files, in directory src, provide utilities for mapcode processing:

    as_u.ads as_u.adb               - Unbounded strings
    bits.ads bits.adb               - Bit operations
    str_tools.ads str_tools.adb     - String utilities

The following files provide the Ada interface for mapcodes:

    mapcode.ads mapcode.adb         - Key operations for mapcode support
    ndata.ads                       - Data table for mapcode support
    ctrynams.ads ctrynams_short.ads - Names of territories (in English)

The following file contains the main procedure for testing the interfaces:

    t_mapcode.adb                   - Command line tool to test Ada mapcodes


In directory test, the command fulltest launches a complete test of the library.

# Using the Library

## Operations related to territories

A territory is identified by a code (an ISO 3166 code such as “NLD” or "US-DC"), with some
possible aliases (example "US" = "USA"), and a unique number, from 0 for "VAT" (Vatican),
to 532 for "AAA" (International), defined as Territory_Range.

Large territories (MX, IN, AU, BR, US, CA, RU and CN) are decomposed into subdivisions.

**Get_Territory_Number** returns the territory number of a territory code. An optional context helps to interpret
ambiguous (abbreviated) alphacodes of subdivisions, such as "AL". If several subdivisions match the specification
(no context provided) it returns the lowest number that matches.

attribute | description
--- | ---
Territory | string, mapcode to decode
Context | optional string, (an ISO code such as “US”) territory for a subdivision
return value | Territory_Range, territory number
exceptions | Unknown_Territory if the territory code is not known

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

**Get_Territory_Alpha_Code** returns the territory ISO 3166 code of a territory.

attribute | description
--- | ---
Territory_Number | Territory_Range
Format | Local (often ambiguous), International (full and unambiguous, default), or Shortest
return value | string, territory ISO code

Examples:

    Get_Territory_Alpha_Code (365)
    -> "US-AR"

    Get_Territory_Alpha_Code (365, Local)
    -> "AR"

    Get_Territory_Alpha_Code (365, Shortest)
    -> "US-AR"        // Because AS is ambiguous (IN-AR)

    Get_Territory_Alpha_Code (391, Shortest)
    -> "CA"           // US-CA, not ambiguous

**Get_Territory_Fullname** returns the full common name of a territory

attribute | description
--- | ---
Territory_Number | Territory_Range
return value | string, territory name

Examples:

    Get_Territory_Fullname (391)
    -> California

**Get_Parent_Of** returns the parent territory number of a subdivision.

attribute | description
--- | ---
Territory_Number | Territory_Range
return value | Territory_Range, parent territory number
exceptions | Not_A_Subdivision, if the Territory_Number has no parent (i.e. is not a subdivision)

**Is_Subdivision** returns True if the provided territory is a subdivision.

attribute | description
--- | ---
Territory_Number | Territory_Range
return value | boolean, True if and only if the Territory_Number is a subdivision

**Has_Subdivision** returns True if the provided territory has subdivisions.

attribute | description
--- | ---
Territory_Number | Territory_Range
return value | boolean, True if and only if the Territory_Number has some subdivisions

## Converting a Coordinate into Mapcodes

In the mapcode system, territories are limited by rectangles, not by actual or political borders. 
This means that a coordinate will often yield mapcode possibilities in more than one territory. 
Each possibility correctly represents the coordinate, but which one is *politically* correct is a 
choice that must be made (in advance or afterwards) by the caller or user of the routines.

There is only one operation, **encode**, which generates the possible mapcodes for a coordinate.
At least it takes as input a latitude in degrees (all values allowed, maximized by routine to 90.0 and minimized
to -90.0) and a longitude in degrees (all values allowed, wrapped to -180.0 and +180.0).

The other arguments are options to be adapted to the situation.

The operation returns an array (possibly with only one element) of mapcodes.

attribute | description 
--- | --- 
Coord | coordinate (latitude and longitude in degrees, reals) to encode as mapcodes
Territory | optional string, (an ISO code such as “NLD”) territory for the scope of the mapcodes
Shortest | boolean, default True, to return only the shortest possible mapcode for the territory or each possible territory
Precision | 0, 1 or 2, default 0, precision of the mapcode to generate
return value | array of mapcode informations (mapcode, territory ISO code and territory number)

This function will return at least one result: the shortest mapcode (if any) that exists
for that coordinate within the specified territory. Such a mapcode is also 
sometimes called the “default mapcode” for a particular territory.

Examples:

With a territory specified, and Shortest set, returns the default mapcode for this territory.

    Encode ( (52.376514000, 4.908543375 40.786245000), "NLD")
    -> 49.4V NLD 'NLD 49.4V' 112


With a territory specified, and Shortest set to False, returns all the possible mapcodes
for this territory.

    Encode ( (52.376514000, 4.908543375 40.786245000), "NLD", False)
    -> 49.4V NLD 'NLD 49.4V' 112
    -> G9.VWG NLD 'NLD G9.VWG' 112
    -> DL6.H9L NLD 'NLD DL6.H9L' 112
    -> P25Z.N3Z NLD 'NLD P25Z.N3Z' 112

With no limitation to a territory (and Shortest set), returns at least a worldwide mapcode
(territory AAA, code 532), and possibly some mapcodes in territories.

    Encode ( (52.376514000, 4.908543375 40.786245000) )
    -> 49.4V NLD 'NLD 49.4V' 112
    -> VHXGB.1J9J AAA VHXGB.1J9J 532

With a precision of 2, returns high precision mapcodes.

    Encode ( (52.376514000, 4.908543375 40.786245000), Pecision -> 2)
    -> 49.4V-K3 NLD 'NLD 49.4V-K3' 112
    -> VHXGB.1J9J-RD AAA VHXGB.1J9J-RD 532

## Converting a Mapcode into a Coordinate

There is only one operation, **decode**, which gives the coordinate of a mapcode.
It accepts an optional argument to define the territoy context of the mapcode.

The operation returns the coordinate (latitude and longitude in degrees), or raises the
exception Decode_Error if the mapcode is not valid or ambiguous (in the context).

attribute | description 
--- | --- 
Mapcode | string, mapcode to decode
Context | optional string, (an ISO code such as “NLD”) territory for the scope of the mapcode
return value | coordinate (latitude and longitude in degrees), reals
exceptions | Decode_Error, if the mapcode is invalid or ambiguous in the Context

Examples:

Without any context, only accept a worldwide mapcode.

    Decode ("49.4V")
    Raises Decode_Error             // Ambiguous

    Decode ("49.4V", NLD)
    -> (52.376514000, 4.908543375)
 
    Decode (VHXGB.1J9J)
    -> (52.376504000, 4.908535500)

# Using the testing program

The command line testing tool **t_mapcode** can perform 3 actions:

* Display information on a territory number or territory ISO 3166 code

* Decode a mapcode (with an optional context) into a coordinate

* Encode a coordinate into mapcodes, according to options

Usage:

    t_mapcode <command>
      -h                            // This help
      -t <territory>                // Territory info
      -d <mapcode> [ <territory> ]  // Decode
      -c <lat> <lon> [ <options> ]  // Encode
      <options> ::= [ <territory> ] [ <shortest> ] [ <precision> ]

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

Encode a coordinate with a context and a precision, put inforamtion of the shortest mapcode.
Information is the mapcode, the territory context of the mapcode, the full mapcode (territory
and mapcode separated by a space and enclosed by quotes, except for international mapcodes) and territory number.

    t_mapcode -c 52.376482500 4.908511796 NLD 2
    ->   52.376482500    4.908511796
    -> => 49.4V-V2 NLD 'NLD 49.4V-V2' 112

Put all shorters mapcodes of a coordinate (no context).

    t_mapcode -c 52.376482500 4.908511796 
    ->  52.376482500    4.908511796
    -> => 49.4V NLD 'NLD 49.4V' 112
    -> => VHXGB.1J9J AAA VHXGB.1J9J 532

Put all mapcodes of a coordinate with a context.

    t_mapcode -c 52.376482500 4.908511796 NLD false
    ->  52.376482500    4.908511796
    -> => 49.4V NLD 'NLD 49.4V' 112
    -> => G9.VWG NLD 'NLD G9.VWG' 112
    -> => DL6.H9L NLD 'NLD DL6.H9L' 112
    -> => P25Z.N3Z NLD 'NLD P25Z.N3Z' 112

Decode a mapcode, no context.

    t_mapcode -d 49.4V
    -> raised MAPCODES.DECODE_ERROR

    t_mapcode -d VHXGB.1J9J
    -> => 52.376504000 4.908535500

Decode a mapcode with context.

    t_mapcode 49.4V NLD
    -> => 52.376514000 4.908543375

# Version History

### 1.0.2

* Fix and improve accuracy

### 1.0.2

* More strict check of context
* Add automatic tests of territory, encoding and decoding, including expected
failures. Fix defects.

### 1.0.1

* Align max nr of mapcode results to C value, and check overflow
* Get rid of global variable (Disambiguate)

### 1.0.0

* Initial version  for public domain release.

