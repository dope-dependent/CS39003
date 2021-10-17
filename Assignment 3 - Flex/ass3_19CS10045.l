%{
#define KEYWORD        10
#define ID             11
#define INT_CONST      12
#define PUNCTUATOR     13
#define STRING_LITERAL 14
#define FLOATING_CONST 15
#define CHAR_CONST     16
%}

/* Regular Expressions Definitions */
KEYWORD        "auto"|"break"|"case"|"char"|"const"|"continue"|"default"|"do"|"double"|"else"|"enum"|"extern"|"float"|"for"|"goto"|"if"|"inline"|"int"|"long"|"register"|"restrict"|"return"|"short"|"signed"|"sizeof"|"static"|"struct"|"switch"|"typedef"|"union"|"unsigned"|"void"|"volatile"|"while"|"_Bool"|"_Complex"|"_Imaginary"
ID             [a-zA-Z_][a-zA-Z0-9_]*
INT_CONST      [1-9][0-9]*
PUNCTUATOR     "["|"]"|"("|")"|"{"|"}"|"."|"->"|"++"|"--"|"&"|"*"|"+"|"-"|"~"|"!"|"/"|"%"|"<<"|">>"|"<"|">"|"<="|">="|"=="|"!="|"^"|"|"|"&&"|"||"|"?"|":"|";"|"..."|"="|"*="|"/="|"%="|"+="|"-="|"<<="|">>="|"&="|"^="|"|="|","|"#"
STRING_LITERAL \"("\\\'"|"\\\""|"\?"|"\\"|"\a"|"\b"|"\f"|"\n"|"\r"|"\t"|"\v"|[^\"\\\n])*\"
FLOATING_CONST [0-9]+[eE][+-]?[0-9]+|[0-9]*\.[0-9]+([eE][+-]?[0-9]+)?|[0-9]+\.([eE][+-]?[0-9]+)?
CHAR_CONST     \'("\\\'"|"\\\""|"\?"|"\\"|"\a"|"\b"|"\f"|"\n"|"\r"|"\t"|"\v"|[^\'\\\n])*\'
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
{KEYWORD}          { return KEYWORD; }
{INT_CONST}        { return INT_CONST; }
{FLOATING_CONST}   { return FLOATING_CONST; }
{CHAR_CONST}       { return CHAR_CONST; }
{STRING_LITERAL}   { return STRING_LITERAL; }
{ID}               { return ID; }
{PUNCTUATOR}       { return PUNCTUATOR; }
{WS}               ;

%%



