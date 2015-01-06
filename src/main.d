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
  string source = "  x := 10; 
  x := x + 5;
  := x;";  

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
  writeln("Press enter to stop");
  readln();
  return 0;
}