#ifndef _LIBLDMATH_MATH_H_
#define _LIBLDMATH_MATH_H_

#define BPara    (void * Destiny, void * A, void * B)
#define BSSPara  (void * Destiny, void * A, float Scalar)
#define PROCPara (void * Destiny, void * Source)
#define LERPPara (void * Result, void * A, void * B, float Factor)
#define GETPara  (void * Source)
#define GET2Para (void * A, void * B)

#define VArith(X)               \
    void X##ADD BPara;          \
    void X##SUB BPara;          \
    void X##MUL BPara;          \
    void X##DIV BPara;          \
    void X##DOT BPara;          \
    void X##NORMALIZE PROCPara; \
    void X##LERP LERPPara;      \
    float X##NORM GETPara;      \
    float X##DISTANCE GETPara

#define SArith(X)               \
    void X##MULSS BSSPara;      \
    void X##DIVSS BSSPara

#define VCross(X)               \
    void X##CROSS BPara

#define VAngle(X)               \
    float X##ANGLE GETPara;     \
    float X##X##ANGLE GET2Para

#ifdef __cplusplus
extern "C" 
{
#endif

    /* Data structures and type definitions */
    typedef struct QUAT{float x,y,z,w;}QUAT;
    typedef QUAT UQUAT;
    typedef struct V4{float x,y,z,w;}V4;
    typedef struct V3{float x,y,z;}V3;
    typedef struct V2{float x,y;}V2;
    typedef float SS;
    typedef double DS;
    typedef float ANGLE;
    typedef struct M2{struct V2 column[2];}M2;
    typedef struct M4{struct V4 column[4];}M4;
    typedef struct EULER{struct V3 axis; float angle;}EULER;
    /******************/

    float SSLERP(float A, float B,float Factor);
    double DSLERP(double A, double B,double Factor);

    VArith(V4);
    SArith(V4);

    VArith(V2);
    SArith(V2);
    VCross(V2);
    VAngle(V2);
    void ANGLEROTV2(void * Destiny, void * Source, float Radians_Angle);
    float RADTODEG(float Radian);
    float DEGTORAD(float Radian);
    #define RADROTV2 ANGLEROTV2
    #define DEGROTV2(Destiny,Source,Degrees) ANGLEROTV2(Destiny,Source,DEGTORAD(Degrees))

    VArith(V3);
    SArith(V3);
    VCross(V3);

    void QUATMUL BPara;
    #define QUATNORMALIZE V4NORMALIZE
    #define QUATTOUQUAT QUATNORMALIZE
    void QUATROTV3  (void * Destiny, void * Quaternion, void * Vector);
    void QUATTOM4 (void * Matrix,void * Quaternion);
    void EULERTOQUAT(void * Destiny, void * Axis, float Radians_Angle);
    #define RADTOQUAT EULERTOQUAT
    #define DEGTOQUAT(Destiny,Axis,Degrees) EULERTOQUAT(Destiny,Axis,DEGTORAD(Degrees))
    void UQUATINV(void * Destiny, void * Unit_Quaternion);
    void UQUATDIFF(void * Destiny, void * A, void * B);
    
    
    void M2MAKE(void * Destiny, float Scale);
    #define M2IDENTITY(Destiny) M2MAKE(Destiny,1.f)
    void M2MUL BPara;
    void M2MULV2(void * V2_Destiny, void * Matrix, void * Vector);
    void M2INV PROCPara;
    float M2DET(void * Matrix);
    void ANGLETOM2(void * Destiny, float Radians_Angle);    
    #define M2ADD   V4ADD
    #define M2SUB   V4SUB
    #define M2MULSS V4MULSS
    #define M2DIVSS V4DIVSS


    void M4MAKE(void * Destiny,float Scale);
    #define M4IDENTITY(Destiny) M4MAKE(Destiny,1.f)
    void M4MUL BPara;
    void M4MULV4(void * V4_Destiny, void * Matrix, void * Vector);
    void M4INV PROCPara;

    void M4MULV3(void * V3_Destiny, void * Matrix, void * Vector);
    void AM4MULV3(void * V3_Destiny, void * Matrix, void * Vector); 

    void M4PERSPECTIVE(void *matrix, float fovyInDegrees, float aspectRatio,float znear, float zfar);
    void M4ORTHO(void *matrix, float Width, float Height, float znear, float zfar);
    void M4LOOKAT(void * matrix, void * Vec3From_EYE, void * Vec3To_CENTER, void * Vec3Up);
#ifdef __cplusplus
}
#endif

#undef LERPPara
#undef PROCPara
#undef GETPara
#undef GET2Para
#undef VArith
#undef BPara
#undef BSSPara

#endif
