module float_multiply(A,B,product, exception , underflow , overflow , zero);
    input [31:0] A ;
    input [31:0] B ; 
    output [31:0] product ; 
    output underflow , overflow , zero , exception ; 

    wire [47:0] Temp_Mantissa , Mantissa_normalized ; 
    wire normalized , round_up , even_round ; 
    wire [24:0] A_mantissa , B_mantissa ; 

    wire sign_final ; 
    wire [8:0] exponent ; 
    wire [22:0] mantissa_final ; 

    // Exception flag is high if one of the no is inf 
    assign exception =   &(A[30:23]) | &(B[30:23]) ; 



    //If exponent is zero then mantissa is 0.---- else its 1.----
    assign A_mantissa = (A[30:23]==8'b0) ? {1'b0 , A[22:0]} : {1'b1 , A[22:0]};
    assign B_mantissa = (B[30:23]==8'b0) ? {1'b0 , B[22:0]} : {1'b1 , B[22:0]};

    //Compute product of mantissas 
    assign Temp_Mantissa = A_mantissa * B_mantissa ; 

    //But we need to only select 23 bits removing implicit 1 
    //Check whether result is normalized or not , because 1.--- x 1.--- can take values from [1,4)
    //So check first 2 MSB bits : 00(not poss) , 01(normalized) , 10(Not) , 11(Not)

    assign normalized = Temp_Mantissa[47] ? 1'b0 : 1'b1 ;

    //Now either shift right or keep as it is 
    assign Mantissa_normalized = normalized ? Temp_Mantissa : Temp_Mantissa>>1 ;

    wire G ,R , S ;  //Guard , Round and Sticky bit 
    //G --> 23rd bit  || R---> 22nd bit  ||  S---> Or of remaning bit 

    //If G=1 R=0 S=0 then your value is half way here so round as per you go to even 
    // If some other combo then you go up or go down 

   assign S = |Mantissa_normalized[21:0];  // Sticky bit = OR of remaining bits
   assign G = Mantissa_normalized[23] ; 
   assign R = Mantissa_normalized[22] ; 

    assign round_up = ((G==1'b1) & (R==0) & (S==0) & (Mantissa_normalized[24]==1)) | // tie, and LSB is odd -> round up
                    ((G==1'b1) & (R==1'b1)) |                                     // more than halfway -> round up
                    ((G==1'b1) & (R==0) & (S==1));                                // slightly more than halfway -> round up





    assign mantissa_final = round_up ? (Mantissa_normalized[47:24] + 1'b1) : Mantissa_normalized[47:24];

    assign exponent = A[30:23] + B[30:23] - 8'd127 + (~normalized); //exponent get incrimented only if it was normalized by me
    
    assign zero = exception ? 1'b0 : (mantissa_final == 23'd0) ? 1'b1 : 1'b0;

    assign overflow = ((exponent[8] & !exponent[7]) & !zero) ; //If overall exponent is greater than 255 then Overflow condition.
    //Exception Case when exponent reaches its maximu value that is 384.

    //If sum of both exponents is less than 127 then Underflow condition.
    assign underflow = ((exponent[8] & exponent[7]) & !zero) ? 1'b1 : 1'b0; 

    assign sign_final = A[31] ^ B[31] ; 

    assign product = exception ? 32'd0 : zero ? {sign_final,31'd0} : overflow ? {sign_final,8'hFF,23'd0} : underflow ? {sign_final,31'd0} : {sign_final,exponent[7:0],mantissa_final};

endmodule 