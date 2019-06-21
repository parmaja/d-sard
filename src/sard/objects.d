module sard.objects;
/**
*   This file is part of the "SARD"
*
*   @license   The MIT License (MIT) Included in this distribution
*   @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
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
import std.conv:to;
import std.uni;
import std.datetime;
import std.string;
import std.array;
import std.typecons;

import sard.utils;
import sard.classes;
import sard.lexers;
import sard.runtimes;
import sard.operators;

import minilib.sets;

const string sVersion = "0.01";
const int iVersion = 1;

class DebugInfo: BaseObject
{
}

/**---------------------------*/
/**          Clause
/**---------------------------*/

class Clause: BaseObject
{
private:
    Operator _operator;
    @property Operator operator() { return _operator; }

    Node _object;
    @property Node object() { return _object; }

public:

    this(Operator operator, Node object) 
    {
        super();
        if (object is null)
            error("Object is null!");
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

    debug(log_nodes){
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

/**---------------------------*/
/**        Statement
/**---------------------------*/

class Statement:Objects!Clause
{
private:
    Node _parent;
    public @property Node parent() { return _parent; }

public:
    this(Node aParent)
    {
        super();
        _parent = aParent;
    }

    void add(Operator operator, Node aObject)
    {
        if (aObject is null)
            error("You can null object!");
        if (aObject.parent !is null)
            error("You can not add object to another parent!");
        debug(log_compile) {
//            writeln("add clause: " ~ (operator? operator.name : "none") ~ ", " ~ aObject.classinfo.nakename);
        }

        aObject.parent = parent;
        super.add(new Clause(operator, aObject));
    }

    void execute(RunData data, RunEnv env)
    {
        //https://en.wikipedia.org/wiki/Shunting-yard_algorithm        
        //:= "Result is " + 10 + 10 ;
        foreach(itm; this)
        {
            itm.execute(data, env);
        }
    }

    public DebugInfo debuginfo; //<-- Null until we compiled it with Debug Info
}

/**---------------------------*/
/**        Statements
/**---------------------------*/

class Statements: Objects!Statement
{
private:
    Node _parent;
    public @property Node parent() { return _parent; }

public:    

    //check BUG1
    this(Node aParent){
        super();
        _parent = aParent;    
    }   

    Statement add()
    {
        Statement statement = new Statement(parent);
        super.add(statement);
        return statement;
    }

    void propose()
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
            foreach(itm; this)
            {
                //* each statment have a result
                env.results.push();
                itm.execute(data, env);
                env.results.pop();
                //* if the current statement assigned to parent or variable result "Reference" here have this object, or we will throw the result
            }
            return true;
        }
    }
}

/**---------------------------*/
/**        Node
/**---------------------------*/

abstract class Node: BaseObject
{
private:
    int _id;
    public @property int id(){ return _id; }
//    public @property int id(int value){ return _id = value; }

    string _name;
    public @property string name(){ return _name; }
    public @property string name(string value){
        if (_name != "")
            error("Already named!");
        return _name = value;
    }

protected:
    int refCount;
    //ObjectType _objectType;

    //public @property ObjectType objectType() {  return _objectType; }
    //public @property ObjectType objectType(ObjectType value) { return _objectType = value; }

public:
    this()
    {       
        super();
        static int lastID;
        lastID++;
        _id = lastID;
    }

    private Node _parent;

    @property Node parent() {return _parent; };
    @property Node parent(Node value) 
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

    void assign(Node fromObject)
    {
        //nothing
    }

    Node clone(bool withValues = true)
    { 
        debug(log_run) {
            //writeln("Cloneing " ~ this.classinfo.nakename);
        }
        //TODO, here we want to check if subclass have a default ctor 
        Node object = cast(Node)this.classinfo.create(); //new typeof(this);//<-bad i want to create new object same as current object but with descent
        if (object is null)
            error("Error when cloning");      

        if (withValues)
            object.assign(this);
        return object;
    }

protected: 
    bool doOperate(Node object, Operator operator) {
        return false;
    }

    void beforeExecute(RunData data, RunEnv env, Operator operator){
        if (data is null)
            error("Data is needed!");
    }

    void afterExecute(RunData data, RunEnv env, Operator operator){

    }

    abstract void doExecute(RunData data, RunEnv env, Operator operator, ref bool done);    

public:
    final bool operate(Node object, Operator operator)
    {
        if (operator is null)
            return false;
        else
            return doOperate(object, operator);
    }

    final bool execute(RunData data, RunEnv env, Operator operator, Defines defines = null, Statements arguments = null, Statements blocks = null)
    {
        bool done = false;

        beforeExecute(data, env, operator);      
        if (defines !is null)
            defines.execute(data, env, arguments);
        doExecute(data, env, operator, done);
        afterExecute(data, env, operator);      
/*
        debug(log_run)
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

    debug(log_nodes){
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln(stringRepeat(" ", level * 2) ~ "name: " ~ name);
            writeln(stringRepeat(" ", level * 2) ~ "value: " ~ asText );
        }
    }
}

/**
*
*   RefObject, refcounted of Node
*   This just trying to make it, not sure about the results
*   maybe move it to runtimes.d
*
*/

struct RefObject
{    
    public Node _object;
    public @property Node object(){ return _object; };    

    alias _object this;

    @disable this();

    this(Node o){
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

    void opAssign(Node rhs)
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

    debug(log_nodes){
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
                if (i < arguments.count)
                {
                    arguments[i].execute(data, env);

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

/**---------------------------*/
/**          Declare_Node
/**---------------------------*/

class Declare_Node: Node
{
private:
    Defines _defines;
    public @property Defines defines(){ return _defines; }

protected:

public:
    this(){
        super();
        _defines = new Defines();
    }

    ~this(){
        destroy(_defines);
    }

    debug(log_nodes){
        override void debugWrite(int level){
            super.debugWrite(level);
            _defines.debugWrite(level + 1);
        }
    }

public:
    //executeObject will execute in a context of statement if it is not null,
    Node executeObject;

    string resultType;

    override protected void doExecute(RunData data, RunEnv env, Operator operator,ref bool done)
    {
        data.declare(this);
    }
}

/**---------------------------*/
/**          RunData
/**
/**   Declare object to take it ref into variable
/**   used by Declare_Node
/**
/**---------------------------*/

/**
x := 10  + ( 500 + 600);
-------------[  Enclose  ]-------
*/

class Enclose_Node: Node
{
protected:
    Statement _statement;
    public @property Statement statement() { return _statement; };

    override void beforeExecute(RunData data, RunEnv env, Operator operator)
    {
        super.beforeExecute(data, env, operator);
        env.results.push();
    }

    override void afterExecute(RunData data, RunEnv env, Operator operator)
    {
        super.afterExecute(data, env, operator);
        RunResult t = env.results.pull();
        if (t.result.value !is null)
            t.result.value.execute(data, env, operator);
    }

    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done)
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
*   Statement_Node is a base class for list of objects (statements) like Block_Node
*/

abstract class Statement_Node: Node
{
protected:
    Statements _statements;
    public @property Statements statements() { return _statements; };

    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done)
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
    debug(log_nodes){
        override void debugWrite(int level){
            super.debugWrite(level);
            _statements.debugWrite(level + 1);
        }
    }

    this(){
        super();
        _statements = new Statements(this);
    }

    ~this(){
        destroy(_statements);
    }
}


/** Block_Node */
/**
    Used by { }
    It a block before execute push in env, after execute will pop the env, it have return value too in the env
*/

class Block_Node: Statement_Node  //Result was droped until using := assign in the first of statement
{
private:

protected:
    override void beforeExecute(RunData data, RunEnv env, Operator operator)
    {
        env.stack.push();
        super.beforeExecute(data, env, operator);
    }

    override void afterExecute(RunData data, RunEnv env, Operator operator)
    {
        super.afterExecute(data, env, operator);
        env.stack.pop();
    }

public:

    Declare_Node declareObject(Node object)
    {
        with (_statements.add) {
            Declare_Node result = new Declare_Node(); //TODO should use ctor to init variables
            result.name = object.name;
            object.parent = result;
            result.executeObject = object;
            add(null, result);
            return result;
        }
    }
}

/*--------------------------------------------*/

abstract class Const_Node: Node
{
    override final void doExecute(RunData data, RunEnv env, Operator operator, ref bool done)
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

/* None_Node */

class None_Node: Const_Node  //None it is not Null, it is an initial value we sart it
{
    //Do operator
    //Convert to 0 or ''
}

/* Comment_Node */

class Comment_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator,ref bool done)
    {
        //Guess what!, we will not to execute the comment ;)
        done = true;
    }

public:
    string value;
}

/* Preprocessor_Node */

/*
class Preprocessor_Node: Node
{
protected:
    override void doExecute(RunEnv env, Operator operator,ref bool done){
        //TODO execute external program and replace it with the result
        done = true;
    }

public:
    string value;
}
*/

abstract class Number_Node: Const_Node //base class for Number and Integer
{
}

/* Integer_Node */

class Integer_Node: Number_Node
{
protected:

public:
    integer value;

    this(){
        super();
    }

    this(integer aValue){
        this();
        value = aValue;
    }

    override void assign(Node fromObject){
        value = fromObject.asInteger;
    }

    override bool doOperate(Node object, Operator operator)
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

/* Number_Node */

class Real_Node: Number_Node
{
protected:

public:
    number value;

    this(){
        super();
    }

    this(number aValue){
        this();
        value = aValue;
    }

    override void assign(Node fromObject){
        value = fromObject.asNumber;
    }

    override bool doOperate(Node object, Operator operator)
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

/* Bool_Node */

class Bool_Node: Number_Node
{
protected:

public:
    bool value;

    this(){
        super();
    }

    this(bool aValue){
        this();
        value = aValue;
    }

    override void assign(Node fromObject){
        value = fromObject.asBool;
    }

    override bool doOperate(Node object, Operator operator)
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

/* Text_Node */

class Text_Node: Const_Node
{
protected:

public:
    text value;

    this(){
        super();
    }

    this(text aValue){
        this();
        value = aValue;
    }

    override void assign(Node fromObject){
        value = fromObject.asText;
    }

    override bool doOperate(Node object, Operator operator)
    {
        switch(operator.name){
            case "+":
                value = value ~ object.asText;
                return true;

            case "-":
                if (cast(Number_Node)object !is null) {
                    int c = value.length -1;
                    c = c - to!int((cast(Number_Node)object).asInteger);
                    value = value[0..c + 1];
                    return true;
                }
                else
                    return false;

            case "*":  //stupid idea ^.^
                if (cast(Number_Node)object !is null) {
                    value = replicate(value, to!int((cast(Number_Node)object).asInteger));
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

/**
*
*   Variable
*   Have object as value, used by env/scope
*
*/

enum RunVarKind {
    Local,  //Local env
    Argument   //It is an argument when call function/object
};

alias RunVarKinds = Set!RunVarKind;

class RunValue: BaseObject
{
public:
    private string _name;
    public @property string name(){ return _name; }

    private RunVarKinds _kind;
    public @property RunVarKinds kind(){ return _kind; }

    Node value;

    this(){
        value = RefObject(null);
        super();
    }

    this(string name, RunVarKinds kind) {
        this();
        _name = name;
        _kind = kind;
    }

    void clear(){
        value = null;
    }
}

class RunVariables: NamedObjects!RunValue
{
public:

    RunValue register(string name, RunVarKinds kind) //TODO bad idea
    {
        RunValue result = find(name);
        if (result is null)
        {
            result = new RunValue(name, kind);
            add(result);
        }
        return result;
    }
}

/**---------------------------*/
/**          RunResult
/**   Need it when execute a statment and get a result from it even if we not have a result, it assigned to it, and killed when exit the env/scope
/**   But it can ref to parent result by parent assign :=, or ref to variable in the env
/**---------------------------*/

class RunResult: BaseObject
{
private:
public:
    RunValue result;

    this()
    {
        super();
        result = new RunValue();
    }
}

class RunResults: Stack!RunResult
{
}

/**   Instance_Node */

/**
*   it is a variable value like x in this "10 + x + 5"
*   it will call the object if it is a object not a variable
*/

/**
*   x := 10  + Foo( 500,  600);
*   -------------Id [Statements]--------
*/

class Instance_Node: Node
{
private
    Statements _arguments;
    public @property Statements arguments() { return _arguments; };

protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done)
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
                error("Variable object is null: " ~ v.name);
            done = v.value.execute(data, env, operator);
        }
    }

public:

    this(){
        super();
        _arguments = new Statements(this);
    }

    ~this(){
        destroy(_arguments);
    }
}

/** It is assign a variable value, x := 10 + y */

class Assign_Node: Node
{
protected:

    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done)
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

public:

    this(){ super(); }
}

//Is that a Scope!!!, idk!

class RunData: Objects!RunData
{
public:
    string name;
    Declare_Node object;

    RunData parent;

    RunData find(const string name)
    {
        RunData result = null;
        foreach(itm; this) {
            if (icmp(name, itm.name) == 0) {
                result = itm;
                break;
            }
        }
        return result;
    }

    RunData findObject(Node object)
    {
        foreach(itm; this) {
            if (itm.object is object) {
                return itm;
            }
        }
        return null;
    }

    RunData declare(Declare_Node object)
    {
        if (object is null)
            error("Can not register null in data");
        RunData o = findObject(object);
        if (o is null)
        {
            o = new RunData(this);
            o.name = object.name;
            o.object = object;
        }
        add(o);//TODO BUG maybe into if
        return o;
    }

    RunData findDeclare(string name)
    {
        RunData result = find(name);
        if ((result is null) && parent)
            result = parent.findDeclare(name);
        return result;
    }

    this(RunData aParent)
    {
        parent = aParent;
        super();
    }

    ~this()
    {
    }

    final bool execute(RunEnv env, Operator operator, Statements arguments = null, Statements blocks = null)
    {
        if (object is null) {
            error("Object of declaration is not set!");
            return false;
        }
        else
        {
            if (object.executeObject is null) {
                error("executeObject of declaration is not set!");
                return false;
            }

            return object.executeObject.execute(this, env, operator, object.defines, arguments, blocks);
        }
    }
}

/**
*
*  Local is stack of flow control
*  Not a scope
*
*/

/** StackItem */

class RunStackItem: BaseObject
{
public:
    RunVariables variables;
public:
//    RunData data; //TODO make it property move it to stack

    this()
    {
        variables = new RunVariables();
        super();
    }

    ~this()
    {
        destroy(variables);
    }
}

/** Stack */

class RunStack: Stack!RunStackItem
{
}

/**
*   @class RunEnv
*
*   Stack have results values to drop it, result can be reference to variable
*   Data have variables and declares
*/

class RunEnv: BaseObject
{
private:
    RunResults _results;
    public @property RunResults results() {return _results; };

    RunStack _stack ;
    public @property RunStack stack() {return _stack;};

    RunData _root;
    public @property RunData root() {return _root;};

public:
    this()
    {
        _stack = new RunStack();
        _root = new RunData(null);
        _results = new RunResults();
        super();
    }

    ~this(){
        destroy(_stack);
        destroy(_root);
        destroy(_results);
    }

    debug(log_nodes)
    {
        override void debugWrite(int level)
        {
            super.debugWrite(level);
            //_root.debugWrite(level + 1);
        }
    }
}
