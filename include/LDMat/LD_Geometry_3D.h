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

    /**AABB3MODE:
     *2 bits flag:
     *bit 0 set the notation mode (Center+Half_extent) or (A->B)
     *bit 1 set the subnotation mode:
        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max) 
    **/

    /**SEGMODE:
     4 bits flag:
	bit 0 set the notation mode (A+B) or (A->B)
	bit 1 and 2 set the line mode (infinite line, ray or line segment)
		= 0 = infinite line
		= 1 = Ray
		= else = line segment
	bit 3 is a placeholder for now.**/	

    /**RETMODE:
     *2 bits flag:
     0 = none contact
     1 = First contact
     2 = Last contact
     3 = Both contact **/

    void TRI3CENTROID (void * Destiny, void * Source);
#define TRI3DBARYCENTER TRI3DCENTROID

    char V3VSV3(void * A, void * B);
    char V3VSSPHERE(void * Point3D, void * SphereCenter);
    char V3VSAABB3(void * V3, void * AABB3, char AABB3MODE);
    char V3VSTRI3(void * V3, void *TRI3D);
    char V3VSPLANE(void * V3, void * PLANE);

    char SPHEREVSSPHERE(void * A, void * B);
    char SPHEREVSTRI3(void * Sphere, void * TRI3);

    char AABB3VSAABB3(void * A, void * B,char AABB3MODE);

    float V3DISTANCEPLANE(void *V3,void *PLANE);

    //TRIMODE: i bit flag: CCW or CW
    char V3V3VSTRI3 (void *Line3D, void *TRI3D, char SEGTRIMODE, float * Time_return);
    void TRI3CLOSESTV3(void * Destiny_V3, void * TRI3,void * V3);
    void TRI3NORMAL(void * Destiny_V3, void * TRI3, char TriangleMode);

/**
SEGAABB2RETMODE:
8 bits flag:
   bit 0 set the line notation mode (A+B)(clear) or (A->B)(set)
   bit 1 and 2 set the line mode (infinite line, ray or line segment)
   bit 3 check collision with only the edges or with also the volume.
   bit 4 set the AABB notation mode (Center+Half_extent) or (A->B)
   bit 5 set the subnotation mode:
   if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max) 
   bits 6 and 7 set the return data:
     0 = none contact
     1 = First contact
     2 = Last contact
     3 = Both contact 
**/
    char V3V3VSAABB3 (void * V3V3, void * AABB, char SEGAABBRETMODE, float * Time_return);
    
    char V3V3VSSPHERE(void * V3V3, void * SPHERE, char SEGRETMODE, float * Time_return);

    char V3V3VSPLANE(void * V3V3,void * PLANE, char SEGMODE,float * Time_return);

#ifdef __cplusplus
}
#endif

#endif
