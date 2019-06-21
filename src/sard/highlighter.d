module sard.highlighter; 
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
import sard.lexers;
import sard.parsers;
import sard.objects;
import sard.scanners;

/**
*
*   HighlighterScanner
*
*/

class HighlightParser: BaseObject, IParser 
{
public:
    override void setToken(Token token){
        writeln(token.value);
    }

    override void setControl(Control control){
        //engine.print(control.name);
    
    }
    override void setOperator(Operator operator){
        writeln(operator.name);
    }

    override void setWhiteSpaces(string whitespaces){
        writeln(whitespaces);
    }

    override void start(){        
    }
    override void stop(){
    }
}

class HighlighterLexer: Scanner
{
public:
    this(){
        super();
        add(new CodeLexer());
    }

    override void doStart() 
    {        
        HighlightParser parser = new HighlightParser();
        //parser.statements = _block.statements;
        lexer.parser = parser;
        lexer.trimSymbols = false;
        lexer.start();
    }

    override void doStop() 
    {
        lexer.stop();
        lexer.parser = null;
    }
}
