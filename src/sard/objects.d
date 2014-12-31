module sard.objects;
/**
  This file is part of the "SARD"

  @license   The MIT License (MIT) Included in this distribution
  @author    Zaher Dirkey <zaher at yahoo dot com>
*/


/**TODO:
  SoArray:   Object have another objects, a list of objectd without execute it,
             it is save the result of statement come from the parser

  RunEngine: Load file and compile it, also have debugger actions and log to console of to any plugin that provide that interface
              Engine cache also compile files to use it again and it check the timestamp before recompile it
  

  Modifier: It is like operator but with one side can be in the context before the identifier like + !x %x $x
*/


import std.stdio;
import std.conv;
import std.uni;
import std.datetime;
import sard.utils;
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

enum RunVarKind {Local, Param}; //Ok there is more in the future

alias RunVarKinds = Set!RunVarKind;

class SrdDebugInfo: SardObject 
{
}

class SrdObjects(T): SardObjects!T 
{ 
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

class SrdDebug: SardObject 
{
  public:
    int line;
    int column;
    string fileName;
    //bool breakPoint; //not sure, do not laugh
}

/** SrdClause */

class SrdClause: SardObject
{
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
        error("Object not set!");
      return _object.execute(aStack, _operator);
    }

    debug{
      override void debugWrite(int level){
        super.debugWrite(level);
        writeln(stringRepeat(" ", level * 2) ~ "operator: " ~ (_operator? _operator.name : "") );
        writeln(stringRepeat(" ", level * 2) ~ "name: " ~ (_object? _object.name : "") );
      }
    }
}

/** SrdStatement */

class SrdStatement: SrdObjects!SrdClause 
{
  //check BUG1
  this(SoObject aParent)
  {
    super(aParent);    
  }   

  public:
    void add(OpOperator aOperator, SoObject aObject)
    {
      debug{
        writeln("Statement.AddClause: " ~ (aOperator? aOperator.name : "none") ~ "," ~ aObject.classinfo.name);
      }
      if (aObject.parent !is null)
        error("You can not add object to another parent!");
      aObject.parent = parent;
      SrdClause clause = new SrdClause(aOperator, aObject);
      super.add(clause);    
    }

    void execute(RunStack aStack)
    {
      aStack.ret.push(); //Each statement have own result
      call(aStack);
      if (aStack.ret.current.reference !is null)
        aStack.ret.current.reference.object = aStack.ret.current.result.extract();  //it is responsible of assgin to parent result or to a variable
      aStack.ret.pop();
    }

    void call(RunStack aStack)
    {
      int i = 0;
      while (i < count) {
        this[i].execute(aStack);
        i++;
      }
    }

    public SrdDebugInfo debuginfo; //<-- Null until we compiled it with Debug Info
}

class SrdStatements: SrdObjects!SrdStatement
{
  public:    

    //check BUG1
    this(SoObject aParent){
      super(aParent);    
    }   

    SrdStatement add()
    {
      SrdStatement statement = new SrdStatement(parent);
      super.add(statement);
      return statement;
    }

    void check()
    {
      if (count == 0) {
        add();
      }
    }

    bool execute(RunStack aStack)
    {
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

/** SoObject */

abstract class SoObject: SardObject 
{
  private:
    SoObject _parent;
    string _name;
    public @property string name(){ return _name; }
    public @property string name(string value){ return _name = value; }

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
    @property SoObject parent(SoObject value) {
        if (_parent !is null) 
          error("Already have a parent");
        _parent = value;
        doSetParent(_parent);
        return _parent; 
      };

    protected void doSetParent(SoObject aParent){
    }

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
    @property final text asText()
    {
      string o;
      if (toText(o))
        return o;
      else
        return "";
    };

    @property final number asNumber()
    {
      number o;
      if (toNumber(o))
        return o;
      else
        return 0;
    };

    @property final integer asInteger()
    {
      integer o;
      if (toInteger(o))
        return o;
      else
        return 0;
    };

    @property final bool asBool()
    {
      bool o;
      if (toBool(o))
        return o;
      else
        return false;
    };

    void assign(SoObject fromObject)
    {
      //nothing
    }

    SoObject clone(bool withValues = true)
    { 
      debug {
        writeln("Cloneing " ~ this.classinfo.name);
      }
      //TODO, here we want to check if subclass have a default ctor 
      SoObject object = cast(SoObject)this.classinfo.create(); //new typeof(this);//<-bad i want to create new object same as current object but with descent
	    if (object is null)
		    error("Error when cloning");      

      if (withValues)
        object.assign(this);
      return object;
    }

  protected: 
    bool doOperate(SoObject object, OpOperator operator) {
      return false;
    }

    final bool operate(SoObject object, OpOperator operator) 
    {
      if (operator is null)
        return false;
      else
        return doOperate(object, operator);
    }

    void beforeExecute(RunStack vStack, OpOperator aOperator){

    }

    void afterExecute(RunStack vStack, OpOperator aOperator){

    }

    //TODO executeParams will be bigger, i want to add to it SrdStatements Blocks too so i will collect it into a struct
    void executeParams(RunStack vStack, SrdDefines vDefines, SrdStatements vParameters) {

    }

    void doExecute(RunStack vStack,OpOperator aOperator, ref bool done){
    }

  public:
    bool execute(RunStack vStack, OpOperator aOperator, SrdDefines vDefines = null, SrdStatements vParameters = null) 
    {
      bool result = false;
      beforeExecute(vStack, aOperator);
      executeParams(vStack, vDefines, vParameters);
      doExecute(vStack, aOperator, result);
      afterExecute(vStack, aOperator);      

      debug {
      
        string s = stringRepeat("-", vStack.ret.currentItem.level)~ "->";
        s = s ~ "Execute: " ~ this.classinfo.name ~ " Level=" ~ to!string(vStack.ret.currentItem.level);
        if (aOperator !is null)
          s = s ~ "{" ~ aOperator.name ~ "}";
        if (vStack.ret.current.result.object !is null)
          s = s ~ " Value: " ~ vStack.ret.current.result.object.asText;
        writeln(s);
      }
      

      return result; 
    }

    int addDeclare(SoNamedObject executeObject, SoNamedObject callObject)
    {
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

class SoNamedObject: SoObject 
{
  private:
    int _id;
  public:
    @property int id(){ return _id; }
    @property int id(int value){ return _id = value; }
  public:

    this(){
      super();
    }

    this(SoObject vParent, string vName)
    {
      this();
      name = vName;
      parent = vParent;
    }

    RunVariable registerVariable(RunStack vStack, RunVarKinds vKind)
    {
      return vStack.local.current.variables.register(name, vKind);
    }
}

/*--------------------------------------------*/

abstract class SoConstObject: SoObject
{
  override final void doExecute(RunStack vStack, OpOperator aOperator, ref bool done){
    if ((vStack.ret.current.result.object is null) && (aOperator is null)) 
    {
      vStack.ret.current.result.object = clone();
      done = true;
    }
    else 
    {      
      if (vStack.ret.current.result.object is null)
        vStack.ret.current.result.object = clone(false);
      done = vStack.ret.current.result.object.operate(this, aOperator);
    }
  }
}

/**-------------------------------**/
/**-------- Const Objects --------**/
/**-------------------------------**/

/** SoNone **/

class SoNone: SoConstObject  //None it is not Null, it is an initial value we sart it
{ 
  //Do operator
  //Convert to 0 or ''
}

/** SoComment **/

class SoComment: SoObject
{
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
    //TODO execute external program and replace it with the result
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

abstract class SoBaseNumber: SoConstObject //base class for Number and Integer
{ 
}

/** SoInteger **/

class SoInteger: SoBaseNumber 
{
  protected:
    override void created(){
      super.created();
      objectType = ObjectType.otInteger;
    }
  public:
    integer value;

    this(){      
      super();
    }

    this(integer aValue){
      this();
      value = aValue;
    }

    override void assign(SoObject fromObject){      
      value = fromObject.asInteger;      
    }    

    override bool doOperate(SoObject object, OpOperator operator)
    {
      switch(operator.name){
        case "+": 
          value = value + object.asInteger;
          return true;
        case "-": 
          value = value - object.asInteger;
          return true;
        case "*": 
          value = value * object.asInteger;
          return true;
        case "/": 
          value = value % object.asInteger;
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

class SoNumber: SoBaseNumber 
{
  protected:
    override void created(){
      super.created();
      objectType = ObjectType.otNumber;
    }

  public:
    number value;

    this(){      
      super();
    }

    this(number aValue){
      this();
      value = aValue;
    }

    override void assign(SoObject fromObject){      
      value = fromObject.asNumber;      
    }    

    override bool doOperate(SoObject object, OpOperator operator)
    {
      switch(operator.name)
      {
        case "+": 
          value = value + object.asNumber;
          return true;
        case "-": 
          value = value - object.asNumber;
          return true;
        case "*": 
          value = value * object.asNumber;
          return true;
        case "/": 
          value = value / object.asNumber;
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

class SoBool: SoBaseNumber 
{
  protected:
    override void created(){
      super.created();
      objectType = ObjectType.otBoolean;
    }
  public:
    bool value;

    this(){      
      super();
    }

    this(bool aValue){
      this();
      value = aValue;
    }

    override void assign(SoObject fromObject){      
      value = fromObject.asBool;
    }    

    override bool doOperate(SoObject object, OpOperator operator)
    {
      switch(operator.name){
        case "+": 
          value = value && object.asBool;
          return true;
        case "-": 
          value = value != object.asBool; //xor //LOL
          return true; 
        case "*": 
          value = value || object.asBool;
          return true;
        /*case "/": 
          value = value  object.asBool;
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

class SoText: SoConstObject 
{
protected:
  override void created(){
    super.created();
    objectType = ObjectType.otText;
  }
public:
  text value;

  this(){      
    super();
  }

  this(text aValue){
    this();
    value = aValue;
  }

  override void assign(SoObject fromObject){      
    value = fromObject.asText;
  }    

  override bool doOperate(SoObject object, OpOperator operator)
  {
    switch(operator.name){
      case "+": 
        value = value ~ object.asText;
        return true;

      case "-": 
        if (cast(SoBaseNumber)object !is null) {
          int c = value.length -1;
          c = c - to!int((cast(SoBaseNumber)object).asInteger);
          value = value[0..c + 1];
          return true;
        }
        else
          return false;

      case "*":  //stupid idea ^.^ 
        if (cast(SoBaseNumber)object !is null) {
          value = stringRepeat(value, to!int((cast(SoBaseNumber)object).asInteger));
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

/**
  SoStatements is a base class for list of objects (statements)
*/

abstract class SoStatements: SoNamedObject
{
  protected:
    SrdStatements _statements;

    public @property SrdStatements statements() { return _statements; };

    override void executeParams(RunStack vStack, SrdDefines vDefines, SrdStatements vParameters){

      super.executeParams(vStack, vDefines, vParameters);
      if (vParameters !is null) 
      { //TODO we need to check if it is a block?      
        int i = 0;
        while (i < vParameters.count) { //here i was added -1 to the count | while (i < vParameters.count -1)
          vStack.ret.push();
          vParameters[i].call(vStack);
          if (i < vDefines.count){      
            RunVariable v = vStack.local.current.variables.register(vDefines[i].name, RunVarKinds([RunVarKind.Local, RunVarKind.Param])); //TODO but must find it locally
            v.value = vStack.ret.current.releaseResult();
          }
          vStack.ret.pop();
          i++;
        }        
      }
    }
                     
    override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done)
    {                
      vStack.ret.push(); //<--here we can push a variable result or create temp result to drop it
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
        _statements.debugWrite(level + 1);
      }
    }

    override void created(){
      super.created();
      _objectType = ObjectType.otBlock;
    }

    this(){
      super();
      _statements = new SrdStatements(this);      
    }

    void call(RunStack vStack){ //vBlock here is params
      statements.execute(vStack);
    }
}

/*--------------------------------------------*/

/**
  x(i: integer) {...
---[ Defines  ]-------   
*/

class SrdDefine: SardObject 
{
public:
  string name;
  string result;
  this(string aName, string aResult){
    super();
    name = aName;
  }
}

class SrdDefines: SardObjects!SrdDefine 
{
  void add(string aName, string aResult) {
    super.add(new SrdDefine(aName, aResult));
  }
}

//Just a references not free inside objects, not sure how to do that in D

class SrdDeclares: SardNamedObjects!SoDeclare {
}

/** SoBlock */
/** 
  Used by { } 
  It a block before execute push in stack, after execute will pop the stack, it have return value too in the stack
*/

class SoBlock: SoStatements  //Result was droped until using := assign in the first of statement
{ 
  private:
    SrdDeclares _declares; //It is cache of objects listed inside statements, it is for fast find the object
    
    public @property SrdDeclares declares() { return _declares; };

  protected:
    override void beforeExecute(RunStack vStack, OpOperator aOperator){
      super.beforeExecute(vStack, aOperator);
      vStack.local.push();
    }

    override void afterExecute(RunStack vStack, OpOperator aOperator){
      super.afterExecute(vStack, aOperator);
      vStack.local.pop();
    }

  public:

    this(){
      _declares = new SrdDeclares();
      super();
    }

    debug{
      override void debugWrite(int level){
        super.debugWrite(level);
        _declares.debugWrite(level + 1);
      }
    }

    override SoDeclare findDeclare(string vName)
    {
      if (parent !is null)
        return parent.findDeclare(vName);
      else
        return null;
    }
}

/**
  x := 10  + ( 500 + 600);
-------------[  Limb    ]-------
Limb (i dislike the name) it is a block but without pushing stack.
*/

class SoLimb: SoObject
{
  protected:
    SrdStatement _statement;
    public @property SrdStatement statement() { return _statement; };

    override void beforeExecute(RunStack vStack, OpOperator aOperator)
    {
      super.beforeExecute(vStack, aOperator);
      vStack.ret.push();
    }  

    override void afterExecute(RunStack vStack, OpOperator aOperator)
    {      
      super.afterExecute(vStack, aOperator);
      RunReturnItem T = vStack.ret.pull();
      if (T.result.object !is null)
        T.result.object.execute(vStack, aOperator);            
    }  

    override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done)
    {
      super.doExecute(vStack, aOperator, done);
      statement.call(vStack);
      done = true;
    }

  public:
    this(){
      super();
      _statement = new SrdStatement(parent);
    }
}

/**  Variables objects */

/**   SoInstance */

/** 
  it is a variable value like x in this "10 + x + 5" 
  it will call the object if it is a object not a variable
*/

class SoInstance: SoStatements
{
  protected:
    override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done)
    {            
      SoDeclare p = findDeclare(name);
      if (p !is null) //maybe we must check Define.count, cuz it refere to it class
        p.call(vStack, aOperator, statements, done);
      else 
      {
        RunVariable v = vStack.local.current.variables.find(name);
        if (v is null)
          error("Can not find a variable: " ~ name);
        if (v.value.object is null)
          error("Variable object is null: " ~ v.name);
        done = v.value.object.execute(vStack, aOperator);
      }      
    }

  public:
    override void created()
    {
      super.created();
      objectType = ObjectType.otObject;
    }
}


class SoVariable: SoNamedObject
{ 
  protected:
    override void doExecute(RunStack vStack, OpOperator aOperator,ref bool done)
    {            
      RunVariable v = registerVariable(vStack, RunVarKinds([RunVarKind.Local]));
        if (v is null)
          error("Can not register a varibale: " ~ name) ;
        if (v.value.object is null)
          error(v.name ~ " variable have no value yet:" ~ name);//TODO make it as empty
      done = v.value.object.execute(vStack, aOperator);
    }

  public:
    ClassInfo resultType;

    this(){
      super();
    }

    this(SoObject vParent, string vName)
    {       
      super(vParent, vName);
    }
}

/** It is assign a variable value, x:=10 + y */

class SoAssign: SoNamedObject
{
  protected:
    override void doSetParent(SoObject value) {
      super.doSetParent(value);
    }

    override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done)
    {
      //super.doExecute(vStack, aOperator, done);
      /** if not name it assign to parent result */
      done = true;
      if (name == "")
        vStack.ret.current.reference = vStack.ret.parent.result;
      else {
        SoDeclare aDeclare = findDeclare(name);//TODO: maybe we can cache it
        if (aDeclare !is null) 
        {
          if (aDeclare.callObject !is null)
          {
            RunVariable v = aDeclare.callObject.registerVariable(vStack, RunVarKinds([RunVarKind.Local])); //parent becuase we are in the statement
            if (v is null)
              error("Variable not found!");
            vStack.ret.current.reference = v.value;
          }
        }
        else 
        { //Ok let is declare it locally
          RunVariable v = registerVariable(vStack, RunVarKinds([RunVarKind.Local]));//parent becuase we are in the statement
          if (v is null)
            error("Variable not found!");
          vStack.ret.current.reference = v.value;
        }
      }
    }

    override void created()
    {
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

class SoDeclare: SoNamedObject
{
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

  public:
    this(){
      super();
      _defines = new SrdDefines();
    }    

    debug{
      override void debugWrite(int level){
        super.debugWrite(level);
        _defines.debugWrite(level + 1);
      }
    }

  public:
    //executeObject will execute in a context of statement if it is not null,
    SoNamedObject executeObject;//You create it but Declare will free it
    //callObject will execute by call, when called from outside,
    SoNamedObject callObject;//You create it but Declare will free it
    //** I hate that above, we need one
    string resultType;

    //This outside execute it will force to execute the Block
    void call(RunStack vStack, OpOperator aOperator, SrdStatements aParameters, ref bool done){
      done = callObject.execute(vStack, aOperator, defines, aParameters);
    }

  override protected void doExecute(RunStack vStack, OpOperator aOperator,ref bool done)
  {
    if (executeObject !is null)
      done = executeObject.execute(vStack, aOperator);
    else
      done = true;
  }
}

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
    while (i < count) 
    {
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
    int level;//TODO it is bad idea, we need more intelligent way to define the power level of operators
    string description;
    //SardControl control;// Fall back to control if is initial, only used for for = to fall back as := //TODO remove it :(
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
      if (this[i].name[0] == toLower(c)) 
        return true;
      
      i++;
    }
    return false;
  }    

  OpOperator scan(string text, int index)
  {
    OpOperator result = null;
    int max = 0;
    int i = 0;
    while (i < count)
    {
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
}

class OpNone: OpOperator{
  this(){
    super();
    name = "";
    title = "None";
    level = 50;
    description = "Nothing";
  }
}

class OpPlus: OpOperator{
  this(){
    super();
    name = "+";
    title = "Plus";
    level = 51;
    description = "Add object to another object";
  }
}

class OpMinus: OpOperator{
  this(){
    super();
    name = "-";
    title = "Minus";
    level = 51;
    description = "Sub object to another object";
  }
}

class OpMultiply: OpOperator{
  this(){
    super();
    name = "*";
    title = "Multiply";
    level = 52;
    description = "";
  }
}

class OpDivide: OpOperator{
  this(){
    super();
    name = "/";
    title = "Divition";
    level = 52;
    description = "";
  }
}

class OpPower: OpOperator{
  this(){
    super();
    name = "^";
    title = "Power";
    level = 53;
    description = "";
  }
}

class OpLesser: OpOperator{
  this(){
    super();
    name = "<";
    title = "Lesser";
    level = 52;
    description = "";
  }
}

class OpGreater: OpOperator{
  this(){
    super();
    name = ">";
    title = "Greater";
    level = 52;
    description = "";
  }
}

class OpEqual: OpOperator{
  this(){
    super();
    name = ":=";
    title = "Equal";
    level = 52;
    description = "";
    //control = ctlAssign; bad idea
  }
}

class OpNotEqual: OpOperator{
  this(){
    super();
    name = "<>";
    title = "NotEqual";
    level = 52;
    description = "";    
  }
}

class OpNot: OpOperator{
  this(){
    super();
    name = "!";
    title = "Not";
    level = 52;
    description = "";
  }
}            

class OpAnd: OpOperator{
  this(){
    super();
    name = "&";
    title = "And";
    level = 52;
    description = "";
  }
}

class OpOr: OpOperator{
  this(){
    super();
    name = "|";
    title = "Or";
    level = 52;
    description = "";
  }
}

class RunVariable: SardObject
{
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

class RunVariables: SardNamedObjects!RunVariable
{
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

class RunResult: SardObject
{
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

class RunLocalItem: SardObject
{
  public:
    RunVariables variables;
    this(){
      super();
      variables = new RunVariables();
    }
}

class RunLocal: SardStack!RunLocalItem 
{
}

class RunReturnItem: SardObject
{
  public:
    private RunResult _result = new RunResult();
    @property RunResult result() { return _result; };

    private RunResult _reference;
    @property RunResult reference() { return _reference; };
    @property RunResult reference(RunResult value) { 
        if (_reference != value) {
          if (_reference !is null) 
            error("Already set a reference");
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

class RunReturn: SardStack!RunReturnItem 
{
  public:        
}

class RunStack: SardObject 
{
  private:
    RunLocal _local = new RunLocal();
    RunReturn _ret = new RunReturn();
    //RunShadow _shadow = new RunShadow(null);
  public:
    //SrdEnvironment env; 
    
    @property RunLocal local() {return _local;};
    //   @property RunShadow shadow() {return _shadow ;};
    @property RunReturn ret() {return _ret ;};
    /*
    RunShadow TouchMe(SoObject aObject) {
    }*/

    this(){
      super();

      local.push();
      ret.push();
    }

    ~this(){      
      ret.pop();
      local.pop();
    }
}

