module sard.process;
/**
This file is part of the "SARD"

@license   The MIT License (MIT) Included in this distribution
@author    Zaher Dirkey <zaher at parmaja dot com>

*/
import std.stdio;
import std.string;
import std.math;
import std.conv;
import std.array;
import std.range;
import sard.classes;
import sard.scanners;
import sard.objects;

class SardRun = class(SardObject)
{
  protected:
  public:
    SrdEnvironment env;
    SoMain main;
    string result;//Temp
    this(){
      super();
      env = SrdEnvironment();
    }
    
    void compile(string text){
    }

    void run(){

    };
}

