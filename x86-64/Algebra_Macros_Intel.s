.intel_syntax
.macro _V4LERP_ Destiny, First, Second, pshufed_Factor
//All Operands must be different
    movaps \Destiny, \Second
    subps \Destiny, \First  
    mulps \Destiny, \pshufed_Factor 
    addps \Destiny, \First  
.endm
