#ifndef _LDM_GEOMETRY_2D_H_
#define _LDM_GEOMETRY_2D_H_

#ifdef __cplusplus
extern "C" 
{
#endif

    void TRI2DCENTROID (void * Destiny, void * Source);
#define TRI2DBARYCENTER TRI2DCENTROID
#define TRIANGLE2DBARYCENTER TRI2DCENTROID
#define TRIANGLE2DCENTROID TRI2DCENTROID

    char P2DVSSEG2D (void * Point2D, void * LineSegment, char SEGMENTMODE);
#define POINT2DVSSEGMENT2D P2DVSSEG2D
#define POINTVSSEGMENT2D P2DVSSEG2D
#define POINT2DVSV2V2(Point2D,SegmentAB) P2DVSSEG2D(Point2D,SegmentAB,1)
#define POINT2DVSV2DIR(Point2D,SegmentV2DIR) P2DVSSEG2D(Point2D,SegmentV2DIR,0)

    char P2DVSTRI2D(float * 2D_Point, float * 2D_Triangle,int bytes_offset);
#define POINT2DVSTRIANGLE2D(2D_Point_ptr, 2D_Triangle_ptr) \
    P2DVSTRI2D(2D_Point_ptr,2D_Triangle_ptr,0)
#define POINT2DVSTRIANGLE2D_EXT P2DVSTRI2D
#define POINTVSTRIANGLE2D POINT2DVSTRIANGLE2D
#define POINTVSTRIANGLE2D_EXT P2DVSTRI2D


#ifdef __cplusplus
}
#endif

#endif