// Nikhil Tudaha
// 19CS10045

#include "myl.h"

#define OK 1
#define ERR 0

int printStr(char *str)
{
    int len = 0;
    while (str[len] != '\0')
	len++;
    len++;
    
    __asm__ __volatile__
    (
        "movl $1, %%eax \n\t"
	"movq $1, %%rdi \n\t"
	"syscall \n\t"
	:
	: "S" (str), "d" (len)
    );
    return len;
}

int printInt(int n)
{
	char str[20] = {0};
	int i = 0;
	long long int num = n;
	if (n < 0)
	{
		str[i++] = '-';
		num = -n;
	}
	if (num == 0)
	{
		str[i++] = '0';
	}
	while (num > 0)
	{
		str[i++] = num % 10 + '0';
		num /= 10;
	}
	int l = 0, r = i - 1;
	if (str[0] == '-')
	{
		l++;
	}
	while (l < r)
	{
		char temp = str[l];
		str[l] = str[r];
		str[r] = temp;
		l++; r--;
	}
	return printStr(str);
}

int readInt(int *n)
{
	char buff[20] = {0};
	char *current_location = buff;
	int negative = 0, error = 0, terminated = 0;
	long long int number = 0;
	for (int i = 0; i < 15; i++)
	{
		__asm__ __volatile__
    		(
        		"movl $0, %%eax \n\t"
			"movq $0, %%rdi \n\t"
			"syscall \n\t"
			:
			: "S" (current_location), "d" (1)
    		);
		char current = *current_location;
		current_location++;
		if (i == 0 && current == '-')
		{
			negative = 1;
		}
		// terminate if any whitespace character is used
		else if (current == '\n' || current == ' ' || current == '\t')
		{
			terminated = 1;
			break;
		}
		// error if non-digit character other than '-' sign
		else if (current < '0' || current > '9')
		{
			n = 0;
			error = 1;
		}
		else
		{
			int digit = current - '0';
			number = 10 * number + digit;
		}
	}
	if (terminated == 0)
	{
		printStr("\nToo long.\n");
	}
	if (terminated == 0 || error == 1)
	{
		n = 0;
		return ERR;
	}
	if (negative == 1)
	{
		number = -number;
	}
	if (number < -2147483648 || number > 2147483647)
	{
		return ERR;
	}
	*n = (int) number;
	return OK;
}
