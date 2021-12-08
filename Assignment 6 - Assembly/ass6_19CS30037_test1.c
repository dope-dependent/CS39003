int printInt(int num);

int main()
{
    int a = 2, b = 3, c = 2;
    printInt(a);
    int *p = &a;
    *p = 10;
    printInt(a);
    return 0;
}