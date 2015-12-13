module minilib.sets;
/**
    This file is part of the "minilib"

    @license   The MIT License (MIT) Included in this distribution
    @author    Zaher Dirkey <zaherdirkey at yahoo dot com>
*/

/**
@describe:
    Set of enumeration based on associative arrays
@ref
    http://rosettacode.org/wiki/Set
    http://rosettacode.org/wiki/Associative_array
*/

import std.string;
import std.array; 
import std.range;

//struct Set(T) {
struct Set(T) if(is(T == enum)) 
{
private:

    alias SetType = typeof(this);
    alias Element = T;
    alias Elements = bool[Element]; //Associative Arrays
    alias SetArray = Element[];

    Elements _elements; 

public:

    this(SetArray array)
    {
        opAssign(array);
    }

    void opAssign(Element element)
    {
        clear();
        include(element);
    }

    void opAssign(SetArray array)
    {
        clear();
        foreach(int i, Element element; array){
            include(element);
        }
    }

    bool opEquals(SetArray other) {
        return other.length == count() && exists(other);
    }
    /+
    //A = B equality; true if every element of set A is in set B and vice-versa.
    //A < B equality; true if every element of set A is in set B but the count less is diff
    //A > B equality; true if every element of set B is in set A but the count less is diff
    bool opBinary(string op)(SetArray other) if (op == "<") {
    return (countOf(other) < count()) && (exists(other));
    }
    +/	
    //A in B subset; true if every element in set A is also in set B.
    bool opBinaryRight(string op)(Element other) if (op == "in") 
    {
        return exists(other);
    }

    bool opBinaryRight(string op)(SetType other) if (op == "in") {
        return exists(other._elements, _elements);
    }

    bool opBinaryRight(string op)(SetArray other) if (op == "in") 
    {
        return exists(other);
    }

    //A + B union; a set of all elements either in set A or in set B.

    SetType opBinary(string op)(Element other) if (op == "+") 
    {
        include(other);
        return this;
    }

    SetType opBinary(string op)(SetArray other) if (op == "+") 
    {
        foreach(int i, Element element; other) {
            include(t);
        }
        return this;
    }

    SetType opBinary(string op)(SetType other) if (op == "+") 
    {
        foreach(Element element, bool b; other._elements) 
        {
            if (b)
                include(element);
        }
        return this;
    }

    //A * B intersection; a set of all elements in both set A and set B.
    SetType opBinary(string op)(Element other) if (op == "*") 
    {
        //todo
        return this;
    }

    //A - B difference; a set of all elements in set A, except those in set B.
    SetType opBinary(string op)(Element other) if (op == "-") {
        exclude(other);
        return this;
    }

    SetType opBinary(string op)(SetArray other) if (op == "-") 
    {
        foreach(int i, Element element; other) {
            exclude(t);
        }
        return this;
    }

    SetType opBinary(string op)(SetType other) if (op == "-") 
    {
        foreach(Element element, bool b; other._elements) {
            if (b)
                exclude(element);
        }
        return this;
    }

public:

    void include(Element element) {
        _elements[element] = true;
    }

    void exclude(Element element) {
        //_elements[element] = false;
        _elements.remove(element);
    }

    protected bool exists(Elements elements, Element element) 
    {
        if (elements.length == 0)
            return false;//todo not sure if we must return false?
        foreach(Element e, bool b; elements) {
            if (b && (element == e)) {
                return true;
            }
        }
        return true;
    }

    protected bool exists(Elements elements, Elements inElements) 
    {
        if (elements.length == 0)
            return false;//todo not sure if we must return false?
        foreach(Element e, bool b; elements) {
            if (b && !exists(inElements, e)) {
                return false;
            }
        }
        return true;
    }

    bool exists(Element element) 
    {
        foreach(Element e, bool b; _elements) {
            if (b && (element == e)) {
                return true;
            }
        }
        return false;
    }

    bool exists(SetArray array) 
    {
        if (array.length == 0)
            return false;//todo not sure if we must return false?
        foreach(int i, Element element; array) {
            if (!exists(element))
                return false;
        }
        return true;
    }

    protected int countOf(Elements elements) 
    {
        int c = 0;
        foreach(Element element, bool b; elements) {
            if (b)
                c++;
        }
        return c;
    }

    ///We count only true elements
    int count() {
        return countOf(_elements);
    }

    void clear(){
        _elements = null;
    }
}