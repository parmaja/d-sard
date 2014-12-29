module sard.process;
/**
  This file is part of the "SARD"

  @license   The MIT License (MIT) Included in this distribution
  @author    Zaher Dirkey <zaher at yahoo dot com>
*/

import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.array;
import std.range;
import std.datetime;
import sard.classes;
import sard.objects;
import sard.scanners;
import sard.parsers;

class SoVersion_Const: SoNamedObject
{
  protected:
    override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done){
      vStack.ret.current.result.object = new SoText(sSardVersion);
    }
}

class SoTime_Const: SoNamedObject
{
  protected:
    override void doExecute(RunStack vStack, OpOperator aOperator, ref bool done){    
      vStack.ret.current.result.object = new SoText(Clock.currTime().toISOExtString());
    }
}

class SoMain: SoSection
{
  protected:
   // SoVersion_Const versionConst;

  public:
    this(){
      super();
      /*versionConst = new SoVersion_Const();
      versionConst.parent = this;
      versionConst.name = "Version";
      addDeclare(null, versionConst);*/
    }
}

class SardRun: SardObject
{
  protected:

  public:
    SoMain main;
    string result;//Temp

    this(){
      super();
    }
    
    void compile(string text){

      //writeln("-------------------------------");

      main = new SoMain(); //destory the old compile and create new

      /* Compile */

      writeln("----Createing lex objects-----");
      writeln();
      SrdParser parser = new SrdParser(main.statements);
      SrdLexical lexical = new SrdLexical();
      
      lexical.parser = parser;      
      SardFeeder feeder = new SardFeeder(lexical);

      writeln("--------Scanning--------");
      feeder.scan(text);

      debug{
        writeln();
        writeln("-------------");
        main.debugWrite(0);
        writeln();
        writeln("-------------");

        //main.printTree();
      }
    }

    void run()
    {
      RunStack stack = new RunStack();
      main.execute(stack, null);
      string result;
      if (stack.ret.current.result.object !is null) 
      {
        debug {
          writeln("We have value");
        }
        result = stack.ret.current.result.object.asText();
      }
    };
}