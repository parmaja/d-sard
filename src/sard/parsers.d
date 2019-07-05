module sard.parsers;
/**
    This file is part of the "SARD"

    @license   The MIT License (MIT) Included in this distribution
    @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

/**
    Generate the runtime objects, it use the current Collector
*/

import std.stdio;
import std.conv;
import std.array;
import std.string;
import std.stdio;
import std.uni;
import std.datetime;

import sard.utils;
import sard.classes;
import sard.objects;
import sard.standards;

import minilib.sets;

/**---------------------------*/
/**        Controls
/**---------------------------*/

enum Ctl: int
{
    None = 0,
    Token,//* Token like Identifier, Keyword or Number
    Operator,//
    Start, //* Start parsing
    Stop, //* Stop parsing
    Declare, //* Declare a class of object

//    Let, //* Same as assign but make it as lexical scope, this variable will be seen from descent/child objects
    Assign, //* Assign to object/variable used as :=
    Next, //* End Params, Comma ,
    End, //* End Statement Semicolon ;
    OpenBlock, //* {
    CloseBlock, //* }
    OpenParams, //* (
    CloseParams, //* )
    OpenPreprocessor, //* <?
    ClosePreprocessor, //* ?>
    OpenArray, //* [
    CloseArray //* ]
}

//TokenType

enum Type : int
{
    None,
    Identifier,
    Number,
    Color,
    String,
    Escape, //Maybe Strings escape
    Comment
}

class SymbolicObject: BaseObject
{
    public bool IsSymbol;
}

/**
*   This will used in the tokenizer
*/

//TODO maybe struct not a class

class Control: SymbolicObject
{
    string name;
    Ctl code;
    int level;
    string description;

    this(){
        super();
    }

    this(string aName, Ctl aCode, string aDescription = "")
    {
        this();
        name = aName;
        code = aCode;
        description = aDescription;
    }
}

class Controls: NamedObjects!Control
{
    Control findControl(Ctl control)
    {
        Control result = null;
        foreach(itm; this) {
            if (control == itm.code) {
                result = itm;
                break;
            }
        }
        return result;
    }

    //getControl like find but raise exception
    Control getControl(Ctl control){
        if (count == 0)
            error("No controls is added" ~ to!string(control));
        Control result = findControl(control);
        if (!result)
            error("Control not found " ~ to!string(control));
        return result;
    }

    Control add(string name, Ctl code, string description = "")
    {
        Control c = new Control(name, code, description);
        super.add(c);
        return c;
    }
}

/**---------------------------*/
/**        Operators
/**---------------------------*/

enum Associative {Left, Right};

class Operator: SymbolicObject
{
public:
    string name; //Sign like + or -
    string title;
//    int precedence;//TODO it is bad idea, we need more intelligent way to define the power level of operators
    Associative associative;
    string description;

public:
    debug(log_nodes) {
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln("operator: " ~ name);
        }
    }
}

class Operators: NamedObjects!Operator
{
public:
    Operator findByTitle(string title)
    {
        foreach(itm; this)
        {
            if (icmp(title, itm.title) == 0)
            return itm;
        }
        return null;
    }
}

/**---------------------------*/
/**        Symbol
/**---------------------------*/

class Symbol: SymbolicObject
{
public:
    string name; //Sign like + or -

    this(string aName)
    {
        name = aName;
    }
}

class Symbols: NamedObjects!Symbol
{
public:
    Symbol add(string name)
    {
        Symbol c = new Symbol(name);
        super.add(c);
        return c;
    }
}

/**---------------------------*/
/**        Token
/**---------------------------*/

struct Token
{
public:
    Ctl control;
    int type;
    string value;

    @disable this();

    this(Ctl c, int t, string v)
    {
        type = t;
        value = v;
        control = c;
    }
}

/**---------------------------*/
/**        Tokenizer
/**---------------------------*/

/**
*
*   Small object scan one type of token
*
*/

class Tokenizer: BaseObject
{
private:
    Lexer _lexer;

    public @property Lexer lexer() {
        return _lexer;
    } ;

protected:
    //Return true if it done, next will auto detect it detect
    abstract void scan(const string text, int started, ref int column, ref bool resume);

    abstract bool accept(const string text, int column);
    //This function call when switched to it

    void switched() {
        //Maybe reseting buffer or something
    }

public:

    this(){
        super();
    }
}

/**---------------------------*/
/**        Lexer
/**---------------------------*/

class Lexer: Objects!Tokenizer {

private:

protected:
    Scanner _scanner;
    public @property Scanner scanner() { return _scanner; } ;

    Tokenizer _current; //current tokenizer
    public @property Tokenizer current() { return _current; } ;

    Symbols _symbols;
    @property public Symbols symbols() { return _symbols; }

    Controls _controls;
    @property public Controls controls() { return _controls; }

    Operators _operators;
    @property public Operators operators () { return _operators; }

    Parser _parser;
    public @property Parser parser() { return _parser; };
    public @property Parser parser(Parser value) { return _parser = value; }

protected:

    Tokenizer detectTokenizer(const string text, int column)
    {
        Tokenizer result = null;
        if (column >= text.length)  // compare > in pascal
        {
            //do i need to switchTokenizer?
            //return null; //no tokenizer for empty line or EOL
            //result = null; nothing to do already nil
        }
        else
        {
            foreach(itm; this)
            {
                if (itm.accept(text, column))
                {
                    result = itm;
                    break;
                }
            }

            if (result is null)
                error("Tokenizer not found: " ~ text[column]);
        }
        switchTokenizer(result);
        return result;
    }

    void switchTokenizer(Tokenizer nextTokenizer)
    {
        if (_current != nextTokenizer)
        {
            _current = nextTokenizer;
            if (_current !is null)
                _current.switched();
        }
    }

    Tokenizer findClass(const ClassInfo tokenizerClass)
    {
        int i = 0;
        foreach(itm; this) {
            if (itm.classinfo == tokenizerClass) {
                return itm;
            }
            i++;
        }
        return null;
    }

    //This find the class and switch to it
    Tokenizer selectTokenizer(ClassInfo tokenizerClass)
    {
        Tokenizer t = findClass(tokenizerClass);
        if (t is null)
            error("Tokenizer not found");
        switchTokenizer(t);
        return t;
    }

public:
    override void beforeAdd(Tokenizer tokenizer)
    {
        super.beforeAdd(tokenizer);
        tokenizer._lexer = this;
    }

    this(){
        super();
        _symbols = new Symbols();
        _controls = new Controls();
        _operators = new Operators();
    }

    ~this(){
        destroy(_symbols);
        destroy(_controls);
        destroy(_operators);
    }

    bool trimSymbols = true; //ommit send open and close tags when setToken

    abstract bool isEOL(char vChar);
    abstract bool isWhiteSpace(char vChar, bool vOpen= true);
    abstract bool isSymbol(char vChar);
    abstract bool isControl(char vChar);
    abstract bool isOperator(char vChar);
    abstract bool isNumber(char vChar, bool vOpen = true);

    bool isKeyword(string keyword){
        return false;
    }

    bool isIdentifier(char vChar, bool vOpen = true)
    {
        bool r = !isWhiteSpace(vChar) && !isControl(vChar) && !isOperator(vChar) &&!isSymbol(vChar);
        if (vOpen)
            r = r && !isNumber(vChar, vOpen);
        return r;
    }

    final void scanLine(const string text, const int line, ref int column)
    {
        int len = text.length;
        bool resume = false;
        while (column < len) //use <= in pascal
        {
            int oldColumn = column;
            Tokenizer oldTokenizer = current;
            try
            {
                if (current is null) //resume the line to current/last tokenizer
                    detectTokenizer(text, column);
                else
                    resume = true;

                current.scan(text, column, column, resume);

                if (!resume)
                    switchTokenizer(null);

                if ((oldColumn == column) && (oldTokenizer == _current))
                    error("Feeder in loop with: " ~ _current.classinfo.nakename); //TODO: be careful here
            }
            catch(Exception e) {
                throw new ParserException(e.msg, line, column);
            }
        }
    }

    void start(){
        if (parser is null)
            error("Parser should be not null");
        parser.start();
    }

    void stop(){
        parser.stop();
    }
}

enum Action
{
    Pop, //Pop the current Collector
    Pass  //resend the control char to the next Collector
}

alias Set!Action Actions;

/**
*    @class Instruction
*/

/**
*    @class Collector
*    list if controller
*/

abstract class Collector: BaseObject
{
private:

protected:
    Controller controller;

    Parser _parser;
    public @property Parser parser() { return _parser; };

    void internalPost(){  
    }

    Controller createController() {
        return null;
    }

public:

    this(){
        debug(log_compile) writeln("new collecter");
    }

    this(Parser aParser)
    {
        this();
        _parser = aParser;
        controller = createController();
        reset();
    }

    ~this(){
        destroy(controller);
        debug(log_compile) writeln("kill collecter");
    }

    //IsInitial: check if the next object will be the first one, usefule for Assign and Declare
    @property bool isInitial()
    {
        return false;
    }

    abstract void reset();

    protected abstract void doToken(Token token);

    protected abstract void doControl(Control control);

    final void setToken(Token token){
        doToken(token);
    }

    final void setControl(Control control){
        doControl(control);
        if (!(controller is null))
            controller.setControl(control);
    }
}

/**
*    @class Controller
*/

abstract class Controller: BaseObject
{
protected:
    Collector collector;

public:
    this(Collector aCollector){
        super();
        collector = aCollector;
    }

    abstract void setControl(Control control);
}

/**
*    @class Parser
*
*/

class Parser: Stack!Collector
{
protected:
    Actions actions;
    Collector nextCollector;

    bool isKeyword(string identifier){
        return false;
    }

public:
    void setToken(Token token){
    }

    void setControl(Control control){
    }

    void setOperator(Operator operator){
    }

    void setWhiteSpaces(string whitespaces){
    }

    void start(){
        if (current is null)
            error("At last you need one collector pushed");
    }

    void stop(){
    }

    //No pop, but when finish Parser will pop it
    void setAction(Actions aActions = [], Collector aNextCollector = null)
    {
        actions = aActions;
        nextCollector = aNextCollector;
    }

}

/**---------------------------*/
/**        Scanner
/**---------------------------*/

class Scanner: Objects!Lexer
{
private:
    bool _active;
    public @property bool active() { return _active; }

    string _ver;
    public @property string ver() { return _ver; }

    string _charset;
    public @property string charset() { return _charset; }

    //TODO: use env to wrap the code inside <?sard ... ?>,
    //the current one must detect ?> to stop scanning and pop
    //but the other lexer will throw none code to output provider

    int _line;
    public @property int line() { return _line; };


protected:
    Parser _parser;
    public @property Parser parser() { return _parser; }

    Lexer current; //current lexer

protected:
    override void beforeAdd(Lexer lexer)
    {
        super.beforeAdd(lexer);
        lexer._scanner = this;
    }

    void doStart() {
    }

    void doStop() {
    }

    abstract Parser createParser();

public:
    this()
    {
        super();
    }

    ~this(){
    }

public:

    void scanLine(const string text, const int line)
    {
        if (!active)
            error("Should be started first");

        _line = line;
        int column = 0;
        //int column = 1; when convert to pascal
        current.scanLine(text, line, column);
    }

    void scan(const string[] lines)
    {
        start();
        int i = 0;
        while(i < lines.count())
        {
            scanLine(lines[i] ~ "\n", i + 1);//TODO i hate to add \n it must be included in the lines itself
            i++;
        }
        stop();
    }

    /*void scan(InputStream stream)
    {
        char[] line;
        start();
        int i = 0;
        while (stream.eof) {
            line = stream.readLine(); //TODO readLineW
            scanLine(to!string(line), i);
            i++;
        }
        stop();
    }
*/
    void scan(const string text)
    {
        string[] lines = text.split("\n");
        scan(lines);
    }

/*    void scanFile(string filename)
    {
        BufferedFile stream = new BufferedFile(filename);
        scope(exit) destroy(stream);

        try {
            scanStream(stream);
        }
        finally {
            stream.close();
        }
    }*/
    void scanFile(string filename)
    {
        auto file = File(filename, "r");
        auto lines = file.byLine();
        start();
        int i = 0;
        foreach(char[] line; lines)
        {
            line = line ~  "\n";
            scanLine(to!string(line) , i); //TODO i hate to add \n it must be included in the lines itself
            i++;
        }
        stop();
    }

/*   void scanStream(Stream stream)
    {
        scan(stream);
    }
*/
    void start()
    {
        if (_active)
            error("Already opened");
        if (count == 0)
            error("There is no lexers added");

        _active = true;
        current = this[0]; //First one
        _parser = createParser();
        current.parser = _parser;
        current.start();
        doStart();
    }

    void stop()
    {
        if (!_active)
            error("Already closed");
        doStop();
        current.stop();
        current.parser = null;
        destroy(_parser);
        current = null;
        _active = false;
    }
}
