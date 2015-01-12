module sard.operators;
/**
This file is part of the "SARD"

@license   The MIT License (MIT) Included in this distribution
@author    Zaher Dirkey <zaher at yahoo dot com>
*/

//Base class of operator

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
import sard.runtimes;

import minilib.sets;


class OpOperator: SardObject
{
public:
    string name;
    string title;
    int level;//TODO it is bad idea, we need more intelligent way to define the power level of operators
    string description;
    //SardControl control;// Fall back to control if is initial, only used for for = to fall back as := //TODO remove it :(

protected: 

public:

    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln(stringRepeat(" ", level * 2) ~ "operator: " ~ name);        
        }
    }

}

class OpOperators: SardNamedObjects!OpOperator
{
public:
    OpOperator findByTitle(string title)
    {
        foreach(o; items){
            if (icmp(title, o.title) == 0) {
                return o;
            }
        }
        return null;
    }

    int addOp(OpOperator operator){
        return super.add(operator);
    }

    bool isOpenBy(const char c)
    {
        foreach(o; items){
            if (o.name[0] == toLower(c)) 
                return true;
        }
        return false;
    }    

    OpOperator scan(string text, int index)
    {
        OpOperator result = null;
        int max = 0;
        foreach(o; items)        
        {
            if (scanCompare(o.name, text, index)) 
            {
                if (max < o.name.length) 
                {
                    max = o.name.length;
                    result = o;
                }
            }
        }
        return result;
    }    
}

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