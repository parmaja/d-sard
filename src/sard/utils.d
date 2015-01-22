module sard.utils;
/**
    This file is part of the "SARD"

    @license   The MIT License (MIT) Included in this distribution
    @author    Zaher Dirkey <zaher at yahoo dot com>
*/

import std.conv;
import std.string;
import std.array;

//Destroy and null the object
void dispose(Object)(ref Object object) 
{
    destroy(object);
    object = null;
}

/**
* Find the tail name of the class
*/
@property string nakename(TypeInfo_Class classinfo)
{
    if (classinfo.name == "")
        return "";
    else {
        int p = classinfo.name.lastIndexOf(".");
        return classinfo.name[p + 1..$];
    }
}

string trim(string s)
{
    if (s == "")
        return "";
    else {
        return s.chomp();
    }
}

bool scanCompare(string s, const string text, int index){
    return scanText(s, text, index);
}

/**
* return true if s is founded in text at index
*/
bool scanText(string s, const string text, ref int index) 
{
    bool r = (text.length - index) >= s.length;
    if (r) {
        string w = text[index..index + s.length];
        r = toLower(w) == toLower(s); //case *in*sensitive
        if (r)
            index = index + s.length;
    }
    return r;
}

string stringRepeat(string s, int count){
    return replicate(s, count);
}