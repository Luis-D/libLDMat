#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/LDMat/LDMat.h"

int main()
{
    char R;
    float P[2] = {-9,-9}; 
    struct AABB2_A AABB_A= {.center = {.x=0,.y=0},.half_extent = {.x=10,.y=10}};
    R = V2VSAABB2(P,&AABB_A,0);
    printf("%x\n",R);

     struct V2V2 LINE = {.a={.x=2,.y=-12},.b={.x=2,.y=-11}}; 
    

    float T=0;R=0;
    R = V2V2VSAABB2(&LINE,&AABB_A,(char)71,&T);
    printf("%x\n",R);

    printf("%f\n",T);
    printf("%f,%f\n",AABB_A.center.x,AABB_A.center.y);
    printf("%x,%x\n",*(int*)&AABB_A.center.x,*(int*)&AABB_A.center.y);

    struct CIRCLE2 CA = {.center = {.x=0, .y=0},.radius = 10};
    struct CIRCLE2 CB = {.center = {.x=22, .y=0},.radius =220};

    R = CIRCLE2VSCIRCLE2(&CA,&CB);
    printf("%x\n",R);



    return 1;
}
