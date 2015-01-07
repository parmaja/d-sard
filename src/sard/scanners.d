module sard.scanners;
/**
  This file is part of the "SARD"

  @license   The MIT License (MIT) Included in this distribution
  @author    Zaher Dirkey <zaher at yahoo dot com>
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
import minilib.sets;

static const char[] sEOL = ['\0', '\n', '\r'];

static const char[] sWhitespace = sEOL ~ [' ', '\t'];
static const char[] sNumberOpenChars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
static const char[] sNumberChars = sNumberOpenChars ~ ['.', 'x', 'h', 'a', 'b', 'c', 'd', 'e', 'f'];

//const sColorOpenChars = ['#',];
//const sColorChars = sColorOpenChars ~ ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];

static const char[] sIdentifierSeparator = ".";

class SrdWhitespace_Scanner: SardScanner
{
  protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
      while ((column < text.length) && (lexical.isWhiteSpace(text[column])))
        column++;
      resume = false;
    }

    override bool accept(const string text, int column){
      return lexical.isWhiteSpace(text[column]);
    }
}

class SrdIdentifier_Scanner: SardScanner
{
  protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
      int pos = column;
      while ((column < text.length) && (lexical.isIdentifier(text[column], false)))
        column++;

      lexical.parser.setToken(text[pos..column], SardType.Identifier);
      resume = false;
    }

    override bool accept(const string text, int column){
      return lexical.isIdentifier(text[column], true);   
    }
}

class SrdNumber_Scanner: SardScanner
{
  protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
      int pos = column;      
      while ((column < text.length) && (lexical.isNumber(text[column], false)))
        column++;    
      
      lexical.parser.setToken(text[pos..column], SardType.Number);
      resume = false;
    }

    override bool accept(const string text, int column){
      return lexical.isNumber(text[column], true);   
    }
}

class SrdControl_Scanner: SardScanner
{
  protected:
    override void scan(const string text, ref int column, ref bool resume) 
    {
      CtlControl control = (cast(SrdLexical)lexical).controls.scan(text, column);//TODO need new way to access lexical without typecasting
      if (control !is null)
        column = column + control.name.length;
      else
        error("Unkown control started with " ~ text[column]);
      
      lexical.parser.setControl(control.code);
      resume = false;
    }

    override bool accept(const string text, int column)
    {
      debug{
        writeln("is accept control" ~ text[column]);
      }
      return lexical.isControl(text[column]);   
    }
}

class SrdOperator_Scanner: SardScanner
{
  protected:
    override void scan(const string text, ref int column, ref bool resume)
    {
      OpOperator operator = (cast(SrdLexical)lexical).operators.scan(text, column);//TODO need new way to access lexical without typecasting
      if (operator !is null)
        column = column + operator.name.length;
      else
        error("Unkown operator started with " ~ text[column]);

      /*if (operator.control <> Control.None) and ((lexical.parser as SrdParser).current.isInitial) //<- very stupid idea
        lexical.parser.setControl(lOperator.Control)
      else*/
      lexical.parser.setOperator(operator);
      resume = false;
    }

    override bool accept(const string text, int column){
      return lexical.isOperator(text[column]);   
    }
}

// Single line comment 

class SrdLineComment_Scanner: SardScanner
{
  protected:
    override void scan(const string text, ref int column, ref bool resume)
    {                                   
      while ((column < text.length) && (!lexical.isEOL(text[column])))
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
      while (column < text.length) {      
        if (scanText("*/", text, column)) {
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

class SrdComment_Scanner: SardScanner
{
  protected:
    string buffer;

    override void scan(const string text, ref int column, ref bool resume)
    {
      int pos = column;    
      if (resume)
        pos = pos + 2;
      while (column < text.length) 
      {
        if (scanCompare("*}", text, column))
        {
          buffer = buffer ~ text[pos..column];
          column = column + 2;//2 is "{*".length
          lexical.parser.setToken(buffer, SardType.Comment);
          debug{
            writeln("block comment" ~ buffer);
          }
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
      return scanText("{*", text, column);
    }
}

abstract class SrdString_Scanner: SardScanner
{
  protected:
    char quote;
    string buffer; //<- not sure it is good idea

    override void scan(const string text, ref int column, ref bool resume)
    {
      int pos = column;    
      while (column < text.length) 
      {      
        if (text[column] == quote)
        { //TODO Escape, not now
          buffer = buffer ~ text[pos..column + 1];
          lexical.parser.setToken(buffer, SardType.String);
          column++;
          buffer = "";
          resume = false;
          return;
        }
        column++;
      }
      column++;
      buffer = buffer ~ text[pos..column];
      resume = true;
    }

    override bool accept(const string text, int column){    
      return scanText(to!string(quote), text, column);
    }
}

/* Single Quote String */

class SrdSQString_Scanner: SrdString_Scanner
{
  protected:
    override void created(){
      super.created();
      quote = '\'';
    }
  public:
}

/* Double Quote String */

class SrdDQString_Scanner: SrdString_Scanner
{
  protected:
    override void created()
    {
      super.created();
      quote = '"';
    }
  public:
}

/*******************************************************************/
/******************     SrdLexical    ******************************/
/*******************************************************************/

class SrdLexical: SardLexical
{
private:
  OpOperators _operators;
  @property public OpOperators operators () { return _operators; }
  CtlControls _controls;
  @property public CtlControls controls() { return _controls; }    

protected:

  override void created()
  {     
    with(_controls)
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
    _operators = new OpOperators();
    _controls = new CtlControls();
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
}