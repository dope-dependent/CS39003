// Recursive Function Calling
// Fibonacci function

int fib (int n) {
    if (n == 0) return 1;
    if (n == 1) return 1;
    return fib(n - 1) + fib(n - 2);
}
// Simple sum function
int sum (int n) {
    if (n == 0) return 0;
    return n + sum(n - 1);
}

// Main function
int main() {
    int q = 0;
    if (q != 0) q = 1;
    if (q == 1) q = 2;
    if (q == 3) q = 3;
    else q = 4;
    q = fib(q);
    q = q + sum(q);
    return 0;
}