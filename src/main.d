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
import sard;

int main(string[] argv) {
  ///testunit
  //writeln(stringRepeat("test", 2));
  int i = 0;
  auto s = scanText("hello", "hello world, i hate you", i);
  writeln(s);


  return 0;
}
