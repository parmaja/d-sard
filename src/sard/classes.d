module sard.classes;
/**
*  This file is part of the "SARD"
*
* @license   The MIT License (MIT)
*            Included in this distribution
* @author    Zaher Dirkey <zaher at parmaja dot com>
*/

import std.stdio;
//import std.stream;
import std.traits;
import std.string;
import std.conv;
import std.uni;
import std.array;
import std.range;
import sard.utils;
import minilib.metaclasses;

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

class SardObject: Object 
{
  protected:
    void created() {
    };

  public:

    debug{
      void debugWrite(int level){
        writeln(stringRepeat(" ", level * 2) ~ this.classinfo.name);
      }
    }

    this(){
      created(); 
    }

    void error(string error) {
      throw new SardException(error);
    }
}

//class SardObjects(T): SardObject if(is(T: SardNamedObject)) {
class SardObjects(T: SardObject): SardObject 
{
  private:
    T[] _items;

  public:
    alias _items this;

  protected:
    T getItem(int index) {

      return _items[index];
    }

    void afterAdd(T object){
      debug{
        //not compiled :(        
        writeln(this.classinfo.name ~ ".add(" ~ object.classinfo.name ~ ")");
        //writeln(fullyQualifiedName!this ~ ".add(" ~ object.classinfo.name ~ ")");        
      }
    }

  public:

    int add(T object) {      
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

    @property T last(){
      if (_items.length == 0)
        return null;
      else
        return _items[_items.length - 1];
    }

    debug{
      override void debugWrite(int level){
        super.debugWrite(level);
        writeln("Count: " ~ to!string(count));
        int i = 0;
        while (i < count) {
          this[i].debugWrite(level + 1);
        }
      }
    }
}

class SardNamedObjects(T: SardObject): SardObjects!T
{
  public:
    T find(string aName) {
      int i = 0;
      T result = null;
      while (i < count) {
        if (icmp(aName, this[i].name) == 0) {
          result = this[i];
          break;
        }
        i++;
      }
      return result;
    }
}

enum SardControl 
{
  None,
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

    T getCurrent() {
      if (currentItem is null)
        return null;
      else
        return currentItem.object;
    }

    void afterPush() {

    };

    void beforePop() {
    };
  }

  public {

    bool isEmpty() {
      return currentItem is null;
    }

    void push(T vObject) {
      SardStackItem aItem;

      if (vObject is null)
        error("Can't push null");

      aItem = new SardStackItem();
      aItem.object = vObject;
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
        error("Stack is empty"); //TODO maybe return nil
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

      //    destroy(aItem);
      //    destroy(aObject);
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

enum SardType {None, Identifier, Number, Color, String, Comment }

interface ISardParser {
protected:
  abstract void start();
  abstract void stop();    

  abstract void doSetControl(SardControl aControl);
  abstract void doSetToken(string aToken, SardType aType);
  abstract void doSetOperator(SardObject aOperator);

public:
  final void setControl(SardControl aControl){
    doSetControl(aControl);
  }

  final void setToken(string aToken, SardType aType){
    doSetToken(aToken, aType);
  }

  final void setOperator(SardObject aOperator){
    doSetOperator(aOperator);
  }
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
    abstract bool scan(const string text, ref int column);

    bool accept(const string text, int column){
      return false;
    }
    //This function call when switched to it

    void switched() {
      //Maybe reseting buffer or something
    }

  public:
    string collected; //buffer
    SardScanner scanner;

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
    final override int add(SardScanner scanner){
      scanner._lexical = _lexical;
      return super.add(scanner);
    }

  this(SardLexical lexical){
    super();
    _lexical = lexical;
  }
}

class SardLexical:SardObject
{
  private:
    int _line;
    SardScanners _scanners;
    public @property SardScanners scanners() { return _scanners; } ;
    SardScanner _scanner; //current scanner
    ISardParser _parser;    

  public:
    @property int line() { return _line; };
    @property SardScanner scanner() { return _scanner; } ;      

    @property ISardParser  parser() { return _parser; };
    @property ISardParser  parser(ISardParser  value) { return _parser = value; }    

  public:
    this(){
      super();
      _scanners = new SardScanners(this);
    }
    abstract bool isWhiteSpace(char vChar, bool vOpen= true);
    abstract bool isControl(char vChar);
    abstract bool isOperator(char vChar);
    abstract bool isNumber(char vChar, bool vOpen = true);

    bool isIdentifier(char vChar, bool vOpen = true){
      bool r = !isWhiteSpace(vChar) && !isControl(vChar) && !isOperator(vChar);
      if (vOpen)
        r = r && !isNumber(vChar, vOpen);
      return r;
    }

  public:

    SardScanner detectScanner(const string text, int column) 
    {
      if (column >= text.length){
        //do i need to switchScanner?
        return null; //no scanner for empty line or EOL
      }
      else {
        SardScanner result = null;
        int i = 0;
        while (i < scanners.count) {
          if ((scanners[i] != result) && scanners[i].accept(text, column)) {
            result = scanners[i];
            break;
          }
          i++;
        }

        if (result is null)
          error("Scanner not found: " ~ text[column]);
        switchScanner(result);
        return result;
      }
    }

    void switchScanner(SardScanner nextScanner) {
      if (_scanner != nextScanner) {

        _scanner = nextScanner;
        if (_scanner is null)
          _scanner.switched();
      }

    }

    SardScanner findClass(const ClassInfo scannerClass) {
      int i = 0;
      while (i < scanners.count) {
        if (scanners[i].classinfo == scannerClass) {
          return scanners[i];
        }
        i++;
      }
      return null;
    }

    //This find the class and switch to it
    void SelectScanner(ClassInfo scannerClass) {
      SardScanner aScanner = findClass(scannerClass);
      if (aScanner is null)
        error("Scanner not found");
      switchScanner(aScanner);
    }

    void scanLine(const string text, const int aLine) {
      int _line = aLine;
      int column = 0; 
      int len = text.length;
      if (scanner is null)
        detectScanner(text, column);
      while (column < len)
      {
        int oldColumn = column;
        SardScanner oldScanner = _scanner;
        try {
          if (scanner.scan(text, column))
            detectScanner(text, column);

          if ((oldColumn == column) && (oldScanner == _scanner))
            error("Feeder in loop with: " ~ _scanner.classinfo.name); //todo becarfull here
        }
        catch(Exception exc) {          
          throw new SardParserException(exc.msg, aLine, column);
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

    /*
    @property SardLexical lexical(SardLexical value) {
        if (_lexical == value)
          return _lexical;
        if (active)
          error("You can not set scanner when started!");
        return _lexical = value;      
      }*/

  protected:

    void doStart() {
      lexical.parser.setControl(SardControl.Start);
    }

    void doStop() {
      lexical.parser.setControl(SardControl.Stop);
    }

  public:
    this(SardLexical lexical) {
      super();
      _lexical = lexical;
    }

    void scanLine(const string text, const int line) {
      if (!active)
        error("Feeder not started");
      lexical.scanLine(text, line);
    }

    void scan(const string[] lines)
    {
      start();
      int i = 0;
      while(i < lines.count()){
        scanLine(lines[i], i);
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
 
    void start(){
      if (_active)
        error("File already opened");
      _active = true;
      doStart();
      lexical.parser.start();
    }

    void stop(){
      if (!_active)
        error("File already closed");
      lexical.parser.stop();
      doStop();
      _active = false;

    }
};

