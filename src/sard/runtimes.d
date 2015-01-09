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

class RunVariable: SardObject
{
public:
    string name;
    RunVarKinds kind;

private:
    RunResult _value;
    public @property RunResult value() { return _value; }
    public @property RunResult value(RunResult newValue) 
    { 
        if (_value !is newValue){
            //destory(_value);//TODO hmmm we must leave it to GC
            _value =  newValue;
        }
        return _value; 
    }

    this(){
        _value = new RunResult();
        super();
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

    RunVariable setValue(string vName, SoObject newValue)
    {
        RunVariable v = find(vName);
        if (v !is null)
            v.value.object = newValue;
        return v;
    }
}

class RunResult: SardObject
{
private:
    SoObject _object;

public:
    @property SoObject object() { return _object; };
    @property SoObject object(SoObject value) { 
        if (_object !is value){
            if (_object !is null) {
            }
            _object = value;
        }
        return _object; 
    };

    @property bool hasValue(){
        return object !is null;
    }

    void assign(RunResult fromResult)
    {
        if (fromResult.object is null)
            object = null;
        else
            object = fromResult.object.clone();
    }

    SoObject extract()
    {
        SoObject o = _object;
        _object = null;
        return o;
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
public:
    private RunResult _result = new RunResult();
    @property RunResult result() { return _result; };

    private RunResult _reference;
    @property RunResult reference() { return _reference; };
    @property RunResult reference(RunResult value) { 
        if (_reference != value) {
            if (_reference !is null) 
                error("Already set a reference");
            _reference = value;
        }

        return _reference; 
    };

    //ReleaseResult return the Result and set FResult to nil witout free it, you need to free the Result by your self
    RunResult releaseResult(){
        auto r = _result;
        _result = null;
        return r;
    }

    this(){
        super();      
    }
}

class RunReturn: SardStack!RunReturnItem 
{
}

class RunStack: SardObject 
{
private:
    RunLocal _local = new RunLocal();
    RunReturn _ret = new RunReturn();

public:    
    @property RunLocal local() {return _local;};
    @property RunReturn ret() {return _ret ;};

    this(){
        super();
        local.push();
        ret.push();
    }

    ~this(){      
        ret.pop();
        local.pop();
    }
}