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

private:
    SoObject _value;
    public @property SoObject value() { return _value; }
    public @property SoObject value(SoObject newValue) 
    { 
        if (_value !is newValue){
            _value =  newValue;
        }
        return _value; 
    }

    this(){
        super();
    }

    void clear(){
        _value = null;
    }
}

class RunVariables: SardNamedObjects!RunVariable
{
    RunVariable register(string vName, RunVarKinds vKind)
    {
        RunVariable result = find(vName);
        if (result is null){      
            result = new RunVariable();
            result.name = vName;
            result.kind = vKind;
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

class RunReturnItem: SardObject
{
private 
    SoObject _value;
    RunReturnItem _reference;
public:
    @property SoObject value() { 
        if (_reference !is null)
            return _reference._value; 
        else
            return _value; 
    };

    @property SoObject value(SoObject newValue) 
    { 
        if (_reference !is null) {
            if (_value !is null) 
                error("Already have a value can not set value for reference!");
            return _reference._value = newValue;  
        }
        else
            return _value = newValue; 
        
    };

    @property RunReturnItem reference(RunReturnItem value) 
    { 
        if (_value !is null) 
            error("Already have a value can not set reference!");
        if (_reference !is null) 
            error("Already have a reference!");
        _reference = value;
        return _reference; 
    };

    this(){        
        super();      
    }
}

class RunReturn: SardStack!RunReturnItem
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

/**
    @class RunStack
*/

class RunStack: SardObject 
{
private:
    //TODO: move srddeclares to the scope stack, it is bad here
    SrdDeclares _declares; //It is cache of objects listed inside statements, it is for fast find the object

    public @property SrdDeclares declares() { return _declares; };

    RunLocal _local = new RunLocal();
    RunReturn _ret = new RunReturn();
    RunRoot root = new RunRoot();

public:    
    @property RunLocal local() {return _local;};
    @property RunReturn ret() {return _ret ;};

    int addDeclare(SoObject executeObject, SoObject callObject)
    {
        SoDeclare declare = new SoDeclare();
        if (executeObject !is null)
            declare.name = executeObject.name;
        else if (callObject !is null)
            declare.name = callObject.name;
        declare.executeObject = executeObject;
        declare.callObject = callObject;
        return _declares.add(declare);
    }

    SoDeclare findDeclare(string vName)
    {
        SoDeclare declare = _declares.find(vName);
        return declare;
    }

    this(){
        _declares = new SrdDeclares();
        super();
        local.push();
        ret.push();
    }

    ~this(){      
        ret.pop();
        local.pop();
    }

    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            _declares.debugWrite(level + 1);
        }
    }
}