// Conditional statement checking
int main() {
    int a = 2, b = 3, c = 4;
    float ax = 8.1, bx = 9.3;
    // Nested if
    if (a > 1) {
        if (b <= 2) {
            b = 2;
        }
        else ax = 1.2;
    } 
    else ax = 9.1;
    // If, else if and else
    if (a >= 2.3) b = 3;
    else if (a != 2) b = 2;
    else if (b < -1) b = 1;
    else c = -1;

    // Conditional Operator
    c = (c == 2 ? (c = 2): (a = 1));

    return 0;
}