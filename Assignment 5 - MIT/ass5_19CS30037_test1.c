int globalI = 5;
// char c = 'z' doesnt work
int globalUI;
char globalUC;
char *globalPStr = "Hello";
char *globalUPStr;
char globalAStr[100] = "Hello Im learning x86";
char globalUAStr[100];

void call(int x)
{
    x = x + 6;
    x /= 19;
    int y, z, A[100];
    y = 9;
    return;
}

int main()
{
    int i = 0;
    int n = 10;
    for (int j = 0; j < n; j++)
    {
        call(i);
    }
    return 0;
}