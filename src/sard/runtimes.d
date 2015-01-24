module sard.runtimes;
/**
*    This file is part of the "SARD"
* 
*    @license   The MIT License (MIT) Included in this distribution
*    @author    Zaher Dirkey <zaher at yahoo dot com>
*/

import std.stdio;
import std.conv;
import std.array;
import std.string;
import std.stdio;
import std.uni;
import std.datetime;
import std.typecons;

import sard.utils;
import sard.classes;
import sard.objects;

import minilib.sets;

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
    string name;
    RunVarKinds kind;
    SoObject value;
    
    this(){
        value = RefObject(null);
        super();
    }

    void clear(){
        value = null;
    }
}

class RunVariables: NamedObjects!RunValue
{
    RunValue register(string name, RunVarKinds kind)//TODO bad idea
    {
        RunValue result = find(name);
        if (result is null)
        {
            result = new RunValue();
            result.name = name;
            result.kind = kind;
            add(result);
        }
        return result;
    }
}

/**
*
*   Result
*   Need it when execute a statment and get a result from it even if we not have a result, it assigned to it, and killed when exit the env/scope
*   But it can ref to parent result by parent assign :=, or ref to variable in the env
*
*/

class RunResult: BaseObject
{
private:
public:
    RunValue result;

    this()
    {
        result = new RunValue();
        super();      
    }
}

class RunResults: Stack!RunResult
{
}

/**
*
*   Declare object to take it ref into variable
*   used by SoDeclare
*
*/

class RunDeclare: BaseObject
{
    string name;
    RunData data;
    private SoDeclare _object;
    
    final bool execute(RunData data, RunEnv env, OpOperator operator, Statements arguments = null, Statements blocks = null)
    {
        if (_object is null) {
            error("Object of declaration is not set!");
            return false;
        }
        else
        {
            if (_object.executeObject is null) {
                error("executeObject of declaration is not set!");
                return false;
            }           

            //env.enter(env.stack.current.data, _object.executeObject);///big mistake ERROR
            bool done = _object.executeObject.execute(data, env, operator, _object.defines, arguments, blocks);
            //env.exit(_object.executeObject);
            return done;
        }
    }

    this(SoDeclare object){
        _object = object;
    }
}

class RunDeclares: NamedObjects!RunDeclare 
{
}

//Is that a Scope!!!, idk!

class RunData: Objects!RunData
{
public:
    //string name;
    SoObject object;
    //RunStackItem stackItem;

    RunDeclares declares; 
    RunData parent;

    RunData find(SoObject object)
    {
        foreach(e; items) {
            if (e.object is object) {
                return e;
            }
        }
        return null;
    }

    RunData register(SoObject object)
    {
        if (object is null)
            error("Can not register null in data");
        RunData o = find(object);
        if (o is null) {
            o = new RunData(this);
            o.object = object;
        }
        return o;
    }

    int addDeclare(SoDeclare object)
    {
        RunDeclare declare = new RunDeclare(object);        
        declare.name = object.name; 
        declare.data = this;
        
        RunData o = register(object);
        //o.name = object.name;
        //o.stackItem = stack.current;
        return declares.add(declare);
    }

    RunDeclare findDeclare(string name)
    {
//        debug writeln("Finding " ~ object.name ~ "."~name);
        RunDeclare declare = declares.find(name);         
        if (parent && (declare is null))
            declare = parent.findDeclare(name);         
        return declare;
    }

    this(RunData aParent)
    {
        parent = aParent;
        declares = new RunDeclares();
        super();
    }

    ~this()
    {
        destroy(declares);
    }
}

class RunRoot: RunData
{
public:
    this(RunData aParent){
        super(aParent);
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
private:

protected:
    override void beforePop() {
        debug{
            writeln("stack.pop" );
        }
    };
public:
    this(){
        super();
    }

    ~this(){
    }
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

    RunRoot _root;
    public @property RunRoot root() {return _root;};

public:
    this()
    {
        _stack = new RunStack();
        _root = new RunRoot(null);
        _results = new RunResults();    
        super();
    }

    ~this(){
        destroy(_stack);
        destroy(_root);
        destroy(_results);    
    }

    void enter(RunData into, SoObject object)
    {
        /*RunData o = into.register(object);
        stack.push();
        stack.current.data = o;
        o.stackItem = stack.current;*/
    }

    void exit(SoObject object)
    {
/*        if (stack.current.data is null)
            error("Enter stack data is needed!");
        if (stack.current.data.object !is object)
            error("Entered data object is null!");
        if (stack.current.data.object !is object)
            error("Entered data have wrong object!");*/
//        stack.pop();
    }

    debug
    {
        override void debugWrite(int level)
        {
            super.debugWrite(level);
            //_root.debugWrite(level + 1);
        }
    }
} 