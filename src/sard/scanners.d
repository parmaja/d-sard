module sard.scanners;
/**
*   This file is part of the "SARD"
*
*   @license   The MIT License (MIT) Included in this distribution
*   @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

/**
*   @module: 
*       Trackers: Scan the source code and generate runtime objects
*
*   Lexer: divied the source code (line) and pass it to small scanners, tracker tell it when it finished
*   Tracker: Take this part of source code and convert it to control, operator or token/indentifier
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
import sard.parsers;
import sard.objects;
import sard.runtimes;
import sard.operators;

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

//TokenType

enum Type : int
{
    None, 
    Identifier, 
    Number, 
    Color, 
    String, 
    Escape, //Maybe Strings escape
    Comment 
}  

class Whitespace_tracker: Tracker
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;
        column++;
        while ((column < text.length) && (lexer.isWhiteSpace(text[column])))
            column++;

        lexer.parser.setWhiteSpaces(text[pos..column]);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isWhiteSpace(text[column]);
    }
}

class Identifier_tracker: Tracker
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;
        column++;
        while ((column < text.length) && (lexer.isIdentifier(text[column], false)))
            column++;

        lexer.parser.setToken(Token(Control.Token, Type.Identifier, text[pos..column]));
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isIdentifier(text[column], true);   
    }
}

class Number_tracker: Tracker
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;      
        column++;
        while ((column < text.length) && (lexer.isNumber(text[column], false)))
            column++;    

        lexer.parser.setToken(Token(Control.Token, Type.Number, text[pos..column]));
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isNumber(text[column], true);   
    }
}

class Control_tracker: Tracker
{
protected:
    override void scan(const string text, ref int column, ref bool resume) 
    {
        CtlControl control = lexer.controls.scan(text, column);
        if (control !is null)
            column = column + control.name.length;
        else
            error("Unkown control started with " ~ text[column]);

        lexer.parser.setControl(control);
        resume = false;
    }

    override bool accept(const string text, int column)
    {
        return lexer.isControl(text[column]);   
    }
}

class Operator_tracker: Tracker
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        OpOperator operator = lexer.operators.scan(text, column);
        if (operator !is null)
            column = column + operator.name.length;
        else
            error("Unkown operator started with " ~ text[column]);

        lexer.parser.setOperator(operator);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isOperator(text[column]);   
    }
}

// Single line comment 

class LineComment_tracker: Tracker
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {                                   
        column++;
        while ((column < text.length) && (!lexer.isEOL(text[column])))
            column++;
        column++;//Eat the EOF char
        resume = false;
    }

    override bool accept(const string text, int column){
        return scanText("//", text, column);
    }
}

class BlockComment_tracker: Tracker
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

abstract class MultiLine_tracker: Tracker
{
protected:

    string openSymbol;
    string closeSymbol;


    abstract void finish();
    abstract void collect(string text);

    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;    
        if (!resume) //first time after accept()
        {
            column = column + openSymbol.length;
            if (lexer.trimSymbols)                    
                pos = pos + openSymbol.length; //we need to ignore open tag {* here
        }
        while (column < text.length) 
        {
            if (scanCompare(closeSymbol, text, column))
            {
                if (!lexer.trimSymbols)                    
                    column = column + closeSymbol.length;
                collect(text[pos..column]);
                if (lexer.trimSymbols)                    
                    column = column + closeSymbol.length;
                
                finish();
                resume = false;
                return;
            }
            column++;
        }      
        collect(text[pos..column]);
        resume = true;
    }

    override bool accept(const string text, int column){
        return scanText(openSymbol, text, column);
    }
}

abstract class BufferedMultiLine_tracker: MultiLine_tracker
{
private:
    string buffer;

protected:
    abstract void setToken(string text);

    override void finish(){
        setToken(buffer);
        buffer = "";
    }

    override void collect(string text){
        buffer = buffer ~ text;
    }
}

//Comment object {* *}
class Comment_tracker: BufferedMultiLine_tracker
{
    this()
    {
        super();
        openSymbol = "{*";
        closeSymbol = "*}";      
    }

    override void setToken(string token)
    {
        lexer.parser.setToken(Token(Control.Token, Type.Comment, token));
    }
}

abstract class String_tracker: BufferedMultiLine_tracker
{
protected:
    override void setToken(string token)
    {
        lexer.parser.setToken(Token(Control.Token, Type.String, token));
    }

}

/* Single Quote String */

class SQString_tracker: String_tracker
{
protected:
    this(){
        super();
        openSymbol = "\'";
        closeSymbol = "\'";      
    }
}

/* Double Quote String */

class DQString_tracker: String_tracker
{
protected:
    this()
    {
        super();
        openSymbol = "\"";
        closeSymbol = "\"";      
    }
public:
}

class Escape_tracker: Tracker
{
protected:    
    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;
        column++; //not need first char, it is not pass from isIdentifier
        //print("Hello "\n"World"); //but add " to the world
        while ((column < text.length) && (lexer.isIdentifier(text[column], false)))
            column++;    

        lexer.parser.setToken(Token(Control.Token, Type.Escape, text[pos..column]));
        resume = false;
    }

    override bool accept(const string text, int column){
        return sEscape.indexOf(text[column]) >= 0;
    }
}

/*-----------------------*/
/*     Script Lexer      */
/*-----------------------*/

class CodeLexer: Lexer
{
protected:

public:
    this(){
        super();
        with(controls)
        {
            add("", Control.None);////TODO i feel it is so bad
            add("", Control.Token);
            add("", Control.Operator);
            add("", Control.Start);
            add("", Control.Stop);
            add("", Control.Declare);
            add("", Control.Assign);
            add("", Control.Let);

            add("(", Control.OpenParams);
            add("[", Control.OpenArray);
            add("{", Control.OpenBlock);
            add(")", Control.CloseParams);
            add("]", Control.CloseArray);
            add("}", Control.CloseBlock);
            add(";", Control.End);
            add(",", Control.Next);
            add(":", Control.Declare);
            add(":=", Control.Assign);
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

        with (this)
        {
            add(new Whitespace_tracker());
            add(new BlockComment_tracker());
            add(new Comment_tracker());
            add(new LineComment_tracker());
            add(new Number_tracker());
            add(new SQString_tracker());
            add(new DQString_tracker());
            add(new Escape_tracker());
            add(new Control_tracker());
            add(new Operator_tracker()); //Register it after comment because comment take /*
            add(new Identifier_tracker());//Sould be last one                           
        }
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

    override bool isSymbol(char vChar)
    {
        return sSymbolChars.indexOf(vChar) >= 0;
    }

    override bool isIdentifier(char vChar, bool vOpen = true)
    {
        return super.isIdentifier(vChar, vOpen); //we can not override it, but it is nice to see it here 
    }
}

/**
*
*   Plain Lexer
*
*/

class OpenPreprocessor_tracker: Tracker
{
protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
        int pos = column;
        column++;
        while ((column < text.length) && (lexer.isWhiteSpace(text[column])))
            column++;

        lexer.parser.setWhiteSpaces(text[pos..column]);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isWhiteSpace(text[column]);
    }
}

class PlainLexer: Lexer
{
    this()
    {
        with(controls)
        {
            add("<?", Control.OpenPreprocessor);
        }

        with(this)
        {
            add(new Whitespace_tracker());
            add(new OpenPreprocessor_tracker());
        }
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
        return false;
    }

    override bool isNumber(char vChar, bool vOpen = true)
    {
        return false;
    }

    override bool isSymbol(char vChar)
    {
        return sSymbolChars.indexOf(vChar) >= 0;
    }
}

/**
*
*   Scanner
*
*/

class CodeScanner: Scanner
{
protected:
    SoBlock _block;

public:
    this(SoBlock block)
    {
        super();
        _block = block;
        add(new CodeLexer());
     }

    override void doStart() 
    {        
        CodeParser parser = new CodeParser(lexer, _block.statements);

        lexer.parser = parser;
        lexer.start();
    }

    override void doStop() 
    {
        lexer.stop();
        lexer.parser = null;
    }
}

class ScriptScanner: Scanner
{
    this()
    {
        super();
        add(new PlainLexer());
        add(new CodeLexer());
    }
}

class HighlighterLexer: CodeLexer
{
    this(){
        super();
        trimSymbols = false;
    }
}