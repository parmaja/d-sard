/**
*   This file is part of the "SARD"
*
*   @license   The MIT License (MIT) Included in this distribution
*   @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

debug
{
    debug = log;

    debug(log){
        debug = log_compile;
        debug = log_run;
        debug = log_nodes;
    }

    version = alpha;
}

import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.array;
import std.range;
import std.file;
import std.path;
import sard;

import arsd.terminal;

alias Terminal = arsd.terminal.Terminal;

class MainEngine: Engine
{
    this(){
        super();
    }

    override void print(sard.Color color, string text, bool eol = true)
    {
        //luck for mutlithread
        //Terminal.color(color); //map it
        if (eol)
            writeln(text);
        else
            write(text);
    }
}

unittest{

}

void run(string source){
    try {
        Script script = new Script();
        scope(exit) destroy(script);

        script.compile(source);
        script.run();

        string s = script.result;
        engine.print(sard.Color.LightCyan, s);

        writeln();
    }
    catch(ParserException e)
    {
        with (e){
            writeln();
            engine.print(sard.Color.LightRed, msg ~ " line: " ~ to!string(line) ~ " column: " ~ to!string(column));
        }

    }
    catch(Exception e)
    {
        with (e){
            writeln();
            engine.print(sard.Color.LightRed, "Error: " ~ msg, true);
        }
    }
}

int main(string[] argv)
{
    writeln("SARD Script version " ~ sVersion);

    setEngine(new MainEngine());

    version(unittest){
        writeln("unittest mode\n");
        import test;
        runTest("");
    } 
    else
    {
       if (argv.length > 1)
        {
            auto file = argv[1];
            if (exists(file))
            {
                string code = readText(file);
                run(code);
            }
            else {
                writeln("File not exists" ~ file ~ "\n");
                return 1;
            }
        }
        else
            run("");
    }
    return 0;
}