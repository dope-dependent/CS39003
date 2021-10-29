int x = -7; // Global int
float sq = -3; // Global float

int main()
{
	int i, j, n;	// int
	int sum=0; // int declaration
	char a ='a'; // character
	int p[5]; // 1D integer array
	int dp[5][5]; // 2D integer array
	float tq = -21; // float
	n=5;
	j=100;
	i=0;
    int *q = &i;  // pointer

	// While loops
	while(i<5) 
	{
		i = i + 1;
		j = j + 1;
		p[i]=i * j;
		dp[i][j] = i - j;
	}

	// Do while loop
	do 
	{
		sum = sum - p[i] + p[i] + p[i];
	} while(i < n);
	
	// Nested for loop
	for(i=0;i<n;i++)
	{
		for(j=0;j<n;j++)  // nested for loop
			dp[i][j] = sum + i*j; // multi dimensional array
	}

	// Return testing
	return 0;
}