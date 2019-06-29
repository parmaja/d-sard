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

static immutable char[] sWhitespace = sEOL ~ [' ', '\t'];
static immutable char[] sNumberOpenChars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
static immutable char[] sNumberChars = sNumberOpenChars ~ ['.', 'x', 'h', 'a', 'b', 'c', 'd', 'e', 'f'];
static immutable char[] sSymbolChars = ['"', '\'', '\\'];
static immutable char[] sIdentifierSeparator = ".";

//const sColorOpenChars = ['#',];
//const sColorChars = sColorOpenChars ~ ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];

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

/**
*
*   Code Scanner
*
*/

class CodeScanner: Scanner
{
protected:
    Block_Node _block;

    override Parser createParser() {
        return new CodeParser(current, _block.statements);
    }

public:
    this(Block_Node block)
    {
        super();
        _block = block;
        add(new CodeLexer());
     }

    override void doStart()
    {

    }

    override void doStop()
    {
    }
}

/**
*
*   Code Instruction
*
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

abstract class CodeCollector: Collector
{
private:

protected:
    Instruction instruction;

public:
    this(Parser aParser)
    {
         super(aParser);
    }

    override void reset(){
        //destroy(instruction);
        instruction = Instruction.init;
        //instruction= new Instruction;
    }

    override void post(){
        debug(log_compile){
            writeln("post(" ~ to!string(instruction.operator) ~ ", " ~ instruction.identifier ~ ")");
        }

        if (instruction.isEmpty)
        {
            debug(log_compile) writeln("post() empty");
        }
        else  {
            prepare();
            internalPost();
        }
        reset();
    }

    override void prepare(){
    }

    override void next(){
    }

    override void addToken(Token token)
    {
        string text = token.value;

        switch (token.type) {
            case Type.Number:
                instruction.setNumber(text);
                break;
            case Type.String:
                instruction.setText(text);
                break;
            case Type.Escape: {
                //TODO text = //need function doing escapes
                if (text == "\\n")
                    text = "\n";
                else if (text == "\\r")
                    text = "\r";
                else if (text == "\\\"")
                    text = "\"";
                else if (text == "\\\'")
                    text = "\'";
                instruction.setText(text);
                break;
            }
            case Type.Comment:
                instruction.setComment(text);
                break;
            default:
                instruction.setIdentifier(text);
        }
    }

    void addOperator(Operator operator)
    {
        post();
        instruction.setOperator(operator);
    }
}

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
        (cast(CodeCollector) current).addOperator(o);
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

class CollectorStatement: CodeCollector
{
protected:
    Statement statement;

    override void internalPost()
    {
        super.internalPost();
        statement.add(instruction.operator, instruction.object);
    }

    override Controller createController() {
        return new ControllerNormal(this);
    }

public:

    this(Parser aParser)
    {
        super(aParser);
    }

    this(Parser aParser, Statement aStatement)
    {
        this(aParser);
        statement = aStatement;
    }

    override void next()
    {
        super.next();
        statement = null;
    }

    override void prepare()
    {
        super.prepare();
        if (instruction.identifier != "")
        {
            if (instruction.object !is null)
                error("Object is already set!");
            instruction.setInstance();
        }
    }

    override bool isInitial(){
        return (statement is null) || (statement.count == 0);
    }
}

class CollectorBlock: CollectorStatement
{
protected:
    Statements statements;

public:

    this(Parser aParser, Statements aStatements)
    {
        super(aParser);
        statements = aStatements;
    }

    override void prepare()
    {
        super.prepare();
        if (statement is null) {
            if (statements is null)
                error("Maybe you need to set a block, or it single statment block");
            statement = statements.add();
            debug(log_compile) writeln("statements.add");
        }
    }
}

class CollectorDeclare: CollectorStatement
{
protected:

public:

    this(Parser aParser){
        super(aParser);
    }

    override void addControl(Control control)
    {
        switch (control.code){
            case Ctl.End, Ctl.Next:
                post();
                parser.setAction(Actions([Action.Pop, Action.Bypass]));
                break;
            default:
                super.addControl(control);
        }
    }
}

/**
    Define is a parameters defines in declare

    //parameters are in the declaration, arguments are the things actually passed to it. so void f(x), f(0), x is the parameter, 0 is the argument
*/
class CollectorDefine: CodeCollector
{
private:
    enum State {Name, Type};
protected:
    State state;
    bool param;
    Declare_Node declare;

    this(Parser aParser){
        super(aParser);
    }

    this(Parser aParser, Declare_Node aDeclare){
        this(aParser);
        declare = aDeclare;
    }

    override void internalPost()
    {
        super.internalPost();
        if (instruction.identifier == "")
            error("Identifier not set"); //TODO maybe check if he post const or another things
        if (param)
        {
            if (state == State.Name)
                declare.defines.parameters.add(instruction.identifier, "");
            else
            {
                if (declare.defines.parameters.last.type != "")
                    error("Result type already set");
                declare.defines.parameters.last.type = instruction.identifier;
            }
        }
        else
            declare.resultType = instruction.identifier;
    }

    override Controller createController(){
        return new ControllerDefines(this);
    }

public:
    override void addControl(Control control)
    {
        /*
        x:int  (p1: int; p2: string);
        ^type (-------Params------)^
        Declare  ^Declare
        We end with ; or : or )
        */
        with(parser)
        {
            switch(control.code)
            {
                case Ctl.OpenBlock:
                    post();
                    Block_Node aBlock = new Block_Node();
                    aBlock.parent = declare;
                    declare.executeObject = aBlock;
                    //We will pass the control to the next Collector
                    setAction(Actions([Action.Pop]), new CollectorBlock(parser, aBlock.statements));
                    break;

                case Ctl.Declare:
                    if (param){
                        post();
                        state = State.Type;
                    }
                    else {
                        post();
                        setAction(Actions([Action.Pop]));
                    }
                    break;

                case Ctl.Assign:
                    post();
                    declare.executeObject = new Assign_Node();
                    declare.executeObject.parent = declare;
                    declare.executeObject.name = declare.name;
                    setAction(Actions([Action.Pop])); //Finish it, mean there is no body/statment for the declare
                    break;

                case Ctl.End:
                    if (param){
                        post();
                        state = State.Name;
                    }
                    else {
                        post();
                        setAction(Actions([Action.Pop]));
                    }
                    break;

                case Ctl.Next:
                    post();
                    state = State.Name;
                    break;

                case Ctl.OpenParams:
                    post();
                    if (declare.defines.parameters.count > 0)
                        error("You already define params! we expected open block.");
                    param = true;
                    break;

                case Ctl.CloseParams:
                    post();
                    //pop(); //Finish it
                    param = false;
                    //action(Actions([paPop]), new CollectorBlock(parser, declare.block)); //return to the statment
                    break;

                default:
                    super.addControl(control);
            }
        }
    }

    override void reset(){
        state = State.Name;
        super.reset();
    }

    override bool isInitial(){
        return true;
    }
}

/**
*    ControllerNormal
*/

class ControllerNormal: Controller
{

public:
    this(Collector aCollector){
        super(aCollector);
    }

    override void setControl(Control control)
    {
        with(cast(CodeCollector) collector)
        {
            switch(control.code)
            {
                case Ctl.Assign:
                    if (isInitial)
                    {
                        instruction.setAssign();
                        post();
                    }
                    else
                        error("You can not use assignment here!");

                    break;

                case Ctl.Declare:
                    if (isInitial)
                    {
                        Declare_Node aDeclare = instruction.setDeclare();
                        post();
                        parser.push(new CollectorDefine(parser, aDeclare));
                    }
                    else
                        error("You can not use a declare here!");
                    break;

                case Ctl.OpenBlock:
                    Block_Node aBlock = new Block_Node();
                    instruction.setObject(aBlock);
                    parser.push(new CollectorBlock(parser, aBlock.statements));
                    break;

                case Ctl.CloseBlock:
                    post();
                    if (parser.count == 1)
                        error("Maybe you closed not opened Curly");
                    parser.setAction(Actions([Action.Pop]));
                    break;

                case Ctl.OpenParams:
                    //params of function/object like: Sin(10)
                    if (instruction.checkIdentifier())
                    {
                        with (instruction.setInstance())
                            parser.push(new CollectorBlock(parser, arguments));
                    }
                    else //No it is just sub statment like: 10+(5*5)
                        with (instruction.setEnclose())
                            parser.push(new CollectorStatement(parser, statement));
                    break;

                case Ctl.CloseParams:
                    post();
                    if (parser.count == 1)
                        error("Maybe you closed not opened Bracket");
                    parser.setAction(Actions([Action.Pop]));
                    break;

                case Ctl.Start:
                    break;
                case Ctl.Stop:
                    post();
                    break;
                case Ctl.End:
                    post();
                    next();
                    break;
                case Ctl.Next:
                    post();
                    next();
                    break;
                default:
                    error("Not implemented yet :(");
            }
        }
    }
}

/**
*    ControllerDefines
*/

class ControllerDefines: ControllerNormal  //TODO should i inherited it from Controller?
{
public:
    this(Collector aCollector){
        super(aCollector);
    }

    override void setControl(Control control)
    {
        //nothing O.o
        //TODO change the inheretance
    }
}

