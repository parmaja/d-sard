module sard.objects;
/**
    This file is part of the "SARD"

    @license   The MIT License (MIT) Included in this distribution
    @author    Zaher Dirkey <zaher at yahoo dot com>
*/


/**TODO:
    SoArray:   Object have another objects, a list of objectd without execute it,
    it is save the result of statement come from the parser  

    Modifiers: It is like operator but with one side can be in the context before the identifier like + !x %x $x
*/

/**TODO:
    result and reference are same, we need to remove reference
*/

import std.stdio;
import std.conv;
import std.uni;
import std.datetime;
import std.string;

import sard.utils;
import sard.classes;
import sard.runtimes;
import sard.operators;

import minilib.sets;


const string sSardVersion = "0.01";
const int iSardVersion = 1;

alias long integer;
alias double number;
alias string text;

enum ObjectType {otUnkown, otInteger, otNumber, otBoolean, otText, otComment, otBlock, otObject, otClass, otVariable};
enum Compare {cmpLess, cmpEqual, cmpGreater};

class SrdDebugInfo: SardObject 
{
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

    this(OpOperator operator, SoObject aObject) 
    {
        super();
        _operator = operator;
        _object = aObject;
    }

    bool execute(RunStack stack) 
    {
        if (_object is null)
            error("Object not set!");
        return _object.execute(stack, _operator);
    }

    debug{
        override void debugWrite(int level)
        {
            super.debugWrite(level);
            if (_operator !is null)
                _operator.debugWrite(level + 1);
            if (_object !is null)
                _object.debugWrite(level + 1);
        }
    }
}

/* SrdStatement */

class SrdStatement: SardObjects!SrdClause 
{
private:
    SoObject _parent;
    public @property SoObject parent() { return _parent; }

    this(SoObject aParent)
    {
        super();
        _parent = aParent;
    }   

public:
    void add(OpOperator operator, SoObject aObject)
    {
        debug{            
            writeln("add clause: " ~ (operator? operator.name : "none") ~ ", " ~ aObject.classinfo.nakename);
        }
        if (aObject.parent !is null)
            error("You can not add object to another parent!");
        aObject.parent = parent;
        SrdClause clause = new SrdClause(operator, aObject);
        super.add(clause);    
    }

    void execute(RunStack stack)
    {
        stack.results.push(); //Each statement have own result
        call(stack);
        stack.results.pop();
    }

    void call(RunStack stack)
    {
        //https://en.wikipedia.org/wiki/Shunting-yard_algorithm        
        foreach(e; items) 
        {
            e.execute(stack);
        }
    }

    public SrdDebugInfo debuginfo; //<-- Null until we compiled it with Debug Info
}

class SrdStatements: SardObjects!SrdStatement
{
private:
    SoObject _parent;
    public @property SoObject parent() { return _parent; }

public:    

    //check BUG1
    this(SoObject aParent){
        super();
        _parent = aParent;    
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

    bool execute(RunStack stack)
    {
        if (count == 0)
            return false;
        else
        {            
            foreach(e; items) {
                e.execute(stack);
                //if the current statement assigned to parent or variable result "Reference" here have this object, or we will throw the result
            }
            return true;
        }
    }
}

/* SoObject */

abstract class SoObject: SardObject 
{
private:
    int _id;
    public @property int id(){ return _id; }
    public @property int id(int value){ return _id = value; }

    SoObject _parent;
    string _name;
    public @property string name(){ return _name; }
    public @property string name(string value){ return _name = value; }

protected:
    ObjectType _objectType;

    public @property ObjectType objectType() {  return _objectType; }
    public @property ObjectType objectType(ObjectType value) { return _objectType = value; }

public:
    this()
    {       
        super();
    }

    this(SoObject aParent, string aName)
    { 
        this();      
        _name = aName;
        parent = aParent;//to trigger doSetParent
    }


    protected void doSetParent(SoObject aParent){
    }

    @property SoObject parent() {return _parent; };
    @property SoObject parent(SoObject value) 
    {
        if (_parent !is null) 
            error("Already have a parent");
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
            writeln("Cloneing " ~ this.classinfo.nakename);
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

    void beforeExecute(RunStack stack, OpOperator operator){

    }

    void afterExecute(RunStack stack, OpOperator operator){

    }

    void doExecute(RunStack stack,OpOperator operator, ref bool done){
    }

public:
    final bool execute(RunStack stack, OpOperator operator, SrdDefines defines = null, SrdStatements arguments = null, SrdStatements blocks = null)
    {
        bool done = false;

        beforeExecute(stack, operator);      
        if (defines !is null)
            defines.execute(stack, arguments);
        doExecute(stack, operator, done);
        afterExecute(stack, operator);      

        debug 
        {      
            string s = "  " ~ stringRepeat(" ", stack.results.currentItem.level) ~ ">";
            s = s ~ this.classinfo.nakename ~ " level: " ~ to!string(stack.results.currentItem.level);
            if (operator !is null)
                s = s ~ "{" ~ operator.name ~ "}";
            if (stack.results.current.variable.value !is null)
                s = s ~ " result: " ~ stack.results.current.variable.value.asText;
            writeln(s);
        }  
        return done; 
    }

    RunVariable registerVariable(RunStack stack, RunVarKinds vKind)//TODO move it into stack
    {
        return stack.local.current.variables.register(name, vKind);
    }

    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln(stringRepeat(" ", level * 2) ~ "name: " ~ name);
            writeln(stringRepeat(" ", level * 2) ~ "value: " ~ asText );
        }
    }
}

/*
SoStatements is a base class for list of objects (statements)
*/

abstract class SoStatements: SoObject
{
protected:
    SrdStatements _statements;

    public @property SrdStatements statements() { return _statements; };

    override void doExecute(RunStack stack, OpOperator operator, ref bool done)
    {                
        stack.results.push(); //<--here we can push a variable result or create temp result to drop it
        call(stack);
        auto t = stack.results.pull();
        //I dont know what if ther is an object there what we do???
        if (t.variable.value !is null)
            t.variable.value.execute(stack, operator);
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

    void call(RunStack stack){ //vBlock here is params
        statements.execute(stack);
    }
}

/** SoBlock */
/** 
    Used by { } 
    It a block before execute push in stack, after execute will pop the stack, it have return value too in the stack
*/

class SoBlock: SoStatements  //Result was droped until using := assign in the first of statement
{ 
private:

protected:
    override void beforeExecute(RunStack stack, OpOperator operator){
        super.beforeExecute(stack, operator);
        stack.local.push();
    }

    override void afterExecute(RunStack stack, OpOperator operator)
    {
        super.afterExecute(stack, operator);
        stack.local.pop();
    }

public:

    this(){
        super();
    }
}

/**
x := 10  + ( 500 + 600);
-------------[  Sub    ]-------
*/

class SoSub: SoObject
{
protected:
    SrdStatement _statement;    
    public @property SrdStatement statement() { return _statement; };
    public alias statement this;

    override void beforeExecute(RunStack stack, OpOperator operator)
    {
        super.beforeExecute(stack, operator);
        stack.results.push();
    }  

    override void afterExecute(RunStack stack, OpOperator operator)
    {      
        super.afterExecute(stack, operator);
        RunResult T = stack.results.pull();
        if (T.variable.value !is null)
            T.variable.value.execute(stack, operator);            
    }  

    override void doExecute(RunStack stack, OpOperator operator, ref bool done)
    {
        super.doExecute(stack, operator, done);
        statement.call(stack);
        done = true;
    }

public:
    this(){
        super();
        _statement = new SrdStatement(parent);
    }
}

/*--------------------------------------------*/

abstract class SoConstObject: SoObject
{
    override final void doExecute(RunStack stack, OpOperator operator, ref bool done)
    {
        if ((stack.results.current.variable.value is null) && (operator is null)) 
        {
            stack.results.current.variable.value = clone();
            done = true;
        }
        else 
        {      
            if (stack.results.current.variable.value is null)
                stack.results.current.variable.value = clone(false);
            done = stack.results.current.variable.value.operate(this, operator);
        }
    }
}

/*-------------------------------*/
/*       Const Objects
/*-------------------------------*/

/* SoNone */

class SoNone: SoConstObject  //None it is not Null, it is an initial value we sart it
{ 
    //Do operator
    //Convert to 0 or ''
}

/* SoComment */

class SoComment: SoObject
{
protected:
    override void doExecute(RunStack stack, OpOperator operator,ref bool done){
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

/* SoPreprocessor */
/*
class SoPreprocessor: SoObject{
protected:
override void doExecute(RunStack stack, OpOperator operator,ref bool done){
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

/* SoInteger */

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

/* SoNumber */

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

/* SoBool */

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

/* SoText */

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

/* TODO: SoArray */

/*--------------------------------------------*/

/**
x(i: integer) {...
---[ Defines  ]-------   
*/

class SrdDefine: SardObject 
{
public:
    string name;
    string type;

    this(string aName, string aType)
    {
        super();
        name = aName;
        type = aType;
    }

    debug {
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln(stringRepeat(" ", level * 2) ~ "name: " ~ name);
            writeln(stringRepeat(" ", level * 2) ~ "type: " ~ type);
        }
    }
}

class SrdDefineItems: SardObjects!SrdDefine 
{
    void add(string name, string type) {
        super.add(new SrdDefine(name, type));
    }
}

class SrdDefines: SardObject
{
    SrdDefineItems parameters;
    SrdDefineItems blocks;

    this(){
        super();
        parameters = new SrdDefineItems();
        blocks = new SrdDefineItems();
    }

    void execute(RunStack stack, SrdStatements arguments)
    {        
        if (arguments !is null) 
        { //TODO we need to check if it is a block?      
            int i = 0;
            while (i < parameters.count)
            { 
                stack.results.push();
                arguments[i].call(stack);
                if (i < arguments.count)
                {      
                    SrdDefine p = parameters[i];
                    RunVariable v = stack.local.current.variables.register(p.name, RunVarKinds([RunVarKind.Local, RunVarKind.Param])); //TODO but must find it locally
                    v.value = stack.results.current.variable.value;
                }
                stack.results.pop();
                i++;
            }        
        }
    }
}

//Just a references not free inside objects, not sure how to do that in D

class SrdDeclares: SardNamedObjects!SoDeclare {
}

/**  Variables objects */

/**   SoInstance */

/** 
it is a variable value like x in this "10 + x + 5" 
it will call the object if it is a object not a variable
*/

/**
x := 10  + Foo( 500,  600);
-------------Id [Statements]--------
*/

class SoInstance: SoStatements
{
protected:
    override void doExecute(RunStack stack, OpOperator operator, ref bool done)
    {            
        SoDeclare p = stack.findDeclare(name);
        if (p !is null) //maybe we must check Define.count, cuz it refere to it class
            p.call(stack, operator, statements, done);
        else 
        {
            RunVariable v = stack.local.current.variables.find(name);
            if (v is null)
                error("Can not find a variable: " ~ name);
            if (v.value is null)
                error("Variable value is null: " ~ v.name);
            if (v.value is null)
                error("Variable object is null: " ~ v.name);
            done = v.value.execute(stack, operator);
        }      
    }

public:
    override void created()
    {
        super.created();
        objectType = ObjectType.otObject;
    }
}


class SoVariable: SoObject
{ 
protected:
    override void doExecute(RunStack stack, OpOperator operator,ref bool done)
    {            
        RunVariable v = registerVariable(stack, RunVarKinds([RunVarKind.Local]));
        if (v is null)
            error("Can not register a varibale: " ~ name) ;
        if (v.value is null)
            error(v.name ~ " variable have no value yet:" ~ name);//TODO make it as empty
        done = v.value.execute(stack, operator);
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

/** It is assign a variable value, x := 10 + y */

class SoAssign: SoObject
{
protected:
    override void doSetParent(SoObject value) 
    {
        super.doSetParent(value);
    }

    override void doExecute(RunStack stack, OpOperator operator, ref bool done)
    {
        //super.doExecute(stack, operator, done);
        /** if not name it assign to parent result */
        done = true;
        if (name == "")
            stack.results.current.variable = stack.results.parent.variable;
        else 
        {
            SoDeclare aDeclare = stack.findDeclare(name);
            if (aDeclare !is null) 
            {
                if (aDeclare.callObject !is null)
                {
                    RunVariable v = aDeclare.callObject.registerVariable(stack, RunVarKinds([RunVarKind.Local])); //parent becuase we are in the statement
                    if (v is null)
                        error("Variable not found!");
                    stack.results.current.variable.value = v.value;
                }
            }
            else 
            { //Ok let is declare it locally
                RunVariable v = registerVariable(stack, RunVarKinds([RunVarKind.Local]));//parent becuase we are in the statement
                if (v is null)
                    error("Variable not found!");
                stack.results.current.variable.value = v.value;
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

class SoDeclare: SoObject
{
private:
    SrdDefines _defines;
    public @property SrdDefines defines(){ return _defines; }

protected:
    override void created(){
        super.created();
        _objectType = ObjectType.otClass;
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
    SoObject executeObject;//You create it but Declare will free it
    //callObject will execute by call, when called from outside,
    SoObject callObject;//You create it but Declare will free it
    //** I hate that above, we need just one call object
    string resultType;

    //This outside execute it will force to execute the Block
    void call(RunStack stack, OpOperator operator, SrdStatements arguments, ref bool done){
        done = callObject.execute(stack, operator, defines, arguments);
    }

    override protected void doExecute(RunStack stack, OpOperator operator,ref bool done)
    {
        //stack.addDeclare(this);
        if (executeObject !is null)
            done = executeObject.execute(stack, operator);
        else
            done = true;
    }
}

/*TODO
class SoArray ....
*/

