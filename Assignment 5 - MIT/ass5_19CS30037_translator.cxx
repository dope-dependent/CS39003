
#include "ass5_19CS30037_translator.h"
using namespace std;

// Global Variables Q for array of all quads and ST for current symbol table
QuadArray Q;
Symboltable *ST;
SymtabStack STS;
Symbol *curr_symbol;
char *variable_type;
vector<Label> label_table; // table to store the labels
long long int table_count; // Number of nested tables

// Basic Types and Sizes
map<string, int> basic_sizes = {
    {"char", SIZE_OF_CHAR},
    {"float", SIZE_OF_FLOAT},
    {"int", SIZE_OF_INT},
    {"ptr", SIZE_OF_POINTER},
    {"void", 0},
    {"bool", 0},
    {"block", 0},
    {"func", 0}};

// Construct a symbol type
SymbolType::SymbolType(string _name, int _size, SymbolType *_next)
    : name(_name), size(_size), next(_next) {}

// Get the space consumed by a data type
int SymbolType::getSize()
{
    if (this->name == "arr")
    {
        return this->size * this->next->getSize();
    }
    if (this->name == "void")
    {
        // return error
        // cout << "Void has no size\n";
        return basic_sizes[this->name];
    }
    return basic_sizes[this->name];
}

// Get the type of the symbol as a C++ string
string SymbolType::getType()
{
    if (this->name == "arr")
    {
        string special = "arr(";
        special += conv_int2string(this->size);
        special += ", ";
        special += this->next->getType();
        special += ")";
        return special;
    }
    else if (this->name == "ptr")
    {
        string special = "ptr(";
        special += this->next->getType();
        special += ")";
        return special;
    }
    else
        return this->name;
}

// Print the type of the symbol
void SymbolType::printType() { cout << this->getType(); }

// Create a new entry in the symbol table
Symbol::Symbol(string name, string type, string initval, int width, Symboltable *nested_table)
    : name(name), type(new SymbolType(type, width)), initial_value(initval), nested_table(nested_table)
{
    cout << "Symbol constructor called\n";
    this->size = this->type->getSize(); // Get the size
    this->offset = 0;                   // Initial offset is 0
    cout << "Symbol constructor ended\n";
}

Symbol::Symbol(string _name) : name(_name) {}

// Update the size of the symbol table entry
// Used when conversion to different types
void Symbol::update(SymbolType *new_type)
{
    cout << "Symbol update called\n";
    this->type = new_type;              // Change the type
    this->size = this->type->getSize(); // Get the size of the new type
    cout << "Symbol update ended\n";
}

// Symboltable constructor
Symboltable::Symboltable(string _name, Symboltable *_parent)
    : name(_name), parent(_parent), symbols({})
{
    cout << "New Symboltable created\n";
}

// Lookup function in a Symboltable
Symbol *Symboltable::lookup(string _id)
{
    cout << "Symboltable Lookup called \n";
    // cout << _id << "\n";
    // If the symbol is already found
    vector<Symbol *>::iterator it = this->symbols.begin();
    while (it != this->symbols.end())
    {
        if ((*it)->name == _id)
        {
            cout << "Symboltable Lookup exited \n";
            return (*it);
        }
        it++;
    }
    // Search in the upper tables
    Symbol * check = nullptr;
    if (this->parent != nullptr) {
        check = this->parent->check_parent(_id);
    } 
    if (check != nullptr) return check;
    // Else create a new symbol with this name
    Symbol *ns = new Symbol(_id);
    // Add to the list of symbols
    this->symbols.push_back(ns);
    // cout << "Symboltable Lookup exited \n";
    return this->symbols.back(); // The latest symbol which was inserted
}
Symbol* Symboltable::check_parent(string _id) {
    cout << "Parent Check called \n";
    vector<Symbol *>::iterator it = this->symbols.begin();
    while (it != this->symbols.end())
    {
        if ((*it)->name == _id)
        {
            cout << "Symboltable Lookup exited \n";
            return (*it);
        }
        it++;
    }
    // Repeat the same for the parent
    if (this->parent != nullptr) return this->parent->check_parent(_id);
    return nullptr;
}

// Gentemp function to generate temporaries
Symbol *Symboltable::gentemp(SymbolType *_type)
{
    cout << "ST->gentemp called\n";
    // Name of the temporary TEMP_x, x = count of the temporaries
    string namx = "_t";
    namx += to_string(STS.temp_count++);
    Symbol *ns = new Symbol(namx);
    ns->type = _type;
    ns->size = _type->getSize();
    this->symbols.push_back(ns);
    cout << "ST->gentemp ended\n";
    return this->symbols.back(); // The latest symbol
}

// Update function to update the symbol table offsets
void Symboltable::update()
{
    cout << "ST->update called\n";
    int off = 0;
    for (Symbol * c : this->symbols)
    {
        c->offset = off;
        c->size = c->type->getSize();
        off += c->size;
        if (c->nested_table != nullptr)
        {
            c->nested_table->update();
        }
    }
    cout << "ST->update ended\n";
}

// Symboltable print function
void Symboltable::print()
{
    // Output the name and the parent
    cout << "\n\n\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
    cout << "\tST Name         : " << this->name << "\n";
    cout << "\tST Parent       : ";
    if (this->parent == nullptr)
        cout << "null\n";
    else
        cout << this->parent->name << "\n";
    cout << "\tST Symbol Count : " <<  this->symbols.size() << "\n";
    cout << "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
    int k = 0;
    for (Symbol * c : this->symbols)
    { 
        cout << "\t\tName          : " << c->name << "\n";
        cout << "\t\tType          : " << c->type->getType() << "\n";
        cout << "\t\tInitial Value : ";
        if (c->initial_value == "")
            cout << "null\n";
        else
            cout << c->initial_value << "\n";
        cout << "\t\tSize          : " << c->size << "\n";
        cout << "\t\tOffset        : " << c->offset << "\n";
        if (c->nested_table == nullptr) {cout << "\t\tNested Table  : null\n";} 
        else cout << "\t\tNested Table  : " << c->nested_table->name << "\n";
        if (k != this->symbols.size() - 1) {
            cout << "--------------------------------------------------------------\n";
        }
        k++;
    }
    cout << "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n\n";
}

// Quad constructor
Quad::Quad(string _res, string _op, string _arg1, string _arg2)
    : res(_res), op(_op), arg1(_arg1), arg2(_arg2) {
        cout << "New Quad Created\n";
    }

// Used to set the result of the quad (used when backpatching)
void Quad::set_res(std::string _res)
{
    this->res = _res;
}

// Print the quad
void Quad::print()
{
    // Get the quad operator
    // Relational, arithmetic and shift operators involve two operands
    vector<string> relop = {">", "<", ">=", "<=", "==", "!="};
    vector<string> arithshift = {"+", "-", "*", "/", "%", "&", "|", "^", ">>", "<<"};

    // Only involve one argument
    vector<string> unary1 = {"=&", "=*", "*="};
    vector<string> unary2 = {"!", "~"};

    bool match = false;

    // Arithmetic and Relational Operators
    for (auto a : arithshift)
        if (op == a)
        {
            cout << res << " = " << arg1 << " " << op << " " << arg2;
            match = true;
        }
    for (auto r : relop)
        if (op == r)
        {
            cout << "if " << arg1 << " " << op << " " << arg2 << " goto " << res;
            match = true;
        }
    // Unary operators print
    for (auto u : unary1)
        if (op == u)
        {
            cout << res << op[0] << " " << op[1] << " " << arg1;
            match = true;
        }
    for (auto u : unary2)
        if (op == u)
        {
            cout << res << " = " << op << " " << arg1;
            match = true;
        }
    if (match)
        cout << "\n";
    else
    {
        // Goto, return and parameter passing
        if (op == "goto")
            cout << "goto " << res;
        else if (op == "return")
            cout << "return " << res;
        else if (op == "param")
            cout << "param " << res;

        // Assignment Operator
        else if (op == "=")
            cout << res << " = " << arg1;

        // Unary minus
        else if (op == "uminus")
            cout << res << "= -" << arg1;

        // Array Access
        else if (op == "=[]")
            cout << res << " = " << arg1 << "[" << arg2 << "]";
        else if (op == "[]=")
            cout << res << "[" << arg1 << "] = " << arg2;

        // Function Call (Format ans = call func, 2)
        else if (op == "call")
            cout << res << " = "
                 << "call " << arg1 << ", " << arg2;
        // Label ?
        else if (op == "label") {
            cout << res << ": ";
        }
        else
            cout << "No matching operator found";

        cout << "\n";
    }
}

// Quadarray functions
// Insert function into quadarray
void QuadArray::insert(Quad *q)
{
    this->quads.push_back(q);
}

// Print the entire QuadArray
void QuadArray::print()
{
    cout << "------------------TAC-----------------\n";
    int index = 0;
    for (Quad * q : this->quads)
    {
        printf("%4d : ", index);
        q->print();
        index++;
    }
}

// Static Emit functions to add to the global quad array
void emit(string _op, string _res, int _arg1, string _arg2)
{
    Quad *nq = new Quad(_res, _op, conv_int2string(_arg1), _arg2);
    Q.insert(nq);
}

void emit(string _op, string _res, float _arg1, string _arg2)
{
    Quad *nq = new Quad(_res, _op, conv_float2string(_arg1), _arg2);
    Q.insert(nq);
}

void emit(string _op, string _res, string _arg1, string _arg2)
{
    Quad *nq = new Quad(_res, _op, _arg1, _arg2);
    Q.insert(nq);
}

// Makelist
vector<int> makelist(int i)
{
    return vector<int>(1, i);
}

// Mergelist
vector<int> merge(vector<int> &p1, vector<int> &p2)
{
    vector<int> v3;
    for (int i = 0; i < p1.size(); i++)
        v3.push_back(p1.at(i));
    for (int i = 0; i < p2.size(); i++)
        v3.push_back(p2.at(i));
    for (auto p : p2)
        v3.push_back(p);
    return v3;
}

// Backpatch
void backpatch(vector<int> &p1, int i)
{
    string s = conv_int2string(i);
    // Add i as the target label for all quads on the list in p1
    for (auto p : p1)
    {
        Q.quads.at(p)->set_res(s);
    }
}

// Conversion of int type expression into bool type expression as done in the class
// Note, that characters and floats can also be similarly converted to boolean types
void conv_int2bool(Expression &E)
{
    if (E.type == "int")
    {
        E.falselist = makelist(nextinstr()); // Update the falselist
        emit("==", "", E.loc->name, "0");    // Goto statement
        E.truelist = makelist(nextinstr());  // Update truelist
        emit("goto", "");                    // Wait for backpatching
    }
}
void conv_float2bool(Expression &E)
{
    if (E.type == "float")
    {
        E.falselist = makelist(nextinstr()); // Update the falselist
        emit("==", "", E.loc->name, "0.0");  // Goto statement
        E.truelist = makelist(nextinstr());  // Update truelist
        emit("goto", "");                    // Wait for backpatching
    }
}
void conv_char2bool(Expression &E)
{
    if (E.type == "char")
    {
        E.falselist = makelist(nextinstr());   // Update the falselist
        emit("==", "", E.loc->name, "\\'\0'"); // Goto statement
        E.truelist = makelist(nextinstr());    // Update truelist
        emit("goto", "");                      // Wait for backpatching
    }
}

// Conversion of bool type expression into int type expression
void conv_bool2int(Expression &E)
{
    if (E.type == "bool")
    {
        SymbolType *ts = new SymbolType("int");
        E.loc = gentemp(ST, ts);
        backpatch(E.truelist, nextinstr());
        emit("==", E.loc->name, "true", "");
        string strx = conv_int2string(nextinstr() + 1);
        emit("goto", strx);
        backpatch(E.falselist, nextinstr());
        emit("==", E.loc->name, "false");
    }
}

// Conversion to float is similar to int
// Only the basic type is changed
void conv_bool2float(Expression &E)
{
    if (E.type == "bool")
    {
        SymbolType *ts = new SymbolType("float");
        E.loc = gentemp(ST, ts);
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
void conv_bool2char(Expression &E)
{
    if (E.type == "bool")
    {
        SymbolType *ts = new SymbolType("char");
        E.loc = gentemp(ST, ts);
        backpatch(E.truelist, nextinstr());
        emit("==", E.loc->name, "true", "");
        int nx = nextinstr() + 1;
        string strx = conv_int2string(nx);
        emit("goto", strx);
        backpatch(E.falselist, nextinstr());
        emit("=", E.loc->name, "false");
    }
}

// Go to the next instruction
/* Next instruction is the index which is one larger than the largest
/* index in the quad array. 
/* However, since C++ vectors follow zero based indexing, the size() of the
/* vector is one larger than the largest index
/* Hence the next instruction is nothing but the size of the vector */
int nextinstr()
{
    // cout << "Next instruction\n";
    return Q.quads.size();
}

// Conversion to string
string conv_int2string(int a)
{
    return to_string(a);
}

string conv_float2string(float b)
{
    return to_string(b);
}

Symbol *gentemp(Symboltable *s, SymbolType *type)
{
    return s->gentemp(type);
}

// Compare Symbols and Check if conversion is possible
// Convert if conversion is possible
int compare(Symbol *&s1, Symbol *&s2)
{
    cout << "Compare Symbol Called\n";
    if (compare(s1->type, s2->type) == 1)
        return 1;
    // Try to convert s1 to s2 (flag 2)
    pair<Symbol *, bool> c = convert(s1, s2->type->name);
    if (c.second)
    {
        s1 = c.first;
        return 2;
    }
    // Convert s2 to s1 (flag 3)
    c = convert(s2, s1->type->name);
    if (c.second)
    {
        s2 = c.first;
        return 3;
    }
    // Conversion impossible (flag 0)
    return 0;
}

// Compare Symbol Types
int compare(SymbolType *s1, SymbolType *s2)
{
    // cout << "Compare SymbolType called\n";
    // Follow the order
    // char --> int --> float
    if (s1 == nullptr && s2 == nullptr)
        return 1;
    if (s1 == nullptr || s2 == nullptr)
        return 0;
    if (s1->getType() != s2->getType())
        return 0;
    if (s1->size != s2->size)
        return 0;
    return compare(s1->next, s2->next);
}

// Convert a symbol to a given type
pair<Symbol *, bool> convert(Symbol *s, std::string type)
{
    // cout << "Convert SymbolType called\n";
    if (s->type->name == type) return make_pair(s, true);
    Symbol *temp = ST->gentemp(new SymbolType(type));
    // Only conversion between standard types
    if (s->type->name == "int" && s->type->next == nullptr)
    {
        if (type == "float")
        {
            emit("=", temp->name, "int2float(" + s->name + ")");
            return make_pair(temp, true);
        }
        else if (type == "char") {
            emit("=", temp->name, "int2char(" + s->name + ")");
            return make_pair(temp, true);
        }
        else
            return make_pair(s, false);
    }
    else if (s->type->name == "char" && s->type->next == nullptr)
    {
        if (type == "int")
        {
            emit("=", temp->name, "char2int(" + s->name + ")");
            return make_pair(temp, true);
        }
        else if (type == "float")
        {
            emit("=", temp->name, "char2float(" + s->name + ")");
            return make_pair(temp, true);
        }
        else
            return make_pair(s, false);
    }
    else if (s->type->name == "float" && s->type->next == nullptr) 
    {
        if (type == "int") {
            emit("=", temp->name, "float2int(" + s->name + ")");
            return make_pair(temp, true);
        }
        else if (type == "char") {
            emit("=", temp->name, "float2char(" + s->name + ")");
            return make_pair(temp, true);
        }
        else return make_pair(s, false);
    }
    return make_pair(s, false);
}

// Label Class constructor
Label::Label(string _name, int address, vector<int> nextlist) : name(_name), addr(address), nextlist(nextlist) {}

Symboltable *SymtabStack::current()
{
    return ST;
}

Symboltable *SymtabStack::global()
{
    return this->tables[0];
}

Symboltable *SymtabStack::search(string _name)
{
    // cout << "Stack search function called\n";
    for (auto c : this->tables)
    {
        if (c->name == _name)
        {
            return c;
        }
    }
    return nullptr;
}

Label *find_label(string _str)
{
    cout << "find_label called\n";
    vector<Label>::iterator it = label_table.begin();
    while (it != label_table.end())
    {
        if ((*it).name == _str)
            return &(*it);
    }
    return nullptr;
}

void updateSymbolTable(Symboltable *_new)
{
    cout << "UpdateSymbolTable called\n";
    ST = _new;
    cout << "UpdateSymbolTable ended\n";
}

void SymtabStack::print() {
    cout << "Number of Symbol Tables: " << this->tables.size() << "\n";
    for (Symboltable * p : this->tables) {
        p->print();
    }
}

int main()
{
    #ifdef YYDEBUG
    yydebug = 1;
    #endif
    ST = new Symboltable("Global");
    STS.add(ST);
    yyparse();
    ST->update();

    cout << "\n\nPRINTING ALL SYMBOL TABLES\n";
    
    STS.print();


    cout << "\n\nPRINTING ALL QUADS\n\n";
    Q.print();

    return 0;
}
