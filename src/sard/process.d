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
import sard.runtimes;
import sard.operators;
import sard.objects;
import sard.scanners;
import sard.parsers;

class SoVersion_Const: SoObject
{
protected:
    override void doExecute(RunEnv env, OpOperator operator, ref bool done){
        env.stack.results.current.result.value = new SoText(sSardVersion);
    }
}

class SoTime_Const: SoObject
{
protected:
    override void doExecute(RunEnv env, OpOperator operator, ref bool done){    
        env.stack.results.current.result.value = new SoText(Clock.currTime().toISOExtString());
    }
}

class Sard: SardObject
{
protected:

public:
    SoBlock main;
    string result;

    this(){
        super();
    }

    void compile(string text)
    {
        //writeln("-------------------------------");

        main = new SoBlock(); //destory the old compile and create new
        main.name = "main";

        /* Compile */

        writeln("----Createing lex objects-----");
        writeln();
        SrdParser parser = new SrdParser(main.statements);
        SrdLexical lexical = new SrdLexical();

        lexical.parser = parser;      
        SardFeeder feeder = new SardFeeder(lexical);

        writeln("--------Scanning--------");
        feeder.scan(text);

        debug
        {
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
        RunEnv env = new RunEnv();
        env.execute(main, null); 

        if (env.stack.results.current.result.value !is null) 
        {
            debug {
                writeln("We have value");
            }
            result = env.stack.results.current.result.value.asText();
            debug {
                writeln("The value is: " ~ result);
            }
        }  
    };
}