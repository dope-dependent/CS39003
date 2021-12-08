// For STL
#include <bits/stdc++.h>

#include "ass6_19CS30037_translator.h"

using namespace std;

// DEBUG //
// #define outputAssemblyFile cout

extern FILE *yyin;

// Global variables
vector <Quad *> quadArray;
string outputFilename;
string inputFilename;
map <int, int> labelNumbers;
vector <Symbol *> allStrings;

// Helper function to determine if a string is a number
pair<bool, long> isNumber(string s)
{
        if (s == "")
        {
                return make_pair(false, 0);
        }
        char *p;
        long number = strtol(s.c_str(), &p, 10);
        if (*p)
        {
                return make_pair(false, -1);
        }
        return make_pair(true, number);
}

void flattenSymbolTable()
{
        // Flat symbol table and calculate offset for all of the symbols
        SymtabStack newSymbolTableStack;
        string currentFunctionName = "";
        int currentOffset = 0;
        Symboltable *currentNewSymbolTable = nullptr;

        for (auto oldSymbolTable : STS.tables)
        {
                if (oldSymbolTable->name == "Global")
                {
                        newSymbolTableStack.tables.push_back(oldSymbolTable);
                        continue;
                }
                if (oldSymbolTable->name.find('$') == string::npos)
                {
                        // It is the parent symbol table of a function
                        if (currentNewSymbolTable != nullptr)
                        {
                                newSymbolTableStack.tables.push_back(currentNewSymbolTable);
                        }
                        currentOffset = 0;
                        currentFunctionName = oldSymbolTable->name;
                        currentNewSymbolTable = new Symboltable(currentFunctionName, STS.tables[0]);
			// Link this table to the global symbol table
			STS.tables[0]->lookup(currentFunctionName)->nested_table = currentNewSymbolTable;
                }
                // All the symbols to the the new symbol table
                for (auto currentSymbol : oldSymbolTable->symbols)
                {
                        currentNewSymbolTable->symbols.push_back(currentSymbol);
                        currentSymbol->offset = currentOffset;
                        currentOffset += currentSymbol->size;
                }
        }
        if (currentNewSymbolTable != nullptr)
        {
                newSymbolTableStack.tables.push_back(currentNewSymbolTable);
        }

        STS = newSymbolTableStack;

        return;
}

// Fix the offset, assign positive offsets to parameters and negative offsets to local variables
void generateAcitivationRecord()
{
        for (auto symbolTable : STS.tables)
        {
                int sizeOfParams = 0;
                // for (auto symbol : symbolTable->symbols)
                // {
                //         if (symbol->scope == "parameter")
                //         {
                //                 sizeOfParams += symbol->size;
                //         }
                // }
                for (auto symbol : symbolTable->symbols)
                {
                        symbol->offset = sizeOfParams - symbol->offset;
                }
        }
        return;
}

// Handles labels and give unique numbers to them
void mapLabelsToNumbers()
{
        int labelCount = 0;
        for (auto quad : Q.quads)
        {
                string op = quad->op;
                if (op == ">" || op == "<" || op == ">=" || op == "<=" || op == "==" || op == "!=" || op == "goto")
                {
                        if (labelNumbers.find(stoi(quad->res)) == labelNumbers.end())
                        {
                                labelNumbers[stoi(quad->res)] = labelCount++;
                        }
                }
        }
        return;
}

void generateAssembly()
{
        quadArray = Q.quads;

        ofstream outputAssemblyFile;
        outputAssemblyFile.open(outputFilename);
        // DEBUG //

        // Handle the intro and static section of the assembly file
        outputAssemblyFile << "        .file      \"" << inputFilename << "\"\n";
        outputAssemblyFile << "        .text\n";

        // Global Symbol tables will have all the symbols
        Symboltable globalSymbolTable = *(STS.tables[0]);
        int strCount = 0;

        Symboltable currentFunctionSymbolTable = globalSymbolTable;

        for (auto globalVariable : globalSymbolTable.symbols)
        {       
                string gvname = globalVariable->name;
                if (gvname == "printInt" || gvname == "readInt" || gvname == "printStr") {
                        continue;
                }
                if (globalVariable->type->name == "int")
                {
                        // Global int
                        // DEBUG //
                        // cout << "Global Int " << globalVariable->name << "\n";

                        if (globalVariable->initial_value == "null")
                        {
                                outputAssemblyFile << "        .comm      " << globalVariable->name << ",4,4\n";
                        }
                        else
                        {
                                outputAssemblyFile << "        .globl     " << globalVariable->name << "\n";
                                outputAssemblyFile << "        .data\n";
                                outputAssemblyFile << "        .align     4\n";
                                outputAssemblyFile << "        .type      " << globalVariable->name << ", @object\n";
                                outputAssemblyFile << "        .size      " << globalVariable->name << ", 4\n";
                                outputAssemblyFile << globalVariable->name << ":\n";
                                outputAssemblyFile << "        .long      " << globalVariable->initial_value << "\n";
                        }
                }
                if (globalVariable->type->name == "char")
                {
                        // Global char

                        // DEBUG //
                        // cout << "Global char " << globalVariable->name << "\n";

                        if (globalVariable->initial_value == "null")
                        {
                                outputAssemblyFile << "        .comm      " << globalVariable->name << ",1,1\n";
                        }
                        else
                        {
                                outputAssemblyFile << "        .globl     " << globalVariable->name << "\n";
                                outputAssemblyFile << "        .type      " << globalVariable->name << ", @object\n";
                                outputAssemblyFile << "        .size      " << globalVariable->name << ", 1\n";
                                outputAssemblyFile << globalVariable->name << ":\n";
                                outputAssemblyFile << "        .byte      " << stoi(globalVariable->initial_value) << "\n";
                        }
                }
                if (globalVariable->type->getType() == "ptr(char)")
                {
                        // String Literal

                        // DEBUG //
                        // cout << "Global String " << globalVariable->name << "\n";
                        
                        if (globalVariable->initial_value == "null")
                        {
                                outputAssemblyFile << "        .comm      " << globalVariable->name << ",8,8\n";
                        }
                        else
                        {
                                outputAssemblyFile << "        .globl     " << globalVariable->name << "\n";
                                outputAssemblyFile << "        .section   .rodata\n";
                                outputAssemblyFile << ".LC" << to_string(strCount) << ":\n";
                                outputAssemblyFile << "        .string    " << globalVariable->initial_value << "\n";
                                outputAssemblyFile << "        .section   .data.rel.local";
                                if (strCount == 0)
                                {
                                        outputAssemblyFile << ", \"aw\"";
                                }
                                outputAssemblyFile << "\n";
                                outputAssemblyFile << "        .align     8\n";
                                outputAssemblyFile << "        .type      " << globalVariable->name << ", @object\n";
                                outputAssemblyFile << "        .size      " << globalVariable->name << ", 8\n";
                                outputAssemblyFile << globalVariable->name << ":\n";
                                outputAssemblyFile << "        .quad      .LC" << to_string(strCount) << "\n";
                                strCount++;
                        }
                        
                }
        }

        // Generate x86_64 instructions corresponding to each quad.
        vector <Quad> functionParameters;
        int functionNumber = 0;
        int quadNumber = 0;
        for (auto currentQuad : quadArray)
        {
                // DEBUG //
                // cout << "\n\nTranslating Quad ";
                // cout << quadNumber << " ";
                // currentQuad->print();
                // cout << "\n";
                
                string res = currentQuad->res;
                string op = currentQuad->op;
                string arg1 = currentQuad->arg1;
                string arg2 = currentQuad->arg2;

                if (labelNumbers.find(quadNumber) != labelNumbers.end())
                {
                        outputAssemblyFile << ".L" << labelNumbers[quadNumber] << ":\n";
                }

                if (op == "param")
                {
                        // DEBUG //
                        // cout << "Parameter " << res << "\n";
                        
                        functionParameters.push_back(*currentQuad);
                        quadNumber++;
                        continue;
                }

                bool isImmediate1 = isNumber(arg1).first;
                long immediateVal1 = isNumber(arg1).second;

                bool isImmediate2 = isNumber(arg2).first;
                long immediateVal2 = isNumber(arg2).second;

                bool isImmediateR = isNumber(res).first;
                long immediateValR = isNumber(res).second;

                // DEBUG //
                // if (isImmediate1)
                // {
                //         cout << "Immediate value 1 is " << immediateVal1 << "\n";
                // }
                // if (isImmediate2)
                // {
                //         cout << "Immediate value 2 is " << immediateVal2 << "\n";
                // }
                // if (isImmediateR)
                // {
                //         cout << "Immediate value R is " << immediateValR << "\n";
                // }

                int offset1, offset2, offsetR;

                if (arg1 != "" && !isImmediate1)
                {
                        offset1 = currentFunctionSymbolTable.lookup(arg1)->offset;

                        // DEBUG //
                        // cout << "arg1 = " << arg1 << " and offset = " << offset1 << "\n";
                }
                if (arg2 != "" && !isImmediate2)
                {
                        offset2 = currentFunctionSymbolTable.lookup(arg2)->offset;

                        // DEBUG //
                        // cout << "arg2 = " << arg2 << " and offset = " << offset2 << "\n";
                }
                if (res != "" && !isImmediateR)
                {
                        offsetR = currentFunctionSymbolTable.lookup(res)->offset;

                        // DEBUG //
                        // cout << "res = " << res << " and offset = " << offsetR << "\n";
                }

                

                // Arithmetic operators (supported only for int)
                if (op == "+")
                {
                                outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                        if (isImmediate2)
                        {
                                outputAssemblyFile << "        addl       $" << immediateVal2 << ", %eax\n";
                        }
                        else
                        {
                                outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %ebx\n";
                                outputAssemblyFile << "        addl       %ebx, %eax\n";
                        }
                                outputAssemblyFile << "        movl       %eax, " << offsetR << "(%rbp)\n";
                }
                else if (op == "-")
                {
                                outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                        if (isImmediate2)
                        {
                                outputAssemblyFile << "        subl       $" << immediateVal2 << ", %eax\n";
                        }
                        else
                        {
                                outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %ebx\n";
                                outputAssemblyFile << "        subl       %ebx, %eax\n";
                        }
                                outputAssemblyFile << "        movl       %eax, " << offsetR << "(%rbp)\n";
                }
                else if (op == "*")
                {
                                outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                        if (isImmediate2)
                        {
                                outputAssemblyFile << "        imull      $" << immediateVal2 << ", %eax\n";
                        }
                        else
                        {
                                outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %ebx\n";
                                outputAssemblyFile << "        imull      %ebx, %eax\n";
                        }
                                outputAssemblyFile << "        movl       %eax, " << offsetR << "(%rbp)\n";
                }
                else if (op == "/")
                {
                                outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                                outputAssemblyFile << "        cltq\n";
                        if (isImmediate2)
                        {
                                outputAssemblyFile << "        idivl      $" << immediateVal2 << "n";
                        }
                        else
                        {
                                outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %ebx\n";
                                outputAssemblyFile << "        idivl      %ebx";
                        }
                                outputAssemblyFile << "        movl       %eax, " << offsetR << "(%rbp)\n";
                }
                else if (op == "%")
                {
                                outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                                outputAssemblyFile << "        cltq\n";
                        if (isImmediate2)
                        {
                                outputAssemblyFile << "        idivl      $" << immediateVal2 << "n";
                        }
                        else
                        {
                                outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %ebx\n";
                                outputAssemblyFile << "        idivl      %ebx";
                        }
                                outputAssemblyFile << "        movl       %edx, " << offsetR << "(%rbp)\n";
                }

                // Conditional Jump operators (supported only for ints)
                else if (op == ">")
                {
                        outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %eax\n";
                        outputAssemblyFile << "        cmp        %eax, " << offset1 << "(%rbp)\n";
                        outputAssemblyFile << "        jg         .L" << labelNumbers[stoi(res)] << "\n";
                }
                else if (op == "<")
                {
                        outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %eax\n";
                        outputAssemblyFile << "        cmp        %eax, " << offset1 << "(%rbp)\n";
                        outputAssemblyFile << "        jl         .L" << labelNumbers[stoi(res)] << "\n";
                }
                else if (op == ">=")
                {
                        outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %eax\n";
                        outputAssemblyFile << "        cmp        %eax, " << offset1 << "(%rbp)\n";
                        outputAssemblyFile << "        jge        .L" << labelNumbers[stoi(res)] << "\n";
                }
                else if (op == "<=")
                {
                        outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %eax\n";
                        outputAssemblyFile << "        cmp        %eax, " << offset1 << "(%rbp)\n";
                        outputAssemblyFile << "        jle        .L" << labelNumbers[stoi(res)] << "\n";
                }
                else if (op == "==")
                {
                        outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %eax\n";
                        outputAssemblyFile << "        cmp        %eax, " << offset1 << "(%rbp)\n";
                        outputAssemblyFile << "        je         .L" << labelNumbers[stoi(res)] << "\n";
                }
                else if (op == "!=")
                {
                        outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %eax\n";
                        outputAssemblyFile << "        cmp        %eax, " << offset1 << "(%rbp)\n";
                        outputAssemblyFile << "        jne        .L" << labelNumbers[stoi(res)] << "\n";
                }
                // Pointer operations
                else if (op == "=&")
                {
                        outputAssemblyFile << "        leaq        " << offset1 << "(%rbp), %rax\n";
                        outputAssemblyFile << "        movq        %rax, " << offsetR << "(%rbp)\n";
                }
                else if (op == "=*")
                {
                        outputAssemblyFile << "        movq        " << offset1 << "(%rbp), %rax\n";

                        // get the size of operands, like 1 for char, 4 for int, 8 for pointers
                        int operandSize = currentFunctionSymbolTable.lookup(res)->size;

                        if (operandSize == 1)
                        {
                                outputAssemblyFile << "        movb       (%rax), %al\n";
                                outputAssemblyFile << "        movb       %al, " << offsetR << "(%rbp)\n";
                        }
                        else if (operandSize == 4)
                        {
                                outputAssemblyFile << "        movl       (%rax), %eax\n";
                                outputAssemblyFile << "        movl       %eax, " << offsetR << "(%rbp)\n";
                        }
                        else if (operandSize == 8)
                        {
                                outputAssemblyFile << "        movq       (%rax), %rax\n";
                                outputAssemblyFile << "        movq       %rax, " << offsetR << "(%rbp)\n";
                        }
                }
                else if (op == "*=")
                {
                        int operandSize = currentFunctionSymbolTable.lookup(arg1)->size;

                        if (operandSize == 1)
                        {
                                outputAssemblyFile << "        movb       " << offset1 << "(%rbp), %al\n";
                        }
                        else if (operandSize == 4)
                        {
                                outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                        }
                        else if (operandSize == 8)
                        {
                                outputAssemblyFile << "        movq       " << offset1 << "(%rbp), %rax\n";
                        }

                        outputAssemblyFile << "        movq       " << offsetR << "(%rbp), %rbx\n";

                        if (operandSize == 1)
                        {
                                outputAssemblyFile << "         movb       %al, (%rbx)\n"; 
                        }
                        else if (operandSize == 4)
                        {
                                outputAssemblyFile << "         movl       %eax, (%rbx)\n"; 
                        }
                        else if (operandSize == 8)
                        {
                                outputAssemblyFile << "         movq       %rax, (%rbx)\n"; 
                        }
                }

                // Goto operation
                else if (op == "goto")
                {
                        outputAssemblyFile << "        jmp        .L" << labelNumbers[stoi(res)] << "\n";
                }
                else if (op == "return")
                {
                        if (res == "")
                        {
                                outputAssemblyFile << "        nop\n";
                        }
                        else if (!isImmediateR)
                        {
                                int operandSize = currentFunctionSymbolTable.lookup(res)->size;
                                if (operandSize == 1)
                                {
                                        outputAssemblyFile << "        movb       " << offsetR << "(%rbp), %al\n";
                                }
                                else if (operandSize == 4)
                                {
                                        outputAssemblyFile << "        movl       " << offsetR << "(%rbp), %eax\n";
                                }
                                else if (operandSize == 8)
                                {
                                        outputAssemblyFile << "        movq       " << offsetR << "(%rbp), %rax\n";
                                }
                        }
                        else
                        {
                                outputAssemblyFile << "        movl       $" << immediateValR << ", %eax\n";
                        }
                }
                // Assignment operator
                else if (op == "=")
                {

                        if (isImmediate1)
                        {
                                outputAssemblyFile << "        movl       $" << immediateVal1 << ", " << offsetR << "(%rbp)\n";
                        }
                        else
                        {
                                int operandSize = currentFunctionSymbolTable.lookup(res)->size;
                                if (operandSize == 1)
                                {
                                        outputAssemblyFile << "        movb       " << offset1 << "(%rbp), %al\n";
                                        outputAssemblyFile << "        movb       %al, " << offsetR << "(%rbp)\n"; 
                                }
                                else if (operandSize == 4)
                                {
                                        outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                                        outputAssemblyFile << "        movl       %eax, " << offsetR << "(%rbp)\n"; 
                                }
                                else if (operandSize == 8)
                                {
                                        outputAssemblyFile << "        movq       " << offset1 << "(%rbp), %rax\n";
                                        outputAssemblyFile << "        movq       %rax, " << offsetR << "(%rbp)\n"; 
                                }
                        }
                }
                // Unary Minus
                else if (op == "uminus")
                {
                        outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                        outputAssemblyFile << "        negl       %eax\n";
                        outputAssemblyFile << "        movl       %eax, " << offsetR << "(%rbp)\n";
                }
                // Array Accesses
                else if (op == "=[]")
                {
                        
                        outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %eax\n";
                        // Sign extend %eax to %rax
                        outputAssemblyFile << "        cltq\n"; 

                        int operandSize = currentFunctionSymbolTable.lookup(res)->size;
                        if (operandSize == 1)
                        {
                                outputAssemblyFile << "        movb       " << offset1 << "(%rbp, %rax, 1), %bl\n";
                                outputAssemblyFile << "        movb       %bl, " << offsetR << "(%rbp)\n";
                        }
                        else if (operandSize == 4)
                        {
                                outputAssemblyFile << "        movl       " << offset1 << "(%rbp, %rax, 1), %ebx\n";
                                outputAssemblyFile << "        movl       %ebx, " << offsetR << "(%rbp)\n";
                        }
                        else if (operandSize == 8)
                        {
                                outputAssemblyFile << "        movq       " << offset1 << "(%rbp, %rax, 1), %rbx\n";
                                outputAssemblyFile << "        movq       %rbx, " << offsetR << "(%rbp)\n";
                        }

                }
                else if (op == "[]=")
                {       
                        outputAssemblyFile << "        movl       " << offset1 << "(%rbp), %eax\n";
                        // Sign extend %eax to %rax
                        outputAssemblyFile << "        cltq\n"; 
                        // Value to be copied is in %ebx

                        outputAssemblyFile << "        leaq       " << offsetR << "(%rbp), %rdx\n";
                        outputAssemblyFile << "        addq       %rax, %rdx\n";

                        if (isImmediate2) {
                                outputAssemblyFile << "        movl       $" << immediateVal2 << offsetR << "(%rdx)\n";
                        }       
                

                        else {
                                int operandSize = currentFunctionSymbolTable.lookup(arg2)->size;
                                if (operandSize == 1)
                                {
                                        outputAssemblyFile << "        movb       " << offset2 << "(%rbp), %bl\n";
                                        outputAssemblyFile << "        movb       %bl, " << offsetR << "(%rdx)\n";
                                }
                                else if (operandSize == 4)
                                {
                                        outputAssemblyFile << "        movl       " << offset2 << "(%rbp), %ebx\n";
                                        outputAssemblyFile << "        movl       %ebx, " << offsetR << "(%rdx)\n";
                                }
                                else if (operandSize == 8)
                                {
                                        outputAssemblyFile << "        movq       " << offset2 << "(%rbp), %rbx\n";
                                        outputAssemblyFile << "        movq       %rbx, " << offsetR << "(%rdx)\n";
                                }
                        }
                        
                }
                // Function Definition Begin quad to generate prologue of the function.
                else if (op == "func")
                {
			string functionName = res;
                        outputAssemblyFile << "        .globl     " << functionName << "\n";
                        outputAssemblyFile << "        .type      " << functionName << ", @function\n";
                        outputAssemblyFile << functionName << ":\n";
                        outputAssemblyFile << ".LFB" << functionNumber << ":\n";
                        outputAssemblyFile << "        .cfi_startproc\n";
                        // outputAssemblyFile << "        endbr64\n";
                        outputAssemblyFile << "        pushq      %rbp\n";
                        outputAssemblyFile << "        .cfi_def_cfa_offset 16\n";
                        outputAssemblyFile << "        .cfi_offset 6, -16\n";
                        outputAssemblyFile << "        movq       %rsp, %rbp\n";
                        outputAssemblyFile << "        .cfi_def_cfa_register 6\n";

                        currentFunctionSymbolTable = *(globalSymbolTable.lookup(functionName)->nested_table);
                        int stackframeSize = -(currentFunctionSymbolTable.symbols.back()->offset - currentFunctionSymbolTable.symbols.back()->size - currentFunctionSymbolTable.symbols[0]->offset);
                        int frameLocation = currentFunctionSymbolTable.symbols[0]->offset;

                        // Allocate the space
                        outputAssemblyFile << "        subq       $" << stackframeSize << ", %rsp\n";
                        // outputAssemblyFile << "        subq       $" << frameLocation << ", %rbp\n";

                        // Transfer the parameters to the stack
                        int paramNumber = 0;
                        for (auto param : currentFunctionSymbolTable.symbols)
                        {
                                if (param->scope == "parameter")
                                {
                                        if (paramNumber == 0)
                                        {
                                                int operandSize = currentFunctionSymbolTable.lookup(param->name)->size;
                                                if (operandSize == 1)
                                                {
                                                        outputAssemblyFile << "        movb       %dil, ";
                                                }
                                                else if (operandSize == 4)
                                                {
                                                        outputAssemblyFile << "        movl       %edi, ";
                                                }
                                                else if (operandSize == 8)
                                                {
                                                        outputAssemblyFile << "        movq       %rdi, ";
                                                }
                                                
                                                outputAssemblyFile << param->offset << "(%rbp)\n";
                                        }
                                        else if (paramNumber == 1)
                                        {
                                                int operandSize = currentFunctionSymbolTable.lookup(param->name)->size;
                                                if (operandSize == 1)
                                                {
                                                        outputAssemblyFile << "        movb       %sil, ";
                                                }
                                                else if (operandSize == 4)
                                                {
                                                        outputAssemblyFile << "        movl       %esi, ";
                                                }
                                                else if (operandSize == 8)
                                                {
                                                        outputAssemblyFile << "        movq       %rsi, ";
                                                }
                                                
                                                outputAssemblyFile << param->offset << "(%rbp)\n";
                                        }
                                        else if (paramNumber == 2)
                                        {
                                                int operandSize = currentFunctionSymbolTable.lookup(param->name)->size;
                                                if (operandSize == 1)
                                                {
                                                        outputAssemblyFile << "        movb       %dl, ";
                                                }
                                                else if (operandSize == 4)
                                                {
                                                        outputAssemblyFile << "        movl       %edx, ";
                                                }
                                                else if (operandSize == 8)
                                                {
                                                        outputAssemblyFile << "        movq       %rdx, ";
                                                }
                                                
                                                outputAssemblyFile << param->offset << "(%rbp)\n";
                                        }
                                        else if (paramNumber == 3)
                                        {
                                                int operandSize = currentFunctionSymbolTable.lookup(param->name)->size;
                                                if (operandSize == 1)
                                                {
                                                        outputAssemblyFile << "        movb       %cl, ";
                                                }
                                                else if (operandSize == 4)
                                                {
                                                        outputAssemblyFile << "        movl       %ecx, ";
                                                }
                                                else if (operandSize == 8)
                                                {
                                                        outputAssemblyFile << "        movq       %rcx, ";
                                                }
                                                
                                                outputAssemblyFile << param->offset << "(%rbp)\n";
                                        }
                                        else if (paramNumber == 4)
                                        {
                                                int operandSize = currentFunctionSymbolTable.lookup(param->name)->size;
                                                if (operandSize == 1)
                                                {
                                                        outputAssemblyFile << "        movb       %r8b, ";
                                                }
                                                else if (operandSize == 4)
                                                {
                                                        outputAssemblyFile << "        movl       %r8d, ";
                                                }
                                                else if (operandSize == 8)
                                                {
                                                        outputAssemblyFile << "        movq       %r8, ";
                                                }
                                                
                                                outputAssemblyFile << param->offset << "(%rbp)\n";
                                        }
                                        else if (paramNumber == 5)
                                        {
                                                int operandSize = currentFunctionSymbolTable.lookup(param->name)->size;
                                                if (operandSize == 1)
                                                {
                                                        outputAssemblyFile << "        movb       %r9b, ";
                                                }
                                                else if (operandSize == 4)
                                                {
                                                        outputAssemblyFile << "        movl       %r9d, ";
                                                }
                                                else if (operandSize == 8)
                                                {
                                                        outputAssemblyFile << "        movq       %r9, ";
                                                }
                                                
                                                outputAssemblyFile << param->offset << "(%rbp)\n";
                                        }
                                        paramNumber++;
                                }
                        }
                }        
                else if (op == "funcend")
                {
                        string functionName = res;

                        int stackframeSize = -(currentFunctionSymbolTable.symbols.back()->offset - currentFunctionSymbolTable.symbols.back()->size - currentFunctionSymbolTable.symbols[0]->offset);

                        // Deallocate the space
                        // outputAssemblyFile << "        movq       %rbp, %rsp\n";
                        // outputAssemblyFile << "        popq       %rbp\n";
                        outputAssemblyFile << "        leave\n";
                        // outputAssemblyFile << "        .cfi_restore 5\n";
                        outputAssemblyFile << "        .cfi_def_cfa 7, 8\n";
                        outputAssemblyFile << "        ret\n";
                        outputAssemblyFile << "        .cfi_endproc\n";
                        outputAssemblyFile << ".LFE" << functionNumber << ":\n";
                        outputAssemblyFile << "        .size      " << res << ", .-" << res << "\n";
                        
                        functionNumber++;
                }
                else if (op == "call")
                {
                        int paramNumber = 0;
                        for (auto param : functionParameters)
                        {
                                int paramOffset = currentFunctionSymbolTable.lookup(param.res)->offset;
                                if (paramNumber == 0)
                                {
                                        int operandSize = currentFunctionSymbolTable.lookup(param.res)->size;
                                        if (operandSize == 1)
                                        {
                                                outputAssemblyFile << "        movb       " << paramOffset << "(%rbp), %dil\n";
                                        }
                                        else if (operandSize == 4)
                                        {
                                                outputAssemblyFile << "        movl       " << paramOffset << "(%rbp), %edi\n";
                                        }
                                        else if (operandSize == 8)
                                        {
                                                outputAssemblyFile << "        movq       " << paramOffset << "(%rbp), %rdi\n";
                                        }
                                }
                                else if (paramNumber == 1)
                                {
                                        int operandSize = currentFunctionSymbolTable.lookup(param.res)->size;
                                        if (operandSize == 1)
                                        {
                                                outputAssemblyFile << "        movb       " << paramOffset << "(%rbp), %sil\n";
                                        }
                                        else if (operandSize == 4)
                                        {
                                                outputAssemblyFile << "        movl       " << paramOffset << "(%rbp), %esi\n";
                                        }
                                        else if (operandSize == 8)
                                        {
                                                outputAssemblyFile << "        movq       " << paramOffset << "(%rbp), %rsi\n";
                                        }
                                }
                                else if (paramNumber == 2)
                                {
                                        int operandSize = currentFunctionSymbolTable.lookup(param.res)->size;
                                        if (operandSize == 1)
                                        {
                                                outputAssemblyFile << "        movb       " << paramOffset << "(%rbp), %dl\n";
                                        }
                                        else if (operandSize == 4)
                                        {
                                                outputAssemblyFile << "        movl       " << paramOffset << "(%rbp), %edx\n";
                                        }
                                        else if (operandSize == 8)
                                        {
                                                outputAssemblyFile << "        movq       " << paramOffset << "(%rbp), %rdx\n";
                                        }
                                }
                                else if (paramNumber == 3)
                                {
                                        int operandSize = currentFunctionSymbolTable.lookup(param.res)->size;
                                        if (operandSize == 1)
                                        {
                                                outputAssemblyFile << "        movb       " << paramOffset << "(%rbp), %cl\n";
                                        }
                                        else if (operandSize == 4)
                                        {
                                                outputAssemblyFile << "        movl       " << paramOffset << "(%rbp), %ecx\n";
                                        }
                                        else if (operandSize == 8)
                                        {
                                                outputAssemblyFile << "        movq       " << paramOffset << "(%rbp), %rcx\n";
                                        }
                                }
                                else if (paramNumber == 4)
                                {
                                        int operandSize = currentFunctionSymbolTable.lookup(param.res)->size;
                                        if (operandSize == 1)
                                        {
                                                outputAssemblyFile << "        movb       " << paramOffset << "(%rbp), %r8b\n";
                                        }
                                        else if (operandSize == 4)
                                        {
                                                outputAssemblyFile << "        movl       " << paramOffset << "(%rbp), %r8d\n";
                                        }
                                        else if (operandSize == 8)
                                        {
                                                outputAssemblyFile << "        movq       " << paramOffset << "(%rbp), %r8\n";
                                        }
                                }
                                else if (paramNumber == 5)
                                {
                                        int operandSize = currentFunctionSymbolTable.lookup(param.res)->size;
                                        if (operandSize == 1)
                                        {
                                                outputAssemblyFile << "        movb       " << paramOffset << "(%rbp), %r9b\n";
                                        }
                                        else if (operandSize == 4)
                                        {
                                                outputAssemblyFile << "        movl       " << paramOffset << "(%rbp), %r8d\n";
                                        }
                                        else if (operandSize == 8)
                                        {
                                                outputAssemblyFile << "        movq       " << paramOffset << "(%rbp), %r8\n";
                                        }
                                }
                                paramNumber++;
                        }

                        outputAssemblyFile << "        call       " << arg1 << "\n";

                        int operandSize = currentFunctionSymbolTable.lookup(res)->size;
                        if (operandSize == 1)
                        {
                                outputAssemblyFile << "        movb       %al, " << offsetR << "(%rbp)\n";
                        }
                        else if (operandSize == 4)
                        {
                                outputAssemblyFile << "        movl       %eax, " << offsetR << "(%rbp)\n";
                        }
                        else if (operandSize == 8)
                        {
                                outputAssemblyFile << "        movq       %rax, " << offsetR << "(%rbp)\n";
                        }

                        functionParameters.clear();

                }
                else if (op == "label")
                {
                        ;
                }

                quadNumber++;
        }
                        
        // Add the bottom of the x86_64 code
        outputAssemblyFile << "        .ident     \"GCC: (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0\"\n";
        outputAssemblyFile << "        .section   .note.GNU-stack,\"\",@progbits\n";
        outputAssemblyFile << "        .section   .note.gnu.property,\"a\"\n";
        outputAssemblyFile << "        .align     8\n";
        outputAssemblyFile << "        .long      1f - 0f\n";
        outputAssemblyFile << "        .long      4f - 1f\n";
        outputAssemblyFile << "        .long      5\n";
        outputAssemblyFile << "0:\n";
        outputAssemblyFile << "        .string    \"GNU\"\n";
        outputAssemblyFile << "1:\n";
        outputAssemblyFile << "        .align     8\n";
        outputAssemblyFile << "        .long      0xc0000002\n";
        outputAssemblyFile << "        .long      3f - 2f\n";
        outputAssemblyFile << "2:\n";
        outputAssemblyFile << "        .long      0x3\n";
        outputAssemblyFile << "3:\n";
        outputAssemblyFile << "        .align     8\n";
        outputAssemblyFile << "4:\n\n";

        // DEBUG //
        outputAssemblyFile.close();
        return;

}

int main(int argc, char *argv[])
{
        #ifdef YYDEBUG
        yydebug = 1;
        #endif
        
        inputFilename = argv[1];
        outputFilename = inputFilename;
        outputFilename[outputFilename.length() - 1] = 's';

        ST = new Symboltable("Global");
        STS.add(ST);
        yyin = fopen(inputFilename.c_str(), "r");
        yyparse();
        ST->update();

        cout << "\n\nPRINTING ALL SYMBOL TABLES\n";
        
        STS.print();

        cout << "\n\nPRINTING ALL QUADS\n\n";
        Q.print();

        flattenSymbolTable();
        STS.print();

        generateAcitivationRecord();
        STS.print();

        mapLabelsToNumbers();
        // for (auto c : labelNumbers) {
        //         cout << c.first << " " << c.second << "\n";
        // }
        generateAssembly();
}