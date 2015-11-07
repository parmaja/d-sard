module test;                           
/**
*    This file is part of the "SARD"
* 
*    @license   The MIT License (MIT) Included in this distribution
*    @author    Zaher Dirkey <zaher at yahoo dot com>
*/

void runTest(string code)
{
    import std.stdio;
    import std.string;
    import std.conv;
    import sard;

    string[] sources;
    string[] results;

    results ~= "";
    sources ~=  ""; //Empty

    results ~= "";
    sources ~= "   "; //3 spaces

    results ~= "";
    sources ~= "10 + 10;"; //no result

    results ~= "10";
    sources ~= ":= 10;"; //simple result

    results ~= "20";
    sources ~= "  :=10 + 10;"; //simple result 

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
    := x;";

//10:
    results ~= "Result is 20";
    sources ~= `:= "Result is " + 10 + 10;`;

    results ~= "10";
    sources ~= "  x := 10; 
    /*
        x := 5;
        x := x + 5;
        */
        := x;";

    results ~= "15";
    sources ~= `//notice before 
         := 5 + (2 * 5);
        `;

    results ~= "150";
    sources ~= `//test divide
        := 100 + (100 / 2);
        `;

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
        *}
        := x;";
    

     results ~= "40";
     sources ~= "//call function
        foo: { := 12 + 23; } //this is a declaration 
        x := foo + 5;
        := x;";

    results ~= "20";
    sources ~= "//call function
    foo:(z){ := z + 10; } //this is a declaration 
    x := foo(5) + 5;
    := x;"; 

    results ~= "150";
    sources ~= `
Bar:{
    := 100;
}

Foo:{ := Bar + 50 }

    := Foo;`;

    results ~= sVersion;
    sources ~= `
    := version;`;

    results ~= "986.96";
    sources ~= `
    R := 10;
    x := PI * R;
    := x * x;
    `;

    results ~= "test";
    sources ~= `//testing change the var type
        x := 10;
        x := "test";
        :=x;
        `;

    results ~= "10";
    sources ~= `//testing var after result
        := 10;
        x := 5;
        `;

    results ~= "20";
    sources ~= "//call function
    foo:(z){ := z + 10; } //this is a declaration 
    x := foo(5 + 1) + 4;
    := x;"; 

    results ~= "40";
    sources ~= "//call function
    y := 23;
    foo:(z){ := z + y; } //this is a declaration 
    x := foo(5) + 12;
    := x;";

    results ~= "";
    sources ~= `/*
    This examples are worked, and this comment will ignored, not compiled or parsed as we say.
*/

x := 10 + 5 - (5 * 5); //Single Line comment

x := x + 10; //Using same variable, until now local variable implemented
x := {    //Block it any where
            y := 0;
            := y + 5; //this is a result return of the block
    } //do not forget to add ; here
{* This a block comment, compiled, useful for documentation, or regenrate the code *}
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

{* First init of the variable define the type *}`; 


/+
//here we must return error 
    results ~= "";
    sources[] = `//call function
    y := 23;
    foo:(z){ := z + 2 }
    x := foo + 5;//error here, no params sent
    := x;`; 
+/

/*
    results ~= "10"; this an example how to convert id to controls
    sources ~= "foo: begin := 10; end;
    := foo;";
*/

    string source = "";
    int index = 0;
    int[] errors;

    while (index < sources.length) 
    {
        try {        

            Script script = new Script();  

            scope(exit) destroy(script);

            source = sources[index];
            engine.print(Color.Green, "---------------", true);
            engine.print(Color.Green, source, true);
            script.compile(source);
            engine.print(Color.Default, "\n");

            script.run();            
            engine.print(Color.LightYellow, "\n---- Result ----\n\n");
            string s = script.result;
            engine.print(Color.LightCyan, s);  
            writeln();

            if ((index >= 0) && (s != results[index]))
                error("Not expected result: " ~ results[index]);           
        }
        catch(ParserException e)
        {        
            with (e){            
                errors ~= index;
                //engine.print(Color.Green, source, true);            
                writeln();
                engine.print(Color.LightRed, "Index: " ~ to!string(index), true);
                writeln();
                engine.print(Color.LightRed, msg ~ " line: " ~ to!string(line) ~ " column: " ~ to!string(column));          
            } 
        }
        catch(Exception e) 
        {
            with(e){
                errors ~= index;
                //engine.print(Color.Green, source, true);
                writeln();
                engine.print(Color.LightRed, "Index: " ~ to!string(index), true);
                writeln();
                engine.print(Color.LightRed, msg, true);            
            }
        }
        writeln();
        index++;
    }

    engine.print(Color.LightRed, "Errors Count: " ~ to!string(errors.length), true);            
    writeln("Press enter to stop");
    readln();
}

/* export array
    int x = 0;   
    import std.stream;

    BufferedFile stream = new BufferedFile();
    stream.open("c:\\1.sard", FileMode.Out);
    while(x < results.length) 
    {
        stream.writeString("//=" ~results[x]);
        stream.writeString("\n" ~ sources[x] ~ "\n");
        if (x < (results.length-1))
            stream.writeString("\n");
        x++;
    }    
    stream.close();
    return;
*/