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

class Version_Const_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done){
        env.results.current.result.value = new Text_Node(sVersion);
    }
}

class PI_Const_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done){
        env.results.current.result.value = new Number_Node(PI);
    }
}

class Time_Const_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done){
        env.results.current.result.value = new Text_Node(Clock.currTime().toISOExtString());
    }
}

class Print_object_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done){
        //env.results.current.result.value = new Text_Node(Clock.currTime().toISOExtString());
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
    Block_Node main;
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

        main = new Block_Node(); //destory the old compile and create new
        main.name = "main";

        auto version_const = new Version_Const_Node();
        version_const.name = "version";
        main.declareObject(version_const);

        auto PI_const = new PI_Const_Node();
        PI_const.name = "PI";
        main.declareObject(PI_const);

        auto print_object = new Print_object_Node();
        print_object.name = "print";
        Declare_Node print_declare = main.declareObject(print_object);
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
