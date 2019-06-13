module sard.runtimes;
/**
*    This file is part of the "SARD"
* 
*    @license   The MIT License (MIT) Included in this distribution
*    @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
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
import sard.lexers;
import sard.objects;
import sard.types;

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
    RunValue register(string name, RunVarKinds kind) //TODO bad idea
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

//Is that a Scope!!!, idk!

class RunData: Objects!RunData
{
public:
    string name;
    SoDeclare object;

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

    RunData findObject(SoObject object)
    {
        foreach(itm; this) {
            if (itm.object is object) {
                return itm;
            }
        }
        return null;
    }

    RunData declare(SoDeclare object)
    {
        if (object is null)
            error("Can not register null in data");
        RunData o = findObject(object);
        if (o is null) 
        {
            o = new RunData(this);
            o.object = object;
            o.name = object.name;        
        }
        add(o);
        return o;        
    }

    RunData findDeclare(string name)
    {
        RunData declare = find(name);         
        if (parent && (declare is null))
            declare = parent.findDeclare(name);         
        return declare;
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

            bool done = object.executeObject.execute(this, env, operator, object.defines, arguments, blocks);
            return done;
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
