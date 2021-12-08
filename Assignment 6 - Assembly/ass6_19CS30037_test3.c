int printInt(int num);

int main() {
    int i;
    int sum = 0;
    int sumOfSquares = 0;
    int sumOfCubes = 0;
    int n = 10;
    for (i = 0; i < n; i++) {
        sum = sum + i;
        sumOfSquares = sumOfSquares + i * i;
        sumOfCubes = sumOfCubes + i * i * i;
    }
    printInt(sum);
    printInt(sumOfSquares);
    printInt(sumOfCubes);
    return 0;
}