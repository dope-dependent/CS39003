int printInt(int num);
int readInt(int *s);

int main() {
    int i = 0;
    int *p = &i;
    readInt(p);
    // printInt(i);
    int j = 1; 
    int fact = 1;
    while (j <= i) {
        fact = fact * j;
        // printInt(fact);
        j++;
    }
    printInt(fact);
    return 0;
}