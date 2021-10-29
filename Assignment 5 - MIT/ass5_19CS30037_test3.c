// Arithmetic operations and nested block testing

float g_d = 2.4 + 2.4;
int p_d = 1 - 0;

void main() {
    int x = 142;
    int *y = &x; // Pointer check
    float j, k, l, m, n, o, p = -0.12;
    int a, b, c, d, e, f, g, h, i = -124;
    char c_q = 'c', d_q = d;
    a = a * b;
    b = b + c;
    c = e + j;
    f = *y / 3;
    g = o / 27.0;
    h = a % 2;
    f = c_q;
    b = b | c;
    c = f & g;
    // Nested testing
    {
        j = -0.23;
        {
            c = 231;
            int q = 2;
            {
                b = -1;
                {
                    if (a == 2) {
                        a = 2;
                    }
                }
            }
        }
    }

    // Shift operator check
    i = h << 4;
    g = c >> 2;
    return;
}