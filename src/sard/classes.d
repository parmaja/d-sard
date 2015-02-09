module sard.classes;
/**
* This file is part of the "SARD"
* 
* @license   The MIT License (MIT) Included in this distribution            
* @author    Zaher Dirkey <zaher at yahoo dot com>
*/

import std.stdio;
import std.string;
import std.conv;
import std.stream;
import std.uni;
import std.array;
import std.range;
import sard.utils;

/**
*
*   Exception
*
*/

class CodeException: Exception 
{
    private uint _code;
    @property uint code() { return _code; }

public:
    this(string msg, int code = -1) {
        _code = code;
        super(msg);
    }
}

class ParserException: Exception 
{
    private int _line;
    private int _column;

    @property {
        int line() {
            return _line;
        }

        int column() {
            return _column;
        }
    }

    this(string msg, int line, int column ) {
        _line = line;
        _column = column;
        super(msg);
    }
}

void error(string err, int code = -1) 
{
    throw new CodeException(err, code);
}

/**
*
*   Base classes
*
*/

class BaseObject: Object 
{
protected:

public:

    debug(log_nodes) {
        /*void printTree(){   
        auto a = [__traits(allMembers, typeof(this))];
        foreach (member; a) 
        {
        writeln(member);
        }
        writeln();
        }*/

        debug(log_nodes) void debugWrite(int level){
            writeln(stringRepeat(" ", level * 2) ~ this.classinfo.nakename);
        }
    }

    this(){
    }
}

//class Objects(T): BaseObject if(is(T: SomeObject)) {
//class Objects(T: BaseObject): BaseObject 
class Objects(T): BaseObject 
{
private:
    T[] _items;//TODO hash string list for namedobjects    
    bool _owned;

public:
    alias items = this;

protected:
    T getItem(int index) {

        return _items[index];
    }

    void beforeAdd(T object){
    }

    void afterAdd(T object){
        debug(log) {
            //writeln(this.classinfo.nakename ~ ".add(" ~ object.classinfo.nakename ~ ")");
        }
    }

public:

    int add(T object) 
    {
        beforeAdd(object);
        _items = _items  ~ object;            
        afterAdd(object);
        return _items.length - 1;
    }

    T opIndex(size_t index) {
        return getItem(index);
    }

    @property int count(){
        return _items.length;
    }

    @property bool empty(){
        return _items.length == 0;
    }

    @property T first(){
        if (_items.length == 0)
            return null;
        else
            return _items[0];
    }

    int opApply(int delegate(T) dg) 
    {            
        foreach(e; _items)
        {
            int b = dg(e);
            if (b)
                return b;                  
        }
        return 0;                  
    }

    @property T last()
    {
        if (_items.length == 0)
            return null;
        else
            return _items[_items.length - 1];
    }

    this(bool owned = true){
        _owned = owned;
        super();
    }

    ~this(){
        if (_owned)
        {
            clear();
        }
    }

    void clear()
    {
        int i = 0;
        while (i < _items.length){
            destroy(_items[i]);
            _items[i] = null;
            i++;
        }
        _items = null;
    }

    debug(log_nodes) {
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln(stringRepeat(" ", level * 2) ~ "Count: " ~ to!string(count));
            foreach(e; items) {
                e.debugWrite(level + 1);
            }
        }
    }
}

class NamedObjects(T: BaseObject): Objects!T
{
public:
    T find(const string name) 
    {            
        T result = null;            
        foreach(e; items) {
            if (icmp(name, e.name) == 0) {
                result = e;
                break;
            }
        }
        return result;
    }

    bool isOpenBy(const char c)
    {
        foreach(o; items){      
            if (!o.name.empty && (o.name[0] == toLower(c)))
                return true;          
        }
        return false;
    }

    T scan(string text, int index)
    {
        T result = null;
        int max = 0;        
        foreach(e; items) 
        {
            if (scanCompare(e.name, text, index))
            {
                if (max < e.name.length) 
                {
                    max = e.name.length;
                    result = e;
                }
            }
        }
        return result;
    }
}

/**
*
*  Stack
*
*/

class Stack(T): BaseObject 
{    
protected:
    bool own = true; //free if when remove it

    static class StackItem: BaseObject {
        protected {
            T object; 
            StackItem parent;
        }

        public {
            Stack owner;
            int level;
        }
    }

private:
    int _count;
    StackItem _currentItem; 

public:
    @property int count() { return _count; }
    @property StackItem currentItem() { return _currentItem; }     

protected:
    T getParent() {
        if (_currentItem is null)
            return null;
        else if (_currentItem.parent is null)
            return null;
        else
            return _currentItem.parent.object;
    }

    T getCurrent() 
    {
        if (currentItem is null)
            return null;
        else
            return currentItem.object;
    }

    public @property T current() { return getCurrent(); }
    public @property T parent() { return getParent(); }

    void afterPush() {
        debug(log) {
            writeln("push: " ~ T.classinfo.nakename);
        }
    };

    void beforePop() {
        debug(log){
            writeln("pop: " ~ T.classinfo.nakename);
        }
    };

public:
    bool isEmpty() {
        return currentItem is null;
    }

    void push(T aObject) 
    {
        StackItem aItem;

        if (aObject is null)
            error("Can't push null");

        aItem = new StackItem();
        aItem.object = aObject;
        aItem.parent = _currentItem;
        aItem.owner = this;
        if (_currentItem is null)
            aItem.level = 0;
        else
            aItem.level = _currentItem.level + 1;
        _currentItem = aItem;
        _count++;
        afterPush();
    }

    T push(){
        T o = new T();
        push(o);
        return o;
    }

    T peek(){
        if (currentItem is null)
            return null;
        else
            return currentItem.object;
    }

    T pull(){
        if (currentItem is null)
            error("Stack is empty");
        beforePop();
        T object = currentItem.object;
        StackItem aItem = currentItem;
        _currentItem = aItem.parent;
        _count--;
        destroy(aItem);
        return object;
    }

    void pop()
    {
        T object = pull();
        if (own)
            destroy(object);            
    }

    void clear(){
        while (current is null)        
            pop();
    }
    
    this(){
        super();
    }

    ~this(){
        if (own)
            clear();
    }
}

enum Control: int
{
    None = 0,
    Token,//Token like Identifier, Keyword or Number, not used in fact    
    Operator,//also not used 
    Start, //Start parsing
    Stop, //Start parsing
    Declare, //Declare a class of object
    Assign, //Assign to object/variable used as :=
    Let, //Assign object reference
    Next, //End Params, Comma
    End, //End Statement Semicolon
    OpenBlock, // {
    CloseBlock, // }
    OpenParams, // (
    CloseParams, // )
    OpenPreprocessor, // <?
    ClosePreprocessor, // ?>
    OpenArray, // [
    CloseArray // ]
}

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

interface IParser 
{
protected:
    //isKeyword call in setToken if you proceesed it return false
    //You can proceess as to setControl or setOperator
    bool isKeyword(string identifier);

public:
    abstract void setToken(Token token);    
    abstract void setControl(CtlControl control);
    abstract void setOperator(OpOperator operator);
    abstract void setWhiteSpaces(string whitespaces);

    abstract void start();
    abstract void stop();
};

/**
*
*   Tracker
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

    void set(Lexer lexer) { //todo maybe rename to opCall
        _lexer = lexer;
    }

    this(){
        super();
    }

    this(Lexer lexer){ 
        this();
        set(lexer);
    }
}

class Lexer: Objects!Tracker{

private:

protected:
    Scanner _scanner;
    public @property Scanner scanner() { return _scanner; } ;      

    Tracker _current; //current tracker
    public @property Tracker current() { return _current; } ;      

    OpOperators _operators;
    @property public OpOperators operators () { return _operators; }
    CtlControls _controls;
    @property public CtlControls controls() { return _controls; }    

    IParser _parser;    
    public @property IParser parser() { return _parser; };
    public @property IParser parser(IParser  value) { return _parser = value; }    

protected:

    Tracker detectTracker(const string text, int column) 
{
    Tracker result = null;
    if (column >= text.length)
        //do i need to switchTracker?
        //return null; //no tracker for empty line or EOL
        result = null;
    else 
    {
        foreach(e; items)
        {
            if (e.accept(text, column)) 
            {
                result = e;
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
        foreach(t; items) {
            if (t.classinfo == trackerClass) {
                return t;
            }
            i++;
        }
        return null;
    }

    //This find the class and switch to it
    void selectTracker(ClassInfo trackerClass) 
    {
        Tracker t = findClass(trackerClass);
        if (t is null)
            error("Tracker not found");
        switchTracker(t);
    }

public:
    override void beforeAdd(Tracker tracker)
    {
        super.beforeAdd(tracker);
        tracker._lexer = this;      
    }

    this(){
        super();
        _operators = new OpOperators();
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
            Tracker oldTracker = _current;
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

/**
*
*   Scanner
*   Base class 
*
*/

class Scanner: Objects!Lexer
{
private:
    bool _active;
    string _ver;
    string _charset;

    public @property bool active() { return _active; }
    public @property string ver() { return _ver; }
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

        int _line = line;
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

    void scan(InputStream stream)
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

    void scan(const string text)
    {      
        string[] lines = text.split("\n");      
        scan(lines);
    }

    void scanFile(string filename)
    {
        BufferedFile stream = new BufferedFile(filename);
        scope(exit) destroy(stream);

        try {
            scanStream(stream);
        } 
        finally {
            stream.close();
        }
    }

    void scanStream(Stream stream)
    {        
        scan(stream);
    }

    void start()
    {
        if (_active)
            error("Already opened");
        _active = true;
        lexer = items[0];
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

/*---------------------------*/
/*        Controls           */
/*---------------------------*/

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

/* Controls */

class CtlControls: NamedObjects!CtlControl
{
    CtlControl findControl(Control control)
    {
        CtlControl result = null;            
        foreach(e; items) {
            if (control == e.code) {
                result = e;
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

/*---------------------------*/
/*        Operators          */
/*---------------------------*/

enum Associative {Left, Right};

class OpOperator: BaseObject
{
public:
    string name; //Sign like + or -
    string title;
    int precedence;//TODO it is bad idea, we need more intelligent way to define the power level of operators
    Associative associative;
    string description;

public:
    debug(log_nodes) {
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln(stringRepeat(" ", precedence * 2) ~ "operator: " ~ name);        
        }
    }
}

/* Operators */

class OpOperators: NamedObjects!OpOperator
{
public:
    OpOperator findByTitle(string title)
    {
        foreach(o; items)
        {
            if (icmp(title, o.title) == 0) 
            return o;
        }
        return null;
    }
}

enum Color 
{   
    None,
    Default,
    Black,
    Red, 
    Green,
    Blue, 
    Cyan, 
    Magenta,
    Yellow, 
    Gray,  
    LightRed, 
    LightGreen,
    LightBlue,
    LightCyan, 
    LightMagenta,
    LightYellow, 
    LightGray,
    White
}
 
private static Engine _engine;

class Engine
{
    abstract void print(Color color, string text, bool eol = true);

    void print(string text, bool eol = true){
        print(Color.Default, text, eol);
    }

    debug void log(string text){
        print(Color.Default, text);
    }

    this(){
    }
}

public static void setEngine(Engine newEngine)
{
    if (_engine !is null)
        destroy(_engine);
    _engine = newEngine;
}

@property public static Engine engine()
{
    if (_engine is null) {
        error("Engine not set! set it in the main().");
    }
    return _engine;
}