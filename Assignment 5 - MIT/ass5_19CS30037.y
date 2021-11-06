%{
#define YYDEBUG 1
#include <stdio.h>
#include "ass5_19CS30037_translator.h"
using namespace std;

extern "C" int yylex();
void yyerror(string s);
extern vector<Label> label_table; // The collection of all label vectors
extern char * variable_type;      // Global variable which controls the type of the most recent identifier
%}

%union
{
      int intval;
      char * string_type;
      Symbol * st_entry;
      Array * ar_entry;
      Next * statement_entry;
      Expression * exp_entry;
      SymbolType * s_type;
      const char * u_op;
}

%token SIZEOF OPEN_PARENTHESIS CLOSE_PARENTHESIS OPEN_BRACE CLOSE_BRACE OPEN_BRACKET CLOSE_BRACKET MINUS PLUS COMMA STAR SLASH MOD LESS GREATER INCREMENT DECREMENT LESS_EQUAL GREATER_EQUAL EQUAL NOT_EQUAL B_AND B_OR L_AND L_OR B_XOR ADD_ASSGN SUB_ASSGN MUL_ASSGN DIV_ASSGN MOD_ASSGN L_SHIFT R_SHIFT L_SHIFT_ASSGN R_SHIFT_ASSGN ASSGN TILDE EXCLAM DOT POINTER_DEREF COLON SEMI_COLON QUESTION AND_ASSGN OR_ASSGN XOR_ASSGN EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL COMPLEX IMAGINARY ENUM CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%token <st_entry> IDENTIFIER
%token <intval> INT_CONST
%token <string_type> STRING_LITERAL FLOATING_CONST CHAR_CONST

%start translation_unit 

%type <u_op>
      unary_operator

%type <exp_entry>
      expression
	primary_expression 
	multiplicative_expression
	additive_expression
	shift_expression
	relational_expression
	equality_expression
	and_expression
	exclusive_or_expression
	inclusive_or_expression
	logical_and_expression
	logical_or_expression
	conditional_expression
	assignment_expression
	expression_statement
      constant_expression

%type <ar_entry>
      postfix_expression
	unary_expression
	cast_expression

%type <statement_entry>
      statement
      compound_statement
	selection_statement
	iteration_statement
	labeled_statement 
	jump_statement
	block_item
	block_item_list
	block_item_list_opt
      N

%type <st_entry>  
      initializer
      direct_declarator 
      init_declarator 
      declarator

%type <s_type> 
      pointer

%type <intval>
      argument_expression_list
      argument_expression_list_opt
      M

// dangling else problem
%right "then" ELSE



%%


/* Expressions */
M: %empty
 {
      // M is used for backpatching in conditional
      // and control constructs, it stores the address of the
      // next quad which will then be backpatched to the constructs
      $$ = nextinstr();
 }
 ;

N: %empty
 {
      // N is used as a fallthrough guard
      // It inserts a goto statement and stores the index
      // of the next goto
      $$ = new Next();
      $$->nextlist = makelist(nextinstr());
      emit("goto", "");
 }
 ;
X: %empty
	{
            // Change the current symbol pointer
            // Used in statements involving nested blocks
		string name = ST->name+".$"+to_string(table_count); // give name for nested table
		table_count++; // increment the table count
		Symbol* s = ST->lookup(name); // lookup the table for new entry
		s->nested_table = new Symboltable(name);
            STS.add(s->nested_table);
		s->nested_table->parent = ST;
		s->name = name;
		s->type = new SymbolType("block");
            s->size = 0;
		curr_symbol = s;
	}  
	;

blocktable: %empty
            {
                  if(curr_symbol->nested_table==nullptr) 
                  {
                        Symboltable *_new = new Symboltable("");
                        _new->parent = ST;
                        STS.add(_new);
                        updateSymbolTable(_new); // Function symbol table doesn't already exist
                  }
                  else 
                  {
                        updateSymbolTable(curr_symbol->nested_table); // Function symbol table already exists	
                        emit("label", ST->name);
                  }   
            }
            ;
changetable: %empty
            {
                  if(curr_symbol->nested_table==nullptr) 
                  {
                        Symboltable *_new = new Symboltable("");
                        _new->parent = ST;
                        STS.add(_new);
                        updateSymbolTable(_new); // Function symbol table doesn't already exist
                  }
                  else 
                  {
                        updateSymbolTable(curr_symbol->nested_table); // Function symbol table already exists	
                        emit("func", ST->name);
                  }
            }
            ;
primary_expression: IDENTIFIER
                  {     
                        $$ = new Expression();
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
                        $$->loc->initial_value = string($1);
                        emit("=", $$->loc->name, $$->loc->initial_value);
                  }
                  | CHAR_CONST 
                  {
                        $$ = new Expression();
                        $$->loc = ST->gentemp(new SymbolType("char"));
                        $$->loc->initial_value = string($1);
                        emit("=", $$->loc->name, $$->loc->initial_value);
                  }
                  | STRING_LITERAL
                  { 
                        $$ = new Expression();
                        $$->loc = ST->gentemp(new SymbolType("ptr"));
                        $$->loc->type->next = new SymbolType("char");
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
                        $$->type = $1->type->next;    // 
                        $$->array = $1->array;        // 
                        $$->loc = ST->gentemp(new SymbolType("int"));
                        // Check if we have nested array
                        $$->variety = "arr";
                        if ($1->variety == "arr") {
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
                            | %empty
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
                        case '*':   // Pointer array
                                    $$->loc = ST->gentemp($2->array->type->next);
                                    $$->array = $2->array;
                                    emit("=*", $$->loc->name, $2->array->name);
                                    $$->variety = "ptr";
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
              { $$ = (char *)("&"); }
              
              | STAR
              { $$ = (char *)("*"); }

              | PLUS 
              { $$ = (char *)("+"); }

              | MINUS 
              { $$ = (char *)("-"); }

              | TILDE 
              { $$ = (char *)("~"); }               

              | EXCLAM 
              { $$ = (char *)("!"); }
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
                     $$->array->update(new SymbolType(variable_type));
               }
               ;

multiplicative_expression: cast_expression 
                         { 
                              $$ = new Expression();
                              if ($1->variety == "arr") {
                                    $$->loc = ST->gentemp($1->loc->type);
                                    emit("=[]", $$->loc->name, $1->array->name, $1->loc->name);
                              }
                              else if ($1->variety == "ptr") {
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
                                    $$->loc = ST->gentemp($1->loc->type);
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
                                    $$->loc = ST->gentemp($1->loc->type);
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
                                    $$->loc = ST->gentemp($1->loc->type);
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
                        if (!compare($1->loc, $3->loc)) {
                              cout << "TypeError: Addition between inconvertible types\n";
                        }
                        else {
                              // Types have already been changed
                              // New temporary for the sum
                              $$ = new Expression();
                              $$->loc = ST->gentemp($1->loc->type);
                              emit("+", $$->loc->name, $1->loc->name, $3->loc->name);
                        }
                   }

                   | additive_expression MINUS multiplicative_expression
                   { 
                        if (!compare($1->loc, $3->loc)) {
                              cout << "TypeError: Subtraction between inconvertible types\n";
                        }
                        else {
                              // Types have already been changed
                              // New temporary for the sum
                              $$ = new Expression();
                              $$->loc = ST->gentemp($1->loc->type);
                              emit("-", $$->loc->name, $1->loc->name, $3->loc->name);
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
                      if (!($3->loc->type->name == "int" && $1->loc->type->name == "int")) {
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
                      if (!($3->loc->type->name == "int" && $1->loc->type->name == "int")) {
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
                              yyerror(string("TypeError: Comparison between incompatible types"));
                        }
                        else {
                              
                              $$ = new Expression();
                              $$->loc = ST->gentemp(new SymbolType("int"));
                              $$->type = "bool";     // New expression of type bool
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
                              yyerror(string("TypeError: Comparison between incompatible types"));
                        }
                        else {
                              $$ = new Expression();
                              $$->loc = ST->gentemp(new SymbolType("int"));
                              $$->type = "bool";     // New expression of type bool
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
                              yyerror(string("TypeError: Comparison between incompatible types"));
                        }
                        else {
                              $$ = new Expression();
                              $$->loc = ST->gentemp(new SymbolType("int"));
                              $$->type = "bool";     // New expression of type bool
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
                              yyerror(string("TypeError: Comparison between incompatible types"));
                        }
                        else {
                              $$ = new Expression();
                              $$->loc = ST->gentemp(new SymbolType("int"));
                              $$->type = "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit(">=", "", $1->loc->name, $3->loc->name); // If a > b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                     }

                     ;

equality_expression: relational_expression
                   {    
                        $$ = $1; 
                   }

                   | equality_expression EQUAL relational_expression
                   { 
                        if (!compare($1->loc, $3->loc)) {
                              yyerror(string("TypeError: Comparison between incompatible types"));
                        }
                        else {
                              // Implicit conversion between bool and int types
                              conv_bool2int(*$1);
                              conv_bool2int(*$3);
                              $$ = new Expression();
                              $$->loc = ST->gentemp(new SymbolType("int"));
                              $$->type = "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit("==", "", $1->loc->name, $3->loc->name); // If a > b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                   }

                   | equality_expression NOT_EQUAL relational_expression
                   { 
                        if (!compare($1->loc, $3->loc)) {
                              yyerror(string("TypeError: Comparison between incompatible types"));
                        }
                        else {
                              // Implicit conversion between bool and int types
                              conv_bool2int(*$1);
                              conv_bool2int(*$3);
                              $$ = new Expression();
                              $$->loc = ST->gentemp(new SymbolType("int"));
                              $$->type = "bool";     // New expression of type bool
                              $$->truelist = makelist(nextinstr()); // the instr numbers of true path
                              $$->falselist = makelist(nextinstr() + 1); // the instr numbers of false path 
                              emit("!=", "", $1->loc->name, $3->loc->name); // If a > b, goto ... (backpatched later)
                              emit("goto", ""); // goto ... (backpatched later)
                        }
                   }

                   ;
                   
and_expression: equality_expression
              { 
                  $$ = $1; 
              }

              | and_expression B_AND equality_expression
              { 
                  // compatibility
                  if (!compare($1->loc, $3->loc)) {
                        yyerror(string("TypeError: Bitwise AND between incompatible types"));
                  }
                  else {
                        // Implicit conversion between bool and int types after checking
                        conv_bool2int(*$1);
                        conv_bool2int(*$3);
                        $$ = new Expression();
                        $$->type = "int";      // AND will give int type expression
                        $$->loc = ST->gentemp(new SymbolType("int"));
                        emit("&", $$->loc->name, $1->loc->name, $3->loc->name);
                  }                  
              }              
              ;

exclusive_or_expression: and_expression
                       {     
                             $$ = $1; 
                        }

                       | exclusive_or_expression B_XOR and_expression
                       { 
                            // compatibility
                              if (!compare($1->loc, $3->loc)) {
                                    yyerror("TypeError: Bitwise XOR between incompatible types");
                              }
                              else {
                                    // Implicit conversion between bool and int types after checking
                                    conv_bool2int(*$1);
                                    conv_bool2int(*$3);
                                    $$ = new Expression();
                                    $$->type = "int"; // XOR will give int type expression
                                    $$->loc = ST->gentemp(new SymbolType("int"));
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
                                    conv_bool2int(*$1);
                                    conv_bool2int(*$3);
                                    $$ = new Expression();
                                    $$->type = "int";      // OR will give int type expression
                                    $$->loc = ST->gentemp(new SymbolType("int"));
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
                        conv_int2bool(*$1);                                  //convert logical_and_expression to bool
                        conv_int2bool(*$4);                                  //convert inclusive_or_expression int to bool	
                        $$ = new Expression();                         
                        $$->loc = ST->gentemp(new SymbolType("int"));
                        $$->type = "bool";                                     // Expression type is bool
                        backpatch($1->truelist, $3);                           //if $1 is true, we move to the next instruction and add a backpatch
                        $$->truelist = $4->truelist;                           //The expression AND is true if the next expression is also true
                        $$->falselist = merge($1->falselist, $4->falselist);   //If either $1 or $t4 are false, then AND is false => merge the falselists
                      }

                      ;

logical_or_expression: logical_and_expression
                     { $$ = $1; 

                     }

                     | logical_or_expression L_OR M logical_and_expression
                     { 
                        conv_int2bool(*$1);                                  // convert logical_and_expression to bool
                        conv_int2bool(*$4);                                  // convert inclusive_or_expression int to bool	
                        $$ = new Expression();               
                        $$->loc = ST->gentemp(new SymbolType("int"));
                        $$->type = "bool";                                     // Expression type is bool
                        backpatch($1->falselist, $3);                          //if $1 is false, we move to the next instruction and add a backpatch
                        $$->falselist = $4->falselist;                         //The expression OR is false if the next expression is also false
                        $$->truelist = merge($1->truelist, $4->truelist);   //If either $1 or $t4 are false, then AND is false => merge the falselists  
                     }
                     ;

conditional_expression: logical_or_expression
                      { 
                            $$ = $1; 
                      }

                      | logical_or_expression N QUESTION M expression N COLON M conditional_expression
                      { 
                        // E1 N1 ? M1 E2 N2 : M2 E3
                        $$ = new Expression();                        
                        $$->loc = ST->gentemp($5->loc->type);     // Type same as E2
                        emit("=", $$->loc->name, $9->loc->name);  // Equal to second expression
                        vector <int> l = makelist(nextinstr());
                        emit("goto", "");                         // prevent fallthrough
                        backpatch($6->nextlist, nextinstr());     // After N2, go out
                        emit("=", $$->loc->name, $5->loc->name);  // Equal to first expression
                        vector <int> m = makelist(nextinstr());
                        l = merge(l, m);
                        emit("goto", "");                         // prevent fallthrough
                        backpatch($2->nextlist, nextinstr());     // Goto the end from 2
                        conv_int2bool(*$1);                  // Conversion of $1 to bool to test
                        backpatch($1->truelist, $4);        // If $1 is true, goto expression
                        backpatch($1->falselist, $8);       // If $1 is false, goto conditional_expression
                        backpatch(l, nextinstr());                        
                      }
                      ;

assignment_expression: conditional_expression
                     {
                        $$ = $1;
                     }

                     | unary_expression assignment_operator assignment_expression
                     { 
                        if ($1->variety == "arr") {
                              // Check for conversion and then emit
                              pair<Symbol *, bool> c = convert($3->loc, $1->type->name);
                              if (c.second) {
                                    $3->loc = c.first;
                                    emit("[]=", $1->array->name, $1->loc->name, $3->loc->name);	
                              }
                              else {
                                    // Error
                                    yyerror("AssignmentError: Conversion between incompatible types (ARRAY)");
                              }

                        }
                        else if ($1->variety == "ptr") {
                              emit("*=", $1->array->name, $3->loc->name); // For pointer types simply emit
                        }
                        else {
                              // Check if conversion is possible and convert
                              pair<Symbol *, bool> c = convert($3->loc, $1->type->name);
                              if (c.second) {
                                    $3->loc = c.first;
                                    emit("=", $1->array->name, $3->loc->name);
                              }
                              else {
                                    yyerror("AssignmentError: Conversion between incompatible types");
                              }
                        }

                        $$ = $3;
                     }                     
                     ;

assignment_operator: ASSGN 
                   { /* Already handled assign in the assignment_expression_section */}
                   | MUL_ASSGN  { }                   
                   | DIV_ASSGN { }                   
                   | MOD_ASSGN { }                   
                   | ADD_ASSGN { }                   
                   | SUB_ASSGN  { }                   
                   | L_SHIFT_ASSGN { }                    
                   | R_SHIFT_ASSGN { }                   
                   | AND_ASSGN { }                   
                   | XOR_ASSGN { }                   
                   | OR_ASSGN { }
                   ;

expression: assignment_expression
          { 
            $$ = $1; 
          }
                   
          | expression COMMA assignment_expression
          {    }                   
          ;

constant_expression: conditional_expression
                   { $$ = $1; }
                   ;

/* Declarations */

declaration: declaration_specifiers init_declarator_list_opt SEMI_COLON
           {    }
           ;

declaration_specifiers: storage_class_specifier declaration_specifiers_opt { }
                      | type_specifier declaration_specifiers_opt {  }
                      | type_qualifier declaration_specifiers_opt {  }
                      | function_specifier declaration_specifiers_opt {  }
                      ;
                   
declaration_specifiers_opt: %empty { }
                          | declaration_specifiers { }
                          ;

init_declarator_list: init_declarator
                    { }                   
                    | init_declarator_list COMMA init_declarator
                    { }                   
                    ;

init_declarator_list_opt: %empty { }
                        | init_declarator_list { }
                        ;

init_declarator: declarator
               { $$ = $1; }
               | declarator ASSGN initializer
               { 
                  $1->initial_value = $3->initial_value;    // Make initial values equal
                  emit("=", $1->name, $3->name);            // Emit equivaluence
               }
               ;

storage_class_specifier: EXTERN { }
                       | STATIC { }
                       | AUTO { } 
                       | REGISTER { }
                       ;

type_specifier: VOID
              { variable_type = (char *)"void"; }
                   
              | CHAR
              { variable_type = (char *)"char"; }                   
                   
              | INT
              { variable_type = (char *)"int"; }     
                   
              | FLOAT
              { variable_type = (char *)"float"; }
              
              | LONG { }
              | SHORT { }
              | DOUBLE { }
              | SIGNED { }
              | UNSIGNED { }
              | BOOL { }
              | COMPLEX { }
              | IMAGINARY { }
              | enum_specifier { }
              ;

specifier_qualifier_list: type_specifier specifier_qualifier_list_opt
                        { }                    
                        | type_qualifier specifier_qualifier_list_opt
                        { }                   
                        ;

specifier_qualifier_list_opt: %empty { }
                            | specifier_qualifier_list { }
                            ;

enum_specifier: ENUM identifier_opt OPEN_BRACE enumerator_list CLOSE_BRACE { }
              | ENUM identifier_opt OPEN_BRACE enumerator_list COMMA CLOSE_BRACE { }
              | ENUM IDENTIFIER { }
              ;

identifier_opt: %empty { }
              | IDENTIFIER { }
              ;
              
enumerator_list: enumerator { }                  
               | enumerator_list COMMA enumerator { }                   
               ;

enumerator: IDENTIFIER { }
          | IDENTIFIER ASSGN constant_expression { }
          ;

type_qualifier: CONST { }
              | RESTRICT { }
              | VOLATILE { }
              ;
 
function_specifier: INLINE { }
                  ;

declarator: pointer direct_declarator
          {       
                SymbolType *t1 = $1;            // Get the type of the pointer
                while (t1->next != nullptr) t1 = t1->next; // Reach the leaf
                t1->next = $2->type;            // Type of the declarator added to leaf
                $2->update(t1);            // Update the symbol with the new type
                $$ = $2;
          }  
          | direct_declarator 
          {
                // Copy everything
                $$ = $1;
          }       
          ;


direct_declarator: IDENTIFIER
                 {     
                       $1->update(new SymbolType(variable_type));
                       $$ = $1;
                       // Current Symbol Pointer?
                       curr_symbol = $$;
                 }
                   
                 | OPEN_PARENTHESIS declarator CLOSE_PARENTHESIS
                 { $$ = $2; }
                   
                 | direct_declarator OPEN_BRACKET type_qualifier_list assignment_expression CLOSE_BRACKET { }
                 | direct_declarator OPEN_BRACKET type_qualifier_list CLOSE_BRACKET
                 { 
                       // This extra projection has been added to handle _opt in assignment_expression
                 }

                 | direct_declarator OPEN_BRACKET assignment_expression CLOSE_BRACKET
                 { 
                       // This extra projection has been added to handle _opt in type_qualifier_list 
                       SymbolType * t1 = $1->type;
                       if (t1->name == "ptr" || t1->next == nullptr) {
                             // Create new array type
                             SymbolType * s = new SymbolType("arr");
                             s->next = t1;
                             // Get the size of the array;
                             int c_size = conv_string2int($3->loc->initial_value);
                             s->size = c_size;
                             // Update the type in the symbol table
                             $1->update(s);
                             $$ = $1;
                       }
                       else {
                             // Type is already an array type
                              SymbolType *prev = nullptr;
                              while (t1->next != nullptr) {
                                    prev = t1;
                                    t1 = t1->next;
                              }
                              // Creation of new array type symbol
                              SymbolType *p = t1;
                              t1 = new SymbolType("arr");
                              t1->size = conv_string2int($3->loc->initial_value);
                              t1->next = p;
                              prev->next = t1;
                              $1->update($1->type);
                              $$ = $1;
                       }              
                 }
                 | direct_declarator OPEN_BRACKET CLOSE_BRACKET
                 {
                       // When both type_qualifier_list_opt and assignment_expression_opt are epsilon transitions
                       SymbolType * t1 = $1->type;     
                       if (t1->name == "ptr" || t1->next == nullptr)  {
                             // Create new array type
                             SymbolType * s = new SymbolType("arr");
                             s->next = t1;
                             // Put size = 0;
                             s->size = 0;
                             // Update the type in the symbol table
                             $1->update(s);
                             $$ = $1;
                       }
                       else {
                             // Type is already an array type
                             SymbolType *prev = nullptr;
                              while (t1->next != nullptr) {
                                    prev = t1;
                                    t1 = t1->next;
                              }
                              // Creation of new array type symbol
                              SymbolType *p = t1;
                              t1 = new SymbolType("arr");
                              t1->size = 0;
                              t1->next = p;
                              prev->next = t1;
                              $1->update($1->type);
                              $$ = $1;
                       }
                 }
                 | direct_declarator OPEN_BRACKET STATIC type_qualifier_list assignment_expression CLOSE_BRACKET { }
	           | direct_declarator OPEN_BRACKET STATIC assignment_expression CLOSE_BRACKET {	}                 
                 | direct_declarator OPEN_BRACKET type_qualifier_list STAR CLOSE_BRACKET { }
                 | direct_declarator OPEN_BRACKET STAR CLOSE_BRACKET
                 { /* This extra projection has been added to handle _opt in type_qualifier_list */}
                   
                 | direct_declarator OPEN_PARENTHESIS changetable parameter_type_list CLOSE_PARENTHESIS
                 { 
                       // Function Call and location with parameters
                       ST->name = $1->name;
                  //      if ($1->type->name != "void") {
                  //            Symbol *val = ST->lookup("return");
                  //            val->update($1->type);
                  //      }
                       $1->nested_table = ST;
                       ST->parent = STS.global();
                       ST = STS.global();
                       curr_symbol = $$;

                 }
                 | direct_declarator OPEN_PARENTHESIS changetable CLOSE_PARENTHESIS
                 { 
                       // Function Call and location with no parameters
                       ST->name = $1->name;
                  //      if ($1->type->name != "void") {
                  //            Symbol *val = ST->lookup("return");
                  //            val->update($1->type);
                  //      }
                       $1->nested_table = ST;
                       ST->parent = STS.global();
                       ST = STS.global();
                       curr_symbol = $$;
                 }
                   
                 | direct_declarator OPEN_PARENTHESIS identifier_list CLOSE_PARENTHESIS
                 { }                   
                 ;

pointer: STAR type_qualifier_list_opt
       {    // Create new pointer
            $$ = new SymbolType("ptr"); 
       }
                   
       | STAR type_qualifier_list_opt pointer
       { 
            // Pointer of pointer
            $$ = new SymbolType("ptr");
            $$->next = $3;
       }                   
       ;

type_qualifier_list: type_qualifier { }
                   | type_qualifier_list type_qualifier { }                  
                   ;

type_qualifier_list_opt: %empty { }
                       | type_qualifier_list { }
                       ;

parameter_type_list: parameter_list { }
                   | parameter_list COMMA DOT DOT DOT { }
                   ;

parameter_list: parameter_declaration { }
              | parameter_list COMMA parameter_declaration { }                   
              ;

parameter_declaration: declaration_specifiers declarator {
                        $2->scope = "parameter";
                     }
                     ;                   
                     | declaration_specifiers { }                   
                     ;

identifier_list: IDENTIFIER { }
               | identifier_list COMMA IDENTIFIER { }                   
               ;

type_name: specifier_qualifier_list { }                   
         ;

initializer: assignment_expression
           { 
                 $$ = $1->loc;      // Assignment
           }
                    
           | OPEN_BRACE initializer_list CLOSE_BRACE { }

           | OPEN_BRACE initializer_list COMMA CLOSE_BRACE { }                   
           ;

initializer_list: designation_opt initializer { }
                | initializer_list COMMA designation_opt initializer { }
                ;

designation: designator_list ASSGN { }
           ;

designation_opt: %empty { }
               | designation { }
               ;

designator_list: designator { }
               | designator_list designator { }
               ;

designator: OPEN_BRACKET constant_expression CLOSE_BRACKET { }
          | DOT IDENTIFIER { }
          ;

/* Statements */

statement: labeled_statement { $$ = $1; }
         | compound_statement { 
               $$ = $1; 
           }       
         | expression_statement
         { 
            $$ = new Next();
            $$->nextlist = $1->nextlist; // New Expression with same nextlist
         }
         | selection_statement { $$ = $1; }
         | iteration_statement { $$ = $1; }
         | jump_statement { $$ = $1; }
         ;

labeled_statement: IDENTIFIER COLON M statement
                 { 
                        $$ = $4;
                        Label *l = find_label($1->name);
                        if (l != nullptr) {
                              l->addr = $3;
                              backpatch(l->nextlist,l->addr);
                        }
                        else {
                              l = new Label($1->name);
                              l->addr = nextinstr();
                              l->nextlist = makelist($3);
                              label_table.push_back(*l);
                        }
                 }
                   
                 | CASE constant_expression COLON statement
                 { }                   
                 | DEFAULT COLON statement
                 { }
                 ;

compound_statement: OPEN_BRACE X blocktable block_item_list_opt CLOSE_BRACE
                  { 
                        // Copy the block item list
                        $$ = $4;
                        // Set symbol table back to original
                        updateSymbolTable(ST->parent);
                  }
                   
                  ;

block_item_list: block_item
               { 
                  $$ = $1;
               }                   
               | block_item_list M block_item
               { 
                  $$ = $3;
                  backpatch($1->nextlist, $2);  // Move to block_item after block_item_list
               }
                   
               ;

block_item_list_opt: %empty 
                     {
                        $$ = new Next();
                     }
                   | block_item_list 
                     {
                        $$ = $1;
                     }
                   ;

block_item: declaration
          { $$ = new Next(); }
                   
          | statement
          { $$ = $1; }

          ;               

expression_statement: expression SEMI_COLON
                    { $$ = $1; }
                    | SEMI_COLON 
                    { $$ = new Expression(); }
                    ;
                    
selection_statement: IF OPEN_PARENTHESIS expression CLOSE_PARENTHESIS M statement N %prec "then"
                   { 
                        // If without else
                        // If (B) M1 statement N2
                        conv_int2bool(*$3);       // Convert this to a boolean expression b
                        $$ = new Next();        // New statement
                        backpatch($3->truelist, $5);  // Backpatch this with M1, to go inside the statement
                        vector <int> tx = merge($3->falselist, $6->nextlist); // merge false condition of expression, nextlist of statement and N (out of the if statement)
                        $$->nextlist = merge(tx, $7->nextlist);
                   }
                   
                   | IF OPEN_PARENTHESIS expression CLOSE_PARENTHESIS M statement N ELSE M statement
                   { 
                        // If with else
                        // If (B) M1 S1 N1 else M2 S2
                        conv_int2bool(*$3);      // Convert Expression to Boolean B
                        $$ = new Next();  
                        backpatch($3->truelist, $5);  // Go inside S1
                        backpatch($3->falselist, $9); // Go inside S2
                        vector <int> temp = merge($6->nextlist, $7->nextlist); // Merge nextlists of S1 and N1 and S2
                        $$->nextlist = merge(temp, $10->nextlist);      
                   }
                   
                   | SWITCH OPEN_PARENTHESIS expression CLOSE_PARENTHESIS statement
                   { /* Not supported */ }
                   
                   ;

iteration_statement: WHILE OPEN_PARENTHESIS X blocktable M expression CLOSE_PARENTHESIS M statement
                   { 
                        // X creates the separate symbol table
                        // blocktable changes to the nested symbol table
                        // while M1 (B) M2 S1
                        $$ = new Next();
                        conv_int2bool(*$6);      // Convert expression to boolean
                        backpatch($6->truelist, $8);  // Enter the while loop if statment is true
                        backpatch($9->nextlist, $5); // Go back to M1 after block execution
                        $$->nextlist = $6->falselist; // Move out when expression false
                        // Emit
                        emit("goto", conv_int2string($5));
                        // Change to the parent table
                        ST = ST->parent;
                   }

                   | DO M statement M WHILE OPEN_PARENTHESIS expression CLOSE_PARENTHESIS SEMI_COLON
                   { 
                        // do M1 while M2 (B1);
                        $$ = new Next();
                        conv_int2bool(*$7);        // Make B1 from expression
                        backpatch($7->truelist, $2); // Goto M1 if B1 is true
                        backpatch($3->nextlist, $4); // Goto M2 if do executed
                        $$->nextlist = $7->falselist; // Exit to the falselist of expression
                   }
                   
                   | FOR OPEN_PARENTHESIS X blocktable expression_statement M expression_statement M expression N CLOSE_PARENTHESIS M statement
                   { 
                        // for M1 (E1; M1 E2; M2 E3 N) M3 S 
                        $$ = new Next();
                        conv_int2bool(*$7);      // Convert E2 to Boolean B (Condition Checking)
                        backpatch($7->truelist, $12); // If B is true, go to M3 (statement)
                        backpatch($10->nextlist, $6); // After N go back to M1
                        backpatch($13->nextlist, $8); // After S, go back to increment step (M2)
                        emit ("goto", conv_int2string($8));  // goto M2 (prevent fall through)
                        $$->nextlist = $7->falselist; // Move out of the loop when B is false
                        ST = ST->parent;
                   }

                   | FOR OPEN_PARENTHESIS X blocktable declaration M expression_statement M expression N CLOSE_PARENTHESIS M statement
                   { 
                        // for M1 (E1; M1 E2; M2 E3 N) M3 S 
                        // Repeat the same as above. 
                        $$ = new Next();
                        conv_int2bool(*$7);      // Convert E2 to Boolean B (Condition Checking)
                        backpatch($7->truelist, $12); // If B is true, go to M3 (statement)
                        backpatch($10->nextlist, $6); // After N go back to M1
                        backpatch($13->nextlist, $8); // After S, go back to increment step (M2)
                        emit ("goto", conv_int2string($8));  // goto M2 (prevent fall through)
                        $$->nextlist = $7->falselist; // Move out of the loop when B is false
                        ST = ST->parent;
                   }
                   
                   | FOR OPEN_PARENTHESIS X blocktable declaration M expression_statement M expression_statement M expression N CLOSE_PARENTHESIS M statement
                   { /* Not supported */ }
                   ;

jump_statement: GOTO IDENTIFIER SEMI_COLON { }
                   
              | CONTINUE SEMI_COLON { }
                   
              | BREAK SEMI_COLON { }
                   
              | RETURN expression SEMI_COLON
              { 
                  $$ = new Next();
                  emit("return", $2->loc->name); // Emit return (from function call)
              }
              | RETURN SEMI_COLON 
              {
                  $$ = new Next();
                  emit("return", "");
              }
                   
              ;

/* External definitions */

translation_unit: external_declaration {  }
                | translation_unit external_declaration { }
                ;

external_declaration: function_definition { }
                    | declaration { }
                    ;
                    
function_definition: declaration_specifiers declarator declaration_list_opt changetable compound_statement
                   { 
                        emit("funcend", ST->name);
                        $2->type = new SymbolType("func");
                        ST->parent = STS.global();
                        table_count = 0;
                        updateSymbolTable(STS.global());
                   }
                   
                   ;

declaration_list: declaration { }
                | declaration_list declaration { }                   
                ;

declaration_list_opt: %empty { }
                    | declaration_list { }
                    ;


%%

void yyerror(string s)
{
      cout << s << "\n";
      return;
}
