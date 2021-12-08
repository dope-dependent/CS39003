
int printInt(int n);
int readInt(int *eP);

int main()
{
    int n1, n2, i, gcd;
    int *p1 = &n1;
    int *p2 = &n2;
    readInt(p1);
    readInt(p2);
    if (n1 == 0) {
        printInt(n2);
    }
    else if (n2 == 0) {
        printInt(n1);
    }
    else {     
        while (n1 != n2)
        {
                if (n1 > n2) n1 = n1 - n2;
                else n2 = n2 - n1;
        }
        printInt(n1);        
    }
    return 0;
}