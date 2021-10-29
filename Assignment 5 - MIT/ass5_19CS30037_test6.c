// Nested loop checking

void heavy_looper() {
    int k = 0;
    while (--k > 0) --k;
    for (k = 1; k < 10; k++) while(k < 10) k++;
    k = -k;
    return;
}

int main() {    
    int i = 0, j = 0, k = 0;
    int dp[10][10][10];
    for (i = 0; i < 9; i++) {
        for (j = 0; j < 9; j++) {
            do {
                dp[i][j][k] = i * j - k;
            }while(k < 9);
            while (k > 0) {
                k--;
            }
        }
    }
    return 0;
}