def word_to_shifted_value(word):
    result = 0
    for char in word:
        # Shift result by 7 bits, then add the ASCII of current char
        result = (result << 7) + ord(char)
    return result

def to_binary_str(value):
    return bin(value)[2:]  # remove '0b' prefix

words = ['add', 'sub', 'sll', 'slt', 'sltu', 'xor', 'srl', 'sra', 'or', 'and',
'addi', 'slti', 'sltiu', 'xori', 'ori', 'andi', 'slli', 'srli', 'srai']

for w in words:
    val = word_to_shifted_value(w)
    print(f"Word: {w}")
    print(f"\tDecimal: {val}")
    print(f"\tBinary: {to_binary_str(val)}")
    print(f"\thex: {hex(val)}")
    print()
