module sard.operators;
/**
*
* This file is part of the "SARD"
* 
* @license   The MIT License (MIT) Included in this distribution
* @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
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
        associative = Associative.Left;
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
        associative = Associative.Left;
        description = "Add object to another object";
    }
}

class OpSub: OpOperator
{
    this()
    {
        super();
        name = "-";
        title = "Sub";
        associative = Associative.Left;
        description = "Sub object from another object";
    }
}

class OpMultiply: OpOperator
{
    this()
    {
        super();
        name = "*";
        title = "Multiply";
        associative = Associative.Left;
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
        associative = Associative.Left;
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
        associative = Associative.Right;
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
        associative = Associative.Left;
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
        associative = Associative.Left;
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
        associative = Associative.Left;
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
        associative = Associative.Left;
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
        associative = Associative.Left;
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
        associative = Associative.Left;
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
        associative = Associative.Left;
        description = "";
    }
}
