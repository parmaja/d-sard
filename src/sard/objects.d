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
  Some objects (like Section) have a Block, and some have one Statment
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
              it is save the result of statment come from the parser

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
*/

import sard.classes;
import minilib.sets;

const string sSardVersion = "0.01";
const int iSardVersion = 1;


enum SrdObjectType {otUnkown, otInteger, otFloat, otBoolean, otString, otComment, otBlock, otObject, otClass, otVariable};
enum SrdCompare {cmpLess, cmpEqual, cmpGreater};


enum RunVarKind {vtLocal, vtParam};//Ok there is more in the future
alias RunVarKinds = Set!RunVarKind;

class SrdObjectList(T): SardObjects!T { //TODO rename it to SoObjects

  private:
    SoObject _parent;

  public:
    @property SoObject parent() { return _parent; }

  public:
  /*
    We need default constructor to resolve this error
    Error	1	Error: class sard.objects.SrdStatement Cannot implicitly generate a default ctor when base class sard.objects.SrdObjectList!(SrdClause).SrdObjectList is missing a default ctor	W:\home\d\lib\sard\src\sard\objects.d	151	
  */
    this(){
      super();
    }

    this(SoObject aParent){
      _parent = aParent;
      this();      
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
      name = aName;
      super();
    }
}

class SrdDefines: SardObjects!SrdDefine {

  void add(string aName, string aResult) {
    super.add(new SrdDefine(aName, aResult));
  }
}

/** SrdClause */

class SrdClause: SardObject {
  private
    OpOperator _operator;
    SoObject _object;

  public:
    @property OpOperator operator() { return _operator; }
    @property SoObject object() { return _object; }

    this(OpOperator aOperator, SoObject aObject) {
      _operator = aOperator;
      _object = aObject;
      super();
    }

    bool execute(RunStack vStack) {
      if (_object is null)
        raiseError("Object not set!");
      return _object.execute(vStack, _operator);
    }
}

/** SrdStatement */

class SrdStatement: SrdObjectList!SrdClause {
  public:
    void add(OpOperator aOperator, SoObject aObject){
      SrdClause clause = new SrdClause(aOperator, aObject);
      aObject.parent = parent;
      super.add(clause);    
    }

  public SrdDebugInfo debuginfo; //<-- Null until we compiled it with Debug Info
}

//--------------  TODO  ----------------

class SrdDebugInfo: SardObject {
}

class RunStack: SardObject {
}

class SrdBlock: SardObject {
}

class OpOperator:SardObject {
}

class SoObject: SardObject {
  private:
    SoObject _parent;

  public:
    @property SoObject parent() {return _parent; };
    @property 
        SoObject parent(SoObject value) {
          return _parent = value; 
     };

  public:
    bool execute(RunStack vStack, OpOperator aOperator, SrdDefines vDefines = null, SrdBlock vParameters = null){
      return false;
    }
}