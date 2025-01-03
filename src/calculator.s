        .section .data
prompt_op1:      .asciz "Enter Operand 1: "
prompt_op:       .asciz "Enter Operator (+, -, *, /): "
prompt_op2:      .asciz "Enter Operand 2: "
result_msg:      .asciz "Result: "
error_msg_op:    .asciz "Error: Invalid operator!\n"
error_msg_div:   .asciz "Error: Division by zero!\n"
error_msg_input: .asciz "Error: Invalid number format!\n"
error_msg_len:   .asciz "Error: Input too long!\n"
newline:         .asciz "\n"
float_format:    .asciz "%.24f"    // Format for floating point output
zero_val:        .double 0.0
ten_val:         .double 10.0

        .equ SYS_READ, 63
        .equ SYS_WRITE, 64
        .equ SYS_EXIT, 93
        .equ MAX_INPUT_LENGTH, 20  // Maximum length for number input

        .section .bss
        .align 8
input_buffer1:   .skip 32          // for operand 1
input_buffer2:   .skip 32          // for operand 2
input_operator:  .skip 2           // store operator and null terminator

        .section .text
        .global main

        // Character constants
        .equ CHAR_0,      0x30
        .equ CHAR_9,      0x39
        .equ CHAR_PLUS,   0x2B
        .equ CHAR_MINUS,  0x2D
        .equ CHAR_STAR,   0x2A
        .equ CHAR_SLASH,  0x2F
        .equ CHAR_SPACE,  0x20
        .equ CHAR_TAB,    0x09
        .equ CHAR_NEWLINE,0x0A
        .equ CHAR_CR,     0x0D
        .equ CHAR_DOT,    0x2E

main:
    stp     x29, x30, [sp, -16]!
    mov     x29, sp

    // Load constant addresses
    adrp    x26, zero_val
    add     x26, x26, :lo12:zero_val
    adrp    x27, ten_val
    add     x27, x27, :lo12:ten_val

    // Read Operand1
    adrp    x0, prompt_op1
    add     x0, x0, :lo12:prompt_op1
    bl      print_str

    adrp    x0, input_buffer1
    add     x0, x0, :lo12:input_buffer1
    mov     x1, 32
    bl      read_line
    mov     w22, w0               // save count

    // Check input length
    cmp     w22, MAX_INPUT_LENGTH
    b.gt    print_length_error

    // Convert first operand to float
    adrp    x0, input_buffer1
    add     x0, x0, :lo12:input_buffer1
    bl      ascii_to_float
    fmov    d19, d0              // Store first operand in d19

    // Check if conversion was successful
    fcmp    d19, d19            // Check if result is NaN
    b.vs    print_input_error

    // Read operator
    adrp    x0, prompt_op
    add     x0, x0, :lo12:prompt_op
    bl      print_str

    bl      read_operator
    mov     w20, w0              // Store operator

    // Validate operator
    cmp     w20, CHAR_PLUS
    b.eq    valid_op
    cmp     w20, CHAR_MINUS
    b.eq    valid_op
    cmp     w20, CHAR_STAR
    b.eq    valid_op
    cmp     w20, CHAR_SLASH
    b.eq    valid_op
    b       print_op_error

valid_op:
    // Read Operand2
    adrp    x0, prompt_op2
    add     x0, x0, :lo12:prompt_op2
    bl      print_str

    adrp    x0, input_buffer2
    add     x0, x0, :lo12:input_buffer2
    mov     x1, 32
    bl      read_line
    mov     w22, w0

    // Check input length
    cmp     w22, MAX_INPUT_LENGTH
    b.gt    print_length_error

    // Convert second operand to float
    adrp    x0, input_buffer2
    add     x0, x0, :lo12:input_buffer2
    bl      ascii_to_float
    fmov    d20, d0              // Store second operand in d20

    // Check if conversion was successful
    fcmp    d20, d20            // Check if result is NaN
    b.vs    print_input_error

    // Perform calculation
    fmov    d0, d19              // First operand
    fmov    d1, d20              // Second operand
    mov     w0, w20              // Operator
    bl      calculate

    // Check calculation result
    fcmp    d0, d0              // Check if result is NaN
    b.vs    print_input_error

    // Print result
    adrp    x0, result_msg
    add     x0, x0, :lo12:result_msg
    bl      print_str
    bl      float_to_ascii

    adrp    x0, newline
    add     x0, x0, :lo12:newline
    bl      print_str

    // Exit
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    bl      exit_program

ascii_to_float:
    stp     x29, x30, [sp, -16]!
    mov     x29, sp

    // Initialize result
    ldr     d0, [x26]            // Load 0.0
    ldr     d1, [x27]            // Load 10.0
    mov     w3, #0               // Sign flag (0 = positive, 1 = negative)
    mov     w4, #0               // Decimal point flag
    mov     w5, #0               // Decimal position counter
    mov     w6, #0               // Valid digit found flag

    // Skip leading whitespace
    bl      skip_whitespace

    // Check for negative sign
    ldrb    w2, [x0]
    cmp     w2, #'-'
    b.ne    1f
    mov     w3, #1
    add     x0, x0, #1

1:  // Main conversion loop
convert_loop:
    ldrb    w2, [x0]            // Load character

    // Check for end of string or newline
    cbz     w2, check_valid
    cmp     w2, #CHAR_NEWLINE
    b.eq    check_valid

    // Check for decimal point
    cmp     w2, #CHAR_DOT
    b.eq    handle_decimal

    // Check if it's a digit
    sub     w7, w2, #'0'
    cmp     w7, #9
    b.gt    check_trailing
    cmp     w7, #0
    b.lt    check_trailing

    // If we get here, we have a valid digit
    mov     w6, #1              // Set valid digit found flag
    mov     w2, w7              // Use the converted digit value

    // Convert digit
    scvtf   d2, w2              // Convert to float

    // Handle decimal position
    cmp     w4, #1
    b.eq    after_decimal

    fmul    d0, d0, d1          // Multiply accumulator by 10
    fadd    d0, d0, d2          // Add new digit
    b       next_char

after_decimal:
    // Handle digits after decimal point
    fmov    d3, #10.0
    add     w5, w5, #1          // Increment decimal position
    mov     w7, w5
    fmov    d4, d2              // Copy digit to d4

divide_loop:
    cbz     w7, add_decimal
    fdiv    d4, d4, d3
    sub     w7, w7, #1
    b       divide_loop

add_decimal:
    fadd    d0, d0, d4

next_char:
    add     x0, x0, #1
    b       convert_loop

handle_decimal:
    cmp     w4, #1              // Check if we already found a decimal point
    b.eq    invalid_char
    mov     w4, #1
    add     x0, x0, #1
    b       convert_loop

check_trailing:
    // Only allow whitespace after number
    cmp     w2, #CHAR_SPACE
    b.eq    skip_trailing
    cmp     w2, #CHAR_TAB
    b.eq    skip_trailing
    cmp     w2, #CHAR_NEWLINE
    b.eq    check_valid
    b       invalid_char

skip_trailing:
    add     x0, x0, #1
    ldrb    w2, [x0]
    cbz     w2, check_valid
    b       check_trailing

check_valid:
    cmp     w6, #0              // Check if we found at least one valid digit
    b.eq    invalid_char

    // Apply sign if negative
    cmp     w3, #1
    b.ne    2f
    fneg    d0, d0

2:  ldp     x29, x30, [sp], #16
    ret

skip_whitespace:
    ldrb    w2, [x0]
    cmp     w2, #CHAR_SPACE
    b.eq    skip_next
    cmp     w2, #CHAR_TAB
    b.eq    skip_next
    ret

skip_next:
    add     x0, x0, #1
    b       skip_whitespace

invalid_char:
    // Signal invalid input by setting NaN
    mov     x8, 0x7FFFFFFFFFFFFFFF
    fmov    d0, x8
    ldp     x29, x30, [sp], #16
    ret

calculate:
    // d0 = first operand, d1 = second operand, w0 = operator
    stp     x29, x30, [sp, -16]!
    mov     x29, sp

    // Validate inputs
    fcmp    d0, d0
    b.vs    calc_error
    fcmp    d1, d1
    b.vs    calc_error

    cmp     w0, CHAR_PLUS
    b.eq    do_add
    cmp     w0, CHAR_MINUS
    b.eq    do_sub
    cmp     w0, CHAR_STAR
    b.eq    do_mul
    cmp     w0, CHAR_SLASH
    b.eq    do_div

    mov     w0, #-1
    b       calc_end

do_add:
    fadd    d0, d0, d1
    b       calc_end

do_sub:
    fsub    d0, d0, d1
    b       calc_end

do_mul:
    fmul    d0, d0, d1
    b       calc_end

do_div:
    // Check for division by zero
    ldr     d2, [x26]           // Load 0.0
    fcmp    d1, d2
    b.eq    div_error

    // Additional check for invalid second operand
    fcmp    d1, d1
    b.vs    calc_error

    fdiv    d0, d0, d1
    b       calc_end

calc_error:
    mov     w0, #-3
    b       print_input_error

div_error:
    mov     w0, #-2
    b       print_div_error

calc_end:
    ldp     x29, x30, [sp], #16
    ret

float_to_ascii:
    stp     x29, x30, [sp, -16]!
    mov     x29, sp

    // Allocate buffer
    sub     sp, sp, #64
    mov     x0, sp              // Buffer for result

    // Convert to string using sprintf
    adrp    x1, float_format
    add     x1, x1, :lo12:float_format
    bl      sprintf

    // Print result
    mov     x0, sp
    bl      print_str

    // Cleanup
    add     sp, sp, #64
    ldp     x29, x30, [sp], #16
    ret

read_operator:
    mov     x8, SYS_READ
    mov     x0, #0
    adrp    x1, input_operator
    add     x1, x1, :lo12:input_operator
    mov     x2, #1
    svc     #0

    // Read and discard newline
    sub     sp, sp, #16
    mov     x8, SYS_READ
    mov     x0, #0
    mov     x1, sp
    mov     x2, #1
    svc     #0
    add     sp, sp, #16

    adrp    x0, input_operator
    add     x0, x0, :lo12:input_operator
    ldrb    w0, [x0]
    ret

read_line:
    mov     x8, SYS_READ
    mov     x2, x1
    mov     x1, x0
    mov     x0, #0
    svc     #0
    ret

print_str:
    mov     x1, x0
    mov     w2, #0
find_len:
    ldrb    w3, [x1]
    cbz     w3, got_length
    add     x1, x1, #1
    add     w2, w2, #1
    b       find_len

got_length:
    mov     x8, SYS_WRITE
    mov     x0, #1
    sub     x1, x1, w2, sxtw
    mov     x2, x2
    svc     #0
    ret

print_op_error:
    adrp    x0, error_msg_op
    add     x0, x0, :lo12:error_msg_op
    bl      print_str
    mov     x0, #1
    bl      exit_program

print_div_error:
    adrp    x0, error_msg_div
    add     x0, x0, :lo12:error_msg_div
    bl      print_str
    mov     x0, #1
    bl      exit_program

print_input_error:
    adrp    x0, error_msg_input
    add     x0, x0, :lo12:error_msg_input
    bl      print_str
    mov     x0, #1
    bl      exit_program

print_length_error:
    adrp    x0, error_msg_len
    add     x0, x0, :lo12:error_msg_len
    bl      print_str
    mov     x0, #1
    bl      exit_program

exit_program:
    mov     x8, SYS_EXIT
    svc     #0
    ret
