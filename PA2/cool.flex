/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int comment_num=0;
char *str_err;
void append_str(char c);
#define SETID cool_yylval.symbol=idtable.add_string(yytext)
#define SETINT cool_yylval.symbol=inttable.add_string(yytext)
#define SETTRUE cool_yylval.boolean=true
#define SETFALSE cool_yylval.boolean=false
#define RETURN_ERROR(err_msg) return cool_yylval.error_msg=err_msg,ERROR;
%}

/*
 * Define names for regular expressions here.
 */

DARROW =>
ASSIGN <-
LE <=
OPERATOR [-=:;.(){}@,~+*/<_]
NEWLINE \n
SPACE [ \f\r\t\v]
DIGIT [0-9]+
OBJECTID [a-z][_a-zA-Z0-9]*
TYPEID [A-Z][_a-zA-Z0-9]*
B_TRUE t(?i:rue)
B_FALSE f(?i:alse)
COMMENT_BEG \(\*
COMMENT_END \*\)
LINE_COMMENT --[^\n]*
STR_ESP \\.|\\\n
STR_ANY [^"\\\n\0]
STR_NULL \0
STR_NL \n
STR_BEG \"
STR_END \"
%x INCOMMENT INSTRING
%%

 /*
  *  Nested comments
  */
<INITIAL>{COMMENT_BEG} {comment_num++;BEGIN(INCOMMENT);}
<INCOMMENT>{COMMENT_BEG} {comment_num++;}
<INCOMMENT>{COMMENT_END} {if(!--comment_num)BEGIN(INITIAL);}
<INCOMMENT><<EOF>> {BEGIN(INITIAL);RETURN_ERROR("EOF in comment");}
<INITIAL>{COMMENT_END} {RETURN_ERROR("Unmatched *)");}
<INITIAL,INCOMMENT>{STR_NL} {curr_lineno++;}
<INCOMMENT>. {}
{LINE_COMMENT} {}
 /*
  *  The multiple-character operators.
  */
{DARROW} {return DARROW;}
{ASSIGN} {return ASSIGN;}
{LE} {return LE;}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:CLASS) {return CLASS;}
(?i:ELSE) {return ELSE;}
(?i:FI) {return FI;}
(?i:IF) {return IF;}
(?i:IN) {return IN;}
(?i:INHERITS) {return INHERITS;}
(?i:LET) {return LET;}
(?i:LOOP) {return LOOP;}
(?i:POOL) {return POOL;}
(?i:THEN) {return THEN;}
(?i:WHILE) {return WHILE;}
(?i:CASE) {return CASE;}
(?i:ESAC) {return ESAC;}
(?i:OF) {return OF;}
(?i:NEW) {return NEW;}
(?i:ISVOID) {return ISVOID;}
(?i:NOT) {return NOT;}

{B_TRUE} {SETTRUE;return BOOL_CONST;}
{B_FALSE} {SETFALSE;return BOOL_CONST;}
{DIGIT} {SETINT;return INT_CONST;}
{OBJECTID} {SETID;return OBJECTID;}
{TYPEID} {SETID;return TYPEID;}
{OPERATOR} {return *yytext;}

{SPACE} {}
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
<INITIAL>{STR_BEG} {string_buf_ptr=string_buf;str_err=NULL;BEGIN(INSTRING);}
<INSTRING>{STR_NULL} {RETURN_ERROR("String contains null character");}
<INSTRING>{STR_ESP} {
  char c=0;
  switch(yytext[1])
  {
    case 'n':c='\n';break;
    case 't':c='\t';break;
    case 'b':c='\b';break;
    case 'f':c='\f';break;
    case '\n':curr_lineno++;
    default:c=yytext[1];
  }
  if(c)append_str(c);
}
<INSTRING>{STR_NL} {curr_lineno++;BEGIN(INITIAL);RETURN_ERROR("Unterminated string constant");}
<INSTRING>{STR_ANY} {append_str(*yytext);}
<INSTRING>{STR_END} {
  BEGIN(INITIAL);
  if(str_err)RETURN_ERROR(str_err);
  *string_buf_ptr=0;
  cool_yylval.symbol=stringtable.add_string(string_buf);
  return STR_CONST;
}
<INSTRING><<EOF>> {BEGIN(INITIAL);RETURN_ERROR("EOF in string constant");}

%%
void append_str(char c)
{
  if(string_buf_ptr==string_buf+MAX_STR_CONST-1)str_err="String constant too long";
  else *string_buf_ptr++=c;
}