# Using the ARMv8 Calculator

## Table of Contents
1. [Building from Source](#building-from-source)
2. [Basic Usage](#basic-usage)
3. [Input Guidelines](#input-guidelines)
4. [Error Messages](#error-messages)
5. [Examples](#examples)

## Building from Source

### Option 1: Using Make
1. Clone the repository
```bash
git clone https://github.com/Abdalla-Eldoumani/ARMv8-Assembly-Calculator.git
cd arm-calculator
```
2. Run ```make```
3. Run the executable
```bash
./calculator
```

### Option 2: Using GCC
1. Clone the repository, if you haven't already it's the same as above
2. Compile the source code
```bash
gcc calculator.s -o calculator
```

## Basic Usage
The calculator operates in an interactive mode:

1. Enter the first operand
2. Enter an operator from the following list: +, -, *, /
3. Enter the second operand
4. The result will be displayed

## Input Guidelines
### Operands
- If the operand is an integer, it should be as follows: ```123 or -123 or 0```
- If the operand is a decimal, it should be as follows: ```123.456 or -123.456 or 0.456 or .456```
- Maximum number of digits is 20
- Leading/trailing spaces are allowed
- Leading zeros are allowed: 007 = 7

### Operators
- The operator should be one of the following: ```+ - * /```

### Restrictions
- Scientific notation not supported (e.g., 1e5)
- Only one decimal point allowed per number
- Only one operator allowed
- No expressions or parentheses

## Error Messages

| Error Message | Cause | Solution |
|--------------|-------|----------|
| "Error: Invalid number format!" | Non-numeric input or invalid characters | Use only numbers, decimal point, and minus sign |
| "Error: Division by zero!" | Attempted division by zero | Use non-zero divisor |
| "Error: Invalid operator!" | Operator not recognized | Use only +, -, *, / |
| "Error: Input too long!" | Input exceeds 20 characters | Shorten input |

## Examples
### Valid Inputs
```txt
# Basic arithmetic
Enter Operand1: 5
Enter Operator (+, -, *, /): +
Enter Operand2: 3
Result: 8.00000000

# Decimal numbers
Enter Operand1: 3.14
Enter Operator (+, -, *, /): *
Enter Operand2: 2
Result: 6.28000000

# Negative numbers
Enter Operand1: -10
Enter Operator (+, -, *, /): /
Enter Operand2: 2
Result: -5.00000000
```

### Invalid Inputs
```txt
# Invalid number
Enter Operand1: abc
Error: Invalid number format!

# Division by zero
Enter Operand1: 5
Enter Operator (+, -, *, /): /
Enter Operand2: 0
Error: Division by zero!

# Invalid operator
Enter Operand1: 5
Enter Operator (+, -, *, /): %
Error: Invalid operator!
```