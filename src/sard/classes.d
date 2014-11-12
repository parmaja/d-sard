module sard.classes;
/**
  This file is part of the "SARD"

  @license   The MIT License (MIT) Included in this distribution
  @author    Zaher Dirkey <zaher at parmaja dot com>

*/

alias long srd_int;
alias double srd_float;

class SardException : Exception
{
  private uint m_code;

  @property uint code(){ return m_code; }

  this(string msg)
  {
    super(msg);
  }
}

class SardParserException : Exception
{
  private int m_line;
  private int m_column;

  @property int line(){ return m_line; }
  @property int column(){ return m_column; }

  this(string msg, int line, int column )
  {
    m_line = line;
    m_column = column; 
    super(msg);
  }
}

/** Base classes **/
