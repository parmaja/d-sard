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

    this(string aName, Ctl aCode)
    {
        this();
        name = aName;
        code = aCode;
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

    Control add(string name, Ctl code)
    {
        Control c = new Control(name, code);
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
        parser.start();
    }

    void stop(){
        parser.stop();
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
    Lexer lexer; //current lexer

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
        lexer.scanLine(text, line, column);
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
        lexer = this[0]; //First one
        doStart();
    }

    void stop()
    {
        if (!_active)
            error("Already closed");
        doStop();
        lexer = null;
        _active = false;
    }
}


class Script: BaseObject{

}

enum Action 
{
    Pop, //Pop the current Collector
    Bypass  //resend the control char to the next Collector
}

alias Set!Action Actions;

/**
*    @class Instruction
*/

struct Instruction
{
public:

protected:
    void internalSetObject(Node aObject)
    {
        if ((object !is null) && (aObject !is null))
            error("Object is already set");
        object = aObject;
    }

public:

    string identifier;
    Operator operator;
    Node object;

    //Return true if Identifier is not empty and object is nil
    bool checkIdentifier(in bool raise = false)
    {
        bool r = identifier != "";
        if (raise && !r)
            error("Identifier is not set!");
        r = r && (object is null);
        if (raise && !r) 
            error("Object is already set!");
        return r;
    }

    //Return true if Object is not nil and Identifier is empty
    bool checkObject(in bool raise = false)
    {
        bool r = object !is null;
        if (raise && !r)
            error("Object is not set!");
        r = r && (identifier == "");
        if (raise && !r)
            error("Identifier is already set!");
        return r;
    }

    //Return true if Operator is not nil
    bool CheckOperator(in bool raise = false)
    {
        bool r = operator !is null;
        if (raise && !r)
            error("Operator is not set!");
        return r;
    }

    @property bool isEmpty() 
    {
        return !((identifier != "") || (object !is null) || (operator !is null));
        //TODO and attributes
    }

    void setOperator(Operator aOperator)
    {
        if (operator !is null)
            error("Operator is already set");
        operator = aOperator;
    }

    void setIdentifier(string aIdentifier)
    {
        if (identifier != "")
            error("Identifier is already set to " ~ identifier);
        identifier = aIdentifier;
    }

    Number_Node setNumber(string aIdentifier)
    {
        if (identifier != "")
            error("Identifier is already set to " ~ identifier);
        //TODO need to check object too
        Number_Node result;
        if ((aIdentifier.indexOf(".") >= 0) || ((aIdentifier.indexOf("E") >= 0)))
            result = new Real_Node(to!float(aIdentifier));
        else 
            result = new Integer_Node(to!int(aIdentifier));

        internalSetObject(result);
        return result;
    }

    Text_Node setText(string text)
    {
        /*if (identifier != "")
            error("Identifier is already set");*/
        //TODO need review

        Text_Node result;
        if (object is null) {
            result = new Text_Node(text);
            internalSetObject(result);
        }
        else {
            result = cast(Text_Node)object;
            if (result is null)
                error("Object is already exist when setting string!");
            result.value = result.value ~ text;
        }
        return result;
    }

    Comment_Node setComment(string aIdentifier)
    {
        //We need to check if it the first expr in the statment
        if (identifier != "")
            error("Identifier is already set");
        //TODO need to check object too
        Comment_Node result = new Comment_Node();
        result.value = aIdentifier;
        internalSetObject(result);
        return result;
    }

    void setObject(Node aObject)
    {
        if (identifier != "")
            error("Identifier is already set");
        internalSetObject(aObject);  
    }  

    Instance_Node setInstance(string aIdentifier)
    {
        if (identifier == "")
            error("Identifier is already set");
        Instance_Node result = new Instance_Node();
        result.name = aIdentifier;
        internalSetObject(result);
        return result;
    }

    Instance_Node setInstance()
    {
        if (identifier == "")
            error("Identifier is not set");
        Instance_Node result = setInstance(identifier);
        identifier = "";	  
        return result;
    }

    Enclose_Node setEnclose()
    { 
        if (identifier != "")
            error("Identifier is already set");
        Enclose_Node result = new Enclose_Node();
        internalSetObject(result);
        return result;
    }

    Assign_Node setAssign()
    {
        //Do not check the Identifier if empty, becuase it is can be empty to assign to result of block
        Assign_Node result = new Assign_Node();
        result.name = identifier;    
        internalSetObject(result);
        identifier = "";
        return result;
    }

    Declare_Node setDeclare()
    {
        if (identifier == "")
            error("identifier is not set");
        Declare_Node result = new Declare_Node();
        result.name = identifier;    
        internalSetObject(result);
        identifier = "";
        return result;
    }
}

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

    abstract Controller createController();

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

    abstract void reset();

    abstract void prepare();

    abstract void next();

    abstract void post();

    abstract void addToken(Token token);

    //IsInitial: check if the next object will be the first one, usefule for Assign and Declare
    @property bool isInitial()
    {
        return false;
    }

    void addControl(Control control){
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

