// Pointer and function test
void swappy(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = *a;

    return;
}

int div1(float a, float b) {
    int q;
    q = a / b;  // Implicit conversion testing
    return q;
}
int mul1(int a, int b) {
    return a * b;
}
// 4 parameter function testing
int mull(int a, int b, float c, int d) {
    return c * a * b * d; // int2flt and flt2int testing
}

int main()
{
    int a_232 = -21;
    int _b2 = 1;
    swappy(&a_232, _b2);
    float f1 = 0.1;
    float f2 = 1;
    float c = div1(f1, f2);

    int c = mul1(a_232, _b2);
    c = 1;
    f1 = 1.2;
    int b = 0;
    int d = 51;
    int e = mull(c, b, f1, d);

    return 0;
}