import sys

# This script simples take an input and converts it to the equivalent SCANCODE information,
# that is, the press and release scancode for each character.
# Currently it only works with simple texts, with characters listed in the SCANCODES variable.

# from http://www.win.tue.nl/~aeb/linux/kbd/scancodes-1.html
# the char "!" is used as ENTER.
SCANCODES = {
    "1": 0x02,
    "2": 0x03,
    "3": 0x04,
    "4": 0x05,
    "5": 0x06,
    "6": 0x07,
    "7": 0x08,
    "8": 0x09,
    "9": 0x0a,
    "0": 0x0b,
    "-": 0x0c,
    "=": 0x0d,
    "Q": 0x10,
    "W": 0x11,
    "E": 0x12,
    "R": 0x13,
    "T": 0x14,
    "Y": 0x15,
    "U": 0x16,
    "I": 0x17,
    "O": 0x18,
    "P": 0x19,
    "[": 0x1a,
    "]": 0x1b,
    "\n":0x1c,
    "!":0x1c,
    "A": 0x1e,
    "S": 0x1f,
    "D": 0x20,
    "F": 0x21,
    "G": 0x22,
    "H": 0x23,
    "J": 0x24,
    "K": 0x25,
    "L": 0x26,
    ";": 0x27,
    "'": 0x28,
    "`": 0x29,
    "\\":0x2b,
    "Z": 0x2c,
    "X": 0x2d,
    "C": 0x2e,
    "V": 0x2f,
    "B": 0x30,
    "N": 0x31,
    "M": 0x32,
    "<": 0x33,
    ".": 0x34,
    "/": 0x35,
    " ": 0x39,

    #shift chars
    "&": 0x08,
    "+": 0x0d,

    #special chars
    "LShift": 0x2a,
}

# format do print the hex in.
FORMAT='{:02x}'

def requires_shift(char):
    return char in ["&", "+"]

def press_code(char_code):
    return FORMAT.format(char_code)
def release_code(char_code):
    return FORMAT.format(char_code|0b10000000)
def press_release_codes(char_code):
    return press_code(char_code) + ' ' + release_code(char_code)

def surround_code(char_code, surround_code):
    """
    Description:
        Takes a char code and surround it with some other code. For example, for getting the
        code of '&', the char code for pressing and releasing the & key would have to be surrounded
        by the shift press and release code.
    Parameters:
        char_code: code to be surrounded by
        surround_code: code to surround
    """
    return '%s %s %s' % (press_code(surround_code), press_release_codes(char_code), release_code(surround_code))

def swap(char):
    """
    Description:
        This function takes a single character and returns a string with its
        scancode information of press and release. If the char is missing from the list,
        return the char surrounded by square brackets.
    Parameters:
        char: a single character
    """
    res = '['+char+']'
    if char in SCANCODES:
        code = SCANCODES[char]
        if requires_shift(char):
            res = surround_code(code, SCANCODES["LShift"])
        else:
            res = press_release_codes(code)
    return res

def main(arg):
    print(' '.join(map(swap, arg.upper())))

if __name__=='__main__':
    main(" ".join(sys.argv[1:]))
