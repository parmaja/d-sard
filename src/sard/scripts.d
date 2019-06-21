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
import sard.objects;
import sard.parsers;
import sard;

/*-----------------------*/
/*     Script Lexer      */
/*-----------------------*/

class CodeLexer: Lexer
{
public:
    this(){
        super();
        with (symbols)
        {
        }
        with(controls)
        {
            add("", Ctl.None);////TODO i feel it is so bad
            add("", Ctl.Token);
            add("", Ctl.Operator);
            add("", Ctl.Start);
            add("", Ctl.Stop);
//            add("", Ctl.Declare);
//            add("", Ctl.Assign);
//            add("", Ctl.Let);

            add("(", Ctl.OpenParams);
            add("[", Ctl.OpenArray);
            add("{", Ctl.OpenBlock);
            add(")", Ctl.CloseParams);
            add("]", Ctl.CloseArray);
            add("}", Ctl.CloseBlock);
            add(";", Ctl.End);
            add(",", Ctl.Next);
            add(":", Ctl.Declare);
            add(":=", Ctl.Assign);
        }

        with (operators)
        {
            add(new OpPlus);
            add(new OpSub);
            add(new OpMultiply);
            add(new OpDivide);

            add(new OpEqual);
            add(new OpNotEqual);
            add(new OpAnd);
            add(new OpOr);
            add(new OpNot);

            add(new OpGreater);
            add(new OpLesser);

            add(new OpPower);
        }

        with (this)
        {
            add(new Whitespace_Tokenizer());
            add(new BlockComment_Tokenizer());
            add(new Comment_Tokenizer());
            add(new LineComment_Tokenizer());
            add(new Number_Tokenizer());
            add(new SQString_Tokenizer());
            add(new DQString_Tokenizer());
            add(new Escape_Tokenizer());
            add(new Control_Tokenizer());
            add(new Operator_Tokenizer()); //Register it after comment because comment take /*
            add(new Identifier_Tokenizer());//Sould be last one
        }
    }

    override bool isEOL(char vChar)
    {
        return sEOL.indexOf(vChar) >= 0;
    }

    override bool isWhiteSpace(char vChar, bool vOpen = true)
    {
        return sWhitespace.indexOf(vChar) >= 0;
    }

    override bool isControl(char vChar)
    {
        return controls.isOpenBy(vChar);
    }

    override bool isOperator(char vChar)
    {
        return operators.isOpenBy(vChar);
    }

    override bool isNumber(char vChar, bool vOpen = true)
    {
        bool r;
        if (vOpen)
            r = sNumberOpenChars.indexOf(vChar) >= 0;
        else
            r = sNumberChars.indexOf(vChar) >= 0;
        return r;
    }

    override bool isSymbol(char vChar)
    {
        return (sSymbolChars.indexOf(vChar) >= 0) || symbols.isOpenBy(vChar);
    }

    override bool isIdentifier(char vChar, bool vOpen = true)
    {
        return super.isIdentifier(vChar, vOpen); //we do not need to override it, but it is nice to see it here
    }
}

/*class ScriptScanner: Scanner
{
    this()
    {
        super();
        add(new PlainLexer());
        add(new CodeLexer());
    }
}*/


/**
*
*   Plain Lexer
*
*/


/**
*
*   Code Parser
*
*/

class CodeParser: Parser
{
protected:
    Ctl lastControl;

    override bool isKeyword(string identifier)
    {
        //example just for fun
        /*
        if (identifier == "begin")
        {
            setControl(Ctl.OpenBlock);
            return true;
        }
        if (identifier == "end")
        {
            setControl(Ctl.CloseBlock);
            return true;
        }
        else  */
        return false;
    }

    override void setToken(Token token)
    {
        //here is the magic, we must find it in tokens detector to check if this id is normal id or is control or operator
        //by default it is id
        if ((token.type != Type.Identifier) || (!isKeyword(token.value)))
        {

            /*
                We will send ; after } if we find a token
                    x:= {
                            ...
                        } <---------here not need to add ;
                    y := 10;
            */
            if (lastControl == Ctl.CloseBlock)
            {
                lastControl = Ctl.None;//prevent loop
                setControl(lexer.controls.getControl(Ctl.End));
            }
            current.addToken(token);
            doQueue();
            actions = [];
            lastControl = Ctl.Token;
        }
    }

    override void setOperator(Operator operator)
    {
        debug(log){
            writeln("SetOperator: " ~ operator.name);
        }
        Operator o = operator;
        if (o is null)
            error("SetOperator not Operator");
        current.addOperator(o);
        doQueue();
        actions = [];
        lastControl = Ctl.Operator;
    }

    override void setControl(Control control)
    {
        debug(log){
            writeln("SetControl: " ~ to!string(control));
        }

        if (lastControl == Ctl.CloseBlock) //see setToken
        {
            lastControl = Ctl.None;//prevent loop
            setControl(lexer.controls.getControl(Ctl.End));
        }

        current.addControl(control);
        doQueue();
        if (Action.Bypass in actions)//TODO check if Set work good here
            current.addControl(control);
        actions = [];
        lastControl = control.code;
    }

    override void setWhiteSpaces(string whitespaces){
        //nothing to do
    }

    override void afterPush()
    {
        super.afterPush();
        debug(log){
            writeln("push: " ~ current.classinfo.nakename);
        }
    }

    override void beforePop(){
        super.beforePop();
        debug(log){
            writeln("pop: " ~ current.classinfo.nakename);
        }
    }

    void doQueue()
    {
        if (Action.Pop in actions)
        {
            actions = actions - Action.Pop;
            pop();
        }

        if (nextCollector !is null) {
            push(nextCollector);
            nextCollector = null;
        }
    }

public:

    protected Lexer lexer;

    this(Lexer lexer, Statements statements)
    {
        super();
        this.lexer = lexer;
        if (statements is null)
            error("You should set Parser.statements!");
        push(new CollectorBlock(this, statements));
    }

    ~this(){
        pop();//pop the first push
    }

    override void start()
    {
        setControl(lexer.controls.getControl(Ctl.Start));
    }

    override void stop(){
        setControl(lexer.controls.getControl(Ctl.Stop));
    }
}

/**
*
*   Code Scanner
*
*/

class CodeScanner: Scanner
{
protected:
    Block_Node _block;
    CodeParser _parser;

public:
    this(Block_Node block)
    {
        super();
        _block = block;
        add(new CodeLexer());
     }

    override void doStart()
    {
        _parser = new CodeParser(lexer, _block.statements);

        lexer.parser = _parser;
        lexer.start();
    }

    override void doStop()
    {
        lexer.stop();
        lexer.parser = null;
        destroy(_parser);
    }
}

class OpenPreprocessor_Tokenizer: Tokenizer
{
protected:
    override void scan(const string text, int started, ref int column, ref bool resume)
    {
        int pos = column;
        column++;
        while (indexInStr(column, text) && (lexer.isWhiteSpace(text[column])))
            column++;

        lexer.parser.setWhiteSpaces(text[pos..column]);
        resume = false;
    }

    override bool accept(const string text, int column){
        return lexer.isWhiteSpace(text[column]);
    }
}

class PlainLexer: Lexer
{
    this()
    {
        with(controls)
        {
            add("<?", Ctl.OpenPreprocessor);
        }

        with(this)
        {
            add(new Whitespace_Tokenizer());
            add(new OpenPreprocessor_Tokenizer());
        }
    }

    override bool isEOL(char vChar)
    {
        return sEOL.indexOf(vChar) >= 0;
    }

    override bool isWhiteSpace(char vChar, bool vOpen = true)
    {
        return sWhitespace.indexOf(vChar) >= 0;
    }

    override bool isControl(char vChar)
    {
        return controls.isOpenBy(vChar);
    }

    override bool isOperator(char vChar)
    {
        return false;
    }

    override bool isNumber(char vChar, bool vOpen = true)
    {
        return false;
    }

    override bool isSymbol(char vChar)
    {
        return sSymbolChars.indexOf(vChar) >= 0;
    }
}

/**
*
*   Highlighter Lexer
*
*/

class HighlighterLexer: CodeLexer
{
    this(){
        super();
        trimSymbols = false;
    }
}

class Version_Const_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done){
        env.results.current.result.value = new Text_Node(sVersion);
        done = true;
    }
}

class PI_Const_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done){
        env.results.current.result.value = new Real_Node(PI);
        done = true;
    }
}

class Time_Const_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done){
        env.results.current.result.value = new Text_Node(Clock.currTime().toISOExtString());
        done = true;
    }
}

class Print_object_Node: Node
{
protected:
    override void doExecute(RunData data, RunEnv env, Operator operator, ref bool done){
        //env.results.current.result.value = new Text_Node(Clock.currTime().toISOExtString());
        auto v = env.stack.current.variables.find("s");
        if ((v !is null) && (v.value !is null)){
            writeln(v.value.asText);
            done = true;
        }
    }
}

class SardScript: BaseObject
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
        //main.name = "main";

        auto version_const = new Version_Const_Node();
        version_const.name = "version";
        main.declareObject(version_const);

        auto PI_const = new PI_Const_Node();
        PI_const.name = "PI";
        main.declareObject(PI_const);

        auto print_object = new Print_object_Node();
        print_object.name = "print";
        with (main.declareObject(print_object))
            defines.parameters.add("s", "string");

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
