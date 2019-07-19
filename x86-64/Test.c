#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/LDMat/LDMat.h"

int main()
{
    float MMA[16]; M4MAKE(MMA,1.f);
    float MMB[16]; M4MAKE(MMB,1.f);
    float MMC[16]; M4MUL(MMC,MMA,MMB);
    

    printf("*****************\n");

    char R;
    float P[2] = {-9,-9}; 
    struct AABB2_A AABB_A= {.center = {.x=0,.y=0},.half_extent = {.x=10,.y=10}};
    R = V2VSAABB2(P,&AABB_A,0);
    printf("%x\n",R);

     struct V2V2 LINE = {.a={.x=20,.y=0},.b={.x=-1,.y=0}}; 
    

    float T=0;R=0;
    R = V2V2VSAABB2(&LINE,&AABB_A,(char)66,&T);
    printf("%x\n",R);
//    printf("%f,%f\n",LINE.a.x,LINE.a.y);
    printf("%f\n",T);
    printf("%f,%f\n",AABB_A.center.x,AABB_A.center.y);
//    printf("%x,%x\n",*(int*)&AABB_A.center.x,*(int*)&AABB_A.center.y);

    struct CIRCLE2 CA = {.center = {.x=0, .y=0},.radius = 10};
    struct CIRCLE2 CB = {.center = {.x=22, .y=0},.radius =220};

    R = CIRCLE2VSCIRCLE2(&CA,&CB);
    printf("%x\n",R);


    struct SPHERE SA = {.center = {.x=0,.y=0,.z=0},.radius = 10};
    
    struct V3V3 LINE3D = {.a={.x=0,.y=0,.z=20},.b={.x=0,.y=0,.z=-1}};

    T=0;
    R = V3V3VSSPHERE(&LINE3D,&SA,(char) 0x12,&T); 
    printf("->%f,%f,%f\n",LINE3D.a.x,LINE3D.a.y,LINE3D.a.z);
    printf("%x @ ",R);printf("%f\n",T);

    struct PLANE PLA = {.point = {.x=0,.y=0,.z=0},.normal ={.x=0,.y=0,.z=1}};

    R = V3V3VSPLANE(&LINE3D,&PLA,0x6,&T);
    printf("->%f,%f,%f > ",LINE3D.a.x,LINE3D.a.y,LINE3D.a.z);
    printf("%f,%f,%f\n",LINE3D.b.x,LINE3D.b.y,LINE3D.b.z);
    printf("%x @ ",R);printf("%f ",T);
    float MADDEDV3[3]; V3MADSS(MADDEDV3,&LINE3D.a,&LINE3D.b,T);
    printf("=%f,%f,%f\n",MADDEDV3[0],MADDEDV3[1],MADDEDV3[2]);

    
    struct AABB3_A AABB3D= {.center = {.x=0,.y=0,.z=0},.half_extent = {.x=10,.y=10,.z=10}};
    T=0;
    R = V3V3VSAABB3(&LINE3D,&AABB3D,66,&T);
    printf("%x @ ",R);printf("%f \n",T);
    printf("->%f,%f,%f > ",LINE3D.a.x,LINE3D.a.y,LINE3D.a.z);
    printf("%f,%f,%f\n",LINE3D.b.x,LINE3D.b.y,LINE3D.b.z);
     

    struct TRI3 TRIA3D = 
    {
	.vertex[0]=
	{
	    .x=-0.5,.y=-0.5,.z=0,
	},
	.vertex[1]=
	{
	    .x=0.5,.y=-0.5,.z=0,
	},
	.vertex[2]=
	{
	    .x=0.0,.y=0,.z=0,
	}
    
    };

    T=0; 
    R = V3V3VSTRI3(&LINE3D,&TRIA3D,2,&T);
    printf("%x @ ",R);printf("%f \n",T);
    printf("->%f,%f,%f > ",LINE3D.a.x,LINE3D.a.y,LINE3D.a.z);
    printf("%f,%f,%f\n",LINE3D.b.x,LINE3D.b.y,LINE3D.b.z);

    return EXIT_SUCCESS
;
}

