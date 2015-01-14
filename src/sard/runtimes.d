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

enum RunVarKind {Local, Param}; //Ok there is more in the future

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

class RunResult: SardObject
{
private:
public:
    RunVariable variable;

    this(){        
        variable = new RunVariable();
        super();      
    }
}

class RunResults: SardStack!RunResult
{
}

/**
    Stack tree
*/

class RunBranch: SardStack!RunBranch
{
public:
}

class RunRoot: RunBranch
{
    string name;
}

class RunDeclare: SardObject
{
    string name;
    //SoObject executeObject;
    SoDeclare object;
}

class RunDeclares: SardNamedObjects!RunDeclare {
}

/**
    @class RunStack
*/

class RunStack: SardObject 
{
private:
    //TODO: move srddeclares to the scope stack, it is bad here
    RunDeclares _declares; //It is cache of objects listed inside statements, it is for fast find the object

    public @property RunDeclares declares() { return _declares; };

    RunLocal _local = new RunLocal();
    RunResults _results = new RunResults();
    RunRoot root = new RunRoot();

public:    
    @property RunLocal local() {return _local;};
    @property RunResults results() {return _results; };

    int addDeclare(SoDeclare object)
    {
        RunDeclare declare = new RunDeclare();
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
        local.push();
        results.push();
    }

    ~this(){      
        results.pop();
        local.pop();
    }

    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            _declares.debugWrite(level + 1);
        }
    }
}