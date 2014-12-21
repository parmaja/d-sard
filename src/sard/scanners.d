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
import std.array;
import std.string;
import std.algorithm;
import std.uni;
import std.datetime;
import sard.classes;
import sard.objects;
import minilib.sets;

protected: 
  const sEOL = ["\0", "\n", "\r"];

  const sWhitespace = sEOL ~ [" ", "\t"];
  const sNumberOpenChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
  const sNumberChars = sNumberOpenChars ~ [".", "x", "h", "a", "b", "c", "d", "e", "f"];

  //const sColorOpenChars = ['#',];
  //const sColorChars = sColorOpenChars ~ ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];

  const sIdentifierSeparator = ".";

  enum Flag {
      None,
      Instance,
      Declare,
      Assign,
      Identifier,
      Const,
      Param,
      Operator,
      Comment,
      Statement,
      Block
  }

  alias Set!Flag Flags;

  enum Action {
        paPopInterpreter, //Pop the current interpreter
        paBypass  //resend the control char to the next interpreter
  }

  alias Set!Action Actions;

class SrdInstruction: SardObject
{
  protected:
    void internalSetObject(SoObject aObject)
    {
      if ((object !is null) && (aObject !is null))
        raiseError("Object is already set");
      object = aObject;
    }

  public:
    Flag flag;
    string identifier;
    OpOperator operator;
    SoObject object;

    //Return true if Identifier is not empty and object is nil
    bool checkIdentifier(in bool raise = false)
    {
      bool r = identifier != "";
      if (raise && !r)
        raiseError("Identifier is not set!");
      r = r && (object is null);
      if (raise && !r) 
        raiseError("Object is already set!");
      return r;
    }

    //Return true if Object is not nil and Identifier is empty
    bool checkObject(in bool raise = false)
    {
      bool r = object !is null;
      if (raise && !r)
        raiseError("Object is not set!");
      r = r && (identifier == "");
      if (raise && !r) 
        raiseError("Identifier is already set!");
      return r;
    }

    //Return true if Operator is not nil
    bool CheckOperator(in bool raise = false)
    {
      bool r = operator !is null;
      if (raise && !r)
        raiseError("Operator is not set!");
      return r;
    }

    bool isEmpty(){
      return !((identifier != "") || (object !is null) || (operator !is null));
    }

    void setFlag(Flag aFlag){
      flag = aFlag;
    }

    void setOperator(OpOperator aOperator){
      if (operator !is null)
        raiseError("Operator is already set");
      operator = aOperator;
    }

    void setIdentifier(string aIdentifier){
      if (identifier != "")
        raiseError("Identifier is already set");
      identifier = aIdentifier;
      setFlag(Flag.Identifier);
    }

    SoBaseNumber setNumber(string aIdentifier){
      if (identifier != "")
        raiseError("Identifier is already set");
      //TODO need to check anObject too
      SoBaseNumber result;
      if ((aIdentifier.indexOf(".") > 0) || ((aIdentifier.indexOf("E") > 0)))
        result = new SoNumber(to!float(aIdentifier));
      else
        result = new SoInteger(to!int(aIdentifier));
      internalSetObject(result);
      setFlag(Flag.Const);
      return result;
    }

    SoText setText(string aIdentifier){
      if (identifier != "")
        raiseError("Identifier is already set");
      //TODO need to check anObject too
      SoText result = new SoText(aIdentifier);
      //result.value = AIdentifier;
      internalSetObject(result);
      setFlag(Flag.Const);
      return result;
    }
}