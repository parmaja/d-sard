module sard.runtimes;
/**
    This file is part of the "SARD"

    @license   The MIT License (MIT) Included in this distribution
    @author    Zaher Dirkey <zaher at yahoo dot com>
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

/**
*
*   Declare object to take it ref into variable
*   I used by SoDeclare
*
*/

class RunDeclare: SardObject
{
    string name;
    //SoObject executeObject;
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

/**
*
*  Local is stack of flow control
*  Not a scope
*
*/

class RunStackItem: SardObject
{
public:
    RunVariables variables;
    this(){
        super();
        variables = new RunVariables();
    }
}

class RunStack: SardStack!RunStackItem 
{
}

/**
    @class RunEnv
*/

class RunEnv: SardObject 
{
private:
    //TODO: move _declares to the scope env, it is bad here
    RunDeclares _declares; 

    public @property RunDeclares declares() { return _declares; };

    RunStack _stack = new RunStack();
    RunResults _results = new RunResults();    

public:    
    @property RunStack stack() {return _stack;};
    @property RunResults results() {return _results; };

    int addDeclare(SoDeclare object)
    {
        RunDeclare declare = new RunDeclare(object);
        declare.name = object.name; 
        return _declares.add(declare);
    }

    RunDeclare findDeclare(string vName)
    {
        return _declares.find(vName);         
    }

    this(){
        _declares = new RunDeclares();
        super();
        stack.push();
        results.push();
    }

    ~this(){
        results.pop();
        stack.pop();
    }

    final bool execute(SoObject object, OpOperator operator, SrdDefines defines = null, SrdStatements arguments = null, SrdStatements blocks = null)
    {
        return object.execute(this, operator, defines, arguments, blocks);
    }
    
    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            _declares.debugWrite(level + 1);
        }
    }
} 