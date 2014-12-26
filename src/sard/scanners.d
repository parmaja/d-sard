module sard.scanners;
/**
  This file is part of the "SARD"

  @license   The MIT License (MIT) Included in this distribution
  @author    Zaher Dirkey <zaher at parmaja dot com>

*/

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

import std.stdio;
import std.conv;
import std.array;
import std.string;
import std.stdio;
import std.uni;
import std.datetime;
import sard.utils;
import sard.classes;
import sard.objects;
import minilib.sets;

protected: 

  static const char[] sEOL = ['\0', '\n', '\r'];

  static const char[] sWhitespace = sEOL ~ [' ', '\t'];
  static const char[] sNumberOpenChars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  static const char[] sNumberChars = sNumberOpenChars ~ ['.', 'x', 'h', 'a', 'b', 'c', 'd', 'e', 'f'];

  //const sColorOpenChars = ['#',];
  //const sColorChars = sColorOpenChars ~ ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];

  static const char[] sIdentifierSeparator = ".";

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
        error("Object is already set");
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
        error("Identifier is not set!");
      r = r && (object is null);
      if (raise && !r) 
        error("Object is already set!");
      return r;
    }

    //Return true if Object is not nil and Identifier is empty
    bool checkObject(in bool raise = false)
    {
      bool r = object !is null;
      if (raise && !r)
        error("Object is not set!");
      r = r && (identifier == "");
      if (raise && !r) 
        error("Identifier is already set!");
      return r;
    }

    //Return true if Operator is not nil
    bool CheckOperator(in bool raise = false)
    {
      bool r = operator !is null;
      if (raise && !r)
        error("Operator is not set!");
      return r;
    }

    @property bool isEmpty() 
    {
      return !((identifier != "") || (object !is null) || (operator !is null));
    }

    void setFlag(Flag aFlag)
    {
      flag = aFlag;
    }

    void setOperator(OpOperator aOperator)
    {
      if (operator !is null)
        error("Operator is already set");
      operator = aOperator;
    }

    void setIdentifier(string aIdentifier){
      if (identifier != "")
        error("Identifier is already set");
      identifier = aIdentifier;
      setFlag(Flag.Identifier);
    }

    SoBaseNumber setNumber(string aIdentifier)
    {
      if (identifier != "")
        error("Identifier is already set");
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

    SoText setText(string aIdentifier)
    {
      if (identifier != "")
        error("Identifier is already set");
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
        error("Identifier is already set");
      //TODO need to check anObject too
      SoComment result = new SoComment();
      result.value = aIdentifier;
      internalSetObject(result);
      setFlag(Flag.Comment);
      return result;
    }
    
  SoInstance setInstance(string aIdentifier){
      if (identifier == "")
      error("Identifier is already set");
    SoInstance result = new SoInstance();
    result.name = aIdentifier;
    internalSetObject(result);
    setFlag(Flag.Instance);
    return result;
  }

	SoInstance setInstance(){
	  if (identifier == "")
		error("Identifier is not set");
	  SoInstance result = setInstance(identifier);
	  identifier = "";	  
	  return result;
	}

	SoStatement setStatment(){ //Statement object not srdStatement	
	  if (identifier != "")
		  error("Identifier is already set");
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
      error("identifier is not set");
    SoDeclare result = new SoDeclare();
    result.name = identifier;    
    internalSetObject(result);
    identifier = "";
    setFlag(Flag.Declare);
    return result;
  }
  
  void setObject(SoObject aObject){
    if (identifier != "")
      error("Identifier is already set");
    internalSetObject(aObject);  
  }  
}

class SrdController: SardObject
{
  protected:
    SrdParser parser;

  public:
    this(SrdParser aParser){
      parser = aParser;
    }

    abstract void control(SardControl aControl);
}

class SrdControllers: SardObjects!SrdController
{
  SrdController findClass(const ClassInfo controllerClass) {
    int i = 0;
    while (i < count) {
      if (this[i].classinfo.name == controllerClass.name) {
        return this[i];
      }
      i++;
    }
    return null;
  }
}

class SrdInterpreter: SardObject
{
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
    void setAction(Actions aActions = [], SrdInterpreter aNextInterpreter = null){
      debug{
        writeln(aActions);
      }
      parser.actions = aActions;
      parser.nextInterpreter = aNextInterpreter;
    }

    void reset(){      
      instruction = new SrdInstruction();
    }

    void prepare(){            
    }

    void post(){            
      debug{
        writeln("post()");
      }
      if (!instruction.isEmpty) {      
        prepare();
        internalPost();
        reset();
      }
    }

    void next(){
      _flags = [];
    }

    void addIdentifier(string aIdentifier, SardType aType){
      switch (aType) {
        case SardType.Number: 
            instruction.setNumber(aIdentifier); 
            break;
        case SardType.String: 
            instruction.setText(aIdentifier);
            break;
        case SardType.Comment: 
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
        error("ControllerClass must have a value!");
      controller = parser.controllers.findClass(aControllerInfo);
      if (controller is null)
        error("Can not find this class!");
    }

    void control(SardControl aControl){
      controller.control(aControl);
    }
}

class SrdInterpreterStatement: SrdInterpreter
{
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
          error("Object is already set!");
        instruction.setInstance();
      }
    }

    override bool isInitial(){
       return (statement is null) || (statement.count == 0);
    }    
}

class SrdInterpreterBlock: SrdInterpreterStatement
{
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
          error("Maybe you need to set a block, or it single statment block");
        statement = block.add();
      }
    }
}

class SrdInterpreterDeclare: SrdInterpreterStatement
{
  protected:

  public:

    this(SrdParser aParser){
      super(aParser);    
    }

    override void control(SardControl aControl){
      switch (aControl){
        case SardControl.End, SardControl.Next:          
            post();
            setAction(Actions([Action.PopInterpreter, Action.Bypass]));
            break;
        default:
          super.control(aControl);
      }
    }
}

class SrdInterpreterDefine: SrdInterpreter
{
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
        error("Identifier not set"); //TODO maybe check if he post const or another things
      if (param){
        if (state == State.Name)
          declare.defines.add(instruction.identifier, "");
        else {
          if (declare.defines.last.result != "") 
            error("Result type already set");
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
            setAction(Actions([Action.PopInterpreter]), new SrdInterpreterBlock(parser, aSection.block));
            break;
          case SardControl.Declare:
            if (param){
              post();
              state = State.Type;
            }
            else {
              post();
              setAction(Actions([Action.PopInterpreter]));
            }
            break;

          case SardControl.Assign:
            post();
            declare.executeObject = new SoAssign(declare, declare.name);            
            declare.callObject = new SoVariable(declare, declare.name);
            setAction(Actions([Action.PopInterpreter])); //Finish it, mean there is no body/statment for the declare
            break;
          case SardControl.End:
            if (param){
              post();
              state = State.Name;
            }
            else {
              post();
              setAction(Actions([Action.PopInterpreter]));
            }
            break;
          case SardControl.Next:
              post();
              state = State.Name;
            break;
          case SardControl.OpenParams:
            post();
            if (declare.defines.count > 0)
              error("You already define params! we expected open block.");
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

class SrdControllerNormal: SrdController
{
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
              error("You can not use assignment here!");
            }
            break;

          case SardControl.Declare:
            if (isInitial){
              SoDeclare aDeclare = instruction.setDeclare();
              post();
              push(new SrdInterpreterDefine(parser, aDeclare));
            } else {
              error("You can not use assignment here!");
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
              error("Maybe you closed not opened Curly");
            setAction(Actions([Action.PopInterpreter]));
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
              error("Maybe you closed not opened Bracket");
            setAction(Actions([Action.PopInterpreter]));
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
            error("Not implemented yet :(");
        }
      }
    }
}

class SrdControllerDefines: SrdControllerNormal
{
  public:
    this(SrdParser aParser){ //TODO BUG why i need to copy it?!
      super(aParser);    
    }

    override void control(SardControl aControl){
      //nothing O.o
    }
}

class SrdParser: SardStack!SrdInterpreter, ISardParser 
{
  protected:
    override void doSetToken(string aToken, SardType aType){
      debug{        
        writeln("SetToken:" ~ aToken ~ " Type:" ~ to!string(aType));
      }
      current.addIdentifier(aToken, aType);
      actionStack();
      actions = [];
    }

    override void doSetOperator(SardObject aOperator){
      OpOperator o = cast(OpOperator)aOperator; //TODO do something i hate typecasting
      if (o is null) 
        error("aOperator not OpOperator");
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
      debug{
        writeln("Push: " ~ current.classinfo.name);
      }
    }

    override void beforePop(){
      super.beforePop();
      debug{
        writeln("Pop: " ~ current.classinfo.name);
      }      
    }

    void actionStack(){
      if (Action.PopInterpreter in actions){      
        actions = actions - Action.PopInterpreter;
        pop();
      }

      if (nextInterpreter !is null) {      
        push(nextInterpreter);
        nextInterpreter = null;
      }
    }

  public:
    Actions actions;
    SrdInterpreter nextInterpreter;
    SrdControllers controllers = new SrdControllers();

    this(SrdBlock aBlock){
      super();      

      if (aBlock is null)
        error("You must set a block");
      
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
        error("Invalid type casting SrdInterpreter");
      result.set(this);
      push(result);
      return result;
    }
}

class SrdFeeder: SardFeeder
{
  protected:
    override void doStart(){
      lexical.parser.setControl(SardControl.Start);
    }

    override void doStop(){
      lexical.parser.setControl(SardControl.Stop);
    }

  public:
    this(SardLexical lexical) {
      super(lexical);      
    }
}

class SrdLexical: SardLexical
{
  private:
    SrdEnvironment _env;
    public @property SrdEnvironment env(){ return _env; };
    public @property SrdEnvironment env(SrdEnvironment value){ return _env = value; };

  protected:

    override void created()
    {      
      add(new SrdWhitespace_Scanner());
      add(new SrdBlockComment_Scanner());
      add(new SrdComment_Scanner());
      add(new SrdLineComment_Scanner());
      add(new SrdNumber_Scanner());
      add(new SrdSQString_Scanner());
      add(new SrdDQString_Scanner());
      add(new SrdControl_Scanner());
      add(new SrdOperator_Scanner()); //Register it after comment because comment take /*
      add(new SrdIdentifier_Scanner());//Sould be last one      
    }

    public:     

      override bool isWhiteSpace(char vChar, bool vOpen = true)
      {
        return sWhitespace.indexOf(vChar) > 0;
      }

      override bool isControl(char vChar)
      {
        return env.controls.isOpenBy(vChar);
      }

      override bool isOperator(char vChar)
      {
        return env.operators.isOpenBy(vChar);
      }

      override bool isNumber(char vChar, bool vOpen = true)
      {
        if (vOpen)
          return sNumberOpenChars.indexOf(vChar) > 0;
        else
          return sNumberChars.indexOf(vChar) > 0;
      }

      override bool isIdentifier(char vChar, bool vOpen = true)
      {
        return super.isIdentifier(vChar, vOpen); //we can not override it, but it is nice to see it here 
      }

}

class SrdWhitespace_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      while ((column < text.length) && (sWhitespace.indexOf(text[column]) > 0))
        column++;
       return true;
    }

    override bool accept(const string text, int column){
      return sWhitespace.indexOf(text[column]) > 0;
    }
}

class SrdIdentifier_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      int c = column;
      while ((column < text.length) && (lexical.isIdentifier(text[column], false)))
        column++;
      column++;
      lexical.parser.setToken(text[c..column], SardType.Identifier);
      return true;
    }

    override bool accept(const string text, int column){
      return lexical.isIdentifier(text[column], true);   
    }
}

class SrdNumber_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      int c = column;
      int l = text.length;
      while ((column < text.length) && (lexical.isNumber(text[column], false)))
        column++;    
      column++;
      lexical.parser.setToken(text[c..column], SardType.Number);
      return true;
    }

    override bool accept(const string text, int column){
      return lexical.isNumber(text[column], true);   
    }
}

class SrdControl_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column) {
      CtlControl control = (cast(SrdLexical)lexical).env.controls.scan(text, column);//TODO need new way to access lexical without typecasting
      if (control !is null){
        column = column + control.name.length;
      }
      else
        error("Unkown control started with " ~ text[column]);
      
      lexical.parser.setControl(control.code);
      return true;
    }

    override bool accept(const string text, int column){
      return lexical.isControl(text[column]);   
    }
}

class SrdOperator_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      OpOperator operator = (cast(SrdLexical)lexical).env.operators.scan(text, column);//TODO need new way to access lexical without typecasting
      if (operator is null)
        column = column + operator.name.length;
      else
        error("Unkown operator started with " ~ text[column]);

      /*if (operator.control <> Control.None) and ((lexical.parser as SrdParser).current.isInitial) //<- very stupid idea
        lexical.parser.setControl(lOperator.Control)
      else*/
      lexical.parser.setOperator(operator);
      return true;
    }

    override bool accept(const string text, int column){
      return lexical.isOperator(text[column]);   
    }
}

class SrdLineComment_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      while ((column < text.length) && (sEOL.indexOf(text[column]) > 0))
        column++;
      column++;////////////////
      return true;
    }

    override bool accept(const string text, int column){
      return scanText("//", text, column);
    }
}

class SrdBlockComment_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      while (column < text.length) {      
        if (scanText("*/", text, column))
          return true;
        column++;
      }
      column++;///////////////////////
      return false;
    }

    override bool accept(const string text, int column){
      return scanText("/*", text, column);
    }
}

class SrdComment_Scanner: SardScanner
{
  protected:
    string buffer;

    override bool scan(const string text, ref int column)
    {
      int c = column;    
      while (column < text.length) {
        if (scanCompare("*}", text, column)){
          buffer = buffer ~ text[c..column + 1];
          column = column + 2;
          lexical.parser.setToken(buffer, SardType.Comment);
          buffer = "";
          return true;
        }
        column++;
      }
      column++;
      buffer = buffer ~ text[c..column];
      return false;
    }

    override bool accept(const string text, int column){
      return scanText("{*", text, column);
    }
}

abstract class SrdString_Scanner: SardScanner
{
  protected:
    char quote;
    string buffer; //<- not sure it is good idea

    override bool scan(const string text, ref int column)
    {
      int c = column;    
      while (column < text.length) {      
        if (text[column] == quote) { //TODO Escape, not now
          buffer = buffer ~ text[c..column + 1];
          lexical.parser.setToken(buffer, SardType.String);
          column++;
          buffer = "";
          return true;
        }
        column++;
      }
      column++;
      buffer = buffer ~ text[c..column];
      return false;
    }

    override bool accept(const string text, int column){    
      return scanText(to!string(quote), text, column);
    }
}

/* Single Quote String */

class SrdSQString_Scanner: SrdString_Scanner
{
  protected:
    override void created(){
      super.created();
      quote = '\'';
    }
  public:
}

/* Double Quote String */

class SrdDQString_Scanner: SrdString_Scanner
{
  protected:
    override void created(){
      super.created();
      quote = '"';
    }
  public:
}