module sard.scripts;
/**
*    This file is part of the "SARD"
*
*    @license   The MIT License (MIT) Included in this distribution
*    @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.array;
import std.range;
import std.datetime;

import sard.classes;
import sard;

class SoVersion_Const: SoObject
{
protected:
    override void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done){
        env.results.current.result.value = new SoText(sVersion);
    }
}

class SoPI_Const: SoObject
{
protected:
    override void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done){
        env.results.current.result.value = new SoNumber(PI);
    }
}

class SoTime_Const: SoObject
{
protected:
    override void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done){
        env.results.current.result.value = new SoText(Clock.currTime().toISOExtString());
    }
}

class SoPrint_object: SoObject
{
protected:
    override void doExecute(RunData data, RunEnv env, OpOperator operator, ref bool done){
        //env.results.current.result.value = new SoText(Clock.currTime().toISOExtString());
        auto v = env.stack.current.variables.find("s");
        if (v !is null){
            //if (v.value !is null) //TODO it is bad, we should not have it null
                sard.classes.engine.print(v.value.asText);
        }
    }
}

class Script: BaseObject
{
protected:

public:
    SoBlock main;
    Scanner scanner;
    string result;

    this(){
        super();
    }

    ~this(){
        destroy(main);
        destroy(scanner);
    }

    void compile(string text)
    {
        //writeln("-------------------------------");

        main = new SoBlock(); //destory the old compile and create new
        main.name = "main";

        auto version_const = new SoVersion_Const();
        version_const.name = "version";
        main.declareObject(version_const);

        auto PI_const = new SoPI_Const();
        PI_const.name = "PI";
        main.declareObject(PI_const);

        auto print_object = new SoPrint_object();
        print_object.name = "print";
        SoDeclare print_declare = main.declareObject(print_object);
        print_declare.defines.parameters.add("s", "string");

        /* Compile */

        scanner = new CodeScanner(main);

        debug(log_compile) writeln("-------- Scanning --------");
        scanner.scan(text);

        debug(log_nodes)
        {
            writeln();
            writeln("-------------");
            main.debugWrite(0);
            writeln();
            writeln("-------------");
        }
    }

    void run()
    {
        RunEnv env = new RunEnv();

        env.results.push();
        //env.root.object = main;
        main.execute(env.root, env, null);

        if (env.results.current && env.results.current.result.value)
        {
            result = env.results.current.result.value.asText();
        }
        env.results.pop();
    };
}
