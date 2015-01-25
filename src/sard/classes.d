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
import std.uni;
import std.array;
import std.range;
import sard.utils;

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

class BaseObject: Object 
{
protected:
    void initialize(){
    }

    void finalize(){
    }

    void created() {
    };

public:

    debug{
        /*void printTree(){   
        auto a = [__traits(allMembers, typeof(this))];
        foreach (member; a) 
        {
        writeln(member);
        }
        writeln();
        }*/


        void debugWrite(int level){
            writeln(stringRepeat(" ", level * 2) ~ this.classinfo.nakename);
        }
    }

    this(){
        created(); 
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
        debug{
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

    debug{
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
            if (o.name[0] == toLower(c))
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
        debug{
//            writeln("push: " ~ T.classinfo.nakename);
        }
    };

    void beforePop() {
        debug{
            //writeln("pop: " ~ T.classinfo.nakename);
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
        //clear();
    }
}

//TokenType
enum Type 
{
    None, 
    Identifier, 
    Number, 
    Color, 
    String, 
    Comment 
}

enum Control
{
    None,
    Object,//Token like Identifier or Number, not used in fact    
    Operator,//also not used 
    Start, //Start parsing
    Stop, //Start parsing
    Declare, //Declare a class of object
    Assign, //Assign to object/variable used as :=
    //Let, //Same as assign in the initial but is equal operator if not in initial statement used to be =
    Next, //End Params, Comma
    End, //End Statement Semicolon
    OpenBlock, // {
    CloseBlock, // }
    OpenParams, // (
    CloseParams, // )
    OpenArray, // [
    CloseArray // ]
}

interface IParser 
{
protected:
    abstract void start();
    abstract void stop();    

public:
    abstract void setToken(string aToken, Type aType);
    abstract void setControl(Control aControl);
    abstract void setOperator(OpOperator operator);
    abstract void setWhiteSpaces(string whitespaces);

public:
};

class Scanner: BaseObject 
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

class Scanners: Objects!Scanner{  

private:
    Lexer _lexer;

public:
    override void beforeAdd(Scanner scanner)
    {
        super.beforeAdd(scanner);
        scanner._lexer = _lexer;      
    }

    this(Lexer aLexer){
        _lexer = aLexer;
        super();
    }
}

class Lexer: BaseObject
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

    IParser _parser;    
    public @property IParser  parser() { return _parser; };
    public @property IParser  parser(IParser  value) { return _parser = value; }    

    Scanner _current; //current scanner
    public @property Scanner current() { return _current; } ;      

    Scanners _scanners;
    public @property Scanners scanners() { return _scanners; } ;  

    OpOperators _operators;
    @property public OpOperators operators () { return _operators; }
    CtlControls _controls;
    @property public CtlControls controls() { return _controls; }    

protected:

    //doIdentifier call in setToken if you proceesed it return false
    //You can proceess as to setControl or setOperator
    bool doIdentifier(string identifier){
        return false;
    }

    void doStart() {
        setControl(Control.Start);
    }

    void doStop() {
        setControl(Control.Stop);
    }

public:

    final void setToken(string aToken, Type aType)
    {
        //here is the magic, we must find it in tokens detector to check if this id is normal id or is control or operator
        //by default it is id
        if ((aType != Type.Identifier) || (!doIdentifier(aToken)))
            parser.setToken(aToken, aType);
    }

    final void setControl(Control aControl){
        parser.setControl(aControl);
    }

    final void setOperator(OpOperator operator){
        parser.setOperator(operator);
    }
    
    final void setWhiteSpaces(string whitespaces){
        parser.setWhiteSpaces(whitespaces);
    }


public:
    this()
    {
        _scanners = new Scanners(this);
        _operators = new OpOperators();
        _controls = new CtlControls();
        super();
    }

    ~this(){
        destroy(_scanners);
        destroy(_operators);
        destroy(_controls);
    }

    abstract bool isEOL(char vChar);
    abstract bool isWhiteSpace(char vChar, bool vOpen= true);
    abstract bool isControl(char vChar);
    abstract bool isOperator(char vChar);
    abstract bool isNumber(char vChar, bool vOpen = true);

    bool isIdentifier(char vChar, bool vOpen = true)
    {
        bool r = !isWhiteSpace(vChar) && !isControl(vChar) && !isOperator(vChar);
        if (vOpen)
            r = r && !isNumber(vChar, vOpen);
        return r;
    }

public:

    Scanner detectScanner(const string text, int column) 
    {
        Scanner result = null;
        if (column >= text.length)
        //do i need to switchScanner?
        //return null; //no scanner for empty line or EOL
        result = null;
        else 
        {
        foreach(e; scanners)                    
        {
            if (e.accept(text, column)) 
            {
                result = e;
                break;
            }
        }

        if (result is null)
            error("Scanner not found: " ~ text[column]);
        }
        switchScanner(result);
        return result;
    }

    void switchScanner(Scanner nextScanner) 
    {
        if (_current != nextScanner) 
        {
            _current = nextScanner;
            if (_current !is null)
                _current.switched();
        }
    }

    Scanner findClass(const ClassInfo scannerClass) 
    {
        int i = 0;
        foreach(scanner; scanners) {
            if (scanner.classinfo == scannerClass) {
                return scanner;
            }
            i++;
        }
        return null;
    }

    //This find the class and switch to it
    void SelectScanner(ClassInfo scannerClass) 
    {
        Scanner aScanner = findClass(scannerClass);
        if (aScanner is null)
            error("Scanner not found");
        switchScanner(aScanner);
    }

    void scanLine(const string text, const int line) 
    {
        if (!active)
            error("Feeder not started");
        int _line = line;
        int column = 0; 
        int len = text.length;
        bool resume = false;
        while (column < len)
        {
            int oldColumn = column;
            Scanner oldScanner = _current;
            try 
            {
                if (current is null) //resume the line to current/last scanner
                    detectScanner(text, column);
                else
                    resume = true;

                current.scan(text, column, resume);
                
                if (!resume)
                    switchScanner(null);

                if ((oldColumn == column) && (oldScanner == _current))
                    error("Feeder in loop with: " ~ _current.classinfo.nakename); //TODO: be careful here
            }
            catch(Exception e) {          
                throw new ParserException(e.msg, line, column);
            }
        }
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

    void scan(const File file)
    {
        //todo  
    }

    void scan(const string text)
    {      
        string[] lines = text.split("\n");      
        scan(lines);
    }

    //void scan(const string fileName);
    //void scan(const Stream stream);

    void start()
    {
        if (_active)
            error("File already opened");
        _active = true;
        doStart();
        parser.start();
    }

    void stop()
    {
        if (!_active)
            error("File already closed");
        parser.stop();
        doStop();
        _active = false;
    }
}

/*---------------------------*/
/*        Controls           */
/*---------------------------*/

/**
This will used in the scanner
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

protected: 

public:

    debug{
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