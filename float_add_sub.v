`include "float_compare.v"


module float_adder(A,B,Result);
    input [31:0]A ;
    input [31:0] B ; 
    output [31:0] Result ;

    wire comp ; 
    wire [23:0]A_mantissa , B_mantissa ;
    wire [7:0] A_exponent , B_exponent ; 
    wire A_sign , B_sign ; 

    wire [7:0]diff_exp ; 
    reg [23:0] Temp_mantissa ; // For intermediate results 

    reg carry ; 
    reg B_temp_mantissa ; //Because its B which always gets alligned  
    reg sign_final ;
    reg exponent_final ; 

    wire [31:0] A_exact , B_exact ; 
    integer i;

    //Edge case flags 
    wire A_is_zero, B_is_zero;
    wire A_is_inf, B_is_inf;
    wire A_is_nan, B_is_nan;
    wire A_is_denorm, B_is_denorm;

    assign A_is_zero = (A[30:0] == 31'b0);
    assign B_is_zero = (B[30:0] == 31'b0);
    assign A_is_inf = (A[30:23] == 8'hFF) && (A[22:0] == 23'b0);
    assign B_is_inf = (B[30:23] == 8'hFF) && (B[22:0] == 23'b0);
    assign A_is_nan = (A[30:23] == 8'hFF) && (A[22:0] != 23'b0);
    assign B_is_nan = (B[30:23] == 8'hFF) && (B[22:0] != 23'b0);
    assign A_is_denorm = (A[30:23] == 8'h00) && (A[22:0] != 23'b0);
    assign B_is_denorm = (B[30:23] == 8'h00) && (B[22:0] != 23'b0);




    //Compares absolute values 

    FloatCompare inst1(.A({1'b0, A[30:0]}), .B({1'b0, B[30:0]}), .compare_res(comp));
    // Irrespective of what A and B are ; in my module A_exact >= B_exact ; 


    assign A_exact = comp ? A_exact : B_exact ; 
    assign B_exact = comp ? B_exact : A_exact ;    // comp==1 then A>=B 

    // extract the parameters 
    assign A_mantissa = A_is_denorm ? {1'b0,A_exact[22:0]} : {1'b1 , A_exact[22:0]};  // If denorm then no leading 1
    assign B_mantissa = B_is_denorm ? {1'b0 , B_exact[22:0]} : {1'b1 , B_exact[22:0]} ; 

    assign A_exponent = A_exact [30:23] ;
    assign B_exponent = B_exact[30:23] ; 


    assign A_sign = A_exact[31];
    assign B_sign = B_exact[31] ; 


    assign diff_exp = A_exponent - B_exponent ; 
    always @(*) begin
        // Handle edge cases first
        if (A_is_nan || B_is_nan) begin
            // NaN propagation
            sign_final = 1'b0;
            exponent_final = 8'hFF;
            Temp_mantissa = 24'h800000; // NaN mantissa
        end
        else if (A_is_zero && B_is_zero) begin
            
            sign_final = A_sign & B_sign;
            exponent_final = 8'h00;
            Temp_mantissa = 24'h000000;
        end
        else if (A_is_zero) begin
            // 0 + B = B
            sign_final = B_sign;
            exponent_final = B_exponent;
            Temp_mantissa = {1'b0, B_mantissa[22:0]};
        end
        else if (B_is_zero) begin
            // A + 0 = A
            sign_final = A_sign;
            exponent_final = A_exponent;
            Temp_mantissa = {1'b0, A_mantissa[22:0]};
        end
        else if (A_is_inf && B_is_inf) begin
            if (A_sign == B_sign) begin
                
                sign_final = A_sign;
                exponent_final = 8'hFF;
                Temp_mantissa = 24'h000000;
            end else begin
                
                sign_final = 1'b0;
                exponent_final = 8'hFF;
                Temp_mantissa = 24'h800000;
            end
        end
        else if (A_is_inf) begin
            
            sign_final = A_sign;
            exponent_final = 8'hFF;
            Temp_mantissa = 24'h000000;
        end
        else if (B_is_inf) begin
            
            sign_final = B_sign;
            exponent_final = 8'hFF;
            Temp_mantissa = 25'h0000000;
        end
        else begin
            
            if (diff_exp > 24) begin
                // B is too small to affect result
                B_temp_mantissa = 24'h000000;
            end else begin
                B_temp_mantissa = (B_mantissa >> diff_exp);
            end
            
            // Perform addition or subtraction
            if (A_sign ^ B_sign) begin
                    Temp_mantissa = A_mantissa - B_temp_mantissa;
                    sign_final = A_sign;
                
                    exponent_final = A_exponent;
                
                
                if (Temp_mantissa[23] == 0 && Temp_mantissa != 0) begin
                    // Need to normalize
                    for (i = 1; i < 24; i = i + 1) begin
                        if (Temp_mantissa[23-i] == 1) begin
                            Temp_mantissa = Temp_mantissa << i;
                            exponent_final = exponent_final - i;
                            i = 24; // Break loop
                        end
                    end
                end
            end else begin
                // Same signs: add
                {carry, Temp_mantissa} = A_mantissa + B_temp_mantissa;
                sign_final = A_sign;
                exponent_final = A_exponent;
                
                // Handle overflow
                if (carry) begin
                    Temp_mantissa = {1'b1, Temp_mantissa[23:1]};
                    exponent_final = (exponent_final <8'hff )? exponent_final + 1 : 8'hff ; //exponent overflow prevented
                    
                    // Check for infinity overflow
                    if (exponent_final == 8'hFF) begin
                        exponent_final = 8'hFF;
                        Temp_mantissa = 24'h000000;
                    end
                end
            end
        end
    end
    
    
    


    assign Result = {sign_final,exponent_final,Temp_mantissa[22:0]};

    


endmodule
