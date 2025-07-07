# IEEE754- Floating Point ALU
## Floating Point Arithmetic Modules

This repository contains Verilog implementations of IEEE 754 single-precision (32-bit) floating-point arithmetic operations. The modules support standard floating-point operations including addition, subtraction, multiplication, division, and comparison.

## Module Overview

### 1. FloatCompare (`float_compare.v`)
A generic floating-point comparison module that determines if A ≥ B.

**Features:**
- Compares two 32-bit IEEE 754 floating-point numbers
- Handles sign bit differences
- Compares exponents and mantissas appropriately
- Returns 1 if A ≥ B, 0 otherwise

**Interface:**
```verilog
module FloatCompare(A, B, compare_res);
    input [31:0] A;      // First operand
    input [31:0] B;      // Second operand  
    output compare_res;  // Result: 1 if A≥B, 0 otherwise
```

### 2. Float Adder (`float_add_sub.v`)
Performs floating-point addition and subtraction with comprehensive edge case handling.

**Features:**
- IEEE 754 compliant addition/subtraction
- Handles special cases: NaN, infinity, zero, denormalized numbers
- Automatic mantissa alignment based on exponent difference
- Proper normalization and rounding
- Uses absolute value comparison for operand ordering

**Interface:**
```verilog
module float_adder(A, B, Result);
    input [31:0] A;      // First operand
    input [31:0] B;      // Second operand
    output [31:0] Result; // Sum/difference result
```

**Special Cases Handled:**
- NaN propagation
- Infinity arithmetic (∞ + ∞, ∞ - ∞)
- Zero handling (+0, -0)
- Denormalized number support
- Overflow and underflow detection

### 3. Float Multiplier (`float_multiply.v`)
Implements IEEE 754 floating-point multiplication with rounding and exception handling.

**Features:**
- 48-bit intermediate mantissa multiplication
- Proper normalization for products in range [1, 4)
- Round-to-nearest-even (banker's rounding)
- Comprehensive exception detection

**Interface:**
```verilog
module float_multiply(A, B, product, exception, underflow, overflow, zero);
    input [31:0] A;       // First operand
    input [31:0] B;       // Second operand
    output [31:0] product; // Multiplication result
    output exception;     // High if operand is infinity
    output underflow;     // High if result underflows
    output overflow;      // High if result overflows
    output zero;          // High if result is zero
```

**Rounding Implementation:**
- Guard (G), Round (R), and Sticky (S) bits
- Round-to-nearest-even for tie-breaking
- Proper handling of halfway cases

### 4. Float Divider (`float_divide.v`)
Implements floating-point division using the Newton-Raphson iterative method.

**Features:**
- Newton-Raphson method for computing reciprocal
- 3 iterations for convergence
- Handles division by zero
- Exponent adjustment for proper scaling

**Interface:**
```verilog
module float_divide(A, B, zero, div_result);
    input [31:0] A;        // Dividend
    input [31:0] B;        // Divisor
    output zero;           // High if division by zero
    output [31:0] div_result; // Division result
```

**Algorithm:**
1. Normalize divisor B to range [1, 2) as D
2. Compute initial approximation: x₀ = 42/17 - 32/17 × D
3. Iterate: xₙ₊₁ = xₙ(2 - D×xₙ) for 3 iterations
4. Scale result: A × (1/B) = A × x₃ × 2^(126-E_B)

## File Structure

```
├── float_compare.v      # Floating-point comparison module
├── float_add_sub.v      # Addition/subtraction module
├── float_multiply.v     # Multiplication module
├── float_divide.v       # Division module (uses add/multiply)
└── README.md           # This file
```

## Dependencies

- `float_divide.v` includes `float_add_sub.v` and `float_multiply.v`
- `float_add_sub.v` includes `float_compare.v`

## Usage Examples

### Basic Instantiation

```verilog
// Float Addition
float_adder add_inst (
    .A(32'h40400000),      // 3.0 in IEEE 754
    .B(32'h40000000),      // 2.0 in IEEE 754
    .Result(sum_result)    // Expected: 5.0
);

// Float Multiplication
float_multiply mult_inst (
    .A(32'h40400000),      // 3.0
    .B(32'h40000000),      // 2.0
    .product(mult_result), // Expected: 6.0
    .exception(mult_exc),
    .underflow(mult_under),
    .overflow(mult_over),
    .zero(mult_zero)
);

// Float Division
float_divide div_inst (
    .A(32'h40C00000),      // 6.0
    .B(32'h40000000),      // 2.0
    .zero(div_by_zero),
    .div_result(div_result) // Expected: 3.0
);

// Float Comparison
FloatCompare comp_inst (
    .A(32'h40400000),      // 3.0
    .B(32'h40000000),      // 2.0
    .compare_res(is_greater) // Expected: 1 (3.0 >= 2.0)
);
```

### Testbench Example

```verilog
module tb_float_ops;
    reg [31:0] a, b;
    wire [31:0] add_result, mult_result, div_result;
    wire comp_result, div_zero;
    wire mult_exception, mult_underflow, mult_overflow, mult_zero;
    
    // Instantiate modules
    float_adder add_dut(.A(a), .B(b), .Result(add_result));
    float_multiply mult_dut(.A(a), .B(b), .product(mult_result), 
                           .exception(mult_exception), .underflow(mult_underflow),
                           .overflow(mult_overflow), .zero(mult_zero));
    float_divide div_dut(.A(a), .B(b), .zero(div_zero), .div_result(div_result));
    FloatCompare comp_dut(.A(a), .B(b), .compare_res(comp_result));
    
    initial begin
        // Test case 1: Normal operations
        a = 32'h40400000; // 3.0
        b = 32'h40000000; // 2.0
        #10;
        $display("A=3.0, B=2.0");
        $display("Add: %h, Mult: %h, Div: %h, Comp: %b", 
                 add_result, mult_result, div_result, comp_result);
        
        // Test case 2: Division by zero
        a = 32'h40400000; // 3.0
        b = 32'h00000000; // 0.0
        #10;
        $display("A=3.0, B=0.0");
        $display("Div by zero: %b, Result: %h", div_zero, div_result);
        
        // Test case 3: Infinity
        a = 32'h7F800000; // +infinity
        b = 32'h40000000; // 2.0
        #10;
        $display("A=+inf, B=2.0");
        $display("Add: %h, Mult: %h", add_result, mult_result);
        
        $finish;
    end
endmodule
```

## IEEE 754 Format Reference

```
Single Precision (32-bit):
┌─────┬─────────────┬───────────────────────────┐
│ S   │ Exponent    │ Mantissa                  │
│ 31  │ 30      23  │ 22                    0   │
└─────┴─────────────┴───────────────────────────┘
```

**Special Values:**
- **Zero**: Exponent = 0, Mantissa = 0
- **Denormalized**: Exponent = 0, Mantissa ≠ 0
- **Infinity**: Exponent = 255, Mantissa = 0
- **NaN**: Exponent = 255, Mantissa ≠ 0

## Implementation Notes

### Addition/Subtraction Algorithm
1. Extract sign, exponent, and mantissa
2. Handle special cases (NaN, infinity, zero)
3. Align mantissas based on exponent difference
4. Perform addition or subtraction based on sign
5. Normalize result and adjust exponent
6. Handle overflow/underflow conditions

### Multiplication Algorithm
1. Multiply mantissas (24-bit × 24-bit = 48-bit)
2. Add exponents and subtract bias (127)
3. Normalize if needed (shift right if MSB is 1)
4. Round using Guard, Round, and Sticky bits
5. Adjust final exponent and check for overflow/underflow

### Division Algorithm (Newton-Raphson)
1. Normalize divisor to [1,2) range
2. Use polynomial approximation for initial guess
3. Iterate: x_{n+1} = x_n(2 - D·x_n)
4. Scale result by appropriate power of 2
5. Handle edge cases (division by zero, infinity)

## Testing Recommendations

1. **Normal Cases**: Test with various positive/negative numbers
2. **Edge Cases**: Test with zero, infinity, NaN
3. **Boundary Cases**: Test with very small/large numbers
4. **Rounding**: Test cases that require rounding
5. **Exceptions**: Verify proper exception flag behavior

## Known Limitations

1. **Precision**: Limited to single-precision (32-bit) format
2. **Rounding**: Only round-to-nearest-even implemented
3. **Division**: Fixed 3 iterations may not be optimal for all cases
4. **Performance**: Not optimized for timing or area

## Future Enhancements

- Double precision (64-bit) support
- Configurable rounding modes
- Pipelined implementations for higher throughput
- Optimization for FPGA/ASIC synthesis
- Comprehensive verification suite

## License

This code is provided as-is for educational and research purposes.
