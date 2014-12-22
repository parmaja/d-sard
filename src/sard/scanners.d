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
    PopInterpreter, //Pop the current interpreter
    Bypass  //resend the control char to the next interpreter
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
	
	SoAssign setAssign(){
    //Do not check the Identifier if empty, becuase it is can be empty to assign to result of block
    SoAssign result = new SoAssign();
    result.name = identifier;    
    internalSetObject(result);
    identifier = "";
    setFlag(Flag.Assign);	
    return result;
	}
	
  SoDeclare setDeclare(){
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

    ClassInfo getControllerInfo(){
      return SrdControllerNormal.classinfo;
    }

  public:

    void set(SrdParser aParser){
      parser = aParser;
      switchController(getControllerInfo());
      reset();
    }

    this(SrdParser aParser){
      super();
      set(aParser);
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
    @property bool isInitial(){
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

class SrdInterpreterStatement: SrdInterpreter{
  protected:
    SrdStatement statement;

    override void internalPost(){
      super.internalPost();
      statement.add(instruction.operator, instruction.object);
    }
  public:

    this(SrdParser aParser){
      super(aParser);
    }

    this(SrdParser aParser, SrdStatement aStatement){
      super(aParser);
      statement = aStatement;
    }

    override void next(){
      super.next();
      statement = null;
    }

    override void prepare(){
      super.prepare();
      if (instruction.identifier != "") {        
        if (instruction.object !is null)
          raiseError("Object is already set!");
        instruction.setInstance();
      }
    }

    override bool isInitial(){
       return (statement is null) || (statement.count == 0);
    }    
}



class SrdInterpreterBlock: SrdInterpreterStatement{
protected:
  SrdBlock block;

public:

  this(SrdParser aParser, SrdBlock aBlock){
    super(aParser);
    block = aBlock;
  }

  override void prepare(){
    super.prepare();
    if (statement is null) {        
      if (block is null)
        raiseError("Maybe you need to set a block, or it single statment block");
      statement = block.add();
    }
  }
}

class SrdInterpreterDeclare: SrdInterpreterStatement{
  protected:

  public:

    this(SrdParser aParser){
      super(aParser);    
    }

    override void control(SardControl aControl){
      switch (aControl){
        case SardControl.End, SardControl.Next:          
            post();
            action(Actions([Action.PopInterpreter, Action.Bypass]));
            break;
        default:
          super.control(aControl);
      }
    }
}

class SrdInterpreterDefine: SrdInterpreter{
  private:
    enum State {Name, Type};
  protected:
    State state;
    bool param;
    SoDeclare declare;

    this(SrdParser aParser){ //TODO BUG why i need to copy it?!
      super(aParser);    
    }

    this(SrdParser aParser, SoDeclare aDeclare){
      this(aParser);
      declare = aDeclare;
    }
    
    override void internalPost(){
      if (instruction.identifier == "")
        raiseError("Identifier not set"); //TODO maybe check if he post const or another things
      if (param){
        if (state == State.Name)
          declare.defines.add(instruction.identifier, "");
        else {
          if (declare.defines.last.result != "") 
            raiseError("Result type already set");
          declare.defines.last.result = instruction.identifier;
        }        
      }
      else 
        declare.resultType = instruction.identifier;            
    }

    override ClassInfo getControllerInfo(){
      return SrdControllerDefines.classinfo;
    }
  public:
    override void control(SardControl aControl){
      /*
        x:int  (p1:int; p2:string);
         ^typd (------Params-----)^
         Declare  ^Declare
         We end with ; or : or )
      */
      with(parser){
        switch(aControl){
          case SardControl.OpenBlock:
            post();
            SoSection aSection = new SoSection();
            aSection.parent = declare;
            declare.callObject = aSection;
            //We will pass the control to the next interpreter
            action(Actions([Action.PopInterpreter]), new SrdInterpreterBlock(parser, aSection.block));
            break;
          case SardControl.Declare:
            if (param){
              post();
              state = State.Type;
            }
            else {
              post();
              action(Actions([Action.PopInterpreter]));
            }
            break;

          case SardControl.Assign:
            post();
            declare.executeObject = new SoAssign(declare, declare.name);            
            declare.callObject = new SoVariable(declare, declare.name);
            action(Actions([Action.PopInterpreter])); //Finish it, mean there is no body/statment for the declare
            break;
          case SardControl.End:
            if (param){
              post();
              state = State.Name;
            }
            else {
              post();
              action(Actions([Action.PopInterpreter]));
            }
            break;
          case SardControl.Next:
              post();
              state = State.Name;
            break;
          case SardControl.OpenParams:
            post();
            if (declare.defines.count > 0)
              raiseError("You already define params! we expected open block.");
            param = true;
            break;
          case SardControl.CloseParams:
            post();
            //pop(); //Finish it
            param = false;
            //action(Actions([paPopInterpreter]), new SrdInterpreterBlock(parser, declare.block)); //return to the statment
            break;
          default: 
              super.control(aControl);
        }
      }      
    }

    override void prepare(){
      super.prepare();
    }

    override void next(){
      super.next();
    }

    override void reset(){
      state = State.Name;
      super.reset();
    }

    override bool isInitial(){
      return true;
    }
}

class SrdControllerNormal: SrdController{
  public:
    this(SrdParser aParser){ //TODO BUG why i need to copy it?!
      super(aParser);    
    }

    override void control(SardControl aControl){
      with(parser.current){
        switch(aControl){
          case SardControl.Assign:
            if (isInitial){
              instruction.setAssign();
              post();
            } else {
              raiseError("You can not use assignment here!");
            }
            break;

          case SardControl.Declare:
            if (isInitial){
              SoDeclare aDeclare = instruction.setDeclare();
              post();
              push(new SrdInterpreterDefine(parser, aDeclare));
            } else {
              raiseError("You can not use assignment here!");
            }
            break;

          case SardControl.OpenBlock:
            SoSection aSection = new SoSection();
            instruction.setObject(aSection);
            push(new SrdInterpreterBlock(parser, aSection.block));
            break;

          case SardControl.CloseBlock:
            post();
            if (parser.count == 1)
              raiseError("Maybe you closed not opened Curly");
            action(Actions([Action.PopInterpreter]));
            break;

          case SardControl.OpenParams:
            //params of function or object like: Sin(10)
            if (instruction.checkIdentifier())
            {
              with (instruction.setInstance())
                push(new SrdInterpreterBlock(parser, block));
            }
            else //No it is just sub statment like: 10+(5*5)
              with (instruction.setStatment())
                push(new SrdInterpreterStatement(parser, statement));
            break;

          case SardControl.CloseParams:
            post();
            if (parser.count == 1)
              raiseError("Maybe you closed not opened Bracket");
            action(Actions([Action.PopInterpreter]));
            break;

          case SardControl.Start:            
            break;
          case SardControl.Stop:            
              post();
            break;
          case SardControl.End:            
              post();
              next();
            break;
          case SardControl.Next:            
              post();
              next();
            break;
          default:
            raiseError("Not implemented yet :(");
        }
      }
    }
}

class SrdControllerDefines: SrdControllerNormal{
  public:
    this(SrdParser aParser){ //TODO BUG why i need to copy it?!
      super(aParser);    
    }

    override void control(SardControl aControl){
      //nothing O.o
    }
}

class SrdParser: SardStack!SrdInterpreter, ISardParser {
  protected:
    override void doSetToken(string aToken, SrdType aType){
      current.addIdentifier(aToken, aType);
      actionStack();
      actions = [];
    }

    override void doSetOperator(SardObject aOperator){
      OpOperator o = cast(OpOperator)aOperator; //TODO do something i hate typecasting
      if (o is null) 
        raiseError("aOperator not OpOperator");
      current.addOperator(o);
      actionStack();
      actions = [];
    }

    override void doSetControl(SardControl aControl){
      current.control(aControl);
      actionStack();
      if (Action.Bypass in actions)//TODO check if Set work good here
        current.control(aControl); 
      actions = [];
    }

    override void afterPush(){
      super.afterPush();
      //WriteLn('Push: '+Current.ClassName);
    }

    override void beforePop(){
      super.beforePop();
      //WriteLn('Pop: '+Current.ClassName);
    }

    void actionStack(){
      if (Action.PopInterpreter in actions){      
        actions = actions - Action.PopInterpreter;
        pop();
      }

      if (nextInterpreter is null) {      
        push(nextInterpreter);
        nextInterpreter = null;
      }
    }

  public:
    Actions actions;
    SrdInterpreter nextInterpreter;
    SrdControllers controllers;

    this(SrdBlock aBlock){
      super();      

      if (aBlock is null)
        raiseError("You must set a block");
      controllers = new SrdControllers();
      controllers.add(new SrdControllerNormal(this));
      controllers.add(new SrdControllerDefines(this));
      push(new SrdInterpreterBlock(this, aBlock));

    }

    override void start(){
    }

    override void stop(){
    }

    SrdInterpreter pushIt(ClassInfo info){
      SrdInterpreter result = cast(SrdInterpreter)info.create();//this is buggy
      if (result is null)
        raiseError("Invalid type casting SrdInterpreter");
      result.set(this);
      push(result);
      return result;
    }
}


/******************************/
/********  TODO   *************/
/******************************/
