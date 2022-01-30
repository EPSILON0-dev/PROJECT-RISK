asm("li sp, 0x00FFFFFC; j main");

#include <math.h>

static volatile float pi = 3.141592f;
static volatile float e = 2.718281f;
static volatile float sqr2 = 1.414213f;
static volatile float res = 0;

int main()
{
    res = pi * e;
    res = res * pi;
    res /= 2.0f;
    res += sqr2;
    res -= 1.0f;
    res = cos(res);
    *(float*)0x20000 = res;
    asm("lui x31, 0x80; jalr zero, 0(x31)");
}