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

unittest{

}

void run(string source){
    try {
        SardScript script = new SardScript();
        scope(exit) destroy(script);

        script.compile(source);
        script.run();

        string s = script.result;
        writeln(s);
        writeln();
    }
    catch(ParserException e)
    {
        with (e){
            writeln();
            writeln(msg ~ " line: " ~ to!string(line) ~ " column: " ~ to!string(column));
        }

    }
    catch(Exception e)
    {
        with (e){
            writeln();
            writeln("Error: " ~ msg, true);
        }
    }
}

int main(string[] argv)
{
    writeln("SARD Script version " ~ sVersion);
    debug{
        writeln("Debug Mode\n");
    }

    string file;

    writeln(getcwd());

    if (argv.length > 1)
    {
        file = argv[1];
    }

    if (exists(file))
    {
        writeln("run file: " ~ file);
        string code = readText(file);
        run(code);
    }
    else {
        writeln("File not exists: " ~ file ~ "\n");
        return 1;
    }
    return 0;
}
