module sard.classes;
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
import sard.utils;

//alias bool bool; //already exists
alias long integer;
alias double number;
alias string text;

/**---------------------------*/
/**        Exception
/**---------------------------*/

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

/**---------------------------*/
/**    Base classes
/**---------------------------*/

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
        created();
    }

    ~this(){
        destroyed();
    }

    void created(){
    }

    void destroyed() {
    }
}

class BaseNamedObject: BaseObject {
    string _name;
    public @property string name(){ return _name; }
    public @property string name(string value){
        return _name = value;
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
    //alias items = this;

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
        foreach(itm; _items)
        {
            int b = dg(itm);
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
            foreach(itm; items) {
                itm.debugWrite(level + 1);
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
        foreach(itm; this) {
            if (icmp(name, itm.name) == 0) {
                result = itm;
                break;
            }
        }
        return result;
    }

    bool isOpenBy(const char c)
    {
        foreach(itm; this){
            if (!itm.name.empty && (itm.name[0] == toLower(c)))
                return true;          
        }
        return false;
    }

    T scan(string text, int index)
    {
        T result = null;
        int max = 0;        
        foreach(itm; this)
        {
            if (scanCompare(itm.name, text, index))
            {
                if (max < itm.name.length)
                {
                    max = itm.name.length;
                    result = itm;
                }
            }
        }
        return result;
    }
}

/**---------------------------*/
/**        Stack
/**---------------------------*/

class Stack(T): BaseObject
{    
protected:
    bool own = true; //free when remove it

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

        if (aObject is null)
            error("Can't push null");

        StackItem aItem = new StackItem();
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

    T push(){  //deprecated
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
        while (!(current is null))        
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

//functions

bool indexInStr(int index,string str) {
    return index < str.length;
    //return index <= str.length; in Pascal
}
