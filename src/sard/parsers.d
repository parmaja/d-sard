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
import sard.objects;
import sard.operators;

import minilib.sets;

enum Action 
{
    PopCollector, //Pop the current Collector
    Bypass  //resend the control char to the next Collector
}

alias Set!Action Actions;

class SrdInstruction: SardObject
{
protected:
    void internalSetObject(SoObject aObject)
    {
        if ((object !is null) && (aObject !is null))
            error("Object is already set");
        object = aObject;
    }

public:

//    Flag flag;
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
    }

    void setOperator(OpOperator operator)
    {
        if (operator !is null)
            error("Operator is already set");
        operator = operator;
    }

    void setIdentifier(string aIdentifier)
    {
        if (identifier != "")
            error("Identifier is already set");
        identifier = aIdentifier;
    }

    SoBaseNumber setNumber(string aIdentifier)
    {
        if (identifier != "")
            error("Identifier is already set");
        //TODO need to check object too
        SoBaseNumber result;
        if ((aIdentifier.indexOf(".") >= 0) || ((aIdentifier.indexOf("E") >= 0)))
            result = new SoNumber(to!float(aIdentifier));
        else 
            result = new SoInteger(to!int(aIdentifier));

        internalSetObject(result);
        return result;
    }

    SoText setText(string aIdentifier)
    {
        if (identifier != "")
            error("Identifier is already set");
        //TODO need to check object too
        SoText result = new SoText(aIdentifier);

        internalSetObject(result);
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

class SrdController: SardObject
{
protected:
    SrdParser parser;

public:
    this(){
        super();
    }

    this(SrdParser aParser){
        this();
        parser = aParser;
    }

    abstract void control(SardControl aControl);
}

class SrdControllers: SardObjects!SrdController
{
public:
    SrdController findClass(const ClassInfo controllerClass) 
    {
        foreach(e; items) {
            if (e.classinfo == controllerClass) {
                writeln("we found " ~ e.classinfo.nakename);                
                return e;
            }
        }
        writeln("not found ");                
        return null;
    }
}

class SrdCollector: SardObject
{
private:

protected:
    SrdInstruction instruction;
    SrdController controller;

    SrdParser parser;

    void internalPost(){  
    }

    ClassInfo getControllerClass(){
        return SrdControllerNormal.classinfo;
    }

public:

    void set(SrdParser aParser)
    {
        parser = aParser;
        switchController(getControllerClass());
        reset();
    }

    this(){
        super();
    }

    this(SrdParser aParser){
        this();
        set(aParser);
    }

    //Push to the Parser immediately
    void push(SrdCollector aItem){
        parser.push(aItem);
    }

    //No pop, but when finish Parser will pop it
    void setAction(Actions aActions = [], SrdCollector aNextCollector = null)
    {
        debug{
            writeln(aActions);
        }
        parser.actions = aActions;
        parser.nextCollector = aNextCollector;
    }

    void reset(){      
        instruction = new SrdInstruction();
    }

    void prepare(){            
    }

    void post(){            
        if (!instruction.isEmpty) {      
            debug{
                writeln("post(" ~ instruction.identifier ~ ")");
            }
            prepare();
            internalPost();
            reset();
        }
    }

    void next(){
    }

    void addToken(string aToken, SardType aType)
    {
        switch (aType) {
            case SardType.Number: 
                instruction.setNumber(aToken);
                break;
            case SardType.String: 
                instruction.setText(aToken);
                break;
            case SardType.Comment: 
                instruction.setComment(aToken);
                break;
            default:
                instruction.setIdentifier(aToken);
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

    void switchController(ClassInfo controllerClass)
    {
        if (controllerClass is null)
            error("ControllerClass must have a value!");
        controller = parser.controllers.findClass(controllerClass);
        if (controller is null)
            error("Can not find this class:" ~ controllerClass.name);
    }

    void control(SardControl aControl){
        controller.control(aControl);
    }
}

class SrdCollectorStatement: SrdCollector
{
protected:
    SrdStatement statement;

    override void internalPost()
    {
        super.internalPost();
        statement.add(instruction.operator, instruction.object);
    }

public:

    this(SrdParser aParser){
        super(aParser);
    }

    this(SrdParser aParser, SrdStatement aStatement)
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

class SrdCollectorBlock: SrdCollectorStatement
{
protected:
    SrdStatements statements;

public:

    this(SrdParser aParser, SrdStatements aStatements)
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
        }
    }
}

class SrdCollectorDeclare: SrdCollectorStatement
{
protected:

public:

    this(SrdParser aParser){
        super(aParser);    
    }

    override void control(SardControl aControl){
        switch (aControl){
            case SardControl.End, SardControl.Next:          
                post();
                setAction(Actions([Action.PopCollector, Action.Bypass]));
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
class SrdCollectorDefine: SrdCollector
{
private:
    enum State {Name, Type};
protected:
    State state;
    bool param;
    SoDeclare declare;

    this(SrdParser aParser){ 
        super(aParser);    
    }

    this(SrdParser aParser, SoDeclare aDeclare){
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

    override ClassInfo getControllerClass(){
        return SrdControllerDefines.classinfo;
    }

public:
    override void control(SardControl aControl)
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
                case SardControl.OpenBlock:
                    post();
                    SoBlock aBlock = new SoBlock();
                    aBlock.parent(declare);
                    declare.callObject = aBlock;
                    //We will pass the control to the next Collector
                    setAction(Actions([Action.PopCollector]), new SrdCollectorBlock(parser, aBlock.statements));
                    break;

                case SardControl.Declare:
                    if (param){
                        post();
                        state = State.Type;
                    }
                    else {
                        post();
                        setAction(Actions([Action.PopCollector]));
                    }
                    break;

                case SardControl.Assign:
                    post();
                    declare.executeObject = new SoAssign(declare, declare.name);            
                    declare.callObject = new SoVariable(declare, declare.name);
                    setAction(Actions([Action.PopCollector])); //Finish it, mean there is no body/statment for the declare
                    break;

                case SardControl.End:
                    if (param){
                        post();
                        state = State.Name;
                    }
                    else {
                        post();
                        setAction(Actions([Action.PopCollector]));
                    }
                    break;

                case SardControl.Next:
                    post();
                    state = State.Name;
                    break;

                case SardControl.OpenParams:
                    post();
                    if (declare.defines.parameters.count > 0)
                        error("You already define params! we expected open block.");
                    param = true;
                    break;

                case SardControl.CloseParams:
                    post();
                    //pop(); //Finish it
                    param = false;
                    //action(Actions([paPopCollector]), new SrdCollectorBlock(parser, declare.block)); //return to the statment
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

class SrdControllerNormal: SrdController
{    
public:
    this(SrdParser aParser){ 
        super(aParser);    
    }

    override void control(SardControl aControl)
    {
        with(parser.current)
        {
            switch(aControl)
            {
                case SardControl.Assign:
                    if (isInitial)
                    {
                        instruction.setAssign();
                        post();
                    } 
                    else 
                        error("You can not use assignment here!");

                    break;

                case SardControl.Declare:
                    if (isInitial)
                    {
                        SoDeclare aDeclare = instruction.setDeclare();
                        post();
                        push(new SrdCollectorDefine(parser, aDeclare));
                    } 
                    else 
                        error("You can not use a declare here!");
                    break;

                case SardControl.OpenBlock:
                    SoBlock aBlock = new SoBlock();
                    instruction.setObject(aBlock);
                    push(new SrdCollectorBlock(parser, aBlock.statements));
                    break;

                case SardControl.CloseBlock:
                    post();
                    if (parser.count == 1)
                        error("Maybe you closed not opened Curly");
                    setAction(Actions([Action.PopCollector]));
                    break;

                case SardControl.OpenParams:
                    //params of function/object like: Sin(10)
                    if (instruction.checkIdentifier())
                    {
                        with (instruction.setInstance())
                            push(new SrdCollectorBlock(parser, statements));
                    }
                    else //No it is just sub statment like: 10+(5*5)
                        with (instruction.setSub())
                            push(new SrdCollectorStatement(parser, statement));
                    break;

                case SardControl.CloseParams:
                    post();
                    if (parser.count == 1)
                        error("Maybe you closed not opened Bracket");
                    setAction(Actions([Action.PopCollector]));
                    break;

                case SardControl.Start:            
                    break;
                case SardControl.Stop:            
                    post();
                    break;
                case SardControl.End:            
                    post();
                    next();
                    break;
                case SardControl.Next:            
                    post();
                    next();
                    break;
                default:
                    error("Not implemented yet :(");
            }
        }
    }
}

class SrdControllerDefines: SrdControllerNormal
{
public:
    this(SrdParser aParser){ //TODO BUG why i need to copy it?!
        super(aParser);    
    }

    override void control(SardControl aControl){
        //nothing O.o
        //TODO change the inheretance 
    }
}

class SrdParser: SardStack!SrdCollector, ISardParser 
{
protected:
    SardControl lastControl;

    override void setToken(string aToken, SardType aType)
    {
        debug{        
            writeln("doSetToken: " ~ aToken ~ " Type:" ~ to!string(aType));
        }
        /* 
            We will send ; after } if we find a token  
                x:= {
                        ...
                    } <---------here not need to add ;
                y := 10;    
        */
        if (lastControl == SardControl.CloseBlock) 
        {
            lastControl = SardControl.None;//prevent from loop
            setControl(SardControl.End);
        }
        current.addToken(aToken, aType);
        doQueue();
        actions = [];
        lastControl = SardControl.Object;
    }

    override void setOperator(SardObject operator)
    {
        debug{
            writeln("SetOperator: " ~ (cast(OpOperator)operator).name);
        }
        OpOperator o = cast(OpOperator)operator; //TODO do something, i hate typecasting
        if (o is null) 
            error("SetOperator not OpOperator");
        current.addOperator(o);
        doQueue();
        actions = [];
        lastControl = SardControl.Operator;
    }

    override void setControl(SardControl aControl)
    {
        debug{        
            writeln("SetControl: " ~ to!string(aControl));
        }

        if (lastControl == SardControl.CloseBlock) //see setToken
        {
            lastControl = SardControl.None;//prevent from loop
            setControl(SardControl.End);
        }

        current.control(aControl);
        doQueue();
        if (Action.Bypass in actions)//TODO check if Set work good here
            current.control(aControl); 
        actions = [];
        lastControl = aControl;
    }

    override void afterPush()
    {
        super.afterPush();
        debug{
            writeln("Push: " ~ current.classinfo.nakename);
        }
    }

    override void beforePop(){
        super.beforePop();
        debug{
            writeln("Pop: " ~ current.classinfo.nakename);
        }      
    }

    void doQueue()
    {
        if (Action.PopCollector in actions){      
            actions = actions - Action.PopCollector;
            pop();
        }

        if (nextCollector !is null) {      
            push(nextCollector);
            nextCollector = null;
        }
    }

public:
    Actions actions;
    SrdCollector nextCollector;
    SrdControllers controllers = new SrdControllers();

    this(SrdStatements aStatements)
    {
        super();      

        if (aStatements is null)
            error("You must set a block");

        controllers.add(new SrdControllerNormal(this));
        controllers.add(new SrdControllerDefines(this));      

        push(new SrdCollectorBlock(this, aStatements));
    }

    override void start(){      
    }

    override void stop(){
    }
}        


