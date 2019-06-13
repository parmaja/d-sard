module sard.types;
/**
* This file is part of the "SARD"
*
* @license   The MIT License (MIT) Included in this distribution
* @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

import std.stdio;
import std.string;
import std.conv:to;
import std.uni;
import std.array;
import std.range;
import std.file;
import sard.utils;

import sard.classes;
import sard.objects;
import sard.runtimes;

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
*   SoEnclose is a base class for list of objects (statements) like SoBlock
*/

abstract class SoEnclose: SoObject
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


/** SoBlock */
/**
    Used by { }
    It a block before execute push in env, after execute will pop the env, it have return value too in the env
*/

class SoBlock: SoEnclose  //Result was droped until using := assign in the first of statement
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
    override void doExecute(RunData data, RunEnv env, Operator operator,ref bool done)
    {
        //Guess what!, we will not to execute the comment ;)
        done = true;
    }

public:
    string value;
}

/* SoPreprocessor */

/*
class SoPreprocessor: SoObject
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

abstract class SoBaseNumber: SoConst //base class for Number and Integer
{
}

/* SoInteger */

class SoInteger: SoBaseNumber
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

    override void assign(SoObject fromObject){
        value = fromObject.asInteger;
    }

    override bool doOperate(SoObject object, Operator operator)
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

    override bool doOperate(SoObject object, Operator operator)
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

    override bool doOperate(SoObject object, Operator operator)
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

    override bool doOperate(SoObject object, Operator operator)
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
                    value = replicate(value, to!int((cast(SoBaseNumber)object).asInteger));
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
                error("Variable value is null: " ~ v.name);
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

class SoAssign: SoObject
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
    SoObject executeObject;

    string resultType;

    override protected void doExecute(RunData data, RunEnv env, Operator operator,ref bool done)
    {
        data.declare(this);
    }
}
