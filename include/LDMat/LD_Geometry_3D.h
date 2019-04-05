#ifndef _LDM_GEOMETRY_3D_H_
#define _LDM_GEOMETRY_3D_H_

#ifdef __cplusplus
extern "C" 
{
#endif

    void TRI3DCENTROID (void * Destiny, void * Source);
#define TRI3DBARYCENTER TRI3DCENTROID

#ifdef __cplusplus
}
#endif

#endif