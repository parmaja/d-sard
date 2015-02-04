module sard.objects;
/**
*   This file is part of the "SARD"
*
*   @license   The MIT License (MIT) Included in this distribution
*   @author    Zaher Dirkey <zaher at yahoo dot com>
*/


/**
*   TODO:
*
*   SoArray:   Object have another objects, a list of objectd without execute it,
*   it is save the result of statement come from the parser  
*
*   Modifiers: It is like operator but with one side can be in the context before the identifier like + !x %x $x
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

import std.typecons;

const string sVersion = "0.01";
const int iVersion = 1;

alias long integer;
alias double number;
alias string text;

//enum ObjectType {otUnkown, otInteger, otNumber, otBoolean, otText, otComment, otBlock, otDeclare, otObject, otClass, otVariable};
enum Compare {cmpLess, cmpEqual, cmpGreater};

class DebugInfo: BaseObject 
{
}

/** Clause */

class Clause: BaseObject
{
private:
    OpOperator _operator;
    SoObject _object;

public:
    @property OpOperator operator() { return _operator; }
    @property SoObject object() { return _object; }

    this(OpOperator operator, SoObject object) 
    {
        super();
        _operator = operator;
        _object = object;
    }

    ~this(){
        destroy(_object);
    }

    bool execute(RunData data, RunEnv env) 
    {
        if (_object is null)
            error("Object not set!");
        return _object.execute(data, env, _operator);        
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

/* Statement */

class Statement: Objects!Clause 
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
//            writeln("add clause: " ~ (operator? operator.name : "none") ~ ", " ~ aObject.classinfo.nakename);
        }
        if (aObject.parent !is null)
            error("You can not add object to another parent!");
        aObject.parent = parent;
        Clause clause = new Clause(operator, aObject);
        super.add(clause);    
    }

    void execute(RunData data, RunEnv env)
    {
        //https://en.wikipedia.org/wiki/Shunting-yard_algorithm        
        //:= "Result is " + 10 + 10 ;
        foreach(e; items) 
        {
            e.execute(data, env);
        }
    }

    public DebugInfo debuginfo; //<-- Null until we compiled it with Debug Info
}

class Statements: Objects!Statement
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

    Statement add()
    {
        Statement statement = new Statement(parent);
        super.add(statement);
        return statement;
    }

    void check()
    {
        if (count == 0) {
            add();
        }
    }

    bool execute(RunData data, RunEnv env)
    {
        if (count == 0)
            return false;
        else
        {            
            foreach(e; items) 
            {
                //each statment have a result
                env.results.push();
                e.execute(data, env);
                env.results.pop();
                //if the current statement assigned to parent or variable result "Reference" here have this object, or we will throw the result
            }
            return true;
        }
    }
}

/* SoObject */

abstract class SoObject: BaseObject
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
    int refCount;
    //ObjectType _objectType;

    //public @property ObjectType objectType() {  return _objectType; }
    //public @property ObjectType objectType(ObjectType value) { return _objectType = value; }

public:
    this()
    {       
        super();
    }

    this(SoObject aParent, string aName)
    { 
        this();      
        _name = aName;
        parent = aParent;
    }


    @property SoObject parent() {return _parent; };
    @property SoObject parent(SoObject value) 
    {
        if (_parent !is null) 
            error("Already have a parent");
        _parent = value;
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
            //writeln("Cloneing " ~ this.classinfo.nakename);
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

    void beforeExecute(RunData data, RunEnv env, OpOperator operator){
        if (data is null)
            error("Data is needed!");
    }

    void afterExecute(RunData data, RunEnv env, OpOperator operator){

    }

    abstract void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done);    

public:
    final bool execute(RunData data, RunEnv env, OpOperator operator, Defines defines = null, Statements arguments = null, Statements blocks = null)
    {
        bool done = false;

        beforeExecute(data, env, operator);      
        if (defines !is null)
            defines.execute(data, env, arguments);
        doExecute(data, env, operator, done);
        afterExecute(data, env, operator);      
/*
        debug 
        {      
            string s = "  " ~ stringRepeat(" ", env.stack.count) ~ ">";
            s = s ~ this.classinfo.nakename ~ " level: " ~ to!string(env.stack.count);
            if (operator !is null)
                s = s ~ "{" ~ operator.name ~ "}";
            if (env.results.current && env.results.current.result.value)
                s = s ~ " result: " ~ env.results.current.result.value.asText;
            writeln(s);
            writeln(".asText: " ~ asText);
        }            */
        return done; 
    }

    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln(stringRepeat(" ", level * 2) ~ "name: " ~ name);
            writeln(stringRepeat(" ", level * 2) ~ "value: " ~ asText );
        }
    }
}

/**
*
*   RefObject, refcounted of SoObject
*   This just trying to make it, not sure about the results
*   maybe move it to runtimes.d
*
*/


struct RefObject
{    
    public SoObject _object;
    public @property SoObject object(){ return _object; };    

    alias _object this;

    @disable this();

    this(SoObject o){
        _object = o;
        if (_object !is null)
            ++_object.refCount;
    }

    ~this(){
        if (_object !is null) {
            --_object.refCount;
            if (_object.refCount == 0)
                destroy(_object);
        }
    }


/*    void opAssign(typeof(this) rhs)
    {

    }
*/

    void opAssign(SoObject rhs)
    {
        if (_object !is null)
            --_object.refCount;
        _object = rhs;
        if (_object !is null)
            ++_object.refCount;
    }

    @property bool isNull(){
        return _object is null;
    }

    bool opCast(){
        return isNull;
    }    
/*
    bool opCast(T: bool)(){
        return isNull;
    }     */
}

/**
x := 10  + ( 500 + 600);
-------------[  Sub    ]-------
*/

class SoSub: SoObject
{
protected:
    Statement _statement;    
    public @property Statement statement() { return _statement; };
    public alias statement this;

    override void beforeExecute(RunData data, RunEnv env, OpOperator operator)
    {
        super.beforeExecute(data, env, operator);
        env.results.push();
    }  

    override void afterExecute(RunData data, RunEnv env, OpOperator operator)
    {      
        super.afterExecute(data, env, operator);
        RunResult t = env.results.pull();
        if (t.result.value !is null)
            t.result.value.execute(data, env, operator);            
    }  

    override void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done)
    {
        statement.execute(data, env);
        done = true;
    }

public:
    this(){
        super();
        _statement = new Statement(parent);
    }

    ~this(){
        destroy(_statement);
    }    
}

/*
*   SoEnclose is a base class for list of objects (statements) like SoBlock
*/

abstract class SoEnclose: SoObject
{
protected:
    Statements _statements;
    public @property Statements statements() { return _statements; };

    override void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done)
    {                
        /*if (env.stack.current.data.object !is this)
            error("Can not execute block directly, data.object must set to this encloser");*/
        env.results.push(); //<--here we can push a variable result or create temp result to drop it
        
        statements.execute(data, env);
        RunResult t = env.results.pull();
        //I dont know what if there is an object there what we do???
        /*
        * := 5 + { := 10 + 10 }
        * it return 25
        * here 20.execute with +
        */
        if (t.result.value !is null) {
            t.result.value.execute(data, env, operator); 
        }
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
        //objectType = ObjectType.otBlock;
    }

    this(){
        super();
        _statements = new Statements(this);      
    }

    ~this(){
        destroy(_statements);
    }
}


/** SoBlock */
/** 
    Used by { } 
    It a block before execute push in env, after execute will pop the env, it have return value too in the env
*/

class SoBlock: SoEnclose  //Result was droped until using := assign in the first of statement
{ 
private:

protected:
    override void beforeExecute(RunData data, RunEnv env, OpOperator operator)
    {
        env.stack.push();
        super.beforeExecute(data, env, operator);
    }

    override void afterExecute(RunData data, RunEnv env, OpOperator operator)
    {
        super.afterExecute(data, env, operator);
        env.stack.pop();
    }

public:
    /*    deprecated("testing") */
    private Statement declareStatement;
    SoDeclare declareObject(SoObject object)
    {
        if (declareStatement is null)
            declareStatement =  statements.add();
        SoDeclare declare = new SoDeclare();
        declare.name = object.name;
        declare.executeObject = object;
        declareStatement.add(null, declare);
        return declare;
    }
}

/*--------------------------------------------*/

abstract class SoConst: SoObject
{
    override final void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done)
    {
        if (!env.results.current)
            error("There is no stack results!");
        if ((env.results.current.result.value is null) && (operator is null)) 
        {
            env.results.current.result.value = clone();
            done = true;
        }
        else 
        {      
            if (env.results.current.result.value is null)
                env.results.current.result.value = clone(false);
            done = env.results.current.result.value.operate(this, operator);
        }
    }
}

/*-------------------------------*/
/*       Const Objects
/*-------------------------------*/

/* SoNone */

class SoNone: SoConst  //None it is not Null, it is an initial value we sart it
{ 
    //Do operator
    //Convert to 0 or ''
}

/* SoComment */

class SoComment: SoObject
{
protected:
    override void doExecute(RunData data, RunEnv env, OpOperator operator,ref bool done)
    {
        //Guess what!, we will not to execute the comment ;)
        done = true;
    }

    override void created(){
        super.created();
        //objectType = ObjectType.otComment;
    }

public:
    string value;
}

/* SoPreprocessor */

/*
class SoPreprocessor: SoObject
{
protected:
    override void doExecute(RunEnv env, OpOperator operator,ref bool done){
        //TODO execute external program and replace it with the result
        done = true;
    }

    void created(){
        super.created();
        //objectType = ObjectType.otComment;
    }

public:
    string value;
}
*/

abstract class SoBaseNumber: SoConst //base class for Number and Integer
{ 
}

/* SoInteger */

class SoInteger: SoBaseNumber 
{
protected:
    override void created(){
        super.created();
        //objectType = ObjectType.otInteger;
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
        switch(operator.name)
        {
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
                value = value / object.asInteger;
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
        //objectType = ObjectType.otNumber;
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
        //objectType = ObjectType.otBoolean;
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

class SoText: SoConst 
{
protected:
    override void created(){
        super.created();
        //objectType = ObjectType.otText;
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

/*--------------------------------------------*/

/**
*   x(i: integer) {...
*   ---[ Defines  ]-------   
*/

class Define: BaseObject 
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

class DefineItems: Objects!Define 
{
    void add(string name, string type) {
        super.add(new Define(name, type));
    }
}

class Defines: BaseObject
{
    DefineItems parameters;
    DefineItems blocks;

    this(){
        super();
        parameters = new DefineItems();
        blocks = new DefineItems();
    }

    ~this(){
        destroy(parameters);
        destroy(blocks);
    }

    void execute(RunData data, RunEnv env, Statements arguments)
    {        
        if (arguments !is null) 
        { //TODO we need to check if it is a block?      
            int i = 0;
            while (i < parameters.count)
            { 
                env.results.push();
                arguments[i].execute(data, env);
                if (i < arguments.count)
                {      
                    Define p = parameters[i];
                    RunValue v = env.stack.current.variables.register(p.name, RunVarKinds([RunVarKind.Local, RunVarKind.Argument])); //TODO but must find it locally
                    v.value = env.results.current.result.value;
                }
                env.results.pop();
                i++;
            }        
        }
    }
}

/**   SoInstance */

/** 
*   it is a variable value like x in this "10 + x + 5" 
*   it will call the object if it is a object not a variable
*/

/**
*   x := 10  + Foo( 500,  600);
*   -------------Id [Statements]--------
*/

class SoInstance: SoObject
{
private
    Statements _arguments;
    public @property Statements arguments() { return _arguments; };

protected:
    override void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done)
    {            
        RunData d = data.findDeclare(name);
        if (d !is null) //maybe we must check Define.count, cuz it refere to it class
        {
            done = d.execute(env, operator, arguments, null);
        }
        else 
        {
            RunValue v = env.stack.current.variables.find(name);
            if (v is null)
                error("Can not find a variable: " ~ name);
            if (v.value is null)
                error("Variable value is null: " ~ v.name);
            if (v.value is null)
                error("Variable object is null: " ~ v.name);
            done = v.value.execute(data, env, operator);
        }      
    }

public:
    override void created()
    {
        super.created();
        //objectType = ObjectType.otObject;
    }

    this(){
        super();
        _arguments = new Statements(this);      
    }

    ~this(){
        destroy(_arguments);
    }
}

/** It is assign a variable value, x := 10 + y */

class SoAssign: SoObject
{
protected:

    override void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done)
    {
        /** if not have a name, assign it to parent result */
        done = true;
        if (name == "") {
            env.results.current.result = env.results.parent.result;        
        }
        else 
        {
            //Ok let is declare it locally
            RunValue v = env.stack.current.variables.register(name, RunVarKinds([RunVarKind.Local]));
            if (v is null)
                error("Variable not found!");
            env.results.current.result = v;
        }
    }

    override void created()
    {
        super.created();
        //objectType = ObjectType.otVariable;
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
    Defines _defines;
    public @property Defines defines(){ return _defines; }

protected:
    override void created(){
        super.created();
        //objectType = ObjectType.otDeclare;
    }

public:
    this(){
        super();
        _defines = new Defines();
    }    

    ~this(){
        destroy(_defines);
    }

    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            _defines.debugWrite(level + 1);
        }
    }

public:
    //executeObject will execute in a context of statement if it is not null,
    SoObject executeObject;

    string resultType;

    override protected void doExecute(RunData data, RunEnv env, OpOperator operator,ref bool done)
    {
        data.declare(this);
    }
}