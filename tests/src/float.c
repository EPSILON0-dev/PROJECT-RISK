asm("li sp, 0x00FFFFFC; j main");

#include <math.h>

int main()
{
    float deg = 60;
    float pi = 3.14;
    float deg2 = 180;
    float res = tan(deg * pi / deg2);
    *(float*)0x20000 = res;
    asm("lui x31, 0x80; jalr zero, 0(x31)");
}
