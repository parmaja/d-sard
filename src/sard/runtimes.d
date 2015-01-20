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

class RunVariable: SardObject
{
public:
    string name;
    RunVarKinds kind;
    SoObject value;

    this(){
        super();
    }

    void clear(){
        value = null;
    }
}

class RunVariables: SardNamedObjects!RunVariable
{
    RunVariable register(string name, RunVarKinds kind)//TODO bad idea
    {
        RunVariable result = find(name);
        if (result is null)
        {
            result = new RunVariable();
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

class RunResult: SardObject
{
private:
public:
    RunVariable result;

    this()
    {
        result = new RunVariable();
        super();      
    }
}

class RunResults: SardStack!RunResult
{
}

/**     s
*
*   Declare object to take it ref into variable
*   used by SoDeclare
*
*/

class RunDeclare: SardObject
{
    string name;
    RunData data;
    private SoDeclare _object;
    
    final bool execute(RunEnv env, OpOperator operator, SrdStatements arguments = null, SrdStatements blocks = null)
    {
        if (_object is null) {
            error("Object of declaration is not set!");
            return false;
        }
        else
            return _object.execute(env, operator, _object.defines, arguments, blocks);
    }

    this(SoDeclare object){
        _object = object;
    }
}

class RunDeclares: SardNamedObjects!RunDeclare 
{
}

//Is that a Scope!!!, idk!

class RunData: SardObjects!RunData
{
public:
    SoObject object;
    RunDeclares declares; 
    RunVariables variables;
    RunData parent;

    int addDeclare(SoDeclare object)
    {
        RunDeclare declare = new RunDeclare(object);
        declare.name = object.name; 
        declare.data = this;
        return declares.add(declare);
    }

    RunDeclare findDeclare(string vName)
    {
        return declares.find(vName);         
    }

    RunData findObject(SoObject object)
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
        RunData o = findObject(object);
        if (o is null) {
            o = new RunData(this);
            o.object = object;
        }
        return o;
    }

    this(RunData aParent)
    {
        parent = aParent;
        variables = new RunVariables();
        declares = new RunDeclares();
        super();
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

class RunStackItem: SardObject
{
public:
    RunData data; //TODO make it property move it to stack
}

/** Stack */

class RunStack: SardStack!RunStackItem 
{
private:
    RunResults _results;
    public @property RunResults results() {return _results; };

public:
    this(){
        _results = new RunResults();    
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

class RunEnv: SardObject 
{
private:
    RunStack _stack ;
    public @property RunStack stack() {return _stack;};

    RunRoot _data;
    public @property RunRoot data() {return _data;};

public:
    void enter(SoObject object){
        auto o = stack.current.data.register(object);
        stack.push();
        stack.current.data = o;
    }

    void exit(SoObject){
        stack.pop();
        //stack.current.data = null;
    }

    this()
    {
        _stack = new RunStack();
        _data = new RunRoot(null);
        super();
    }

    ~this(){
    }

    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            _data.debugWrite(level + 1);
        }
    }
} 