module sard.parsers;
/**
    This file is part of the "SARD"

    @license   The MIT License (MIT) Included in this distribution
    @author    Zaher Dirkey <zaher at yahoo dot com>
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
import sard.scanners;
import sard.objects;
import sard.operators;

import minilib.sets;

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
    void internalSetObject(SoObject aObject)
    {
        if ((object !is null) && (aObject !is null))
            error("Object is already set");
        object = aObject;
    }

public:

    string identifier;
    OpOperator operator;
    SoObject object;

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
        bool b = object !is null;
        if (raise && !b)
            error("Object is not set!");
        b = b && (identifier == "");
        if (raise && !b) 
            error("Identifier is already set!");
        return b;
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

    void setOperator(OpOperator aOperator)
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

    SoBaseNumber setNumber(string aIdentifier)
    {
        if (identifier != "")
            error("Identifier is already set to " ~ identifier);
        //TODO need to check object too
        SoBaseNumber result;
        if ((aIdentifier.indexOf(".") >= 0) || ((aIdentifier.indexOf("E") >= 0)))
            result = new SoNumber(to!float(aIdentifier));
        else 
            result = new SoInteger(to!int(aIdentifier));

        internalSetObject(result);
        return result;
    }

    SoText setText(string text)
    {
        /*if (identifier != "")
            error("Identifier is already set");*/
        //TODO need review

        SoText result;
        if (object is null) {
            result = new SoText(text);
            internalSetObject(result);
        }
        else {
            result = cast(SoText)object;
            if (result is null)
                error("Object is already exist when setting string!");
            result.value = result.value ~ text;
        }
        return result;
    }

    SoComment setComment(string aIdentifier)
    {
        //We need to check if it the first expr in the statment
        if (identifier != "")
            error("Identifier is already set");
        //TODO need to check object too
        SoComment result = new SoComment();
        result.value = aIdentifier;
        internalSetObject(result);
        return result;
    }

    void setObject(SoObject aObject)
    {
        if (identifier != "")
            error("Identifier is already set");
        internalSetObject(aObject);  
    }  

    SoInstance setInstance(string aIdentifier)
    {
        if (identifier == "")
            error("Identifier is already set");
        SoInstance result = new SoInstance();
        result.name = aIdentifier;
        internalSetObject(result);
        return result;
    }

    SoInstance setInstance()
    {
        if (identifier == "")
            error("Identifier is not set");
        SoInstance result = setInstance(identifier);
        identifier = "";	  
        return result;
    }

    SoSub setSub()
    { 
        if (identifier != "")
            error("Identifier is already set");
        SoSub result = new SoSub();
        internalSetObject(result);
        return result;
    }

    SoAssign setAssign()
    {
        //Do not check the Identifier if empty, becuase it is can be empty to assign to result of block
        SoAssign result = new SoAssign();
        result.name = identifier;    
        internalSetObject(result);
        identifier = "";
        return result;
    }

    SoDeclare setDeclare()
    {
        if (identifier == "")
            error("identifier is not set");
        SoDeclare result = new SoDeclare();
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

class Collector: BaseObject
{
private:

protected:
    Instruction instruction;
    Controller controller;

    CodeParser parser;

    void internalPost(){  
    }

    Controller createControllerClass() {
        return new ControllerNormal(this);
    }

public:

    this(){
        super();
        debug writeln("new collecter");
    }

    this(CodeParser aParser)
    {
        this();
        parser = aParser;
        controller = createControllerClass();
        reset();
    }

    ~this(){
        destroy(controller);
        debug writeln("kill collecter");
    }

    //No pop, but when finish CodeParser will pop it
    void setAction(Actions aActions = [], Collector aNextCollector = null)
    {
        debug{
            writeln(aActions);
        }
        parser.actions = aActions;
        parser.nextCollector = aNextCollector;
    }

    void reset(){                      
        //destroy(instruction);
        instruction = Instruction.init;
        //instruction= new Instruction;
    }

    void prepare(){            
    }

    void post(){
        debug{
            writeln("post(" ~ to!string(instruction.operator) ~ ", " ~ instruction.identifier ~ ")");
        }

        if (instruction.isEmpty) 
        {
            writeln("post() empty");
        }
        else  {
            prepare();
            internalPost();
        } 
        reset();
    }

    void next(){
    }

    void addToken(Token token)
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
                    text = "\n";
                else if (text == "\\n")
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

    void addOperator(OpOperator operator)
    {
        post();
        instruction.setOperator(operator);
    }

    //IsInitial: check if the next object will be the first one, usefule for Assign and Declare
    @property bool isInitial()
    {
        return false;
    }

    void control(Control aControl){
        controller.control(aControl);
    }
}

class CollectorStatement: Collector
{
protected:
    Statement statement;

    override void internalPost()
    {
        super.internalPost();
        statement.add(instruction.operator, instruction.object);
    }

public:

    this(CodeParser aParser){
        super(aParser);
    }

    this(CodeParser aParser, Statement aStatement)
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

    this(CodeParser aParser, Statements aStatements)
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
            debug writeln("statements.add");
        }
    }
}

class CollectorDeclare: CollectorStatement
{
protected:

public:

    this(CodeParser aParser){
        super(aParser);    
    }

    override void control(Control aControl){
        switch (aControl){
            case Control.End, Control.Next:          
                post();
                setAction(Actions([Action.Pop, Action.Bypass]));
                break;
            default:
                super.control(aControl);
        }
    }
}

/**
    Define is a parameters defines in declare 
    
    //parameters are in the declaration, arguments are the things actually passed to it. so void f(x), f(0), x is the parameter, 0 is the argument
*/
class CollectorDefine: Collector
{
private:
    enum State {Name, Type};
protected:
    State state;
    bool param;
    SoDeclare declare;

    this(CodeParser aParser){ 
        super(aParser);    
    }

    this(CodeParser aParser, SoDeclare aDeclare){
        this(aParser);
        declare = aDeclare;
    }

    override void internalPost()
    {
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

    override Controller createControllerClass(){
        return new ControllerDefines(this);
    }

public:
    override void control(Control aControl)
    {
        /*
        x:int  (p1: int; p2: string);
        ^type (-------Params------)^
        Declare  ^Declare
        We end with ; or : or )
        */
        with(parser)
        {
            switch(aControl)
            {
                case Control.OpenBlock:
                    post();
                    SoBlock aBlock = new SoBlock();
                    aBlock.parent(declare);
                    declare.executeObject = aBlock;
                    //We will pass the control to the next Collector
                    setAction(Actions([Action.Pop]), new CollectorBlock(parser, aBlock.statements));
                    break;

                case Control.Declare:
                    if (param){
                        post();
                        state = State.Type;
                    }
                    else {
                        post();
                        setAction(Actions([Action.Pop]));
                    }
                    break;

                case Control.Assign:
                    post();
                    declare.executeObject = new SoAssign(declare, declare.name);            
                    setAction(Actions([Action.Pop])); //Finish it, mean there is no body/statment for the declare
                    break;

                case Control.End:
                    if (param){
                        post();
                        state = State.Name;
                    }
                    else {
                        post();
                        setAction(Actions([Action.Pop]));
                    }
                    break;

                case Control.Next:
                    post();
                    state = State.Name;
                    break;

                case Control.OpenParams:
                    post();
                    if (declare.defines.parameters.count > 0)
                        error("You already define params! we expected open block.");
                    param = true;
                    break;

                case Control.CloseParams:
                    post();
                    //pop(); //Finish it
                    param = false;
                    //action(Actions([paPop]), new CollectorBlock(parser, declare.block)); //return to the statment
                    break;

                default: 
                    super.control(aControl);
            }
        }      
    }

    override void prepare(){
        super.prepare();
    }

    override void next(){
        super.next();
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

    abstract void control(Control aControl);
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

    override void control(Control aControl)
    {
        with(collector)
        {
            switch(aControl)
            {
                case Control.Assign:
                    if (isInitial)
                    {
                        instruction.setAssign();
                        post();
                    } 
                    else 
                        error("You can not use assignment here!");

                    break;

                case Control.Declare:
                    if (isInitial)
                    {
                        SoDeclare aDeclare = instruction.setDeclare();
                        post();
                        parser.push(new CollectorDefine(parser, aDeclare));
                    } 
                    else 
                        error("You can not use a declare here!");
                    break;

                case Control.OpenBlock:
                    SoBlock aBlock = new SoBlock();
                    instruction.setObject(aBlock);
                    parser.push(new CollectorBlock(parser, aBlock.statements));
                    break;

                case Control.CloseBlock:
                    post();
                    if (parser.count == 1)
                        error("Maybe you closed not opened Curly");
                    setAction(Actions([Action.Pop]));
                    break;

                case Control.OpenParams:
                    //params of function/object like: Sin(10)
                    if (instruction.checkIdentifier())
                    {
                        with (instruction.setInstance())
                            parser.push(new CollectorBlock(parser, arguments));
                    }
                    else //No it is just sub statment like: 10+(5*5)
                        with (instruction.setSub())
                            parser.push(new CollectorStatement(parser, statement));
                    break;

                case Control.CloseParams:
                    post();
                    if (parser.count == 1)
                        error("Maybe you closed not opened Bracket");
                    setAction(Actions([Action.Pop]));
                    break;

                case Control.Start:            
                    break;
                case Control.Stop:            
                    post();
                    break;
                case Control.End:            
                    post();
                    next();
                    break;
                case Control.Next:            
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

    override void control(Control aControl)
    {
        //nothing O.o
        //TODO change the inheretance 
    }
}

/**
*    @class Parser
*
*/

class CodeParser: Stack!Collector, IParser 
{
protected:
    Control lastControl;

    override bool takeIdentifier(string identifier)
    {
        //example just for fun
        /*
        if (identifier == "begin")
        {
            setControl(Control.OpenBlock);
            return true;
        } 
        if (identifier == "end")
        {
            setControl(Control.CloseBlock);
            return true;
        }   
        else  */    
        return false;
    }

    override void setToken(Token token)
    {
        //here is the magic, we must find it in tokens detector to check if this id is normal id or is control or operator
        //by default it is id
        if ((token.type != Type.Identifier) || (!takeIdentifier(token.value))) 
        {

            /* 
                We will send ; after } if we find a token  
                    x:= {
                            ...
                        } <---------here not need to add ;
                    y := 10;    
            */
            if (lastControl == Control.CloseBlock) 
            {
                lastControl = Control.None;//prevent loop
                setControl(Control.End);
            }
            current.addToken(token);
            doQueue();
            actions = [];
            lastControl = Control.Token;
        }
    }

    override void setOperator(OpOperator operator)
    {
        debug{
            writeln("SetOperator: " ~ operator.name);
        }
        OpOperator o = operator; 
        if (o is null) 
            error("SetOperator not OpOperator");
        current.addOperator(o);
        doQueue();
        actions = [];
        lastControl = Control.Operator;
    }

    override void setControl(Control aControl)
    {
        debug{        
            writeln("SetControl: " ~ to!string(aControl));
        }

        if (lastControl == Control.CloseBlock) //see setToken
        {
            lastControl = Control.None;//prevent loop
            setControl(Control.End);
        }

        current.control(aControl);
        doQueue();
        if (Action.Bypass in actions)//TODO check if Set work good here
            current.control(aControl); 
        actions = [];
        lastControl = aControl;
    }

    override void setWhiteSpaces(string whitespaces){
        //nothing to do
    }

    override void afterPush()
    {
        super.afterPush();
        debug{
            //writeln("push: " ~ current.classinfo.nakename);
        }
    }

    override void beforePop(){
        super.beforePop();
        debug{
            //writeln("pop: " ~ current.classinfo.nakename);
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
    Actions actions;
    Collector nextCollector;

    Statements statements;//external statements

    this()
    {
        super();      
    }

    ~this(){        
    }

    void start()
    {
        if (statements is null) 
            error("You should set Parser.statements!");

        push(new CollectorBlock(this, statements));
        setControl(Control.Start); 
    }

    void stop(){
        setControl(Control.Stop);
        pop();//pop the first push
    }
}