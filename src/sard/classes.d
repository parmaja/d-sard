module sard.classes;
/**
  This file is part of the "SARD"

  @license   The MIT License (MIT) Included in this distribution
  @author    Zaher Dirkey <zaher at parmaja dot com>

*/

alias long srd_int;
alias double srd_float;

class SardException : Exception {
  private uint _code;

  @property uint code() { return _code; }

  this(string msg) {
    super(msg);
  }
}

class SardParserException : Exception {
  private int _line;
  private int _column;

  @property int line() {
    return _line;
  }

  @property int column() {
    return _column;
  }

  this(string msg, int line, int column ) {
    _line = line;
    _column = column;
    super(msg);
  }
}

class SardObject: Object {

  void created() {
  };

  this() {
    created();
  }
}

class SardObjectList: SardObject {
  private:
    Object[] _items;

  public Object getItem(int index) {
    return _items[index];
  }

  protected void _add(Object object) {
    _items = _items  ~ object;
  }

  @property int count(){
    return _items.length;
  }

  Object opIndex(size_t index) {
    return _items[index];
  }

/*
    @property SardObject items(int index){
    return _items[index];
  }
*/
}

class SardObjects(T): SardObjectList {/////////////////
  T opIndex(size_t index) {
    return cast(T)getItem(index);
  }
}

class SardNamedObjects: SardObjectList {///////////////

}

enum SardControl {
  ctlNone,
  ctlStart, //Start parsing
  ctlStop, //Start parsing
  ctlDeclare, //Declare a class of object
  ctlAssign, //Assign to object/variable used as :=
  //ctlLet, //Same as assign in the initial but is equal operator if not in initial statment used to be =
  ctlNext, //End Params, Comma
  ctlEnd, //End Statement Semicolon
  ctlOpenBlock, // {
  ctlCloseBlock, // }
  ctlOpenParams, // (
  ctlCloseParams, // )
  ctlOpenArray, // [
  ctlCloseArray // ]
}

class SardStackItem: SardObject {
  protected {
    Object anObject; //rename it to object
    SardStackItem parent;
  }

  public {
    SardStack owner;
    int level;
  }
}

class SardStack: SardObject {
  private {
    int _count;
    SardStackItem _currentItem;
  }

  public {
    @property int count() {
      return _count;
    }
    @property SardStackItem currentItem() {
      return _currentItem;
    }
  }

  protected {
    Object getParent() {
      if (_currentItem is null)
        return null;
      else if (_currentItem.parent is null)
        return null;
      else
        return _currentItem.parent.anObject;
    }

    Object getCurrent() {
      if (currentItem is null)
        return null;
      else
        return currentItem.anObject;
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

    void push(Object vObject) {
      SardStackItem aItem;

      if (vObject is null)
        raiseError("Can't push null");

      aItem = new SardStackItem;
      aItem.anObject = vObject;
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

    void pop() {

      if (currentItem is null)
        raiseError("Stack is empty");
      beforePop;
      Object aObject = currentItem.anObject;
      SardStackItem aItem = currentItem;
      _currentItem = aItem.parent;
      _count--;

      //    destroy(aItem);
      //    destroy(aObject);
    }

    @property Object current() {
      return getCurrent;
    }
    @property Object parent() {
      return getParent;
    }
  }
}

class SardScanner: SardObject {
  private:
    SardLexical _lexical;

    public @property SardLexical lexical() { return _lexical; } ;

  protected:
    //Return true if it done, next will auto detect it detect
    abstract bool Scan(const string text, inout int Column);
    bool accept(const string text, inout int column){
      return false;
    }
    //This function call when switched to it

    void switched() {
      //Maybe reseting buffer or something
    }
  public:
    string collected; //buffer
    SardScanner scanner;

    void initIt(SardLexical lexical) { //todo maybe rename to opCall
      _lexical = lexical;
    }

    this(SardLexical lexical){
      initIt(lexical);
      super();
    }

    ~this(){
    }
}

class SardLexical: SardObjects!SardScanner{
  private:
    int _line;
    SardScanner _scanner;

    @property int line() { return _line; } ;
    @property SardScanner scanner() { return _scanner; } ;

    SardParser _parser;

  protected:
    @property SardParser parser() { return _parser; };
    @property SardParser parser(SardParser value) { return _parser = value; }

  public:
    abstract bool isWhiteSpace(char vChar, bool vOpen= true);
    abstract bool isControl(char vChar);
    abstract bool isOperator(char vChar);
    abstract bool isNumber(char vChar, bool vOpen = true);

    abstract bool isIdentifier(char vChar, bool vOpen = true){
      bool r = !isWhiteSpace(vChar) && !isControl(vChar) && !isOperator(vChar);
      if (vOpen)
        r = r && !isNumber(vChar, vOpen);
      return r;
    }

  public:
    SardScanner detectScanner(const string text, inout int column) {
      SardScanner r = null;

      int i = 0;
      while (i < count) {
        if ((this[i] <> r) && this[i].accept(text, column)) {
          r = this[i];
          break;
        }
        i++;
      }

      if (r is null)
        raiseError("Scanner not found:" ~ text[column]);
      switchScanner(r);
      return r;
    }

    void switchScanner(SardScanner nextScanner) {
      if (_scanner <> nextScanner) {

        _scanner = nextScanner;
        if (_scanner is null)
          _scanner.switched();
      }

    }


    SardScanner findClass(const ClassInfo scannerClass) {
      int i = 0;
      while (i < count) {
        if (this[i].classinfo == scannerClass) {
          return this[i];
        }
        i++;
      }
      return null;
    }

    //This find the class and switch to it
    void SelectScanner(ClassInfo scannerClass) {
      SardScanner aScanner = findClass(scannerClass);
      if (aScanner is null)
        raiseError("Scanner not found");
      switchScanner(aScanner);
    }

    SardScanner addScanner(ClassInfo scannerClass) {
      SardScanner scanner;
      //scanner = new typeof(scannerClass);
      scanner = cast(SardScanner)scannerClass.create();
      scanner.initIt(this);

      _add(scanner);
      return scanner;
    }
};

class SardParser {////////////////
};

void raiseError(string error) {
  throw new SardException(error);
}

/*function ScanCompare(S: string; const Text: string; Index: Integer): Boolean;
function ScanText(S: string; const Text: string; var Index: Integer): Boolean;
function StringRepeat(S: string; C: Integer): string;*/

