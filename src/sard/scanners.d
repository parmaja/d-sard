module sard.scanners;
/**
  This file is part of the "SARD"

  @license   The MIT License (MIT) Included in this distribution
  @author    Zaher Dirkey <zaher at parmaja dot com>

*/

//Porting in progress
/**
    Module: Scanner, scan the source code and generate runtime objects

    SrdFeeder: Load the source lines and feed it to the Lexical, line by line
    SrdLexical: divied the source code (line) and pass it to small scanners, scanner tell it when it finished
    SrdScanner: Take this part of source code and convert it to control, operator or indentifier
    SrdParser: Generate the runtime objects, it use the current Interpreter
*/

/**TODO:
  Arrays: If initial parse [] as an index and passit to executer or assigner, not initial,
          it is be a list of statments then run it in runtime and save the results in the list in TsoArray

  Scanner open: Open with <?sard link php or close it ?> then pass it to the compiler and runner,
          but my problem i cant mix outputs into the program like php, it is illogical for me, sorry guys :(

  Preprocessor: When scan {?somthing it will passed to addon in engine to return the result to rescan it or replace it with this preprocessor

  What about private, public or protected, the default must be protected
    x:(p1, p2){ block } //protected
    x:-(){} //private
    x:+(){} //public

  We need to add multi blocks to the identifier like this
    x(10,10){ ... } { ... }
    or with : as seperator
    x(10,10){ ... }:{ ... }
  it is good to make the "if" object with "else" as the second block.

*/

/**
  Scope
    Block
    Statment
    Instruction, Preface, clause,
      Expression
*/

import std.conv;
import std.uni;
import std.datetime;
import sard.classes;
import sard.objects;

const sEOL = ["\0", "\n", "\r"];

const sWhitespace = sEOL ~ [" ", "\t"];
const sNumberOpenChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
const sNumberChars = sNumberOpenChars ~ [".", "x", "h", "a", "b", "c", "d", "e", "f"];

//const sColorOpenChars = ['#',];
//const sColorChars = sColorOpenChars ~ ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];

const sIdentifierSeparator = ".";
