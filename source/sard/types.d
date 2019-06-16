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
import sard.lexers;
import sard.objects;
import sard.runtimes;

/**
x := 10  + ( 500 + 600);
-------------[  Fork  ]-------
*/

class Fork_Node: Node
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
*   Enclose_Node is a base class for list of objects (statements) like Block_Node
*/

abstract class Enclose_Node: Node
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

class Block_Node: Enclose_Node  //Result was droped until using := assign in the first of statement
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

    Declare_Node declareObject(Node object)
    {
        if (declareStatement is null)
            declareStatement =  statements.add();
        Declare_Node declare = new Declare_Node(); //TODO should use ctor to init variables
        declare.name = object.name;
        declare.executeObject = object;
        declareStatement.add(null, declare);
        return declare;
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

    this(){
        super();
    }

    this(Node vParent, string vName){ //not auto inherited, OH Deee
        super(vParent, vName);
    }
}

