module sard.scanners;
/**
This file is part of the "SARD"

@license   The MIT License (MIT) Included in this distribution
@author    Zaher Dirkey <zaher at parmaja dot com>

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
    override bool scan(const string text, ref int column)
    {
      while ((column < text.length) && (sWhitespace.indexOf(text[column]) > 0))
        column++;
       return true;
    }

    override bool accept(const string text, int column){
      return sWhitespace.indexOf(text[column]) > 0;
    }
}

class SrdIdentifier_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      int c = column;
      while ((column < text.length) && (lexical.isIdentifier(text[column], false)))
        column++;
      column++;
      lexical.parser.setToken(text[c..column], SardType.Identifier);
      return true;
    }

    override bool accept(const string text, int column){
      return lexical.isIdentifier(text[column], true);   
    }
}

class SrdNumber_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      int c = column;
      int l = text.length;
      while ((column < text.length) && (lexical.isNumber(text[column], false)))
        column++;    
      column++;
      lexical.parser.setToken(text[c..column], SardType.Number);
      return true;
    }

    override bool accept(const string text, int column){
      return lexical.isNumber(text[column], true);   
    }
}

class SrdControl_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column) {
      CtlControl control = (cast(SrdLexical)lexical).controls.scan(text, column);//TODO need new way to access lexical without typecasting
      if (control !is null){
        column = column + control.name.length;
      }
      else
        error("Unkown control started with " ~ text[column]);
      
      lexical.parser.setControl(control.code);
      return true;
    }

    override bool accept(const string text, int column){
      return lexical.isControl(text[column]);   
    }
}

class SrdOperator_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      OpOperator operator = (cast(SrdLexical)lexical).operators.scan(text, column);//TODO need new way to access lexical without typecasting
      if (operator is null)
        column = column + operator.name.length;
      else
        error("Unkown operator started with " ~ text[column]);

      /*if (operator.control <> Control.None) and ((lexical.parser as SrdParser).current.isInitial) //<- very stupid idea
        lexical.parser.setControl(lOperator.Control)
      else*/
      lexical.parser.setOperator(operator);
      return true;
    }

    override bool accept(const string text, int column){
      return lexical.isOperator(text[column]);   
    }
}

class SrdLineComment_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      while ((column < text.length) && (sEOL.indexOf(text[column]) > 0))
        column++;
      column++;////////////////
      return true;
    }

    override bool accept(const string text, int column){
      return scanText("//", text, column);
    }
}

class SrdBlockComment_Scanner: SardScanner
{
  protected:
    override bool scan(const string text, ref int column)
    {
      while (column < text.length) {      
        if (scanText("*/", text, column))
          return true;
        column++;
      }
      column++;///////////////////////
      return false;
    }

    override bool accept(const string text, int column){
      return scanText("/*", text, column);
    }
}

class SrdComment_Scanner: SardScanner
{
  protected:
    string buffer;

    override bool scan(const string text, ref int column)
    {
      int c = column;    
      while (column < text.length) {
        if (scanCompare("*}", text, column)){
          buffer = buffer ~ text[c..column + 1];
          column = column + 2;
          lexical.parser.setToken(buffer, SardType.Comment);
          buffer = "";
          return true;
        }
        column++;
      }
      column++;
      buffer = buffer ~ text[c..column];
      return false;
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

    override bool scan(const string text, ref int column)
    {
      int c = column;    
      while (column < text.length) {      
        if (text[column] == quote) { //TODO Escape, not now
          buffer = buffer ~ text[c..column + 1];
          lexical.parser.setToken(buffer, SardType.String);
          column++;
          buffer = "";
          return true;
        }
        column++;
      }
      column++;
      buffer = buffer ~ text[c..column];
      return false;
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
  OpOperators _operators = new OpOperators();
  @property public OpOperators operators () { return _operators; }
  CtlControls _controls = new CtlControls();
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

  override bool isWhiteSpace(char vChar, bool vOpen = true)
  {
    return sWhitespace.indexOf(vChar) > 0;
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
    if (vOpen)
      return sNumberOpenChars.indexOf(vChar) > 0;
    else
      return sNumberChars.indexOf(vChar) > 0;
  }

  override bool isIdentifier(char vChar, bool vOpen = true)
  {
    return super.isIdentifier(vChar, vOpen); //we can not override it, but it is nice to see it here 
  }
}