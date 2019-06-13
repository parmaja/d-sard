module sard.lexers;
/**
* This file is part of the "SARD"
*
* @license   The MIT License (MIT) Included in this distribution
* @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

import std.stdio;
import std.string;
import std.conv;
import std.uni;
import std.array;
import std.range;
import std.file;

import sard.classes;
import sard.utils;

/**---------------------------*/
/**        Controls
/**---------------------------*/

enum Control: int
{
    None = 0,
    Token,//* Token like Identifier, Keyword or Number, not used in fact
    Operator,// *also not used
    Start, //* Start parsing
    Stop, //* Stop parsing
    Declare, //* Declare a class of object

    Let, //* Assign object reference
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

/**
*   This will used in the tracker
*/

//TODO maybe struct not a class

class CtlControl: BaseObject
{
    string name;
    Control code;
    int level;
    string description;

    this(){
        super();
    }

    this(string aName, Control aCode)
    {
        this();
        name = aName;
        code = aCode;
    }
}

class CtlControls: NamedObjects!CtlControl
{
    CtlControl findControl(Control control)
    {
        CtlControl result = null;
        foreach(itm; this) {
            if (control == itm.code) {
                result = itm;
                break;
            }
        }
        return result;
    }

    //getControl like find but raise exception
    CtlControl getControl(Control control){
        if (count == 0)
            error("No controls is added" ~ to!string(control));
        CtlControl result = findControl(control);
        if (!result)
            error("Control not found " ~ to!string(control));
        return result;
    }

    CtlControl add(string name, Control code)
    {
        CtlControl c = new CtlControl(name, code);
        super.add(c);
        return c;
    }
}

/**---------------------------*/
/**        Operators
/**---------------------------*/

enum Associative {Left, Right};

class Operator: BaseObject
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
/**        Token
/**---------------------------*/

struct Token
{
public:
    Control control;
    int type;
    string value;

    @disable this();

    this(Control c, int t, string v)
    {
        type = t;
        value = v;
        control = c;
    }
}

/**---------------------------*/
/**        IParser
/**---------------------------*/

interface IParser
{
protected:
    //isKeyword call in setToken if you proceesed it return false
    //You can proceess as to setControl or setOperator
    bool isKeyword(string identifier);

public:
    abstract void setToken(Token token);
    abstract void setControl(CtlControl control);
    abstract void setOperator(Operator operator);
    abstract void setWhiteSpaces(string whitespaces);

    abstract void start();
    abstract void stop();
};

/**---------------------------*/
/**        Tracker
/**---------------------------*/

/**
*
*   Small object scan one type of token
*
*/

class Tracker: BaseObject
{
private:
    Lexer _lexer;

    public @property Lexer lexer() {
        return _lexer;
    } ;

protected:
    //Return true if it done, next will auto detect it detect
    abstract void scan(const string text, ref int column, ref bool resume);

    bool accept(const string text, int column){
        return false;
    }
    //This function call when switched to it

    void switched() {
        //Maybe reseting buffer or something
    }

public:

    void setLexer(Lexer lexer) { //todo maybe rename to opCall
        _lexer = lexer;
    }

    this(){
        super();
    }

    this(Lexer lexer){
        this();
        setLexer(lexer);
    }
}

/**---------------------------*/
/**        Lexer
/**---------------------------*/

class Lexer: Objects!Tracker {

private:

protected:
    Scanner _scanner;
    public @property Scanner scanner() { return _scanner; } ;

    Tracker _current; //current tracker
    public @property Tracker current() { return _current; } ;

    Operators _operators;
    @property public Operators operators () { return _operators; }

    CtlControls _controls;
    @property public CtlControls controls() { return _controls; }

    IParser _parser;
    public @property IParser parser() { return _parser; };
    public @property IParser parser(IParser value) { return _parser = value; }

protected:

    Tracker detectTracker(const string text, int column)
    {
        Tracker result = null;
        if (column >= text.length) {
            //do i need to switchTracker?
            //return null; //no tracker for empty line or EOL
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
                error("Tracker not found: " ~ text[column]);
        }
        switchTracker(result);
        return result;
    }

    void switchTracker(Tracker nextTracker)
    {
        if (_current != nextTracker)
        {
            _current = nextTracker;
            if (_current !is null)
                _current.switched();
        }
    }

    Tracker findClass(const ClassInfo trackerClass)
    {
        int i = 0;
        foreach(itm; this) {
            if (itm.classinfo == trackerClass) {
                return itm;
            }
            i++;
        }
        return null;
    }

    //This find the class and switch to it
    Tracker selectTracker(ClassInfo trackerClass)
    {
        Tracker t = findClass(trackerClass);
        if (t is null)
            error("Tracker not found");
        switchTracker(t);
        return t;
    }

public:
    override void beforeAdd(Tracker tracker)
    {
        super.beforeAdd(tracker);
        tracker._lexer = this;
    }

    this(){
        super();
        _operators = new Operators();
        _controls = new CtlControls();
    }

    ~this(){
        destroy(_operators);
        destroy(_controls);
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
        while (column < len)
        {
            int oldColumn = column;
            Tracker oldTracker = current;
            try
            {
                if (current is null) //resume the line to current/last tracker
                    detectTracker(text, column);
                else
                    resume = true;

                current.scan(text, column, resume);

                if (!resume)
                    switchTracker(null);

                if ((oldColumn == column) && (oldTracker == _current))
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
        lexer.scanLine(text, line, column);
    }

    void scan(const string[] lines)
    {
        start();
        int i = 0;
        while(i < lines.count())
        {
            scanLine(lines[i] ~ "\n", i);//TODO i hate to add \n it must be included in the lines itself
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
