%{
#include <stdio.h>
extern int yylex();
void yyerror(char *s);
%}

%union
{
        int intval;
}

%token STRING_LITERAL IDENTIFIER INT_CONST FLOATING_CONST CHAR_CONST ENUM_CONST SIZEOF OPEN_PARENTHESIS CLOSE_PARENTHESIS OPEN_BRACE CLOSE_BRACE OPEN_BRACKET CLOSE_BRACKET MINUS PLUS COMMA STAR SLASH MOD LESS GREATER INCREMENT DECREMENT LESS_EQUAL GREATER_EQUAL EQUAL NOT_EQUAL B_AND B_OR L_AND L_OR B_XOR ADD_ASSGN SUB_ASSGN MUL_ASSGN DIV_ASSGN MOD_ASSGN L_SHIFT R_SHIFT L_SHIFT_ASSGN R_SHIFT_ASSGN ASSGN TILDE EXCLAM DOT POINTER_DEREF COLON SEMI_COLON QUESTION AND_ASSGN OR_ASSGN XOR_ASSGN EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL COMPLEX IMAGINARY ENUM CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%nonassoc CLOSE_PARENTHESIS
%nonassoc ELSE

%start translation_unit 

%%


/* Expressions */

primary_expression: IDENTIFIER
                  { printf("primary-expression -> identifier\n"); }

                  | constant
                  { printf("primary-expression -> constant\n"); }

                  | STRING_LITERAL
                  { printf("primary-expression -> string-literal\n"); }

                  | OPEN_PARENTHESIS expression CLOSE_PARENTHESIS
                  { printf("primary-expression -> ( expression )\n"); }

                  ;

constant: INT_CONST
        | FLOATING_CONST
        | CHAR_CONST
        | ENUM_CONST
        ;

postfix_expression: primary_expression
                  { printf("postfix-expression -> primary-expression\n"); }

                  | postfix_expression OPEN_BRACKET expression CLOSE_BRACKET
                  { printf("postfix-expression -> postfix-expression [ expression ]\n"); }

                  | postfix_expression OPEN_PARENTHESIS argument_expression_list_opt CLOSE_PARENTHESIS
                  { printf("postfix-expression -> postfix-expression ( argument-expression-list(opt) )\n"); }

                  | postfix_expression DOT IDENTIFIER
                  { printf("postfix-expression -> postfix-expression . identifier\n"); }

                  | postfix_expression POINTER_DEREF IDENTIFIER
                  { printf("postfix-expression -> postfix-expression −> identifier\n"); }

                  | postfix_expression INCREMENT
                  { printf("postfix-expression -> postfix-expression++\n"); }

                  | postfix_expression DECREMENT
                  { printf("postfix-expression -> postfix-expression--\n"); }

                  | OPEN_PARENTHESIS type_name CLOSE_PARENTHESIS OPEN_BRACE initializer_list CLOSE_BRACE
                  { printf("postfix-expression -> ( type-name ) { initializer-list }\n"); }

                  | OPEN_PARENTHESIS type_name CLOSE_PARENTHESIS OPEN_BRACE initializer_list COMMA CLOSE_BRACE
                  { printf("postfix-expression -> ( type-name ) { initializer-list , }\n"); }

                  ;

argument_expression_list_opt: argument_expression_list
                            |
                            ;

argument_expression_list: assignment_expression
                        { printf("assignment-expression-list -> assignment-expression\n"); }

                        | argument_expression_list COMMA assignment_expression
                        { printf("assignment-expression-list -> argument-expression-list , assignment-expression\n"); }

                        ;

unary_expression: postfix_expression
                { printf("unary-expression -> postfix-expression\n"); }

                | INCREMENT unary_expression
                { printf("unary-expression -> ++unary-expression\n"); }

                | DECREMENT unary_expression
                { printf("unary-expression -> --unary-expression\n"); }

                | unary_operator cast_expression
                { printf("unary-expression -> unary-operator cast-expression\n"); }

                | SIZEOF unary_expression
                { printf("unary-expression -> sizeof unary-expression\n"); }

                | SIZEOF OPEN_PARENTHESIS type_name CLOSE_PARENTHESIS
                { printf("unary-expression -> sizeof ( type-name )\n"); }

                ;

unary_operator: B_AND
              { printf("unary-operator -> &\n"); }

              | STAR
              { printf("unary-operator -> *\n"); }

              | PLUS 
              { printf("unary-operator -> +\n"); }

              | MINUS 
              { printf("unary-operator -> -\n"); }

              | TILDE 
              { printf("unary-operator -> ~\n"); }               

              | EXCLAM 
              { printf("unary-operator -> !\n"); }

              ;

cast_expression: unary_expression 
               { printf("cast-expression -> unary-expression\n"); }


               | OPEN_PARENTHESIS type_name CLOSE_PARENTHESIS cast_expression 
               { printf("cast-expression -> ( type-name ) cast-expression\n"); }

               ;

multiplicative_expression: cast_expression 
                         { printf("multiplicative-expression -> cast-expression\n"); }

                         | multiplicative_expression STAR cast_expression 
                         { printf("multiplicative-expression -> multiplicative-expression ∗ cast-expression\n"); }

                         | multiplicative_expression SLASH cast_expression 
                         { printf("multiplicative-expression -> multiplicative-expression / cast-expression\n"); }

                         | multiplicative_expression MOD cast_expression 
                         { printf("multiplicative-expression -> multiplicative-expression %% cast-expression\n"); }

                         ;

additive_expression: multiplicative_expression
                   { printf("additive-expression -> multiplicative-expression\n"); }

                   | additive_expression PLUS multiplicative_expression
                   { printf("additive-expression -> additive-expression + multiplicative-expression\n"); }

                   | additive_expression MINUS multiplicative_expression
                   { printf("additive-expression -> additive-expression − multiplicative-expression\n"); }

                   ;

shift_expression: additive_expression
                { printf("shift-expression -> additive-expression\n"); }

                | shift_expression L_SHIFT additive_expression
                { printf("shift-expression -> shift-expression << additive-expression\n"); }

                | shift_expression R_SHIFT additive_expression
                { printf("shift-expression -> hift-expression >> additive-expression\n"); }

                ;

relational_expression: shift_expression
                     { printf("relational-expression -> shift-expression\n"); }

                     | relational_expression LESS shift_expression
                     { printf("relational-expression -> relational-expression < shift-expression\n"); }

                     | relational_expression GREATER shift_expression
                     { printf("relational-expression -> relational-expression > shift-expression\n"); }

                     | relational_expression LESS_EQUAL shift_expression
                     { printf("relational-expression -> relational-expression <= shift-expression\n"); }

                     | relational_expression GREATER_EQUAL shift_expression
                     { printf("relational-expression -> relational-expression >= shift-expression\n"); }

                     ;

equality_expression: relational_expression
                   { printf("equality-expression -> relational-expression\n"); }

                   | equality_expression EQUAL relational_expression
                   { printf("equality-expression -> equality-expression == relational-expression\n"); }

                   | equality_expression NOT_EQUAL relational_expression
                   { printf("equality-expression -> equality-expression != relational-expression\n"); }

                   ;
                   
and_expression: equality_expression
              { printf("AND-expression -> equality-expression\n"); }

              | and_expression B_AND equality_expression
              { printf("AND-expression -> AND-expression & equality-expression\n"); }
              
              ;

exclusive_or_expression: and_expression
                       { printf("exclusive-OR-expression -> AND-expression\n"); }

                       | exclusive_or_expression B_XOR and_expression
                       { printf("exclusive-OR-expression -> exclusive-OR-expression ^ AND-expression\n"); }

                       ;

inclusive_or_expression: exclusive_or_expression
                       { printf("inclusive-OR-expression -> exclusive-OR-expression\n"); }

                       | inclusive_or_expression B_OR exclusive_or_expression
                       { printf("inclusive-OR-expression -> inclusive-OR-expression | exclusive-OR-expression\n"); }

                       ;

logical_and_expression: inclusive_or_expression
                      { printf("logical-AND-expression -> inclusive-OR-expression\n"); }

                      | logical_and_expression L_AND inclusive_or_expression
                      { printf("logical-AND-expression -> logical-AND-expression && inclusive-OR-expression\n"); }

                      ;

logical_or_expression: logical_and_expression
                     { printf("logical-OR-expression -> logical-AND-expression\n"); }

                     | logical_or_expression L_OR logical_and_expression
                     { printf("logical-OR-expression -> logical-OR-expression || logical-AND-expression\n"); }

                     ;

conditional_expression: logical_or_expression
                      { printf("conditional-expression -> logical-OR-expression\n"); }

                      | logical_or_expression QUESTION expression COLON conditional_expression
                      { printf("conditional-expression -> logical-OR-expression ? expression : conditional-expression\n"); }

                      ;

assignment_expression: conditional_expression
                     { printf("assignment-expression -> conditional-expression\n"); }

                     | unary_expression assignment_operator assignment_expression
                     { printf("assignment-expression -> unary-expression assignment-operator assignment-expression\n"); }
                     
                     ;

assignment_expression_opt:
                         | assignment_expression
                         ;

assignment_operator: ASSGN 
                   { printf("assignment-operator -> =\n"); }

                   | MUL_ASSGN 
                   { printf("assignment-operator -> *=\n"); }
                   
                   | DIV_ASSGN 
                   { printf("assignment-operator -> /=\n"); }
                   
                   | MOD_ASSGN 
                   { printf("assignment-operator -> %%=\n"); }
                   
                   | ADD_ASSGN 
                   { printf("assignment-operator -> +=\n"); }
                   
                   | SUB_ASSGN
                   { printf("assignment-operator -> -=\n"); }
                   
                   | L_SHIFT_ASSGN 
                   { printf("assignment-operator -> <<=\n"); }
                   
                   | R_SHIFT_ASSGN 
                   { printf("assignment-operator -> >>=\n"); }
                   
                   | AND_ASSGN 
                   { printf("assignment-operator -> &=\n"); }
                   
                   | XOR_ASSGN 
                   { printf("assignment-operator -> ^=\n"); }
                   
                   | OR_ASSGN
                   { printf("assignment-operator -> |=\n"); }
                   
                   ;

expression: assignment_expression
          { printf("expression -> assignment-expression\n"); }
                   
          | expression COMMA assignment_expression
          { printf("expression -> expression , assignment-expression\n"); }
                   
          ;

constant_expression: conditional_expression
                   { printf("constant-expression -> conditional-expression\n"); }
                   
                   ;

/* Declarations */

declaration: declaration_specifiers init_declarator_list_opt SEMI_COLON
           { printf("declaration -> declaration-specifiers init-declarator-list(opt) ;\n"); }
                   
           ;

declaration_specifiers: storage_class_specifier declaration_specifiers_opt
                      { printf("declaration-specifiers -> storage-class-specifier declaration-specifiers(opt)\n"); }
                   
                      | type_specifier declaration_specifiers_opt
                      { printf("declaration-specifiers -> type-specifier declaration-specifiers(opt)\n"); }
                   
                      | type_qualifier declaration_specifiers_opt
                      { printf("declaration-specifiers -> type-qualifier declaration-specifiers(opt)\n"); }
                   
                      | function_specifier declaration_specifiers_opt
                      { printf("declaration-specifiers -> function-specifier declaration-specifiers(opt)\n"); }

                      ;
                   
declaration_specifiers_opt:
                          | declaration_specifiers
                          ;

init_declarator_list: init_declarator
                    { printf("init-declarator-list -> init-declarator\n"); }
                   
                    | init_declarator_list COMMA init_declarator
                    { printf("init-declarator-list -> init-declarator-list , init-declarator\n"); }
                   
                    ;

init_declarator_list_opt:
                        | init_declarator_list
                        ;

init_declarator: declarator
               { printf("init-declarator -> declarator\n"); }
                   
               | declarator ASSGN initializer
               { printf("init-declarator -> declarator = initializer\n"); }
                   
               ;

storage_class_specifier: EXTERN
                       { printf("storage-class-specifier -> extern\n"); }
                   
                       | STATIC
                       { printf("storage-class-specifier -> static\n"); }
                   
                       | AUTO
                       { printf("storage-class-specifier -> auto\n"); }
                   
                       | REGISTER
                       { printf("storage-class-specifier -> register\n"); }
                   
                       ;

type_specifier: VOID
              { printf("type-specifier -> void\n"); }
                   
              | CHAR
              { printf("type-specifier -> char\n"); }
                   
              | SHORT
              { printf("type-specifier -> short\n"); }
                   
              | INT
              { printf("type-specifier -> int\n"); }
                   
              | LONG
              { printf("type-specifier -> long\n"); }
                   
              | FLOAT
              { printf("type-specifier -> float\n"); }
                   
              | DOUBLE
              { printf("type-specifier -> double=\n"); }
                   
              | SIGNED
              { printf("type-specifier -> signed\n"); }
                   
              | UNSIGNED
              { printf("type-specifier -> unsigned\n"); }
                   
              | BOOL
              { printf("type-specifier -> _Bool\n"); }
                   
              | COMPLEX
              { printf("type-specifier -> _Complex\n"); }
                   
              | IMAGINARY
              { printf("type-specifier -> _Imaginary\n"); }
                   
              | enum_specifier
              { printf("type-specifier -> enum-specifier\n"); }
                   
              ;

specifier_qualifier_list: type_specifier specifier_qualifier_list_opt
                        { printf("specifier-qualifier-list -> type-specifier specifier-qualifier-list(opt)\n"); }
                   
                        | type_qualifier specifier_qualifier_list_opt
                        { printf("specifier-qualifier-list -> type-qualifier specifier-qualifier-list(opt)\n"); }
                   
                        ;

specifier_qualifier_list_opt:
                            | specifier_qualifier_list
                            ;

enum_specifier: ENUM identifier_opt OPEN_BRACE enumerator_list CLOSE_BRACE
              { printf("enum-specifier -> enum identifier(opt) { enumerator-list }\n"); }
                   
              | ENUM identifier_opt OPEN_BRACE enumerator_list COMMA CLOSE_BRACE
              { printf("enum-specifier -> enum identifier(opt) { enumerator-list , }\n"); }
                   
              | ENUM IDENTIFIER
              { printf("enum-specifier -> enum identifier\n"); }
                   
              ;

identifier_opt: 
              | IDENTIFIER
              ;
              
enumerator_list: enumerator
               { printf("enumerator-list -> enumerator\n"); }
                   
               | enumerator_list COMMA enumerator
               { printf("enumerator-list -> enumerator-list , enumerator\n"); }
                   
               ;

enumerator: IDENTIFIER
          { printf("enumerator -> enumeration-constant\n"); }
                   
          | IDENTIFIER ASSGN constant_expression
          { printf("enumerator -> enumeration-constant = constant-expression\n"); }
                   
          ;

type_qualifier: CONST
              { printf("type-qualifier -> const\n"); }
                   
              | RESTRICT
              { printf("type-qualifier -> restrict\n"); }
                   
              | VOLATILE
              { printf("type-qualifier -> volatile\n"); }
                   
              ;
 
function_specifier: INLINE
                  { printf("function-specifier -> inline\n"); }
                   
                  ;

declarator: pointer_opt direct_declarator
          { printf("declarator -> pointer(opt) direct-declarator\n"); }
                   
          ;

pointer_opt: 
           | pointer
           ;

direct_declarator: IDENTIFIER
                 { printf("direct-declarator -> identifier\n"); }
                   
                 | OPEN_PARENTHESIS declarator CLOSE_PARENTHESIS
                 { printf("direct-declarator -> ( declarator )\n"); }
                   
                 | direct_declarator OPEN_BRACKET type_qualifier_list_opt assignment_expression_opt CLOSE_BRACKET
                 { printf("direct-declarator -> direct-declarator [ type-qualifier-list(opt) assignment-expression(opt) ]\n"); }
                   
                 | direct_declarator OPEN_BRACKET STATIC type_qualifier_list_opt assignment_expression CLOSE_BRACKET
                 { printf("direct-declarator -> direct-declarator [ static type-qualifier-list(opt) assignment-expression ]\n"); }
                   
                 | direct_declarator OPEN_BRACKET type_qualifier_list STATIC assignment_expression CLOSE_BRACKET
                 { printf("direct-declarator -> direct-declarator [ type-qualifier-list static assignment-expression ]\n"); }
                   
                 | direct_declarator OPEN_BRACKET type_qualifier_list_opt STAR CLOSE_BRACKET
                 { printf("direct-declarator -> direct-declarator [ type-qualifier-listopt * ]\n"); }
                   
                 | direct_declarator OPEN_PARENTHESIS parameter_type_list CLOSE_PARENTHESIS
                 { printf("direct-declarator -> direct-declarator ( parameter-type-list )\n"); }
                   
                 | direct_declarator OPEN_PARENTHESIS identifier_list_opt CLOSE_PARENTHESIS
                 { printf("direct-declarator -> ( identifier-list(opt) )\n"); }
                   
                 ;

pointer: STAR type_qualifier_list_opt
       { printf("pointer -> * type-qualifier-list(opt)\n"); }
                   
       | STAR type_qualifier_list_opt pointer
       { printf("pointer -> * type-qualifier-list(opt) pointer\n"); }
                   
       ;

type_qualifier_list: type_qualifier
                   { printf("type-qualifier-list -> type-qualifier\n"); }
                   
                   | type_qualifier_list type_qualifier
                   { printf("type-qualifier-list -> type-qualifier-list type-qualifier\n"); }
                   
                   ;

type_qualifier_list_opt: 
                       | type_qualifier_list
                       ;

parameter_type_list: parameter_list
                   { printf("parameter-type-list -> parameter-list\n"); }
                   
                   | parameter_list COMMA DOT DOT DOT
                   { printf("parameter-type-list -> parameter-list , ...\n"); }
                   
                   ;

parameter_list: parameter_declaration
              { printf("parameter-list -> parameter-declaration\n"); }
                   
              | parameter_list COMMA parameter_declaration
              { printf("parameter-list -> parameter-list , parameter-declaration\n"); }
                   
              ;

parameter_declaration: declaration_specifiers declarator
                     { printf("parameter-declaration -> declaration-specifiers declarator\n"); }
                   
                     | declaration_specifiers
                     { printf("parameter-declaration -> declaration-specifiers\n"); }
                   
                     ;

identifier_list: IDENTIFIER
               { printf("identifier-list -> identifier\n"); }
                   
               | identifier_list COMMA IDENTIFIER
               { printf("identifier-list -> identifier-list , identifier\n"); }
                   
               ;

identifier_list_opt:
                   | identifier_list
                   ;

type_name: specifier_qualifier_list
         { printf("type-name -> specifier-qualifier-list\n"); }
                   
         ;

initializer: assignment_expression
           { printf("initializer -> assignment-expression\n"); }
                   
           | OPEN_BRACE initializer_list CLOSE_BRACE
           { printf("initializer -> { initializer-list }\n"); }
                   
           | OPEN_BRACE initializer_list COMMA CLOSE_BRACE
           { printf("initializer -> { initializer-list , }\n"); }
                   
           ;

initializer_list: designation_opt initializer
                { printf("initializer-list -> designation(opt) initializer\n"); }
                   
                | initializer_list COMMA designation_opt initializer
                { printf("initializer-list -> initializer-list , designation(opt) initializer\n"); }
                   
                ;

designation: designator_list ASSGN
           { printf("designation -> designator-list =\n"); }
                   
           ;

designation_opt: 
               | designation
               ;

designator_list: designator
               { printf("designator-list -> designator\n"); }
                   
               | designator_list designator
               { printf("designator-list -> designator-list designator\n"); }
                   
               ;

designator: OPEN_BRACKET constant_expression CLOSE_BRACKET
          { printf("designator -> [ constant-expression ]\n"); }
                   
          | DOT IDENTIFIER
          { printf("designator -> . identifier\n"); }
                   
          ;

/* Statements */

statement: labeled_statement
         { printf("statement -> labeled-statement\n"); }
                   
         | compound_statement
         { printf("statement -> compound-statement\n"); }
                   
         | expression_statement
         { printf("statement -> expression-statement\n"); }
                   
         | selection_statement
         { printf("statement -> selection-statement\n"); }
                   
         | iteration_statement
         { printf("statement -> iteration-statement\n"); }
                   
         | jump_statement
         { printf("statement -> jump-statement\n"); }
                   
         ;

labeled_statement: IDENTIFIER COLON statement
                 { printf("labeled-statement -> identifier : statement\n"); }
                   
                 | CASE constant_expression COLON statement
                 { printf("labeled-statement -> case constant-expression : statement\n"); }
                   
                 | DEFAULT COLON statement
                 { printf("labeled-statement -> default : statement\n"); }
                   
                 ;

compound_statement: OPEN_BRACE block_item_list_opt CLOSE_BRACE
                  { printf("compound-statement -> { block-item-list(opt) }\n"); }
                   
                  ;

block_item_list: block_item
               { printf("block-item-list -> block-item\n"); }
                   
               | block_item_list block_item
               { printf("block-item-list -> block-item-list block-item\n"); }
                   
               ;

block_item_list_opt:
                   | block_item_list
                   ;

block_item: declaration
          { printf("block-item -> declaration\n"); }
                   
          | statement
          { printf("block-item -> statement\n"); }

          ;               

expression_statement: expression_opt SEMI_COLON
                    { printf("expression-statement -> expression(opt) ;\n"); }
                   
                    ;
                    
expression_opt:
              | expression
              ;

selection_statement: IF OPEN_PARENTHESIS expression CLOSE_PARENTHESIS statement
                   { printf("selection-statement -> if ( expression ) statement\n"); }
                   
                   | IF OPEN_PARENTHESIS expression CLOSE_PARENTHESIS statement ELSE statement
                   { printf("selection-statement -> if ( expression ) statement else statement\n"); }
                   
                   | SWITCH OPEN_PARENTHESIS expression CLOSE_PARENTHESIS statement
                   { printf("selection-statement -> switch ( expression ) statement\n"); }
                   
                   ;

iteration_statement: WHILE OPEN_PARENTHESIS expression CLOSE_PARENTHESIS statement
                   { printf("iteration-statement -> while ( expression ) statement\n"); }
                   
                   | DO statement WHILE OPEN_PARENTHESIS expression CLOSE_PARENTHESIS SEMI_COLON
                   { printf("iteration-statement -> do statement while ( expression ) ;\n"); }
                   
                   | FOR OPEN_PARENTHESIS expression_opt SEMI_COLON expression_opt SEMI_COLON expression_opt CLOSE_PARENTHESIS statement
                   { printf("iteration-statement -> for ( expression(opt) ; expression(opt) ; expression(opt) ) statement\n"); }
                   
                   | FOR OPEN_PARENTHESIS declaration expression_opt SEMI_COLON expression_opt CLOSE_PARENTHESIS statement
                   { printf("iteration-statement -> for ( declaration  expression(opt) ; expression(opt) ) statement\n"); }
                   
                   ;

jump_statement: GOTO IDENTIFIER SEMI_COLON
              { printf("jump-statement -> goto identifier ;\n"); }
                   
              | CONTINUE SEMI_COLON
              { printf("jump-statement -> continue ;\n"); }
                   
              | BREAK SEMI_COLON
              { printf("jump-statement -> break ;\n"); }
                   
              | RETURN expression_opt SEMI_COLON
              { printf("jump-statement -> return expression(opt) ;\n"); }
                   
              ;

/* External definitions */

translation_unit: external_declaration
                { printf("translation-unit -> external-declaration\n\n\n"); }
                   
                | translation_unit external_declaration
                { printf("translation-unit -> translation-unit external-declaration\n\n\n"); }
                   
                ;

external_declaration: function_definition
                    { printf("external-declaration -> function-definition\n"); }
                   
                    | declaration
                    { printf("external-declaration -> declaration\n"); }
                   
                    ;
                    
function_definition: declaration_specifiers declarator declaration_list_opt compound_statement
                   { printf("function-definition -> declaration-specifiers declarator declaration-list(opt) compound-statement\n"); }
                   
                   ;

declaration_list: declaration
                { printf("declaration-list -> declaration\n"); }
                   
                | declaration_list declaration
                { printf("declaration-list -> declaration-list declaration\n"); }
                   
                ;

declaration_list_opt: 
                    | declaration_list
                    ;


%%

void yyerror(char *s)
{
        printf("Error: %s\n", s);
        return;
}

