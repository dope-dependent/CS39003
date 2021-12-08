int printInt(int num);

int main()
{
    int a = 5;
    int b = 7;
    if (b != 7) {
        printInt(a);
    }
    else {
        printInt(b);
        if (a >= 5) {
            printInt(a);
        }
        else {
            printInt(b);
        }
    }


    return 0;
}