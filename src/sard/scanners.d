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

    @property bool isEmpty(){
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

    SoComment setComment(string aIdentifier){
      //We need to check if it the first expr in the statment
      if (identifier != "")
        raiseError("Identifier is already set");
      //TODO need to check anObject too
      SoComment result = new SoComment();
      result.value = aIdentifier;
      internalSetObject(result);
      setFlag(Flag.Comment);
      return result;
    }
    
    SoInstance setInstance(string aIdentifier){
        if (identifier == "")
        raiseError("Identifier is already set");
      SoInstance result = new SoInstance();
      result.name = aIdentifier;
      internalSetObject(result);
      setFlag(Flag.Instance);
      return result;
    }

	SoInstance setInstance(){
	  if (identifier == "")
		raiseError("Identifier is not set");
	  SoInstance result = setInstance(identifier);
	  identifier = "";	  
	  return result;
	}

	SoStatement setStatment()//Statement object not srdStatement
	{
	  if (identifier != "")
		raiseError("Identifier is already set");
	  SoStatement result = new SoStatement();
	  internalSetObject(result);
	  setFlag(Flag.Statement);
	  return result;
	}
	
	SoAssign SetAssign(){
    //Do not check the Identifier if empty, becuase it is can be empty to assign to result of block
    SoAssign result = new SoAssign();
    result.name = identifier;    
    internalSetObject(result);
    identifier = "";
    setFlag(Flag.Assign);	
    return result;
	}
	
  SoDeclare SetDeclare(){
    if (identifier == "")
      raiseError("identifier is not set");
    SoDeclare result = new SoDeclare();
    result.name = identifier;    
    internalSetObject(result);
    identifier = "";
    setFlag(Flag.Declare);
    return result;
  }
  
  void setObject(SoObject aObject){
    if (identifier != "")
      raiseError("Identifier is already set");
    internalSetObject(aObject);  
  }  
}

class SrdController: SardObject{
  protected:
    SrdParser parser;
  public:
    this(SrdParser aParser){
      parser = aParser;
    }

    abstract void control(SardControl aControl);    
}

class SrdControllers: SardObjects!SrdController{

  SrdController findClass(const ClassInfo controllerClass) {
    int i = 0;
    while (i < count) {
      if (this[i].classinfo == controllerClass) {
        return this[i];
      }
      i++;
    }
    return null;
  }
}

class SrdInterpreter: SardObject{
  private:
    Flags _flags;
  protected:
    SrdInstruction instruction;
    SrdController controller;

    SrdParser parser;

    void internalPost(){  //virtual
    }

    ClassInfo GetControllerInfo(){
      return SrdControllerNormal.classinfo;
    }

  public:

    this(SrdParser aParser){
      super();
      parser = aParser;
    }

    void setFlag(Flag aFlag){
      _flags = _flags + aFlag;
    }

    //Push to the Parser immediately
    void push(SrdInterpreter aItem){
      parser.push(aItem);
    }

    //No pop, but when finish Parser will pop it
    void action(Actions aActions = [], SrdInterpreter aNextInterpreter = null){
      parser.actions = aActions;
      parser.nextInterpreter = aNextInterpreter;
    }

    void reset(){      
      instruction = new SrdInstruction();
    }

    void prepare(){            
    }

    void post(){            
      if (!instruction.isEmpty) {      
        prepare();
        internalPost();
        reset();
      }
    }

    void next(){
      _flags = [];
    }

    void addIdentifier(string aIdentifier, SrdType aType){
      switch (aType) {
        case SrdType.Number: 
            instruction.setNumber(aIdentifier); 
            break;
        case SrdType.String: 
            instruction.setText(aIdentifier);
            break;
        case SrdType.Comment: 
            instruction.setComment(aIdentifier);
            break;
        default:
           instruction.setIdentifier(aIdentifier);
      }
    }

    void addOperator(OpOperator aOperator){
      post();
      instruction.setOperator(aOperator);
    }

    //IsInitial: check if the next object will be the first one, usefule for Assign and Declare
    bool isInitial(){
      return false;
    }

    void switchController(ClassInfo aControllerInfo){
      if (aControllerInfo is null)
        raiseError("ControllerClass must have a value!");
      controller = parser.controllers.findClass(aControllerInfo.classinfo);
      if (controller is null)
        raiseError("Can not find this class!");
    }

    void control(SardControl aControl){
      controller.control(aControl);
    }
}

/******************************/
/********  TODO   *************/
/******************************/
class SrdParser:SardObject{
  Actions actions;
  SrdInterpreter nextInterpreter;
  SrdControllers controllers;
  void push(SrdInterpreter aItem){
  }
}

class SrdControllerNormal{
}
