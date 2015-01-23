module sard.process;
/**
*    This file is part of the "SARD"
* 
*    @license   The MIT License (MIT) Included in this distribution
*    @author    Zaher Dirkey <zaher at yahoo dot com>
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
        env.results.current.result.value = new SoText(sSardVersion);
    }
}

class SoTime_Const: SoObject
{
protected:
    override void doExecute(RunEnv env, OpOperator operator, ref bool done){    
        env.results.current.result.value = new SoText(Clock.currTime().toISOExtString());
    }
}

class Sard: SardObject
{
protected:

public:
    SoBlock main;
    SrdLexer lexer;
    string result;

    this(){
        super();
    }

    ~this(){
        destroy(main);
        destroy(lexer);
    }

    void compile(string text)
    {
        //writeln("-------------------------------");

        main = new SoBlock(); //destory the old compile and create new
        main.name = "main";

        /* Compile */

        writeln("----Createing lex objects-----");
        writeln();

        lexer = new SrdLexer();

        SrdParser parser = new SrdParser(main.statements);

        lexer.parser = parser;      
        
        writeln("--------Scanning--------");
        lexer.scan(text);

        destroy(parser);

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

        env.enter(env.root, main);
        env.results.push();
        main.execute(env, null);         

        if (env.results.current && env.results.current.result.value) 
        {
            result = env.results.current.result.value.asText();
        }  
        env.results.pop();
        env.exit(main);
    };
}