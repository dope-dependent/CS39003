%{
#include <stdio.h>
#include "ass5_19CS30037_translator.h"

extern int yylex();
void yyerror(char *s);
%}

%union
{
        int intval;
        char * string_type;
        Symbol * st_entry;
}

%token STRING_LITERAL IDENTIFIER INT_CONST FLOATING_CONST CHAR_CONST ENUM_CONST SIZEOF OPEN_PARENTHESIS CLOSE_PARENTHESIS OPEN_BRACE CLOSE_BRACE OPEN_BRACKET CLOSE_BRACKET MINUS PLUS COMMA STAR SLASH MOD LESS GREATER INCREMENT DECREMENT LESS_EQUAL GREATER_EQUAL EQUAL NOT_EQUAL B_AND B_OR L_AND L_OR B_XOR ADD_ASSGN SUB_ASSGN MUL_ASSGN DIV_ASSGN MOD_ASSGN L_SHIFT R_SHIFT L_SHIFT_ASSGN R_SHIFT_ASSGN ASSGN TILDE EXCLAM DOT POINTER_DEREF COLON SEMI_COLON QUESTION AND_ASSGN OR_ASSGN XOR_ASSGN EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL COMPLEX IMAGINARY ENUM CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%nonassoc CLOSE_PARENTHESIS
%nonassoc ELSE

%start translation_unit 

%%


/* Expressions */
M: 
 {
      // M is used for backpatching in conditional
      // and control constructs, it stores the address of the
      // next quad which will then be backpatched to the constructs
      $$ = nextinstr();
 }
 ;

N:
 {
      // N is used as a fallthrough guard
      // It inserts a goto statement and stores the index
      // of the next goto
      $$ = new Next();
      $$->nextlist = makelist(nextinstr());
      emit("goto", "");
 }
 ;
primary_expression: IDENTIFIER
                  {     $$ = new Expression();
                        $$->loc = $1;
                        $$->type = "int";
                  }

                  | INT_CONST
                  { 
                        $$ = new Expression();
                        $$->loc = ST->gentemp(new SymbolType("int"));
                        $$->loc->initial_value = conv_int2string($1);
                        emit("=",$$->loc->name, $$->loc->initial_value);
                  }
                  | FLOATING_CONST
                  {
                        $$ = new Expression();
                        $$->loc = ST->gentemp(new SymbolType("float"));
                        $$->loc->initial_value = $1;
                        emit("=", $$->loc->name, $$->loc->initial_value);
                  }
                  | CHAR_CONST 
                  {
                        $$ = new Expression();
                        $$->loc = ST->gentemp(new SymbolType("char"));
                        $$->loc->initial_value = $1;
                        emit("=", $$->loc->name, $$->loc->initial_value);
                  }
                  | STRING_LITERAL
                  { 
                        $$ = new Expression();
                        $$->loc = ST->gentemp(new SymbolType("ptr"));
                        $$->loc->next = new SymbolType("char");
                        $$->loc->initial_value = $1;
                        emit("=", $$->loc->name, $$->loc->initial_value);
                  }

                  | OPEN_PARENTHESIS expression CLOSE_PARENTHESIS
                  { 
                        $$ = $2; 
                  }
                  ;

postfix_expression: primary_expression
                  { 
                        $$ = new Array();
                        $$->array = $1->loc;
                        $$->loc = $1->loc;
                        $$->type = $1->loc->type;
                  }

                  | postfix_expression OPEN_BRACKET expression CLOSE_BRACKET
                  {
                        $$ = new Array();
                        $$->type = $1->type->next;
                        $$->array = $1->array;
                        $$->loc = ST->gentemp(new SymbolType("int"));
                        // Check if we have nested array
                        if ($1->type == "arr") {
                              Symbol * t = ST->gentemp(new SymbolType("int"));
                              // Multiply by the size
                              int t_size = $$->type->getSize();
                              emit("*", t->name, $3->loc->name, conv_int2string(t_size));
                              // Add to the previous size
                              emit("+", $$->loc->name, $1->loc->name, t->name);
                        }
                        // No nested array, directly compute size
                        else {
                              Symbol * t = ST->gentemp(new SymbolType("int"));
                              int t_size = $$->type->getSize();
                              emit("*", $$->loc->name, $3->loc->name, conv_int2string(t_size));
                        }

                  }

                  | postfix_expression OPEN_PARENTHESIS argument_expression_list_opt CLOSE_PARENTHESIS
                  {
                        // Function call
                        $$ = new Array();
                        $$->array = ST->gentemp($1->type);
                        // call function_name and send in the number of parameters ($3)
                        emit("call", $$->array->name, $1->array->name, conv_int2string($3));
                  }

                  | postfix_expression DOT IDENTIFIER { }

                  | postfix_expression POINTER_DEREF IDENTIFIER { }

                  | postfix_expression INCREMENT
                  { 
                        // First store the value in a temporary and then increment by 1
                        $$ = new Array();
                        $$->array = ST->gentemp($1->array->type);
                        emit("=", $$->array->name, $1->array->name);
                        emit("+", $1->array->name, $1->array->name, "1");
                  }

                  | postfix_expression DECREMENT
                  { 
                        // First store the value in a temporary and then decrement by 1
                        $$ = new Array();
                        $$->array = ST->gentemp($1->array->type);
                        emit("=", $$->array->name, $1->array->name);
                        emit("-", $1->array->name, $1->array->name, "1");
                  }

                  | OPEN_PARENTHESIS type_name CLOSE_PARENTHESIS OPEN_BRACE initializer_list CLOSE_BRACE { }

                  | OPEN_PARENTHESIS type_name CLOSE_PARENTHESIS OPEN_BRACE initializer_list COMMA CLOSE_BRACE { }

                  ;


argument_expression_list_opt: argument_expression_list 
                            {
                                  $$ = $1;     // Equal to number of params in list
                            }
                            |
                            {
                                  $$ = 0;      // No parameters
                            }
                            ;

argument_expression_list: assignment_expression
                        { 
                              $$ = 1;          // One argument param parameter_name
                              emit("param", $1->loc->name);
                        }

                        | argument_expression_list COMMA assignment_expression
                        { 
                              // Many emissions of params
                              $$ = $1 + 1;
                              emit("param", $3->loc->name); // Emit the name of the assignment_expression    
                        }
                        ;

unary_expression: postfix_expression
                { 
                      $$ = $1;      // Equate both the expressions
                }

                | INCREMENT unary_expression
                { // Add 1 to the expression and then make them equal
                      emit("+", $2->loc->name, $2->loc->name, "1");
                      $$ = $2;
                }

                | DECREMENT unary_expression
                {
                      // Subtract 1 and then make them equal
                      emit("-", $2->loc->name, $2->loc->name, "1");
                      $$ = $2;
                }     

                | unary_operator cast_expression
                {
                      // Checking all the unary operators one by 1
                      $$ = new Array();
                      // Check first character
                      switch ($1[0]) {
                        case '&':   // Generation of pointer
                                    // The new temp has type ptr(type of $2)
                                    $$->array = ST->gentemp(new SymbolType("ptr"));
                                    $$->array->type->next = $2->array->type;
                                    emit("=&", $$->array->name, $2->array->name);
                                    break;
                        case '*':   // Pointer Dereferencing and value generation
                                    $$->loc = ST->gentemp($2->array->type->next);
                                    $$->array = $2->array;
                                    emit("=*", $$->loc->name, $2->array->name);
                                    break;
                        case '+':   // Unary +, expression copy
                                    $$ = $2;
                                    break;
                        case '-':   // Unary -, create a temporary of same type
                                    $$->array = ST->gentemp(new SymbolType($2->array->type->name));
                                    emit("uminus", $$->array->name, $2->array->name);
                                    break;
                        case '~':   // Bitwise NOT, handled in a similar manner
                                    $$->array = ST->gentemp(new SymbolType($2->array->type->name));
                                    emit("~", $$->array->name, $2->array->name);
                                    break;
                        case '!':   // Logical NOT, generate new temporary of same type
                                    $$->array = ST->gentemp(new SymbolType($2->array->type->name));
                                    emit("!", $$->array->name, $2->array->name);
                                    break;
                      }             
                }

                | SIZEOF unary_expression { }

                | SIZEOF OPEN_PARENTHESIS type_name CLOSE_PARENTHESIS { }
                ;

unary_operator: B_AND
              { $$ = "&"; }
              
              | STAR
              { $$ = "*"; }

              | PLUS 
              { $$ = "+"; }

              | MINUS 
              { $$ = "-"; }

              | TILDE 
              { $$ = "~"; }               

              | EXCLAM 
              { $$ = "!"; }
              ;

cast_expression: unary_expression 
               { 
                     $$ = $1; // Simply equate in the case of unary expression
               }


               | OPEN_PARENTHESIS type_name CLOSE_PARENTHESIS cast_expression 
               { 
                     // If Cast type is given, generate a symbol of 
                     // new type
                     $$ = new Array();
                     $$->array->update(new SymbolType($2));
               }
               ;

multiplicative_expression: cast_expression 
                         { 
                              $$ = new Expression();
                              if ($1->type->name == "arr") {
                                    $$->loc = ST->gentemp($1->loc->type);
                                    emit("=[]", $$->loc->name, $1->array->name, $1->loc->name);
                              }
                              else if ($1->type->name == "ptr") {
                                    $$->loc = $1->loc;
                              }     
                              else {
                                    $$->loc = $1->array;
                              }
                         }

                         | multiplicative_expression STAR cast_expression 
                         { 
                              if (!compare($1->loc, $3->array)) {
                                    cout << "TypeError: Multiplication between inconvertible types\n";
                              }
                              else {
                                    // Types have already been changed
                                    // New temporary for the product
                                    $$ = new Expression();
                                    $$->loc = ST->gentemp($1->loc->type->name);
                                    emit("*", $$->loc->name, $1->loc->name, $3->array->name);
                              }
                         }

                         | multiplicative_expression SLASH cast_expression 
                         { 
                              if (!compare($1->loc, $3->array)) {
                                    cout << "TypeError: Division between inconvertible types\n";
                              }
                              else {
                                    // Types have already been changed
                                    // New temporary for the quotient
                                    $$ = new Expression();
                                    $$->loc = ST->gentemp($1->loc->type->name);
                                    emit("/", $$->loc->name, $1->loc->name, $3->array->name);
                              }
                         }

                         | multiplicative_expression MOD cast_expression 
                         { 
                              if (!compare($1->loc, $3->array)) {
                                    cout << "TypeError: Division between inconvertible types\n";
                              }
                              else {
                                    // Types have already been changed
                                    // New temporary for the remainder
                                    $$ = new Expression();
                                    $$->loc = ST->gentemp($1->loc->type->name);
                                    emit("%", $$->loc->name, $1->loc->name, $3->array->name);
                              }      
                         }

                         ;

additive_expression: multiplicative_expression
                   { 
                        $$ = $1; // Simply equate expressions 
                   }

                   | additive_expression PLUS multiplicative_expression
                   { 
                        // Type checking and conversion first
                        if (!compare($1->loc, $3->array)) {
                              cout << "TypeError: Addition between inconvertible types\n";
                        }
                        else {
                              // Types have already been changed
                              // New temporary for the sum
                              $$ = new Expression();
                              $$->loc = ST->gentemp($1->loc->type->name);
                              emit("+", $$->loc->name, $1->loc->name, $3->array->name);
                        }
                   }

                   | additive_expression MINUS multiplicative_expression
                   { 
                        if (!compare($1->loc, $3->array)) {
                              cout << "TypeError: Subtraction between inconvertible types\n";
                        }
                        else {
                              // Types have already been changed
                              // New temporary for the sum
                              $$ = new Expression();
                              $$->loc = ST->gentemp($1->loc->type->name);
                              emit("-", $$->loc->name, $1->loc->name, $3->array->name);
                        }
                   }

                   ;

shift_expression: additive_expression
                { 
                      $$ = $1; // Equate the expressions
                }

                | shift_expression L_SHIFT additive_expression
                { 
                      // In shift (x << i),x and i must be integers
                      // the $3 must be of integer type
                      if (!($3->type->name == "int" && $1->type->name == "int")) {
                        cout << "TypeError: Bits to shift should be integers\n";
                      }
                      // Else shift and generate temporary
                      else {
                        $$ = new Expression();
                        $$->loc = ST->gentemp(new SymbolType("int"));
                        emit("<<", $$->loc->name, $1->loc->name, $3->loc->name);      
                      }
                }

                | shift_expression R_SHIFT additive_expression
                { // Similar to left shift 
                      if (!($3->type->name == "int" && $1->type->name == "int")) {
                        cout << "TypeError: Bits to shift should be integers\n";
                      }
                      else {
                        $$ = new Expression();
                        $$->loc = ST->gentemp(new SymbolType("int"));
                        emit("<<", $$->loc->name, $1->loc->name, $3->loc->name);      
                      }
                }
                ;

relational_expression: shift_expression
                     { 
                        $$ = $1; // Equate 
                     }

                     | relational_expression LESS shift_expression
                     { 
                        // Again compare symbol types
                        if (!compare($1->loc, $3->loc)) {
                              yyerror("TypeError: Comparison between incompatible types");
                        }
                        else {
                              $$ = new Expression();
                              $$->type == "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit("<", "", $1->loc->name, $3->loc->name); // If a < b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                     }

                     | relational_expression GREATER shift_expression
                     { 
                        // Compare Symbol Types
                        if (!compare($1->loc, $3->loc)) {
                              yyerror("TypeError: Comparison between incompatible types");
                        }
                        else {
                              $$ = new Expression();
                              $$->type == "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit(">", "", $1->loc->name, $3->loc->name); // If a > b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                     }

                     | relational_expression LESS_EQUAL shift_expression
                     { 
                        // Compare Symbol Types
                        if (!compare($1->loc, $3->loc)) {
                              yyerror("TypeError: Comparison between incompatible types");
                        }
                        else {
                              $$ = new Expression();
                              $$->type == "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit("<=", "", $1->loc->name, $3->loc->name); // If a <= b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                     }

                     | relational_expression GREATER_EQUAL shift_expression
                     { 
                        // Compare Symbol Types
                        if (!compare($1->loc, $3->loc)) {
                              yyerror("TypeError: Comparison between incompatible types");
                        }
                        else {
                              $$ = new Expression();
                              $$->type == "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit(">=", "", $1->loc->name, $3->loc->name); // If a > b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                     }

                     ;

equality_expression: relational_expression
                   { $$ = $1; }

                   | equality_expression EQUAL relational_expression
                   { 
                        if (!compare($1->loc, $3->loc)) {
                              yyerror("TypeError: Comparison between incompatible types");
                        }
                        else {
                              // Implicit conversion between bool and int types
                              conv_bool2int($1);
                              conv_bool2int($3);
                              $$ = new Expression();
                              $$->type == "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit("==", "", $1->loc->name, $3->loc->name); // If a > b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                   }

                   | equality_expression NOT_EQUAL relational_expression
                   { 
                        if (!compare($1->loc, $3->loc)) {
                              yyerror("TypeError: Comparison between incompatible types");
                        }
                        else {
                              // Implicit conversion between bool and int types
                              conv_bool2int($1);
                              conv_bool2int($3);
                              $$ = new Expression();
                              $$->type == "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit("!=", "", $1->loc->name, $3->loc->name); // If a > b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                   }

                   ;
                   
and_expression: equality_expression
              { $$ = $1; }

              | and_expression B_AND equality_expression
              { 
                  // compatibility
                  if (!compare($1->loc, $3->loc)) {
                        yyerror("TypeError: Bitwise AND between incompatible types");
                  }
                  else {
                        // Implicit conversion between bool and int types after checking
                        conv_bool2int($1);
                        conv_bool2int($3);
                        $$ = new Expression();
                        $$->type == "int";      // AND will give int type expression
                        $$->loc = gentemp(new SymbolType("int"));
                        emit("&", $$->loc->name, $1->loc->name, $3->loc->name);
                  }                  
              }              
              ;

exclusive_or_expression: and_expression
                       { $$ = $1; }

                       | exclusive_or_expression B_XOR and_expression
                       { 
                            // compatibility
                              if (!compare($1->loc, $3->loc)) {
                                    yyerror("TypeError: Bitwise XOR between incompatible types");
                              }
                              else {
                                    // Implicit conversion between bool and int types after checking
                                    conv_bool2int($1);
                                    conv_bool2int($3);
                                    $$ = new Expression();
                                    $$->type == "int"; // XOR will give int type expression
                                    $$->loc = gentemp(new SymbolType("int"));
                                    emit("^", $$->loc->name, $1->loc->name, $3->loc->name);
                              }   
                       }
                       ;

inclusive_or_expression: exclusive_or_expression
                       { $$ = $1; }

                       | inclusive_or_expression B_OR exclusive_or_expression
                       { 
                              if (!compare($1->loc, $3->loc)) {
                                    yyerror("TypeError: Bitwise XOR between incompatible types");
                              }
                              else {
                                    // Implicit conversion between bool and int types after checking
                                    conv_bool2int($1);
                                    conv_bool2int($3);
                                    $$ = new Expression();
                                    $$->type == "int";      // OR will give int type expression
                                    $$->loc = gentemp(new SymbolType("int"));
                                    emit("|", $$->loc->name, $1->loc->name, $3->loc->name);
                              }
                       }
                       ;

logical_and_expression: inclusive_or_expression
                      { 
                        $$ = $1;
                      }

                      | logical_and_expression L_AND M inclusive_or_expression
                      { 
                        convertIntToBool($1);                                  //convert logical_and_expression to bool
                        convertIntToBool($4);                                  //convert inclusive_or_expression int to bool	
                        $$ = new Expression();                                 
                        $$->type = "bool";                                     // Expression type is bool
                        backpatch($1->truelist, $3);                           //if $1 is true, we move to the next instruction and add a backpatch
                        $$->truelist = $4->truelist;                           //The expression AND is true if the next expression is also true
                        $$->falselist = merge($1->falselist, $4->falselist);   //If either $1 or $t4 are false, then AND is false => merge the falselists
                      }

                      ;

logical_or_expression: logical_and_expression
                     { $$ = $1; }

                     | logical_or_expression L_OR M logical_and_expression
                     { 
                        convertIntToBool($1);                                  // convert logical_and_expression to bool
                        convertIntToBool($4);                                  // convert inclusive_or_expression int to bool	
                        $$ = new Expression();                                 
                        $$->type = "bool";                                     // Expression type is bool
                        backpatch($1->falselist, $3);                          //if $1 is false, we move to the next instruction and add a backpatch
                        $$->falselist = $4->falselist;                         //The expression OR is false if the next expression is also false
                        $$->truelist = merge($1->truelist, $4->truelist);   //If either $1 or $t4 are false, then AND is false => merge the falselists  
                     }
                     ;

conditional_expression: logical_or_expression
                      { $$ = $1; }

                      | logical_or_expression N QUESTION M expression N COLON M conditional_expression
                      { 
                        // E1 N1 ? M1 E2 N2 : M2 E3

///// START FROM HERE                        
                        
                      }

                      ;

assignment_expression: conditional_expression
                     { $$ = $1; }

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
