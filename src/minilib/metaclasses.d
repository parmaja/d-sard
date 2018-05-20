module minilib.metaclasses;
/**
    This file is part of the "minilib"

    @license   The MIT License (MIT) Included in this distribution
    @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

/**
@describe:
    Manage creating objects from variable classes
    @ref:
    @example:
    alias MyMetaClass = MetaClass!BaseClass mc;

@doc:  
    check if is instance of my class
    typeid(obj1) == typeid(obj2)
    typeid(obj1) == typeid(MyClass)

@hints:
    if you want to use factory your class must have default constructor (or no constructors).  
    if you have subclass constructor SubClass(a,b) you need to add default constructor even if u have it in the base class, D hide the functions in base class if u add new one in subclass.
*/


pragma(msg, "You are using metaclasses.d it is not finished!");

/*
    use hasMember to check, http://dlang.org/phobos/std_traits.html
    template hasMember(T, string name)
*/
struct MetaClass(T)  
{
    ClassInfo _info;
    this(ClassInfo cf){
        _info = cf;
        //here we need to check if that class dirived from base class T
    }

    T create(){
        return cast(T)_info.create();        
    }
}