/**
*   This file is part of the "SARD"
*
*   @license   The MIT License (MIT) Included in this distribution
*   @author    Zaher Dirkey <zaher at yahoo dot com>
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
import sard.utils;
import consoled;

class MainEngine: Engine 
{
    private static consoled.Color[sard.Color] colors;

    this(){
        super();
        colors = 
        [
            sard.Color.None: consoled.Color.initial,
            sard.Color.Default: consoled.Color.initial,
            sard.Color.Black: consoled.Color.black,
            sard.Color.Blue: consoled.Color.blue,
            sard.Color.Green: consoled.Color.green,
            sard.Color.Cyan: consoled.Color.cyan,
            sard.Color.Red: consoled.Color.red,
            sard.Color.Magenta: consoled.Color.magenta,
            sard.Color.Yellow: consoled.Color.yellow,
            sard.Color.LightGray: consoled.Color.lightGray,
            sard.Color.Gray: consoled.Color.gray,
            sard.Color.LightBlue: consoled.Color.lightBlue,
            sard.Color.LightGreen: consoled.Color.lightGreen,
            sard.Color.LightCyan: consoled.Color.lightCyan,
            sard.Color.LightRed: consoled.Color.lightRed,
            sard.Color.LightMagenta: consoled.Color.lightMagenta,
            sard.Color.LightYellow: consoled.Color.lightYellow,
            sard.Color.White: consoled.Color.white
        ];
    }

    consoled.Color mapColor(sard.Color color){
       return colors[color] ;
    }

    override void print(sard.Color color, string text, bool eol = true)
    {
        //luck for mutlithread
        auto saved = foreground;
        foreground = mapColor(color);
        if (eol)
            writeln(text);
        else
            write(text);
        foreground = saved;
    }
}

unittest{
    
}

void run(string source){
    Script script;

}

int main(string[] argv) 
{
    writeln("SARD Script version " ~ sVersion);

    setEngine(new MainEngine());

    version(unittest){
        import test;
        runTest("");
    }
    else
    {
        

        if (argv.length > 1)
        {
            string code = readText(argv[1]);
            run(code);
        }
        else
            run("");
    }
    return 0;
}