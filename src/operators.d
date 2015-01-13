module sard.operators;
/**
*
* This file is part of the "SARD"
* 
* @license   The MIT License (MIT) Included in this distribution
* @author    Zaher Dirkey <zaher at yahoo dot com>
*
*/

//Base class of operator

import std.stdio;
import std.conv;
import std.array;
import std.string;
import std.stdio;

import sard.utils;
import sard.classes;

class OpNone: OpOperator
{
    this()
    {
        super();
        name = "";
        title = "None";
        level = 50;
        description = "Nothing";
    }
}

class OpPlus: OpOperator
{
    this()
    {
        super();
        name = "+";
        title = "Plus";
        level = 51;
        description = "Add object to another object";
    }
}

class OpMinus: OpOperator
{
    this()
    {
        super();
        name = "-";
        title = "Minus";
        level = 51;
        description = "Sub object to another object";
    }
}

class OpMultiply: OpOperator
{
    this()
    {
        super();
        name = "*";
        title = "Multiply";
        level = 52;
        description = "";
    }
}

class OpDivide: OpOperator
{
    this()
    {
        super();
        name = "/";
        title = "Divition";
        level = 52;
        description = "";
    }
}

class OpPower: OpOperator
{
    this()
    {
        super();
        name = "^";
        title = "Power";
        level = 53;
        description = "";
    }
}

class OpLesser: OpOperator
{
    this()
    {
        super();
        name = "<";
        title = "Lesser";
        level = 52;
        description = "";
    }
}

class OpGreater: OpOperator
{
    this()
    {
        super();
        name = ">";
        title = "Greater";
        level = 52;
        description = "";
    }
}

class OpEqual: OpOperator
{
    this()
    {
        super();
        name = "=";
        title = "Equal";
        level = 52;
        description = "";
        //control = ctlAssign; bad idea
    }
}

class OpNotEqual: OpOperator
{
    this()
    {
        super();
        name = "<>";
        title = "NotEqual";
        level = 52;
        description = "";    
    }
}

class OpNot: OpOperator
{
    this()
    {
        super();
        name = "!";
        title = "Not";
        level = 52;
        description = "";
    }
}            

class OpAnd: OpOperator
{
    this()
    {
        super();
        name = "&";
        title = "And";
        level = 52;
        description = "";
    }
}

class OpOr: OpOperator
{
    this()
    {
        super();
        name = "|";
        title = "Or";
        level = 52;
        description = "";
    }
}