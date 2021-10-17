/* Assignment 3 test file*/
/* ROLL NO - 19CS10045, 19CS30037 */
/* GROUP   - 11                   */

#include <stdio.h>
#include <stdlib.h>

struct a {
    _Bool a;
    _Complex b;
};

int main() {
    int a = 5;
    const int b = 22144;
    const unsigned c = 1;
    unsigned long long d = 20006262662;

    /* float, double, id test */
    float _a = 4e7;
    float _b = 1e2 + 5.0;
    double _c = 2.435E-56;
    float _d = 0.;
    float _e235232rhsjfh45 = .523;

    /* for, while, 
        do, if, 
        else, break, 
    continue test */
    do {
        for (int c = 1; c <= 1; c++) continue;
    } while (a != 5);

    char d1 = 'a';
    char d2 = '\"';
    char d3[10] = "Hello\n";
    char d4[50] = "hello\twhatnu$#*&er02325261 make;goodtea:<3>?=-{}()\n";
    char d5u_43[42] = "DrDOOFENSHMIRTZ\n\tRICKANDMORTY\n";
    
    switch (d1) {
        case 'a': break;
        default: break;
    }

    // if-else test 
    if (d1 == 'a') {}
    else if (d2 == 'a') {}
    else {}

    int e134252 = (5 + (9 - 12) + (1 << 2) ^ (1 % 2));
    e134252 = e134252 && a;
    a = a || (!e134252);
    a++;
    a--;
    a ^=2;
    a |= 25;
    a %= 1;
    a *= 32;
    a /= 2626;
    a += 12356;
    int *ap = &a;

}