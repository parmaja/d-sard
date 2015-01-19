/**
*   This file is part of the "SARD"
*
*   @license   The MIT License (MIT) Included in this distribution
*   @author    Zaher Dirkey <zaher at yahoo dot com>
*/

import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.array;
import std.range;
import std.file;
import sard.runtimes;
import sard.classes;
import sard.objects;
import sard.process;
import sard.utils;
import consoled;
                                             
int main(string[] argv) 
{
    string[] sources;
    string[] results;

/*  results ~= "10"; this an example how to convert id to controls
    sources ~= "foo: begin := 10; end;
     := foo;";*/

//0
    results ~= "";
    sources ~=  ""; //Empty

    results ~= "";
    sources ~= "   "; //3 spaces

    results ~= "10";
    sources ~= ":=10;"; //simple result

    results ~= "11";
    sources ~= "  :=10+1;"; //simple result started with spaces

    results ~= "";
    sources ~= "x:=10;"; //simple assign, this must not return a value

//5
    results ~= "";
    sources ~= "x:=10+1;";  

    results ~= "10";
    sources ~= "  x := 10; 
    := x";  

    results ~= "15";
    sources ~= "  x := 10; 
    x := x + 5;
    := x;";  

    results ~= "10";
    sources ~= "  x := 10; 
    //x := x + 5;
    := x;";

    results ~= "10";
    sources ~= "  x := 10; 
    /*
        x := 5;
        x := x + 5;
        */
        := x;";

//10:
    //statment using semicolon closed by block closer
    results ~= "5";
    sources ~= `//notice before }
        x := { := 5 }
        :=x;
        `;

    //block without using semicolon
    results ~= "5";
    sources ~= `//block without using semicolon
        x := { := 5; }
        :=x;
        `;

    results ~= "Hello\nWorld";
    sources ~= "//Hello World 
        s:=\"Hello\nWorld\";
        := s;";

    results ~= "Hello World";
    sources ~= `//Hello World 
        s:='Hello';
        s := s+' World';
        := s;`;

    results ~= "10";
    sources ~= "  x := 10; 
    {*
        x := 5;
        x := x + 5;
        *};
        := x;";
    

     results ~= "40";
     sources ~= "//call function
        foo: { := 12 + 23; }; //this is a declaration 
        x := foo + 5;
        := x;";

        results ~= "20";
        sources ~= "//call function
        foo:(z){ := z + 10; }; //this is a declaration 
        x := foo(5) + 5;
        := x;"; 

/+
//here we must return error 
        results ~= "";
        sources[] = "//call function
        y := 23;
        foo:(z){ := z + 2; }; //this is a declaration 
        x := foo + 5;
        := x;"; 
+/

        results ~= "test";
        sources ~= `//testing change the var type
            x := 10;
            x := "test";
            :=x;
            `;

        results ~= "test";
        sources ~= `//testing change the var type
            := 10;
            x := 5;
            `;

        results ~= "20";
        sources ~= "//call function
        foo:(z){ := z + 10; }; //this is a declaration 
        x := foo(5 + 1) + 4;
        := x;"; 

        results ~= "40";
        sources ~= "//call function
        y := 23;
        foo:(z){ := z + y; }; //this is a declaration 
        x := foo(5) + 12;
        := x;";

        results ~= "";
        sources ~= "/*
    This examples are worked, and this comment will ignored, not compiled or parsed as we say.
*/

x := 10 + 5 - (5 * 5); //Single Line comment

x := x + 10; //Using same variable, until now local variable implemented
x := {    //Block it any where
            y := 0;
            := y + 5; //this is a result return of the block
    }; //do not forget to add ; here
{* This a block comment, compiled, useful for documentation, or regenrate the code *};
:= x; //Return result to the main object

s:='Foo';
s:=s + ' Bar';
:=s; //It will retrun 'Foo Bar';

i := 10;
i := i + 5.5;
//variable i now have 15 not 15.5

i := 10.0;
i := i + 5.5;
//variable i now have 15.5

{* First init of the variable define the type *}"; 


    try {        
        bool loop = true;
        while (loop) 
        {
            foreground = Color.lightYellow;
            writeln("--------- SARD (" ~ sSardVersion ~ ")----------");
            writeln();
            foreground = Color.initial;

            string source;
            int index;

            if (argv.length > 1)
            {
                source = readText(argv[1]);
                loop = false;
            }
            else {
                write("Enter test source #");
                string answer;
                answer = trim(readln());                
                if (answer =="") {
                    loop = false;
                    break;
                }                    
                index = to!int(answer);
                if (index < sources.length)
                    source = sources[index];
                else
                {
                    foreground = Color.red;
                    writeln("There is no source at this index");
                    foreground = Color.initial;
                    continue;
                }
            }
            writeln();
            writeln("--- Compile ---");
            writeln();
            Sard sard = new Sard();  
            //source = sources[sources.length-1];
            //source = sources[$-1];        
            //source = sources.back;
            foreground = Color.green;
            writeln(source);
            foreground = Color.initial;
            writeln("---------------");
            sard.compile(source);
            writeln();
//            writeln("Press enter to run");
            //getch();
            //readln();
            writeln("----- Run -----");
            sard.run();
            writeln();
            writeln("----- Result -----");
            foreground = Color.lightCyan;
            string s = sard.result;
            writeln(s);  
            foreground = Color.initial;
            if (s != results[index])
                error("Not expcepted result: " ~ results[index]);
            writeln();
        }
        writeln("---------------");
    }
    catch(SardParserException e)
    {
        foreground = Color.red;
        writeln("*******************************");
        with (e){
            writeln(msg ~ " line: " ~ to!string(line) ~ " column: " ~ to!string(column));          
        } 
        writeln("*******************************");
        foreground = Color.initial;
    }
    catch(Exception e) 
    {
        foreground = Color.red;
        writeln("*******************************");
        with (e)
            writeln(msg);    
        writeln("*******************************");
        foreground = Color.initial;
    }
    writeln("Press enter to stop");
    //getch();
    readln();
    return 0;
}