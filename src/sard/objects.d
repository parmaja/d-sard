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
//import std.conv;
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

const string sVersion = "0.01";
const int iVersion = 1;

//enum ObjectType {otUnkown, otInteger, otNumber, otBoolean, otText, otComment, otBlock, otDeclare, otObject, otClass, otVariable};

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
        debug(log_compile) {            
//            writeln("add clause: " ~ (operator? operator.name : "none") ~ ", " ~ aObject.classinfo.nakename);
        }

        if (aObject.parent !is null)
            error("You can not add object to another parent!");
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

