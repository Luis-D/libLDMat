#ifndef _LDM_GEOMETRY_2D_H_
#define _LDM_GEOMETRY_2D_H_

#ifdef __cplusplus
extern "C" 
{
#endif

#define POINT2D V2

    struct CIRCLE2
    {
        struct {float x,y;} center;
        float radius;
    };

    struct AABB2_A //AABB2 with center and half extends
    {
        struct {float x,y;} center,half_extent;
    };

    struct V2V2V2 //2D TRIANGLE
    {
	    struct {float x,y;} vertex[3];
    };
#define TRI2 V2V2V2
#define TRIANGLE2D TRI2

    struct V2V2 //Two 2D points in space
    {
        struct{float x,y;} a,b;
    };
#define RAY2D V2V2
#define SEGMENT2D V2V2
#define LINE2D V2V2
#define AABB2_B V2V2
   
    struct RANGE2
    {
	struct {float x,y;}a,b;
	float angle;
    };
 
    /**AABB2MODE:
     *2 bits flag:
     *bit 0 set the notation mode (Center+Half_extent) or (A->B)
     *bit 1 set the subnotation mode:
        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max) 
    **/

    /**SEGMODE:
     4 bits flag:
	bit 0 set the notation mode (A+B) or (A->B)
	bit 1 and 2 set the line mode (infinite line, ray or line segment)
	bit 3 is a placeholder for now.**/	

    /**RETMODE:
     *2 bits flag:
     0 = none contact
     1 = First contact
     2 = Last contact
     3 = Both contact **/

    void TRI2CENTROID (void * Destiny, void * Source);
#define TRI2BARYCENTER TRI2DCENTROID

    void AABB2CENTROID (void * Destiny, void * Source, char AABB2MODE);
#define AABB2BARYCENTER AABB2CENTROID
#define AABB2CENTER AABB2CENTROID

    char V2VSTRI2_EXT(void * Point2D, void * Triangle2D,unsigned int bytes_offset);
#define V2VSTRI2(Point2D_ptr, Triangle2D_ptr)   \
        V2VSTRI2_EXT(Point2D_ptr,Triangle2D_ptr,0)

    char V2VSV2(void * A,void *B);

    float V2DISTANCEV2V2(void * Point2D, void * Line, char SEGMODE);


    char V2VSV2V2 (void * Point2D, void * LineSegment, char SEGMODE);
    char V2V2VSV2V2 (float * Seg_A, float * Seg_B,char SEGMODE, float * Time_Return);

    char V2VSV2RADIUS(void * Point2D, void * CircleCenter, float Radius);
#define V2VSCIRCLE2(Point2D_ptr,CIRCLE2_ptr) \
        V2VSV2RADIUS(Point2D_ptr,CIRCLE2_ptr,((float*) CIRCLE2_ptr)+2 ) 

    char V2VSAABB2 (void * Point2D, void * AABB2, char AABB2MODE);
#define V2VSAABB2_A(Point2Dptr,AABB2Aptr) V2VSAABB2(Point2Dptr,AABB2Aptr,0)
#define V2VSAABB2_B_OD(Point2Dptr,AABB2Aptr) V2VSAABB2(Point2Dptr,AABB2Aptr,1)
#define V2VSAABB2_B_MM(Point2Dptr,AABB2Aptr) V2VSAABB2(Point2Dptr,AABB2Aptr,3)

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
    char V2V2VSAABB2(void * Line2D, void * AABB2, char SEGAABB2RETMODE, float * Times_Return);
 
    char AABB2VSAABB2(void* AABB2_A,void * AABB2_B, char AABB2MODE);
    char CIRCLE2VSCIRCLE2(void * Circle2D_A,void * Circle2D_B);
    char CIRCLE2VSAABB2(void* CIRCLE2,void * AABB2, char AABB2MODE);
    char V2VSPOLY2(void * Point_2D, void * Vertices_Buffer_2D,unsigned int VerticesCount);

    char V2VSRANGEDLINE2(void * Vector2,void * Range2_Line,char RANGEMODE,float Angle);
#define V2VSRANGE2(Vector2_ptr,RANGE2_ptr,RANGEMODE)\
    V2VSRANGEDLINE2(Vector2_ptr,RANGE2_ptr,RANGEMODE,(RANGE2_ptr)->angle)
#define V2VSRANGE2_OD(Vector2_ptr,RANGE2_ptr) V2VSRANGE2(Vector2_ptr,RANGE2_ptr,0)
#define V2VSRANGE2_AB(Vector2_ptr,RANGE2_ptr) V2VSRANGE2(Vector2_ptr,RANGE2_ptr,1)

    char V2V2VSCIRCLE2(void * Line2D, void * Circle2D, char SEGRETMODE, void * Times_Return);

/*
    char POLY2SAT(void * VerticesBuffer_A, unsigned int vertices Count_A,
    void * VerticesBuffer_B, unsigned int vertices Count_B);
*/

#ifdef __cplusplus
}
#endif

#endif
