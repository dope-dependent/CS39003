
#include "ass5_19CS30037_translator.h"
using namespace std;

// Global Variables Q for array of all quads and ST for current symbol table
QuadArray Q;
Symboltable ST;

// Basic Types and Sizes
map <string, int> basic_sizes = {
    {"char", SIZE_OF_CHAR}, 
    {"float", SIZE_OF_FLOAT}, 
    {"int", SIZE_OF_INT}, 
    {"ptr", SIZE_OF_POINTER}, 
    {"void", INT32_MAX}, 
    {"bool", INT32_MAX}, 
    {"block", 0}, 
    {"func", 0}
};

// Construct a symbol type
SymbolType::SymbolType(string _name, int _size, SymbolType * _next) 
    :name (_name), size(_size), next(_next) {}

// Get the space consumed by a data type
int SymbolType::getSize() {
    if (this->name == "arr") {
        return this->size * this->next->getSize();
    }
    if (this->name == "void") {
        // return error
        cout << "Void has no size\n";
        return basic_sizes[this->name];
    }
    return basic_sizes[this->name];
}

// Get the type of the symbol as a C++ string
string SymbolType::getType() {
    if (this->name == "arr") {
        string special = "arr(";
        special += conv_int2string(this->size);
        special += ", ";
        special += this->next->getType();
        special += ")";
        return special;
    }
    else if (this->name == "ptr") {
        string special = "ptr(";
        special += this->next->getType();
        special += ")";
        return special;
    }
    else return this->name;
}

// Print the type of the symbol
void SymbolType::printType() {cout << this->getType() << "\n";}

// Create a new entry in the symbol table
Symbol::Symbol(string name, string type, string initval, int width, Symboltable * nested_table)
    :name(name), type(new SymbolType(type, width)), initial_value(initval), nested_table(nested_table) {
        this->size = this->type->getSize(); // Get the size
        this->offset = 0;                   // Initial offset is 0
}

Symbol::Symbol(string _name) : name(_name) {}

// Update the size of the symbol table entry
// Used when conversion to different types
void Symbol::update(SymbolType * new_type) {
    this->type = new_type;              // Change the type
    this->size = this->type->getSize(); // Get the size of the new type
} 

// Symboltable constructor
Symboltable::Symboltable(string _name, Symboltable * _parent) 
    : name(_name), parent(_parent), symbols({}) {
        this->temporary_count = 0;
    }

// Lookup function in a Symboltable
Symbol * Symboltable::lookup(string _id) {
    // If the symbol is already found
    for (Symbol c : this->symbols) {
        if (c.name == _id) return &c;
    }
    // Else create a new symbol with this name
    Symbol * ns = new Symbol(_id);
    // Add to the list of symbols
    this->symbols.push_back(*ns);
    return &this->symbols.back();   // The latest symbol which was inserted
}

// Gentemp function to generate temporaries
Symbol * Symboltable::gentemp(SymbolType * _type) {
    // Name of the temporary TEMP_x, x = count of the temporaries
    string namx = "TEMP_";
    namx += to_string(this->temporary_count++);
    Symbol * ns = new Symbol(namx);
    ns->type = _type;

    this->symbols.push_back(*ns);
    return &this->symbols.back();   // The latest symbol
}

// Update function to update the symbol table offsets
void Symboltable::update() {
    int off = 0;
    for (Symbol c : this->symbols) {
        c.offset = off;
        off += c.size;
        if (c.nested_table != nullptr) {
            c.nested_table->update();
        }
    }
}

// Symboltable print function
void Symboltable::print() {
    // Output the name and the parent
    cout << "ST Name   : " << this->name << "\n";
    cout << "ST Parent : ";
    if (this->parent == nullptr) cout << "null\n";
    else cout << this->parent->name << "\n";
    cout << "\n++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
    for (Symbol c : this->symbols) {
        cout << "Name          : " << c.name << "\n";
        cout << "Type          : " << c.type << "\n";
        cout << "Initial Value : ";
        if (c.initial_value == "") cout << "null\n";
        else cout << c.initial_value << "\n";
        cout << "Size          : " << c.size << "\n";
        cout << "Offset        : " << c.offset << "\n";
        cout << "Nested Table  : " << c.nested_table->name << "\n";
    }
    cout << "\n";
}


// Quad constructor
Quad::Quad(string _res, string _op, string _arg1, string _arg2) 
    : res(_res), op(_op), arg1(_arg1), arg2(_arg2) {}

// Used to set the result of the quad (used when backpatching)
void Quad::set_res(std::string _res) {
    this->res = _res;
}

// Print the quad
void Quad::print() {
    // Get the quad operator
    // Relational, arithmetic and shift operators involve two operands
    vector <string> relop = {">", "<", ">=", "<=", "==", "!="};
    vector <string> arithshift = {"+", "-", "*", "/", "%", "&", "|", "^", ">>", "<<"};

    // Only involve one argument
    vector <string> unary1 = {"=&", "=*", "*="};
    vector <string> unary2 = {"!", "~"};

    bool match = false;
    
    // Arithmetic and Relational Operators
    for (auto a : arithshift) if (op == a) {
        cout << res << " = " << arg1 << " " << op << " " << arg2;
        match = true;
    }
    for (auto r : relop) if (op == r) {
        cout << "if " << arg1 << " " << op << " " << arg2 << " goto " << res;
        match = true;
    }
    // Unary operators print
    for (auto u : unary1) if (op == u) {
        cout << res << op[0] << " " << op[1] << " " << arg1;
        match = true;
    }
    for (auto u : unary2) if (op == u) {
        cout << res << " = " << op << " " << arg1;
        match = true;
    }
    if (match) cout << "\n"; 
    else {
        // Goto, return and parameter passing
        if (op == "goto") cout << "goto " << res;
        else if (op == "return") cout << "return " << res;
        else if (op == "param") cout << "param " << res;

        // Assignment Operator
        else if (op == "=") cout << res << " = " << arg1;
        
        // Unary minus
        else if (op == "uminus") cout << res << "= -" << arg1;
        
        // Array Access
        else if (op == "=[]") cout << res << " = " << arg1 << "[" << arg2 << "]";
        else if (op == "[]=") cout << res << "[" << arg1 << "] = " << arg2;

        // Function Call (Format ans = call func, 2)
        else if (op == "call") cout << res << " = " << "call " << arg1 << ", " << arg2;
        // Label ? 

        else cout << "No matching operator found";

        cout << "\n";
    }

}


// Quadarray functions
// Insert function into quadarray
void QuadArray::insert(Quad q) {
    this->quads.push_back(q);
}

// Print the entire QuadArray
void QuadArray::print() {
    cout << "------------------TAC-----------------\n";
    for (Quad q : this->quads) {
        q.print();
    }
}

// Static Emit functions to add to the global quad array
void emit(string _op, string _res, int _arg1, string _arg2) {
    Quad * nq = new Quad(_res, _op, conv_int2string(_arg1), _arg2);
    Q.insert(*nq);
}

void emit(string _op, string _res, float _arg1, string _arg2) {
    Quad * nq = new Quad(_res, _op, conv_float2sring(_arg1), _arg2);
    Q.insert(*nq);
}

void emit(string _op, string _res, string _arg1, string _arg2) {
    Quad * nq = new Quad(_res, _op, _arg1, _arg2);
    Q.insert(*nq);
}


// Makelist
vector <int> makelist (int i) {
    return vector <int> (1, i);
}

// Mergelist
vector <int> merge (vector <int> &p1, vector <int> &p2) {
    vector <int> v3;
    copy(p1.begin(), p1.end(), v3);
    for (auto p : p2) v3.push_back(p);
    return v3;
}

// Backpatch
void backpatch(vector<int> &p1, int i) {
    string s = conv_int2string(i);    
    // Add i as the target label for all quads on the list in p1
    for (auto p : p1) {
        Q.quads[p].set_res(s);
    }
}

// Conversion of int type expression into bool type expression as done in the class
// Note, that characters and floats can also be similarly converted to boolean types
void conv_int2bool(Expression &E) {
    if (E.type == "int") {
        E.falselist = makelist(nextinstr());    // Update the falselist
        emit("==", "", E.loc->name, "0");       // Goto statement
        E.truelist = makelist(nextinstr());     // Update truelist
        emit("goto","");                        // Wait for backpatching
    }    
}
void conv_float2bool(Expression &E) {
    if (E.type == "float") {
        E.falselist = makelist(nextinstr());    // Update the falselist
        emit("==", "", E.loc->name, "0.0");     // Goto statement
        E.truelist = makelist(nextinstr());     // Update truelist
        emit("goto","");                        // Wait for backpatching
    }    
}
void conv_char2bool(Expression &E) {
    if (E.type == "char") {
        E.falselist = makelist(nextinstr());    // Update the falselist
        emit("==", "", E.loc->name, "\\'\0'");  // Goto statement
        E.truelist = makelist(nextinstr());     // Update truelist
        emit("goto","");                        // Wait for backpatching
    }    
}


// Conversion of bool type expression into int type expression 
void conv_bool2int(Expression &E) {
    if (E.type == "bool") {
        SymbolType * ts = new SymbolType("int");
        E.loc = gentemp(&ST, ts);
        backpatch(E.truelist, nextinstr());
        emit("==", E.loc->name, "true", "");
        int nx = nextinstr() + 1;
        string strx = conv_int2string(nx);
        emit("goto", strx);
        backpatch(E.falselist, nextinstr());
        emit("=", E.loc->name, "false");
    }    
}

// Conversion to float is similar to int
// Only the basic type is changed
void conv_bool2float(Expression &E) {
    if (E.type == "bool") {
        SymbolType * ts = new SymbolType("float");
        E.loc = gentemp(&ST, ts);
        backpatch(E.truelist, nextinstr());
        emit("==", E.loc->name, "true", "");
        int nx = nextinstr() + 1;
        string strx = conv_int2string(nx);
        emit("goto", strx);
        backpatch(E.falselist, nextinstr());
        emit("=", E.loc->name, "false");
    }    
}

// Conversion to char is the same as int
// Only the basic type is changed
void conv_bool2char(Expression &E) {
    if (E.type == "bool") {
        SymbolType * ts = new SymbolType("char");
        E.loc = gentemp(&ST, ts);
        backpatch(E.truelist, nextinstr());
        emit("==", E.loc->name, "true", "");
        int nx = nextinstr() + 1;
        string strx = conv_int2string(nx);
        emit("goto", strx);
        backpatch(E.falselist, nextinstr());
        emit("=", E.loc->name, "false");
    }       
}


// Check the types of E1 and E2 and convert 
// E1 to E2 if possible
void typecheck (Expression &E1, Expression &E2) {
    if (E1.type == E2.type) return;
    // Int to bool conversion
    if (E1.type == "bool") {
        if (E2.type == "int") conv_bool2int(E1);
        else if (E2.type == "float") conv_bool2float(E1);
        else if (E2.type == "char") conv_bool2char(E1);
        else {
            // Flag error
        }
    }
    else if (E1.type == "int") {
        if (E2.type == "bool") conv_int2bool(E1);
        if (E2.type == "float") conv_int2float(E1);
        else {
            // Flag error
        }
    }
    else if (E1.type == "float") {
        if (E2.type == "bool") conv_float2bool(E1);
        else {
            // Flag error
        }
    }
    else if (E1.type == "char") {
        if (E2.type == "bool") conv_char2bool(E1);
        else {
            // Flag error
        }
    }
    else {
        // Flag error
    }
}

// Go to the next instruction
/* Next instruction is the index which is one larger than the largest
/* index in the quad array. 
/* However, since C++ vectors follow zero based indexing, the size() of the
/* vector is one larger than the largest index
/* Hence the next instruction is nothing but the size of the vector */
int nextinstr() {
    return Q.quads.size();
}



// Conversion to string
string conv_int2string(int a) {
    return to_string(a);
}

string conv_float2sring(float b) {
    return to_string(b);
}


Symbol * gentemp (Symboltable * s, SymbolType * type) {
    return s->gentemp(type);
}