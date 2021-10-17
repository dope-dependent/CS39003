/* Assignment 3 main function file*/
/* ROLL NO - 19CS10045, 19CS30037 */
/* GROUP   - 11                   */

#include <stdio.h>

#define KEYWORD        10
#define ID             11
#define INT_CONST      12
#define PUNCTUATOR     13
#define STRING_LITERAL 14
#define FLOATING_CONST 15
#define CHAR_CONST     16

extern int yylex();
extern char *yytext;

int main()
{
	int token;
	while (token = yylex())
	{
		switch(token)
		{
			case KEYWORD: printf("<KEYWORD: %s>\n", yytext); break;
			case ID: printf("<ID: %s>\n", yytext); break;
			case INT_CONST: printf("<INT_CONST: %s>\n", yytext); break;
			case FLOATING_CONST: printf("<FLOATING_CONST: %s>\n", yytext); break;
			case STRING_LITERAL: printf("<STRING_LITERAL: %s>\n", yytext); break;
			case CHAR_CONST: printf("<CHAR_CONST: %s>\n", yytext); break;
			case PUNCTUATOR: printf("<PUNCTUATOR: %s>\n", yytext); break;
		}
	}
	return 0;
}
