#ifndef _TRANSLATOR_H_
#define _TRANSLATOR_H_

#define SIZE_OF_CHAR    1
#define SIZE_OF_INT     4
#define SIZE_OF_FLOAT   8
#define SIZE_OF_POINTER 4

#include <string> 
#include <vector>
#include <iostream>
#include <map> 
#include <cmath>



// Declarations of all classes to avoid any conflicts
class SymbolType;
class Symbol;
class Symboltable;
class SymtabStack;
class Quad;
class QuadArray;
class Label;


extern char* yytext;
extern int yyparse();


extern QuadArray Q;             // The program array of quads
extern Symboltable *ST;          // The current symbol table
extern char * variable_type;    // Stores the variable type (int, char, float)
extern Symbol *curr_symbol;     // The current Symbol being pointed to in the table
extern long long int table_count;  // denotes count of nested tables
extern SymtabStack STS;         // Stores all the symbol tables
extern int yydebug;

// The type of an object in the symbol table defined in a recursive manner
class SymbolType {
public:
    std::string name;       // Type name
    int size;               // Size of the current type
    SymbolType * next;      // Pointer to the type deeper in the recursive tree
    SymbolType(std::string _name, int _size = 1, SymbolType * _next = nullptr);
    std::string getType();// Print the type depicting the string
    void printType();
    int getSize();          // Get the total size 
};

// A symbol which is an entry of the symbol table
class Symbol {
public:
    std::string name;           // Name of the symbol (string)
    SymbolType * type;          // Type of the symbol (can be a list e.g. arr(10, arr(10, int)) )
    std::string initial_value;  // Initial value of the symbol
    int size;                   // Size of the symbol 
    int offset;                 // Offset of the symbol
    Symboltable * nested_table; // Pointer to the nested symbol table
    std::string scope;          // Scope of the symbol (local, temporary or parameter)
    Symbol(std::string name);
    Symbol(std::string name, 
        std::string type, 
        std::string initval = "", 
        int width = 0, 
        Symboltable * nested_table = nullptr);        // Make new entry
    
    void update (SymbolType *);                       // Change the type

};

// The symboltable which is a list of symbols
class Symboltable{
public:
    std::vector<Symbol *> symbols;        // The symbols in the symbol table
    std::string name;                   // Name of the symbol table
    Symboltable * parent;               // Parent table of the symbol table
    Symboltable(std::string _name, Symboltable * _parent = nullptr);    // New symbol table
    Symboltable();                      // Empty constructor
    Symbol * lookup(std::string id);     // Lookup a given symbol using name
    Symbol * gentemp(SymbolType *);      // Generate a new temporary and insert it into the symbol table
    void print();                        // Print the symbol table
    void update();                       // Update the symbol table
    Symbol * check_parent(std::string id); // Check the parents for ths id
};

// The Stack of the Symboltables on which the search will be carried out
class SymtabStack {
private:
    std::vector<Symboltable *> tables;
public:
    inline SymtabStack() {temp_count = 0;}
    long long int temp_count;
    Symboltable * current();    
    Symboltable * global ();    // First symbol table
    void updateCurrent (Symboltable * newST); // Update current symbol table
    inline void add (Symboltable * st) {
        this->tables.push_back(st);
    }
    Symboltable * search(std::string _name);
    void print(); // Prints all symbol tables
};

// Definition of the Quad
class Quad {
public:
    std::string res;                    // Result
    std::string op;                     // Opcode
    std::string arg1;                   // Argument 1
    std::string arg2;                   // Argument 2

public:
    // Constructor
    Quad (std::string _res, std::string _op, std::string _arg1 = "", std::string _arg2 = "");
    void print();                       // Print the quad
    void set_res(std::string _res);     // Set the result (used in backpatching)
};

// Definition of the Quad Array
class QuadArray {
public:
    std::vector<Quad *> quads;            // All the quads stored in the array
    void insert (Quad *q);               // Insert a quad into the quad array
    void print();                       // Print all the quads
};

// Static emit functions which emit quads
void emit (std::string _res, std::string _op, std::string _arg1 = "", std::string _arg2 = "");
void emit (std::string _res, std::string _op, int _arg1, std::string _arg2 = "");
void emit (std::string _res, std::string _op, float _arg1, std::string _arg2 = "");


// The Label Class for label symbols
class Label {
    public:
        std::string name;                    // Name of the label
        int addr;                       // Address the label is pointing to 
        std::vector <int> nextlist;          // All the dangling goto statements
        Label (std::string _name, int address = -1, std::vector <int> nextlist = std::vector<int>(0)); // Constructor
        
};

// Expressions
struct Expression {
    Symbol * loc;                       // Pointer to the symbol table entry
    std::string type;                   // Type of the expression
    std::vector <int> nextlist;         // Nextlist for statement expressions
    std::vector <int> truelist;         // Truelist for boolean expressions
    std::vector <int> falselist;        // Falselist for boolean expressions

};

//Statement Block
struct Next {
    std::vector <int> nextlist;              // Dangling exit nextlist
};

// Arrays in Expression
struct Array {
    Symbol * loc;   // Location of the temporary used to compute indices
    Symbol * array; // Array location (array.base) in the symbol table
    SymbolType * type; // Type of the subarray generated by Array
    std::string variety; // Arr or *
};

// Global Functions
// Gentemp function, to generate a temporary and add it to the given
// symbol table and return an address to the symbol
Symbol * gentemp (Symboltable * s, SymbolType * type = new SymbolType("int"));

/* makelist : Create a new list comprising only i and return a pointer
 * to the newly created list */
std::vector <int> makelist (int i);
// merge: Merge two lists p1 and p2 and return a pointer to the merged list
std::vector <int> merge (std::vector <int> &p1, std::vector <int> &p2);
// backpatch: Insert i as the target label for each quads on the list pointed to by p
void backpatch (std::vector <int> &p, int i);

// Typecheck and conversion functions
void typecheck (Expression &E1, Expression &E2);

// Conversion of int and float to string
std::string conv_int2string (int a);
std::string conv_float2string (float a);
// Conversion of string to float and int
inline int conv_string2int (std::string s) {return s == "" ? 0: stoi(s);}
inline float conv_string2float (std::string s) {return s == "" ? 0: stof(s);}
// Convert integer to float by multiplying by 1.0
inline float conv_int2float (int a) {return a * 1.0;}
// Convert float to int by taking the floor of the floating point value. 
inline int conv_float2int (float a) {return floor(a);}

// Integer to Boolean conversion in Conditional Expressions
void conv_int2bool (Expression &E);
void conv_float2bool (Expression &E);
void conv_char2bool (Expression &E);
void conv_bool2int (Expression &E);

void conv_int2float(Expression &E);
void conv_char2int(Expression &E);

// Compare and convert between symbol types and Symbols
int compare(SymbolType *s1, SymbolType *s2);
int compare(Symbol * &s1, Symbol * &s2);
std::pair<Symbol *,bool> convert(Symbol *S1, std::string new_type);

// Next instruction address
int nextinstr();
Label * find_label(std::string _str);
void updateSymbolTable(Symboltable *_new);

void printspaces(int n);
std::string getspaces(int n);
#endif // _TRANSLATOR_H_