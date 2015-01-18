module sard.classes;
/**
This file is part of the "SARD"

@license   The MIT License (MIT) Included in this distribution            
@author    Zaher Dirkey <zaher at yahoo dot com>
*/

import std.stdio;
import std.string;
import std.conv;
import std.uni;
import std.array;
import std.range;
import sard.utils;

class SardException: Exception 
{
    private uint _code;
    @property uint code() { return _code; }

public:
    this(string msg) {
        super(msg);
    }
}

class SardParserException: Exception 
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

void error(string err) 
{
    throw new SardException(err);
}

/+
class SardPrint: SardObject {
public:
    void text(string s){
        writeln(s);
    }
}

SardPrint print = new SardPrint(); 
+/

/**
SardObject is the base class for all object in this project
*/

class SardObject: Object 
{
protected:
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

//class SardObjects(T): SardObject if(is(T: SomeObject)) {
class SardObjects(T: SardObject): SardObject 
{
private:
    T[] _items;//TODO hash string list for namedobjects    

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

class SardNamedObjects(T: SardObject): SardObjects!T
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

class SardStack(T): SardObject 
{
    static class SardStackItem: SardObject {
        protected {
            T object; 
            SardStackItem parent;
        }

        public {
            SardStack owner;
            int level;
        }
    }

private:
    int _count;
    SardStackItem _currentItem; 

public:
    @property {
        int count() {
            return _count;
        }

        SardStackItem currentItem() {
            return _currentItem;
        }
    } 

    protected {
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

        void afterPush() {
            debug{
                writeln("push: " ~ T.classinfo.nakename);
            }
        };

        void beforePop() {
            debug{
                writeln("pop: " ~ T.classinfo.nakename);
            }
        };
    }

    public {

        bool isEmpty() {
            return currentItem is null;
        }

        void push(T aObject) {
            SardStackItem aItem;

            if (aObject is null)
                error("Can't push null");

            aItem = new SardStackItem();
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

        T pull(){
            if (currentItem is null)
                error("Stack is empty");
            beforePop();
            T aObject = currentItem.object;
            SardStackItem aItem = currentItem;
            _currentItem = aItem.parent;
            _count--;
            return aObject;
        }

        T peek(){
            if (currentItem is null)
                error("Stack is empty"); //TODO maybe return null
            return currentItem.object;
        }

        void pop() {
            if (currentItem is null)
                error("Stack is empty");
            beforePop();
            T aObject = currentItem.object;
            SardStackItem aItem = currentItem;
            _currentItem = aItem.parent;
            _count--;
        }

    public:
        @property {
            T current() {
                return getCurrent();
            }
            T parent() {
                return getParent();
            }
        }
    }
}

//TokenType
enum SardType 
{
    None, 
    Identifier, 
    Number, 
    Color, 
    String, 
    Comment 
}

enum SardControl
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

interface ISardParser 
{
protected:
    abstract void start();
    abstract void stop();    

public:
    abstract void setToken(string aToken, SardType aType);
    abstract void setControl(SardControl aControl);
    abstract void setOperator(OpOperator operator);

public:
};

class SardScanner: SardObject 
{
private:
    SardLexical _lexical;

    public @property SardLexical lexical() { 
        return _lexical; 
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

    void set(SardLexical lexical) { //todo maybe rename to opCall
        _lexical = lexical;
    }

    this(){
        super();
    }

    this(SardLexical lexical){ 
        this();
        set(lexical);
    }
}

class SardScanners: SardObjects!SardScanner{  

private:
    SardLexical _lexical;

public:
    override void beforeAdd(SardScanner scanner)
    {
        super.beforeAdd(scanner);
        scanner._lexical = _lexical;      
    }

    this(SardLexical aLexical){
        _lexical = aLexical;
        super();
    }
}

class SardLexical: SardObject
{
private:
    int _line;    

    public @property int line() { return _line; };

    SardScanners _scanners;
    public @property SardScanners scanners() { return _scanners; } ;  

    SardScanner _scanner; //current scanner
    public @property SardScanner scanner() { return _scanner; } ;      

    ISardParser _parser;    
    public @property ISardParser  parser() { return _parser; };
    public @property ISardParser  parser(ISardParser  value) { return _parser = value; }    

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

public:

    final void setToken(string aToken, SardType aType)
    {
        //here is the magic, we must find it in tokens detector to check if this id is normal id or is control or operator
        //by default it is id
        if ((aType != SardType.Identifier) || (!doIdentifier(aToken)))
            parser.setToken(aToken, aType);
    }

    final void setControl(SardControl aControl){
        parser.setControl(aControl);
    }

    final void setOperator(OpOperator operator){
        parser.setOperator(operator);
    }

public:
    this()
    {
        _scanners = new SardScanners(this);
        _operators = new OpOperators();
        _controls = new CtlControls();
        super();
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

    SardScanner detectScanner(const string text, int column) 
    {
        SardScanner result = null;
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

    void switchScanner(SardScanner nextScanner) 
    {
        if (_scanner != nextScanner) 
        {
            _scanner = nextScanner;
            if (_scanner !is null)
                _scanner.switched();
        }
    }

    SardScanner findClass(const ClassInfo scannerClass) 
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
        SardScanner aScanner = findClass(scannerClass);
        if (aScanner is null)
            error("Scanner not found");
        switchScanner(aScanner);
    }

    void scanLine(const string text, const int aLine) 
    {
        int _line = aLine;
        int column = 0; 
        int len = text.length;
        bool resume = false;
        while (column < len)
        {
            int oldColumn = column;
            SardScanner oldScanner = _scanner;
            try 
            {
                if (scanner is null) //resume the line to current/last scanner
                    detectScanner(text, column);
                else
                    resume = true;

                scanner.scan(text, column, resume);
                
                if (!resume)
                    switchScanner(null);

                if ((oldColumn == column) && (oldScanner == _scanner))
                    error("Feeder in loop with: " ~ _scanner.classinfo.nakename); //TODO: be careful here
            }
            catch(Exception e) {          
                throw new SardParserException(e.msg, aLine, column);
            }
        }
    }
};

class SardFeeder: SardObject 
{
private:
    bool _active;
    string _ver;
    string _charset;
    SardLexical _lexical; //TODO: use stack to wrap the code inside <?sard ... ?>,
    //the current one must detect ?> to stop scanning and pop
    //but the other lexical will throw none code to output provider

public:

    @property bool active() { return _active; }
    @property string ver() { return _ver; }
    @property string charset() { return _charset; }

    @property SardLexical lexical() { 
        return _lexical; 
    }

protected:

    void doStart() {
        lexical.setControl(SardControl.Start);
    }

    void doStop() {
        lexical.setControl(SardControl.Stop);
    }

public:
    this(SardLexical lexical) {
        super();
        _lexical = lexical;
    }

    void scanLine(const string text, const int line) 
    {
        if (!active)
            error("Feeder not started");
        lexical.scanLine(text, line);
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
        lexical.parser.start();
    }

    void stop()
    {
        if (!_active)
            error("File already closed");
        lexical.parser.stop();
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

class CtlControl: SardObject
{
    string name;
    SardControl code;
    int level;
    string description;

    this(){
        super();
    }

    this(string aName, SardControl aCode)
    {
        this();
        name = aName;
        code = aCode;
    }
}

/* Controls */

class CtlControls: SardNamedObjects!CtlControl
{
    CtlControl add(string name, SardControl code)
    {
        CtlControl c = new CtlControl(name, code);    
        super.add(c);
        return c;
    }
}

/*---------------------------*/
/*        Operators          */
/*---------------------------*/

class OpOperator: SardObject
{
public:
    string name;
    string title;
    int level;//TODO it is bad idea, we need more intelligent way to define the power level of operators
    string description;
    //SardControl control;// Fall back to control if is initial, only used for for = to fall back as := //TODO remove it :(

protected: 

public:

    debug{
        override void debugWrite(int level){
            super.debugWrite(level);
            writeln(stringRepeat(" ", level * 2) ~ "operator: " ~ name);        
        }
    }

}

/* Operators */

class OpOperators: SardNamedObjects!OpOperator
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