module sard.scanners;
/**
    This file is part of the "SARD"

    @license   The MIT License (MIT) Included in this distribution
    @author    Zaher Dirkey <zaher at yahoo dot com>
*/

/**
    @module: 
        Scanners: Scan the source code and generate runtime objects

    SrdLexer: divied the source code (line) and pass it to small scanners, scanner tell it when it finished
    SrdScanner: Take this part of source code and convert it to control, operator or token/indentifier
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
import sard.runtimes;
import sard.operators;

import minilib.sets;

static immutable char[] sEOL = ['\0', '\n', '\r'];
static immutable char[] sWhitespace = sEOL ~ [' ', '\t'];
static immutable char[] sNumberOpenChars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
static immutable char[] sNumberChars = sNumberOpenChars ~ ['.', 'x', 'h', 'a', 'b', 'c', 'd', 'e', 'f'];
static immutable char[] sIdentifierSeparator = ".";

//const sColorOpenChars = ['#',];
//const sColorChars = sColorOpenChars ~ ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];

class SrdWhitespace_Scanner: SardScanner
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        while ((column < text.length) && (lexer.isWhiteSpace(text[column])))
            column++;
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isWhiteSpace(text[column]);
    }
}

class SrdIdentifier_Scanner: SardScanner
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;
        while ((column < text.length) && (lexer.isIdentifier(text[column], false)))
            column++;

        lexer.setToken(text[pos..column], SardType.Identifier);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isIdentifier(text[column], true);   
    }
}

class SrdNumber_Scanner: SardScanner
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;      
        while ((column < text.length) && (lexer.isNumber(text[column], false)))
            column++;    

        lexer.setToken(text[pos..column], SardType.Number);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isNumber(text[column], true);   
    }
}

class SrdControl_Scanner: SardScanner
{
protected:
    override void scan(const string text, ref int column, ref bool resume) 
    {
        CtlControl control = lexer.controls.scan(text, column);
        if (control !is null)
            column = column + control.name.length;
        else
            error("Unkown control started with " ~ text[column]);

        lexer.setControl(control.code);
        resume = false;
    }

    override bool accept(const string text, int column)
    {
        return lexer.isControl(text[column]);   
    }
}

class SrdOperator_Scanner: SardScanner
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        OpOperator operator = lexer.operators.scan(text, column);
        if (operator !is null)
            column = column + operator.name.length;
        else
            error("Unkown operator started with " ~ text[column]);

        lexer.setOperator(operator);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isOperator(text[column]);   
    }
}

// Single line comment 

class SrdLineComment_Scanner: SardScanner
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {                                   
        while ((column < text.length) && (!lexer.isEOL(text[column])))
            column++;
        column++;//Eat the EOF char
        resume = false;
    }

    override bool accept(const string text, int column){
        return scanText("//", text, column);
    }
}

class SrdBlockComment_Scanner: SardScanner
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        while (column < text.length) 
        {
            if (scanText("*/", text, column)) 
            {
                resume = false;
                return;
            }
            column++;
        }
        column++;//Eat the second chat //not sure
        resume = true;
    }

    override bool accept(const string text, int column){
        return scanText("/*", text, column);
    }
}

abstract class SrdMultiLine_Scanner: SardScanner
{
private:
    string buffer;

protected:

    string openSymbol;
    string closeSymbol;
    bool trimSymbols = true; //ommit send open and close tags when setToken

    abstract void setToken(string token);

    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;    
        if (!resume) //first time after accept()
        {
            column = column + openSymbol.length;
            if (trimSymbols)                    
                pos = pos + openSymbol.length; //we need to ignore open tag {* here
        }
        while (column < text.length) 
        {
            if (scanCompare(closeSymbol, text, column))
            {
                if (!trimSymbols)                    
                    column = column + closeSymbol.length;
                buffer = buffer ~ text[pos..column];
                if (trimSymbols)                    
                    column = column + closeSymbol.length;
                setToken(buffer);
                buffer = "";
                resume = false;
                return;
            }
            column++;
        }      
        buffer = buffer ~ text[pos..column];
        resume = true;
    }

    override bool accept(const string text, int column){
        return scanText(openSymbol, text, column);
    }
}

//Comment object {* *}
class SrdComment_Scanner: SrdMultiLine_Scanner
{
    override void created()
    {
        super.created();
        openSymbol = "{*";
        closeSymbol = "*}";      
    }

    override void setToken(string token)
    {
        lexer.setToken(token, SardType.Comment);
    }
}

abstract class SrdString_Scanner: SrdMultiLine_Scanner
{
protected:
    override void setToken(string token)
    {
        lexer.setToken(token, SardType.String);
    }

}

/* Single Quote String */

class SrdSQString_Scanner: SrdString_Scanner
{
protected:
    override void created(){
        super.created();
        openSymbol = "\'";
        closeSymbol = "\'";      
    }
}

/* Double Quote String */

class SrdDQString_Scanner: SrdString_Scanner
{
protected:
    override void created()
    {
        super.created();
        openSymbol = "\"";
        closeSymbol = "\"";      
    }
public:
}

/*-----------------------*/
/*      SrdLexer       */
/*-----------------------*/

class SrdLexer: SardLexer
{
private:

protected:

    override void created()
    {     
        with(controls)
        {
            add("(", SardControl.OpenParams);
            add("[", SardControl.OpenArray);
            add("{", SardControl.OpenBlock);
            add(")", SardControl.CloseParams);
            add("]", SardControl.CloseArray);
            add("}", SardControl.CloseBlock);
            add(";", SardControl.End);
            add(",", SardControl.Next);
            add(":", SardControl.Declare);
            add(":=", SardControl.Assign);
        }

        with (operators)
        {
            add(new OpPlus);
            add(new OpMinus());
            add(new OpMultiply());
            add(new OpDivide());

            add(new OpEqual());
            add(new OpNotEqual());
            add(new OpAnd());
            add(new OpOr());
            add(new OpNot());

            add(new OpGreater());
            add(new OpLesser());

            add(new OpPower());
        }

        with (scanners)
        {
            add(new SrdWhitespace_Scanner());
            add(new SrdBlockComment_Scanner());
            add(new SrdComment_Scanner());
            add(new SrdLineComment_Scanner());
            add(new SrdNumber_Scanner());
            add(new SrdSQString_Scanner());
            add(new SrdDQString_Scanner());
            add(new SrdControl_Scanner());
            add(new SrdOperator_Scanner()); //Register it after comment because comment take /*
            add(new SrdIdentifier_Scanner());//Sould be last one      
        }
    }

public:
    this(){
        super();
    }

    override bool isEOL(char vChar)
    {
        return sEOL.indexOf(vChar) >= 0;
    }

    override bool isWhiteSpace(char vChar, bool vOpen = true)
    {
        return sWhitespace.indexOf(vChar) >= 0;
    }

    override bool isControl(char vChar)
    {
        return controls.isOpenBy(vChar);
    }

    override bool isOperator(char vChar)
    {
        return operators.isOpenBy(vChar);
    }

    override bool isNumber(char vChar, bool vOpen = true)
    {
        bool r;
        if (vOpen)
            r = sNumberOpenChars.indexOf(vChar) >= 0;
        else
            r = sNumberChars.indexOf(vChar) >= 0;
        return r;
    }

    override bool isIdentifier(char vChar, bool vOpen = true)
    {
        return super.isIdentifier(vChar, vOpen); //we can not override it, but it is nice to see it here 
    }

    override bool doIdentifier(string identifier)
    {
        //example just for fun
        /*
        if (identifier == "begin")
        {
            setControl(SardControl.OpenBlock);
            return true;
        } 
        if (identifier == "end")
        {
            setControl(SardControl.CloseBlock);
            return true;
        }   
        else  */    
        return super.doIdentifier(identifier);
    }
}