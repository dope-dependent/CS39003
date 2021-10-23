%{
#include "ass5_19CS30037_translator.h"
#include "ass5_19CS30037.tab.h"

#include <stdlib.h>

extern YYSTYPE yylval;
extern "C" int yylex();
%}

/* Regular Expressions Definitions */
IDENTIFIER     [a-zA-Z_][a-zA-Z0-9_]*
INT_CONST      [1-9][0-9]*|[0]
STRING_LITERAL \"("\'"|"\""|"\?"|"\\"|"\a"|"\b"|"\f"|"\n"|"\r"|"\t"|"\v"|[^\"\\])*\"
FLOATING_CONST [0-9]+[eE][+-]?[0-9]+|[0-9]*\.[0-9]+([eE][+-]?[0-9]+)?|[0-9]+\.([eE][+-]?[0-9]+)?
CHAR_CONST     \'("\'"|"\""|"\?"|"\\"|"\a"|"\b"|"\f"|"\n"|"\r"|"\t"|"\v"|[^\'\\\n])*\'
WS             [ \t]
%x CMT_LINE
%x CMT_BLK

/* Definitions of Rules and Actions */

%%

"//"               BEGIN(CMT_LINE);
"/*"               BEGIN(CMT_BLK);
<CMT_LINE>[^\n]    ;
<CMT_LINE>\n       BEGIN(INITIAL);
<CMT_BLK>[^*]      ;
<CMT_BLK>"*"+[^*/] ;
<CMT_BLK>"*"+"/"   BEGIN(INITIAL);
"sizeof"         { return SIZEOF; }
"extern"         { return EXTERN; }
"static"         { return STATIC; }
"auto"           { return AUTO; }
"register"       { return REGISTER; }
"void"           { return VOID; }
"char"           { return CHAR; }
"short"          { return SHORT; }
"int"            { return INT; }
"long"           { return LONG; }
"float"          { return FLOAT; }
"double"         { return DOUBLE; }
"signed"         { return SIGNED; }
"unsigned"       { return UNSIGNED; }
"_Bool"          { return BOOL; }
"_Complex"       { return COMPLEX; }
"_Imaginary"     { return IMAGINARY; }
"enum"           { return ENUM; }
"const"          { return CONST; }
"restrict"       { return RESTRICT; }
"volatile"       { return VOLATILE; }
"inline"         { return INLINE; }
"case"           { return CASE; }
"default"        { return DEFAULT; }
"if"             { return IF; }
"else"           { return ELSE; }
"switch"         { return SWITCH; }
"while"          { return WHILE; }
"do"             { return DO; }
"for"            { return FOR; }
"goto"           { return GOTO; }
"continue"       { return CONTINUE; }
"break"          { return BREAK; }
"return"         { return RETURN; }

{INT_CONST}      { yylval.intval = atoi(yytext);
                   return INT_CONST; 
                 }

{FLOATING_CONST} { yylval.string_type = yytext;
                   return FLOATING_CONST; 
                 }

{CHAR_CONST}     { yylval.string_type = yytext;
                   return CHAR_CONST; 
                 }

{STRING_LITERAL} { yylval.string_type = yytext;
                   return STRING_LITERAL; 
                 }

{IDENTIFIER}     { 
                   yylval.st_entry = ST->lookup(yytext);
                   return IDENTIFIER; 
                 }
                 
"("              { return OPEN_PARENTHESIS; }
")"              { return CLOSE_PARENTHESIS; }
"{"              { return OPEN_BRACE; }
"}"              { return CLOSE_BRACE; }
"["              { return OPEN_BRACKET; }
"]"              { return CLOSE_BRACKET; }
"+"              { return PLUS; }
"-"              { return MINUS; }
","              { return COMMA; }
"*"              { return STAR; }
"/"              { return SLASH; }
"%"              { return MOD; }
"+="             { return ADD_ASSGN; }
"-="             { return SUB_ASSGN; }
"*="             { return MUL_ASSGN; }
"/="             { return DIV_ASSGN; }
"%="             { return MOD_ASSGN; }
"=="             { return EQUAL; }
"!="             { return NOT_EQUAL; }
"<"              { return LESS; }
">"              { return GREATER; }
"<="             { return LESS_EQUAL; }
">="             { return GREATER_EQUAL; }
"++"             { return INCREMENT; }
"--"             { return DECREMENT; }
"&"              { return B_AND; }
"|"              { return B_OR; }
"&&"             { return L_AND; }
"||"             { return L_OR; }
"^"              { return B_XOR; }
"&="             { return AND_ASSGN; }
"|="             { return OR_ASSGN; }
"^="             { return XOR_ASSGN; }
"<<"             { return L_SHIFT; }
">>"             { return R_SHIFT; }
"<<="            { return L_SHIFT_ASSGN; }
">>="            { return R_SHIFT_ASSGN; }
"="              { return ASSGN; }
"~"              { return TILDE; }
"!"              { return EXCLAM; }
"."              { return DOT; }
"->"             { return POINTER_DEREF; }
":"              { return COLON; }
";"              { return SEMI_COLON; }
"?"              { return QUESTION ; }
{WS}             ;

%%



