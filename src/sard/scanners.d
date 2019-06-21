module sard.scanners;
/**
*   This file is part of the "SARD"
*
*   @license   The MIT License (MIT) Included in this distribution
*   @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

/**
*   @module: 
*       Tokenizers: Scan the source code and generate runtime objects
*
*   Lexer: divied the source code (line) and pass it to small scanners, tokenizer tell it when it finished
*   Tokenizer: Take this part of source code and convert it to control, operator or token/indentifier
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
import sard.lexers;
import sard.parsers;
import sard.objects;

import minilib.sets;

static immutable char[] sEOL = ['\0', '\n', '\r'];
static immutable char[] sWhitespace = sEOL ~ [' ', '\t'];
static immutable char[] sNumberOpenChars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
static immutable char[] sNumberChars = sNumberOpenChars ~ ['.', 'x', 'h', 'a', 'b', 'c', 'd', 'e', 'f'];
static immutable char[] sSymbolChars = ['"', '\'', '\\'];
static immutable char[] sIdentifierSeparator = ".";
static immutable char[] sEscape = ['\\'];

//const sColorOpenChars = ['#',];
//const sColorChars = sColorOpenChars ~ ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];

/**
    Tokenizers
*/

class Whitespace_Tokenizer: Tokenizer
{
protected:
    override void scan(const string text, int started, ref int column, ref bool resume)
    {
        column++;
        while (indexInStr(column, text) && (lexer.isWhiteSpace(text[column])))
            column++;

        lexer.parser.setWhiteSpaces(text[started..column]);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isWhiteSpace(text[column]);
    }
}

class Identifier_Tokenizer: Tokenizer
{
protected:
    override void scan(const string text, int started, ref int column, ref bool resume)
    {
        column++;
        while (indexInStr(column, text) && (lexer.isIdentifier(text[column], false)))
            column++;

        lexer.parser.setToken(Token(Ctl.Token, Type.Identifier, text[started..column]));
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isIdentifier(text[column], true);   
    }
}

class Number_Tokenizer: Tokenizer
{
protected:
    override void scan(const string text, int started, ref int column, ref bool resume)
    {
        column++;
        while (indexInStr(column, text) && (lexer.isNumber(text[column], false)))
            column++;    

        lexer.parser.setToken(Token(Ctl.Token, Type.Number, text[started..column]));
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isNumber(text[column], true);   
    }
}

class Control_Tokenizer: Tokenizer
{
protected:
    override void scan(const string text, int started, ref int column, ref bool resume)
    {
        Control control = lexer.controls.scan(text, column);
        if (control !is null)
            column = column + control.name.length;
        else
            error("Unkown control started with " ~ text[started]);

        lexer.parser.setControl(control);
        resume = false;
    }

    override bool accept(const string text, int column)
    {
        return lexer.isControl(text[column]);
    }
}

class Operator_Tokenizer: Tokenizer
{
protected:
    override void scan(const string text, int started, ref int column, ref bool resume)
    {
        Operator operator = lexer.operators.scan(text, column);
        if (operator !is null)
            column = column + operator.name.length;
        else
            error("Unkown operator started with " ~ text[started]);

        lexer.parser.setOperator(operator);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isOperator(text[column]);   
    }
}

// Single line comment 

class LineComment_Tokenizer: Tokenizer
{
protected:
    override void scan(const string text, int started, ref int column, ref bool resume)
    {                                   
        column++;
        while (indexInStr(column, text) && (!lexer.isEOL(text[column])))
            column++;
        column++;//Eat the EOF char
        resume = false;
    }

    override bool accept(const string text, int column){
        return scanText("//", text, column);
    }
}

class BlockComment_Tokenizer: Tokenizer
{
protected:
    override void scan(const string text, int started, ref int column, ref bool resume)
    {
        while (indexInStr(column, text))
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

//Comment object {* *}
class Comment_Tokenizer: BufferedMultiLine_Tokenizer
{
    this()
    {
        super();
        openSymbol = "{*";
        closeSymbol = "*}";      
    }

    override void setToken(string text)
    {
        lexer.parser.setToken(Token(Ctl.Token, Type.Comment, text));
    }
}

/* Single Quote String */

class SQString_Tokenizer: String_Tokenizer
{
public:
    this(){
        super();
        openSymbol = "\'";
        closeSymbol = "\'";      
    }
}

/* Double Quote String */

class DQString_Tokenizer: String_Tokenizer
{
public:
    this()
    {
        super();
        openSymbol = "\"";
        closeSymbol = "\"";      
    }
}

class Escape_Tokenizer: Tokenizer
{
protected:    
    override void scan(const string text, int started, ref int column, ref bool resume)
    {
        int pos = column;
        column++; //not need first char, it is not pass from isIdentifier
        //print("Hello "\n"World"); //but add " to the world
        while (indexInStr(column, text) && (lexer.isIdentifier(text[column], false)))
            column++;    

        lexer.parser.setToken(Token(Ctl.Token, Type.Escape, text[pos..column]));
        resume = false;
    }

    override bool accept(const string text, int column){
        return sEscape.indexOf(text[column]) >= 0;
    }
}
