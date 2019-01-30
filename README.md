# libLDM
The fast, low level and non-bloated (*maybe*) math library.

###### This library is conformant with:
 *  **x86-64**:
    * System V AMD64 ABI (*nix systems)
    * Microsoft x64 calling convention (Windows) 
    
### Tutorial:

#### Data types:
  The next datatypes are the one currently handled by the library:
- (Matrices are Row Major).
* **SS**: *float*. IEEE-754 single precision floating point number.
* **ANGLE**: A *float*. It stands for "*angle in radians*".
* **RAD**: *Radians*. A *float*. It stands for "Angle in radians".
* **DEG**: *Degrees*. A *float*. It stands for "Angle in degrees".
* **V2**: *Vector 2*. An array of two IEEE-754 single precision floating point numbers.
* **V3**: *Vector 3*. An array of three IEEE-754 single precision floating point numbers.
* **V4**: *Vector 4*. An array of four IEEE-754 single precision floating point numbers.
* **QUAT**: *Quaternion*. An array of four IEEE-754 single precision floating point numbers.
* **UQUAT**: *Unitary Quaternion*. The same as a *Quaternion*.
* **EULER**: *EULER ANGLE*. A *Vector 3* plus a contiguous Scalar, tecnically a *Vector 4* too.
* **M2**: *Matrix 2*, *2x2 Matrix*. An array of four IEEE-754 single precision floating point numbers.
* **M4**: *Matrix 4*, *4x4 Matrix*. An array of 16 IEEE-754 single precision floating point numbers.


#### Usage:
##### C/C++:
###### Example:
```C
#include "LDM/LDM.h"
#include "stdio.h"

int main()
{
  float A[2] = {1,2};
  //The same as V2 A = {.x = 1, .y = 2};
  
  float B[2] = {3,4};
  //The same as V2 B = {.x = 3, .y = 4};
  
  float C[2];
  //The same as V3 C;
  
  V2ADD (C, A, B);
  //This could also be V2ADD(&C, &A, &B);
  //Because functions relies on pointers.
  
  printf("%f,%f\n",C[0], C[1]);
  //This could also be printf(%f,%f\n", C.x,C.y);
  
  return 1;
}

```
