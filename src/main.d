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
	string[] sources;
	string[] results;

/*  results ~= "10"; this an example how to convert id to controls
	sources ~= "foo: begin := 10; end;
	 := foo;";*/


	results ~= "";
	sources ~=  ""; //Empty

	results ~= "";
	sources ~= "   "; //3 spaces

	results ~= "10";
	sources ~= ":=10;"; //simple result

	results ~= "10";
	sources ~= "  :=10;"; //simple result started with spaces

	results ~= "";
	sources ~= "x:=10;"; //simple assign, this must not return a value

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

//-10:

	results ~= "10";
	sources ~= "  x := 10; 
	{*
		x := 5;
		x := x + 5;
		*};
		:= x;";
	

	 results ~= "40";
	 sources ~= "//call function
		foo: { 12 + 23; }; //this is a declaration 
		x := foo + 5;
		:= x;";

		results ~= "20";
		sources ~= "//call function
		foo:(z){ := z + 10; }; //this is a declaration 
		x := foo(5) + 5;
		:= x;"; 

/+
//here we must return error but good one
		results ~= "";
		sources[] = "//call function
		y := 23;
		foo:(z){ := z + 2; }; //this is a declaration 
		x := foo + 5;
		:= x;"; 
+/


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
s:=s+' Bar';
:=s; //It will retrun 'Foo Bar';

i := 10;
i := i + 5.5;
//variable i now have 15 not 15.5

i := 10.0;
i := i + 5.5;
//variable i now have 15.5

{* First init of the variable define the type *}";


/*
	do not forget add ; after } bad idea
*/
string source;

	try {
		writeln();
		writeln("--- Compile ---");
		
		source = sources[10];
		writeln(source);
		writeln("---------------");
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