module sard.objects;
/***
 *  This file is part of the "SARD"
 *
 * @license   The MIT License (MIT)
 *            Included in this distribution
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 */

/**
  Unit: Objects of run time generated by the scanner and raise in the memory until you free it,
  you can run it multiple time, also in the seperated thread

  The main object is TsoMain

  Object have Execute and Operate
  Some objects (like Section) have a Block, and some have one Statement
  Block have Statements
    Statement: haves Clauses
      Clause: Operator,Modifier,Object

  Declare: is define how to call that object, it have Defines and link to the object to execute and call
      Declare is a object of Caluse that call external (or internal) object, until now this object freed by declare and it is wrong :(

  Stack: have data for run time execute, you cant share value between thread or multiple execute for the main object
    So Stack have Local Variables, Shadow of object
  Shadow: it is mirror of object but have extra data about it that we can not save it in the original object,
    it is useful for multiexecute.

*/

/**
  Prefix guid:
    srd: global classes inherited from sard
    run: Runtime classes
    so: Sard objects, that created when compile the source
    op: Operators objects
*/

/**TODO:
  TtpType:    Type like integer, float, string, color or datetime, it is global, and limited

  TsoArray:   From the name, object have another objects, a list of objectd without execute it,
              it is save the result of statement come from the parser

* TsrdShadow: This object shadow of another object, he resposible of the memory storage like a varible
              When need to execute an object it will done by this shadow and insure it is exist before run
              Also we can make muliple shadow of one object when creating link to it, i mean creating another object based on first one
              Also it is made for dynamic scoping, we can access the value in it instead of local variable

  TrunEngine: Load file and compile it, also have debugger actions and log to console of to any plugin that provide that interface
              Engine cache also compile files to use it again and it check the timestamp before recompile it

  TsrdAddons: It have any kind of addon, parsing, preprocessor, or debugger

  TmdModifier: It is like operator but with one side can be in the context before the identifier like + !x %x $x

*/

/**
  DLang
  TODO: rename prefix Srd tp Obj //hmmm
  
  Renamed:
    return -> ret
*/

import std.stdio;
import std.conv;
import std.uni;
import std.datetime;
import sard.classes;

import minilib.sets;
import minilib.metaclasses;

const string sSardVersion = "0.01";
const int iSardVersion = 1;

alias long integer;
alias double number;
alias string text;

enum ObjectType {otUnkown, otInteger, otNumber, otBoolean, otText, otComment, otBlock, otObject, otClass, otVariable};
enum Compare {cmpLess, cmpEqual, cmpGreater};

enum RunVarKind {vtLocal, vtParam};//Ok there is more in the future

//alias bool[RunVarKind] RunVarKinds;
alias RunVarKinds = Set!RunVarKind;

class SrdObjects(T): SardObjects!T { //TODO rename it to SoObjects

  private:
    SoObject _parent;

  public:
    @property SoObject parent() { return _parent; }

  public:
  /**BUG1
    We need default constructor to resolve this error
    Error	1	Error: class sard.objects.SrdStatement Cannot implicitly generate a default ctor when base class sard.objects.SrdObjects!(SrdClause).SrdObjects is missing a default ctor	W:\home\d\lib\sard\src\sard\objects.d	151	
    
    add this to your subclass
  
    this(SoObject aParent){
      super(aParent);    
    }   
  */

    this(SoObject aParent){
      super();
      _parent = aParent;
    }   
}

class SrdDebug: SardObject {

  public:
    int line;
    int column;
    string fileName;
    //bool breakPoint; //not sure, do not laugh
}

class SrdDefine: SardObject {
  public:
    string name;
    string result;
    this(string aName, string aResult){
      super();
      name = aName;
    }
}

class SrdDefines: SardObjects!SrdDefine {

  void add(string aName, string aResult) {
    super.add(new SrdDefine(aName, aResult));
  }
}

/** SrdClause */

class SrdClause: SardObject {
  private:
    OpOperator _operator;
    SoObject _object;
  public:
    @property OpOperator operator() { return _operator; }
    @property SoObject object() { return _object; }

    this(OpOperator aOperator, SoObject aObject) {
      super();
      _operator = aOperator;
      _object = aObject;
    }

    bool execute(RunStack aStack) {
      if (_object is null)
        raiseError("Object not set!");
      return _object.execute(aStack, _operator);
    }
}

/** SrdStatement */

class SrdStatement: SrdObjects!SrdClause {
  //check BUG1
  this(SoObject aParent){
    super(aParent);    
  }   

  public:
    void add(OpOperator aOperator, SoObject aObject){
      SrdClause clause = new SrdClause(aOperator, aObject);
      aObject.parent = parent;
      super.add(clause);    
    }

  void execute(RunStack aStack){
    aStack.ret.insert(); //Each statement have own result
    call(aStack);
    if (aStack.ret.current.reference is null)
      aStack.ret.current.reference.object = aStack.ret.current.result.extract();  //it is responsible of assgin to parent result or to a variable
    aStack.ret.pop();
  }

  void call(RunStack aStack){
    int i = 0;
    while (i < count) {
      this[i].execute(aStack);
      i++;
    }
  }

  public SrdDebugInfo debuginfo; //<-- Null until we compiled it with Debug Info
}

class SrdBlock: SrdObjects!SrdStatement {

  //check BUG1
  this(SoObject aParent){
    super(aParent);    
  }   

  public:
    @property SrdStatement statement() {
      //check();//TODO: not sure
      return last();
    }

    SrdStatement add(){
      return new SrdStatement(parent);
    }

    void check(){
      if (count==0) {
        add();
      }
    }

  bool execute(RunStack aStack){
    if (count == 0)
      return false;
    else{
      int i = 0;
      while (i < count) {
        this[i].execute(aStack);
        //if the current statement assigned to parent or variable result "Reference" here have this object, or we will throw the result
        i++;
      }
      return true;
    }
  }
}

class SrdBlockStack:SardStack!SrdBlock {
}

/** SoObject */

abstract class SoObject: SardObject {
  private:
    SoObject _parent;

  protected:
    ObjectType _objectType;
    
    public @property ObjectType objectType() {
      return _objectType;
    }

    public @property ObjectType objectType(ObjectType value) {
      return _objectType = value;
    }

  public:
    @property SoObject parent() {return _parent; };
    @property 
      SoObject parent(SoObject value) {
        if (_parent !is null) 
          raiseError("Already have a parent");
        _parent = value;
        doSetParent(_parent);
        return _parent; 
      };

  public:

    bool toBool(out bool outValue){
      return false;
    }

    bool toText(out text outValue){
      return false;
    }

    bool toNumber(out number outValue){
      return false;
    }

    bool toInteger(out integer outValue){
      return false;
    }

  public:
    @property final text asText(){
      string o;
      if (toText(o))
        return o;
      else
        return "";
    };

    @property final number asNumber(){
      number o;
      if (toNumber(o))
        return o;
      else
        return 0;
    };

    @property final integer asInteger(){
      integer o;
      if (toInteger(o))
        return o;
      else
        return 0;
    };

    @property final bool asBool(){
      bool o;
      if (toBool(o))
        return o;
      else
        return false;
    };

  protected: 
    bool operate(SoObject aObject, OpOperator AOperator) {
      return false;
    }

    void beforeExecute(RunStack vStack, OpOperator aOperator){

    }

    void afterExecute(RunStack vStack, OpOperator aOperator){

    }

    void executeParams(RunStack vStack, SrdDefines vDefines, SrdBlock vParameters) {

    }

    void doExecute(RunStack vStack,OpOperator aOperator, ref bool done){
    }

    void doSetParent(SoObject aParent){
    }
 
  public:
      bool execute(RunStack vStack, OpOperator aOperator, SrdDefines vDefines = null, SrdBlock vParameters = null) {
      //vStack.TouchMe(Self);
      bool result = false;
      beforeExecute(vStack, aOperator);
      executeParams(vStack, vDefines, vParameters);
      doExecute(vStack, aOperator, result);
      afterExecute(vStack, aOperator);      
/*
      //std.experimental.logger
      //std.logger

      debug.writeln(s) {
        s = StringOfChar('-', vStack.Return.CurrentItem.Level)+'->';
        s := s + 'Execute: ' + ClassName+ ' Level=' + IntToStr(vStack.Return.CurrentItem.Level);
        if AOperator <> nil then
          s := s +'{'+ AOperator.Name+'}';
        if vStack.Return.Current.Result.anObject <> nil then
          s := s + ' Value: '+ vStack.Return.Current.Result.anObject.asText;
        WriteLn(s);
      }*/
      return result; 
    }

    void assign(SoObject fromObject){
      //nothing
    }

    SoObject clone(bool withValue = true){
      SoObject object = cast(SoObject)this.classinfo.create(); //new typeof(this);//<-bad i want to create new object same as current object but with descent
	    if (object is null)
		    raiseError("Error when clongin");      
	  
      if (withValue)
        object.assign(this);
      return object;
    }

    int addDeclare(SoNamedObject executeObject, SoNamedObject callObject){
      SoDeclare declare = new SoDeclare();
      if (executeObject !is null)
        declare.name = executeObject.name;
      else if (callObject !is null)
        declare.name = callObject.name;
      declare.executeObject = executeObject;
      declare.callObject = callObject;
      return addDeclare(declare);
    }

    int addDeclare(SoDeclare aDeclare){
      if (parent is null)
        return -1;
      else
        return parent.addDeclare(aDeclare);
    }

    SoDeclare findDeclare(string vName){
      if (parent !is null)
        return parent.findDeclare(vName);
      else
        return null;
    }
}

class SoNamedObject: SoObject {
  private:
    int _id;
    string _name;
  public:
    @property int id(){ return _id; }
    @property int id(int value){ return _id = value; }
    @property string name(){ return _name; }
    @property string name(string value){ return _name = value; }

  public:

    this(){
      super();
    }

    this(SoObject vParent, string vName){
      this();
      name = vName;
      parent = vParent;
    }

    RunVariable registerVariable(RunStack vStack, RunVarKinds vKind){
      return vStack.local.current.variables.register(name, vKind);
    }
}

abstract class SoConstObject: SoObject
{
  override final void doExecute(RunStack vStack, OpOperator aOperator, ref bool done){
    if ((vStack.ret.current.result.object is null) && (aOperator is null)) {
      vStack.ret.current.result.object = clone();
    done = true;
    }
    else {
      
      if (vStack.ret.current.result.object is null)
        vStack.ret.current.result.object = clone(false);
      done = vStack.ret.current.result.object.operate(this, aOperator);
    }
  }
}

abstract class SoBlock: SoNamedObject{
  protected:
    SrdBlock _block;

    public @property SrdBlock block() { return _block; };

    override void executeParams(RunStack vStack, SrdDefines vDefines, SrdBlock vParameters){

      super.executeParams(vStack, vDefines, vParameters);
      if (vParameters !is null) { //TODO we need to check if it is a block?      
        int i = 0;
        while (i < vParameters.count) { //here i was added -1 to the count | while (i < vParameters.count -1)
          vStack.ret.insert();
          vParameters[i].call(vStack);
          if (i < vDefines.count){      
            RunVariable v = vStack.local.current.variables.register(vDefines[i].name, RunVarKinds([RunVarKind.vtLocal, RunVarKind.vtParam])); //must find it locally//bug//todo
            v.value = vStack.ret.current.releaseResult();
          }
          vStack.ret.pop();
          i++;
        }        
      }
    }

    override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done){
      vStack.ret.insert(); //<--here we can push a variable result or create temp result to drop it
      call(vStack);
      auto t = vStack.ret.pull();
      //I dont know what if ther is an object there what we do???
      if (t.result.object !is null)
        t.result.object.execute(vStack, aOperator);
      t = null; //destroy it
      done = true;
    }

  public:
    debug{
      override void debugWrite(int level){
        super.debugWrite(level);
        _block.debugWrite(level + 1);
      }
    }

    override void created(){
      super.created();
      _objectType = ObjectType.otBlock;
    }

    this(){
      super();
      _block = new SrdBlock(this);      
    }

    void call(RunStack vStack){ //vBlock here is params
      block.execute(vStack);
    }
}

//Just a references not free inside objects, not sure how to do that in D

class SrdDeclares: SardNamedObjects!SoDeclare {
}

/** SoSection */
/** Used by { } */

class SoSection: SoBlock { //Result was droped until using := assign in the first of statement
  private:
    SrdDeclares _declares; //It is cache of objects listed inside statements, it is for fast find the object
    
    public @property SrdDeclares declares() { return _declares; };

  protected:
    override void beforeExecute(RunStack vStack, OpOperator aOperator){
      super.beforeExecute(vStack, aOperator);
      vStack.local.insert();
    }

    override void afterExecute(RunStack vStack, OpOperator aOperator){
      super.afterExecute(vStack, aOperator);
      vStack.local.pop();
    }

  public:
    this(){
      super();
      _declares = new SrdDeclares();
    }

    override int addDeclare(SoNamedObject executeObject, SoNamedObject callObject){
      return super.addDeclare(executeObject, callObject);
    }

    override int addDeclare(SoDeclare vDeclare){
      return declares.add(vDeclare);
    }

    override SoDeclare findDeclare(string vName){
      if (parent !is null)
        return parent.findDeclare(vName);
      else
        return null;
    }
}

class SoCustomStatement: SoObject
{
  protected:
    SrdStatement _statement;
    public @property SrdStatement statement() { return _statement; };

    override void beforeExecute(RunStack vStack, OpOperator aOperator){
      super.beforeExecute(vStack, aOperator);
      vStack.ret.insert();
    }  

    override void afterExecute(RunStack vStack, OpOperator aOperator){        
      
      super.afterExecute(vStack, aOperator);
      RunReturnItem T = vStack.ret.pull();
      if (T.result.object !is null)
        T.result.object.execute(vStack, aOperator);            
    }  

    override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done){
      statement.call(vStack);
      done = true;
    }
  public:

}

class SoStatement: SoCustomStatement
{
  public:
    this(){
      super();
      _statement = new SrdStatement(parent);
  }
}

/**  Variables objects */

/**   SoInstance */

/** it is a variable value like x in this "10 + x + 5" */

class SoInstance: SoBlock{
  protected:
    override void doExecute(RunStack vStack, OpOperator aOperator,ref bool done){            

      SoDeclare p = findDeclare(name);
      if (p !is null) //maybe we must check Define.count, cuz it refere to it class
        p.call(vStack, aOperator, block, done);
      else {
        RunVariable v = vStack.local.current.variables.find(name);
        if (v is null)
          raiseError("Can not find a variable: " ~ name);
        done = v.value.object.execute(vStack, aOperator);
      }      
    }

  public:
    override void created(){
      super.created();
      objectType = ObjectType.otObject;
    }
}


class SoVariable: SoNamedObject
{ 
protected:
  override void doExecute(RunStack vStack, OpOperator aOperator,ref bool done){            
    RunVariable v = registerVariable(vStack, RunVarKinds([RunVarKind.vtLocal]));
      if (v is null)
        raiseError("Can not register a varibale: " ~ name) ;
      if (v.value.object is null)
        raiseError(v.name ~ " variable have no value yet:" ~ name);//TODO make it as empty
    done = v.value.object.execute(vStack, aOperator);
  }

public:
  ClassInfo resultType;
//  SardMetaClass resultType; OUTCH

  this(){
    super();
  }

  this(SoObject vParent, string vName){ //not auto inherited
    super(vParent, vName);
  }
}

/** It is assign a variable value, x:=10 + y */

class SoAssign: SoNamedObject{
  protected:
    override void doSetParent(SoObject value) {
      super.doSetParent(value);
    }

    override void doExecute(RunStack vStack, OpOperator aOperator,ref bool done){
      //super.doExecute(vStack, aOperator, done);
      /** if not name it assign to parent result */
      done = true;
      if (name == "")
        vStack.ret.current.reference = vStack.ret.parent.result;
      else {
        SoDeclare aDeclare = findDeclare(name);//TODO: maybe we can cashe it
        if (aDeclare !is null) {
          if (aDeclare.callObject !is null){
            RunVariable v = aDeclare.callObject.registerVariable(vStack, RunVarKinds([RunVarKind.vtLocal])); //parent becuase we are in the statement
            if (v is null)
              raiseError("Variable not found!");
            vStack.ret.current.reference = v.value;
          }
        }
        else { //Ok let is declare it locally
          RunVariable v = registerVariable(vStack, RunVarKinds([RunVarKind.vtLocal]));//parent becuase we are in the statement
          if (v is null)
            raiseError("Variable not found!");
          vStack.ret.current.reference = v.value;
        }
      }
    }

    override void created(){
      super.created();
      objectType = ObjectType.otVariable;
    }

  public:  

    this(){
      super();
    }

    this(SoObject vParent, string vName){ //not auto inherited, OH Deee
      super(vParent, vName);
    }
}

class SoDeclare: SoNamedObject{
  private:
    SrdDefines _defines;
    public @property SrdDefines defines(){ return _defines; }

  protected:
    override void created(){
      super.created();
      _objectType = ObjectType.otClass;
    }

    override void doSetParent(SoObject value) {
      super.doSetParent(value);
      value.addDeclare(this);
    }

    override void doExecute(RunStack vStack, OpOperator aOperator,ref bool done){
      if (executeObject !is null)
        done = executeObject.execute(vStack, aOperator);
      else
        done = true;
    }

  public:
    //ExecuteObject will execute in a context of statement if it is not null,
    SoNamedObject executeObject;//You create it but Declare will free it
    //ExecuteObject will execute by call, when called from outside,
    SoNamedObject callObject;//You create it but Declare will free it
    string resultType;

    //This outside execute it will force to execute the section
    void call(RunStack vStack, OpOperator aOperator, SrdBlock aParameters, ref bool done){
      done = callObject.execute(vStack, aOperator, defines, aParameters);
    }

    this(){
      super();
      _defines = new SrdDefines();
    }    
}

/**-------------------------------**/
/**-------- Const Objects --------**/
/**-------------------------------**/

/** SoNone **/

class SoNone: SoConstObject{ //None it is not Null, it is an initial value we sart it
  //Do operator
  //Convert to 0 or ''
}

/** SoComment **/

class SoComment: SoObject{
protected:
  override void doExecute(RunStack vStack, OpOperator aOperator,ref bool done){
    //Guess what!, we will not to execute the comment ;)
    done = true;
  }

  override void created(){
    super.created();
    objectType = ObjectType.otComment;
  }

public:
  string value;
}

/** SoPreprocessor **/
/*
class SoPreprocessor: SoObject{
protected:
  override void doExecute(RunStack vStack, OpOperator aOperator,ref bool done){
    //TODO execute external programm and replace it with 
    done = true;
  }

  void created(){
    super.created();
    objectType = ObjectType.otComment;
  }
public:
  string value;
}
*/

abstract class SoBaseNumber: SoConstObject{ //base class for Number and Integer
}

/** SoInteger **/

class SoInteger: SoBaseNumber {
protected:
  override void created(){
    super.created();
    objectType = ObjectType.otInteger;
  }
public:
  integer value;

  this(integer aValue){
    value = aValue;
  }

  override void assign(SoObject fromObject){      
    value = fromObject.asInteger;      
  }    

  override bool operate(SoObject aObject, OpOperator aOperator){

    switch(aOperator.name){
      case "+": 
        value = value + aObject.asInteger;
        return true;
      case "-": 
        value = value - aObject.asInteger;
        return true;
      case "*": 
        value = value * aObject.asInteger;
        return true;
      case "/": 
        value = value % aObject.asInteger;
        return true;
      default:
        return false;
    }
  }

  override bool toText(out string outValue){
    outValue = to!text(value);
    return true;
  }

  override bool toNumber(out number outValue){
    outValue = to!number(value);
    return true;
  }

  override bool toInteger(out integer outValue){
    outValue = value;
    return true;
  }

  override bool toBool(out bool outValue){
    outValue = value != 0;
    return true;
  }
}

/** SoNumber **/

class SoNumber: SoBaseNumber {
protected:
  override void created(){
    super.created();
    objectType = ObjectType.otNumber;
  }
public:
  number value;

  this(number aValue){
    value = aValue;
  }

  override void assign(SoObject fromObject){      
    value = fromObject.asNumber;      
  }    

  override bool operate(SoObject aObject, OpOperator aOperator){

    switch(aOperator.name){
      case "+": 
        value = value + aObject.asNumber;
        return true;
      case "-": 
        value = value - aObject.asNumber;
        return true;
      case "*": 
        value = value * aObject.asNumber;
        return true;
      case "/": 
        value = value / aObject.asNumber;
        return true;
      default:
        return false;
    }
  }

  override bool toText(out string outValue){
    outValue = to!text(value);
    return true;
  }

  override bool toNumber(out number outValue){
    outValue = value;
    return true;
  }

  override bool toInteger(out integer outValue){
    outValue = to!integer(value);
    return true;
  }

  override bool toBool(out bool outValue){
    outValue = value != 0;
    return true;
  }
}
/** SoBool **/

class SoBool: SoBaseNumber {
  protected:
    override void created(){
      super.created();
      objectType = ObjectType.otBoolean;
    }
  public:
    bool value;
    this(bool aValue){
      value = aValue;
    }

    override void assign(SoObject fromObject){      
      value = fromObject.asBool;
    }    

    override bool operate(SoObject aObject, OpOperator aOperator)
    {
      switch(aOperator.name){
        case "+": 
          value = value && aObject.asBool;
          return true;
        case "-": 
          value = value != aObject.asBool; //xor //LOL
          return true; 
        case "*": 
          value = value || aObject.asBool;
          return true;
        /*case "/": 
          value = value  aObject.asBool;
          return true;*/
        default:
          return false;
      }
    }

    override bool toText(out string outValue){
      outValue = to!text(value);
      return true;
    }

    override bool toNumber(out number outValue){
      outValue = value;
      return true;
    }

    override bool toInteger(out integer outValue){
      outValue = to!integer(value);
      return true;
    }

    override bool toBool(out bool outValue){
      outValue = value != 0;
      return true;
    }
}

/** SoText **/

class SoText: SoConstObject {
protected:
  override void created(){
    super.created();
    objectType = ObjectType.otText;
  }
public:
  text value;

  this(text aValue){
    value = aValue;
  }

  override void assign(SoObject fromObject){      
    value = fromObject.asText;
  }    

  override bool operate(SoObject aObject, OpOperator aOperator){

    switch(aOperator.name){
      case "+": 
        value = value ~ aObject.asText;
        return true;

      case "-": 
        if (cast(SoBaseNumber)aObject !is null) {
          int c = value.length -1;
          c = c - to!int((cast(SoBaseNumber)aObject).asInteger);
          value = value[0..c + 1];
          return true;
        }
        else
          return false;

      case "*":  //stupid idea ^.^ 
        if (cast(SoBaseNumber)aObject !is null) {
          value = stringRepeat(value, to!int((cast(SoBaseNumber)aObject).asInteger));
          return true;
        }
        else
          return false;
/*      case "/": 
        value = value / aObject.asText; Hmmmmm
        return true;*/
      default:
        return false;
    }
  }

  override bool toText(out text outValue){
    outValue = value;
    return true;
  }

  override bool toNumber(out number outValue){
    outValue = to!number(value);
    return true;
  }

  override bool toInteger(out integer outValue){
    outValue = to!integer(value);
    return true;
  }

  override bool toBool(out bool outValue){    
    outValue = to!bool(value);
    return true;
  }
}

/** TODO: SoArray **/

/*TODO
  class SoArray ....

*/


/**---------------------------**/
/**-------- Controls  --------**/
/**---------------------------**/
/**
  This will used in the scanner
*/

//TODO maybe struct not a class
class CtlControl: SardObject{
  string name;
  SardControl code;
  int level;
  string description;

  this(){
    super();
  }

  this(string aName, SardControl aCode){
    this();
    name = aName;
    code = aCode;
  }
}

alias ClassInfo ControlClass;//TODO maybe remove it idk

/*****************/
/** CtlControls **/
/*****************/

class CtlControls: SardNamedObjects!CtlControl
{
  CtlControl add(string aName, SardControl aCode)
  {
    CtlControl c = new CtlControl(aName, aCode);    
    super.add(c);
    return c;
  }

  CtlControl scan(string text, int index)
  {
    CtlControl result = null;
    int max = 0;
    int i = 0;
    while (i < count) {
      string w = this[i].name;
      if (scanCompare(w, text, index)) {
        if (max < this[i].name.length) {
          max = this[i].name.length;
          result = this[i];
        }
      }
      i++;
    }
    return result;
  }

  bool isOpenBy(const char c){
    int i = 0;
    while (i < count){      
      if (this[i].name[0] == toLower(c))
        return true;          
      i++;
    }
    return false;
  }
}

class OpOperator: SardObject{
  public:
    string name;
    string title;
    int level;//TODO it is bad idea, we need more intelligent way to define power of operators
    string description;
    SardControl control;// Fall back to control if is initial, only used for for = to fall back as := //TODO remove it :(
  protected: 
    bool doExecute(RunStack vStack, SoObject vObject){  //TODO maybe abstract function
      return false;
    }
  public:
    final bool execute(RunStack vStack, SoObject vObject){
      return doExecute(vStack, vObject);
    }
}

class OpOperators: SardNamedObjects!OpOperator{
  public:
    OpOperator findByTitle(string title){
      int i = 0;
      while (i < count){
        if (icmp(title, this[i].title) == 0) {
          return this[i];
        }
        i++;
      }
      return null;
    }

  int addOp(OpOperator operator){
    return super.add(operator);
  }

  bool isOpenBy(const char c){
    int i = 0;
    while (i < count){
      if (this[i].name[0] == toLower(c)) {
        return true;
      }
      i++;
    }
    return false;
  }    

  OpOperator scan(string text, int index){
    OpOperator operator = null;
    int max = 0;
    int i = 0;
    while (i < count){
      if (scanCompare(this[i].name, text, index)) {
        if (max < this[i].name.length) {
          max = this[i].name.length;
          operator = this[i];
        }
      }
      i++;
    }
    return operator;
  }    
}

class OpPlus: OpOperator{
  this(){
    super();
    name = "+";
    title = "Plus";
    level = 50;
    description = "Add object to another object";
  }
}

class OpMinus: OpOperator{
  this(){
    super();
    name = "-";
    title = "Minus";
    level = 50;
    description = "Sub object to another object";
  }
}

class OpMultiply: OpOperator{
  this(){
    super();
    name = "*";
    title = "Multiply";
    level = 51;
    description = "";
  }
}

class OpDivide: OpOperator{
  this(){
    super();
    name = "/";
    title = "Divition";
    level = 51;
    description = "";
  }
}

class OpPower: OpOperator{
  this(){
    super();
    name = "^";
    title = "Power";
    level = 52;
    description = "";
  }
}

class OpLesser: OpOperator{
  this(){
    super();
    name = "<";
    title = "Lesser";
    level = 51;
    description = "";
  }
}

class OpGreater: OpOperator{
  this(){
    super();
    name = ">";
    title = "Greater";
    level = 51;
    description = "";
  }
}

class OpEqual: OpOperator{
  this(){
    super();
    name = ":=";
    title = "Equal";
    level = 51;
    description = "";
    //control = ctlAssign; bad idea
  }
}

class OpNotEqual: OpOperator{
  this(){
    super();
    name = "<>";
    title = "NotEqual";
    level = 51;
    description = "";    
  }
}

class OpNot: OpOperator{
  this(){
    super();
    name = "!";
    title = "Not";
    level = 51;
    description = "";
  }
}

class OpAnd: OpOperator{
  this(){
    super();
    name = "&";
    title = "And";
    level = 51;
    description = "";
  }
}

class OpOr: OpOperator{
  this(){
    super();
    name = "|";
    title = "Or";
    level = 51;
    description = "";
  }
}
/*
class RunShadows: SardNamedObjects!RunShadow{
public:
  string name;
private:
    SoObject _link;
    public @property SoObject link() {return _link;}
    public @property SoObject link(SoObject value) {
      if (_link != value){
        _link = value;        
      }
      return _link;
    }
    RunShadow _parent;
    public @property RunShadow parent() {return _parent;}

public:
    this(RunShadow parent){
      super();
      _parent = parent;
    }
}
*/

class RunVariable: SardObject{
  public:
    string name;
    RunVarKinds kind;
private:

    RunResult _value;
    public @property RunResult value() { return _value; }
    public @property RunResult value(RunResult newValue) { 
      if (_value !is newValue){
        //destory(_value);//TODO hmmm we must leave it to GC
        _value =  newValue;
      }
      return _value; 
    }
}

class RunVariables: SardNamedObjects!RunVariable{

  RunVariable register(string vName, RunVarKinds vKind){
    RunVariable result = find(vName);
    if (result is null){      
      result = new RunVariable();
      result.name = vName;
      result.kind = vKind;
      add(result);
    }
    return result;
  }

  RunVariable setValue(string vName, SoObject newValue){
    RunVariable v = find(vName);
    if (v !is null)
      v.value.object = newValue;
    return v;
  }
}

class RunResult: SardObject{
  private:
    SoObject _object;
  public:
    @property SoObject object() { return _object; };
    @property SoObject object(SoObject value) { 
      if (_object !is value){
        if (_object !is null) {
        }
        _object = value;
      }
      return _object; 
    };
  
    @property bool hasValue(){
      return object !is null;
    }

    void assign(RunResult fromResult){
      if (fromResult.object is null)
        object = null;
      else
        object = fromResult.object.clone();
    }

    SoObject extract(){
      SoObject o = _object;
      _object = null;
      return o;
    }
}

class RunLocalItem: SardObject{
  public:
    RunVariables variables;
    this(){
      super();
      variables = new RunVariables();
    }
}

class RunLocal: SardStack!RunLocalItem {
  void insert() {
    push(new RunLocalItem());
  }
}

class RunReturnItem: SardObject{
  public:
    private RunResult _result = new RunResult();
    @property RunResult result() { return _result; };

    private RunResult _reference;
    @property RunResult reference() { return _reference; };
    @property RunResult reference(RunResult value) { 
        if (_reference != value) {
          if (_reference !is null) 
            raiseError("Already set a reference");
          _reference = value;
        }

        return _reference; 
    };

    //ReleaseResult return the Result and set FResult to nil witout free it, you need to free the Result by your self
    RunResult releaseResult(){
      auto r = _result;
      _result = null;
      return r;
    }

    this(){
      super();      
    }
}

class RunReturn: SardStack!RunReturnItem {
  public:        
    void insert() {
      push(new RunReturnItem());
    }
}

class RunStack: SardObject {
  private:
    RunLocal _local = new RunLocal();
    RunReturn _ret = new RunReturn();
    //RunShadow _shadow = new RunShadow(null);
  public:
    SrdEnvironment env; //TODO maybe struct not a class
    //@property SrdEnvironment env() {return _env ;};
    @property RunLocal local() {return _local;};
    //   @property RunShadow shadow() {return _shadow ;};
    @property RunReturn ret() {return _ret ;};
    /*
    RunShadow TouchMe(SoObject aObject) {
    }*/

    this(){
      super();

      local.insert();
      ret.insert();
    }

    ~this(){      
      ret.pop();
      local.pop();
    }
}

class SoVersion_Const:SoNamedObject{
protected:
  override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done){
    vStack.ret.current.result.object = new SoText(sSardVersion);
  }
}

class SoTime_Const: SoNamedObject{
protected:
  override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done){    
    vStack.ret.current.result.object = new SoText(Clock.currTime().toISOExtString());
  }
}

class SoMain: SoSection
{
  protected:
    SoVersion_Const versionConst = new SoVersion_Const();

  public:
    this(){
      super();
      versionConst.parent = this;
      versionConst.name = "Version";
      addDeclare(null, versionConst);
    }
}

class SrdEngine: SardObject{  
}

//--------------------------------------
//--------------  TODO  ----------------
//--------------------------------------


class SrdEnvironment: SardObject{
  private:
  protected:
    override void created(){
      with (operators)
      {

        add(new OpPlus);
        add(new OpMinus());
        add(new OpMultiply());
        add(new OpDivide());

        add(new OpEqual());
        add(new OpNotEqual());
        add(new OpAnd());
        add(new OpOr());
        add(new OpNot());

        add(new OpGreater());
        add(new OpLesser());

        add(new OpPower());
      } 
    }

  public:
    OpOperators operators = new OpOperators();
    this(){
      super();
    }    
}

class SrdDebugInfo: SardObject {
}