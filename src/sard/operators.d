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
        precedence = 50;
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
        precedence = 51;
        associative = Associative.Left;
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
        precedence = 51;
        associative = Associative.Left;
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
        precedence = 52;
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
        precedence = 52;
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
        precedence = 53;
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
        precedence = 54;
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
        precedence = 54;
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
        precedence = 54;
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
        precedence = 54;
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
        precedence = 54;
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
        precedence = 54;
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
        precedence = 54;
        associative = Associative.Left;
        description = "";
    }
}