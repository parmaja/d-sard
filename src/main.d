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
import sard.classes;
import sard.objects;
import sard.process;

int main(string[] argv) 
{
  writeln("--------- SARD (" ~ sSardVersion ~ ")----------");
  Sard sard = new Sard();  
  //string source = ""; //Empty
  //string source = "   "; //3 spaces
  //string source = ":=10;"; //simple result
  //string source = "  :=10;"; //simple result started with spaces
  //string source = "x:=10;"; //simple assign, this must not return a value
  //string source = "x:=10+1;";  
  /*string source = "  x := 10; 
  := x";  */
  /*string source = "  x := 10; 
  x := x + 5;
  := x;";  */

  /*string source = "  x := 10; 
  //x := x + 5;
  := x;";*/  

/+
  string source = "  x := 10; 
  /*
    x := 5;
    x := x + 5;
    */
    := x;";
+/  

/+  string source = "//call function
    foo: { 12 + 23; }; //this is a declaration 
    x := foo + 5;
    := x;";
+/
    string source = "//call function
    y := 23;
    foo:(z){ := z + 2; }; //this is a declaration 
    x := foo(5) + 5;
    := x;"; 

/+here we must return error but good one
    string source = "//call function
    y := 23;
    foo:(z){ := z + 2; }; //this is a declaration 
    x := foo + 5;
    := x;"; 
+/

  try {
    writeln();
    writeln("--- Compile ---");
    sard.compile(source);
    writeln();
    writeln("Press enter run");
    readln();
    writeln("----- Run -----");
    sard.run();
    writeln();
    writeln("----- Result -----");
    string s = sard.result;
    writeln(s);  
    writeln();
    writeln("---------------");
  }
  catch(SardParserException e) {          
    writeln("*******************************");
    writeln(source);
    writeln("---------------");
    with (e){
      writeln(msg ~ " line: " ~ to!string(line) ~ " column: " ~ to!string(column));          
    } 
    writeln("*******************************");
  }
  catch(Exception e) {          
    writeln("*******************************");
    with (e)
      writeln(msg);    
    writeln("*******************************");
  }
  writeln("Press enter to stop");
  readln();
  return 0;
}