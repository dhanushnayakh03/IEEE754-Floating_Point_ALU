`include "float_add_sub.v"
`include "float_multiply.v"
//Floating point division has to be done by some numerical method 
// Here I have choosen Newton Raphson Method 

module float_divide(A , B , zero , div_result);
    input [31:0] A ; 
    input [31:0] B ;
    output zero ; 
    output [31:0]div_result ;


    wire [31:0]x_0 , x_1 , x_2 , x_3 ; 
    wire[31:0] temp1 , temp2 , temp3 , temp4 , temp5 , temp6 , temp7 , temp8 ; 
    wire[31:0] const1 , const2 ; 
    wire [31:0] temp_answer ; 
    assign const1 = 32'b01000000000111100001111000011110 ; // 42/17
    assign const2 = 32'b00111111111100001111000011110001; //  32/17 

    // I have to fixed number of iterations ( hardware perspective)
    // 3 iterations is what we will do here 

    //We will first find 1/B and newton raphson works faster if divisor is less than one
    // So force exponent to -1 or 126 (bias) ; instead of doing 1/B we do 1/D 

    // B = D x 2^(E_B-126) ; 

    wire[31:0] D ; 
    assign D = {1'b0 , 8'd126 , B[22:0]} ; 

    // x_0 = 42/17 - 32/17 * D ; 
    float_multiply inst1 ( .A(const2),.B(D),.product(temp1), .exception() , .underflow() , .overflow() , .zero());
    float_adder inst2 (.A(const1),.B({1'b1 , temp1[30:0]}),.Result(x_0)); 

    //First Iteration 
    // x1 = x0 (2-D*x0)
    float_multiply inst3 ( .A(x_0),.B(D),.product(temp2), .exception() , .underflow() , .overflow() , .zero());
    float_adder inst4 (.A(32'h40000000),.B({~temp2[31] , temp2[30:0]}),.Result(temp3)); 
    float_multiply inst5( .A(x_0),.B(temp3),.product(x_1), .exception() , .underflow() , .overflow() , .zero());

    //Second Iteration
    // x2 = x1(2-D*x_0)
    float_multiply inst6 ( .A(x_1),.B(D),.product(temp4), .exception() , .underflow() , .overflow() , .zero());
    float_adder inst7 (.A(32'h40000000),.B({~temp4[31] , temp4[30:0]}),.Result(temp5)); 
    float_multiply inst8( .A(x_1),.B(temp5),.product(x_2), .exception() , .underflow() , .overflow() , .zero());

    //Third Iteration
    float_multiply inst9 ( .A(x_2),.B(D),.product(temp6), .exception() , .underflow() , .overflow() , .zero());
    float_adder inst10 (.A(32'h40000000),.B({~temp6[31] , temp6[30:0]}),.Result(temp7)); 
    float_multiply inst11( .A(x_2),.B(temp7),.product(x_3), .exception() , .underflow() , .overflow() , .zero());

    //1/B : {B[31],x3[30:23]+8'd126-B[30:23],x3[22:0]}
    wire[7:0] final_exponent;
    assign final_exponent = x_3[30:23] + 8'd126 - B[30:23];

    wire[31:0] reciprocal_B ;
    assign reciprocal_B = {B[31], final_exponent , x_3[22:0]};

    //Final Value A*1/B
    float_multiply inst12 ( .A(A),.B(reciprocal_B),.product(temp_answer), .exception() , .underflow() , .overflow() , .zero(zero));

    assign zero = (B[30:23] == 8'b0) ;
    assign div_result = ((A[30:23] == 0) || zero) ? 32'h0000_0000 : temp_answer;


endmodule
