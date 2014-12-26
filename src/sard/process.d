module sard.process;
/**
This file is part of the "SARD"

@license   The MIT License (MIT) Included in this distribution
@author    Zaher Dirkey <zaher at parmaja dot com>

*/
import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.array;
import std.range;
import std.datetime;
import sard.classes;
import sard.scanners;
import sard.objects;

class SoVersion_Const:SoNamedObject
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
    SoVersion_Const versionConst = new SoVersion_Const();

  public:
    this(){
      super();
      versionConst.parent = this;
      versionConst.name = "Version";
      addDeclare(null, versionConst);
    }
}

class SrdEngine: SardObject{  
}

class SardRun: SardObject
{
  protected:

  public:
    SrdEnvironment env;
    SoMain main;
    string result;//Temp

    this(){
      super();
      env = new SrdEnvironment();
    }
    
    void compile(string text){

      //writeln("-------------------------------");

      main = new SoMain(); //destory the old compile and create new

      /* Compile */

      SrdParser parser = new SrdParser(main.block);
      SrdLexical lexical = new SrdLexical();
      lexical.parser = parser;
      lexical.env = env;
      SrdFeeder feeder = new SrdFeeder(lexical);

      feeder.scan(text);

      debug{
        main.debugWrite(0);
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