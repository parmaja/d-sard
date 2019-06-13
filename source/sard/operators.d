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
import sard.lexers;

class OpNone: Operator
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

class OpPlus: Operator
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

class OpSub: Operator
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

class OpMultiply: Operator
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

class OpDivide: Operator
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

class OpPower: Operator
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

class OpLesser: Operator
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

class OpGreater: Operator
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

class OpEqual: Operator
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

class OpNotEqual: Operator
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

class OpNot: Operator
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

class OpAnd: Operator
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

class OpOr: Operator
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
