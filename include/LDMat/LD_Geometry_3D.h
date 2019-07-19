#ifndef _LDM_GEOMETRY_3D_H_
#define _LDM_GEOMETRY_3D_H_

#ifdef __cplusplus
extern "C" 
{
#endif

    struct AABB3_A
    {
	struct {float x,y,z;} center, half_extent;	
    };

    struct SPHERE
    {
	struct {float x,y,z;}center;
	float radius;
    }; 

    struct V3V3V3
    {
	struct {float x,y,z;}vertex[3];	
    };

    struct V3V3
    {
	struct {float x,y,z;} a,b;
    };

    struct PLANE
    {
	struct {float x,y,z;}point,normal;
    };

    struct RANGE3
    {
	struct {float x,y,a;}a,b;
	float angle;
    };

#define TRI3 V3V3V3
#define TRIANGLE3D TRI3
#define AABB3_B V3V3

    void TRI3CENTROID (void * Destiny, void * Source);
#define TRI3DBARYCENTER TRI3DCENTROID

    //TRIMODE: i bit flag: CCW or CW
    char V3V3VSTRI3 (void *Line3D, void *TRI3D, char SEGTRIMODE, float * Time_return);
    void TRI3CLOSESTV3(void * Destiny_V3, void * TRI3,void * V3);
    void TRI3NORMAL(void * Destiny_V3, void * TRI3, char TriangleMode);

    char V3V3VSAABB3 (void * V3V3, void * AABB, char SEGAABBREDMODE, float * Time_return);
    
    char V3V3VSSPHERE(void * V3V3, void * SPHERE, char SEGRETMODE, float * Time_return);

    char V3V3VSPLANE(void * V3V3,void * PLANE, char SEGMODE,float * Time_return);

    float V3DISTANCEPLANE(void *V3,void *PLANE);

    char V3VSTRI3(void * V3, void *TRI3D);

#ifdef __cplusplus
}
#endif

#endif
