module FloatCompare(A , B , compare_res);
    input [31:0] A ;
    input [31:0] B ; 
    output compare_res ;

    //Although in the main implimentation we have to just compare the abs values 
    // Here this module is a generic module which gives 1 if A>=B 


    reg result_reg ;

    always @(*) begin 
        if(A==B) result_reg = 1 ;

        else if(A[31]!=B[31]) begin  //diff sign bit
            result_reg = (A[31]==1'b1) ? 0 : 1;  
        end
        else begin           // same sign 
            if(A[30:23] == B[30:23]) begin  // same exponents
                result_reg = (A[22:0]>B[22:0]) ? 1 : 0 ;
                if(B[31]) result_reg = ~result_reg ; 
            end

            else begin 
                result_reg = (A[30:23]>B[30:23]) ? 1 : 0 ; 
                if(A[31]==1) result_reg = ~result_reg ;   // If A is negetive then bigger exp means smaller no 

            end
            
        end 
    end  

    assign compare_res = result_reg ; 


endmodule 