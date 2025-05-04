# KAOS

## Overview
 KAOS is a simple programming language for educational purposes. It has dynamic typing, some basic control structures, functions, arrays, and exception handling.

## Group Members
- KAAN BERK SAĞLAM
- AKIN TATAR
- OZAN ERGÜLEÇ
- SEHER OĞUZ

## Grammar in BNF Form
We wrote the formal grammar in BNF.txt. It explains:

- How programs are structured
- How expressions and statements work
- Array operations and function definitions
- Control flow and exception handling

The grammar helps us make sure our compiler works correctly.

## Syntax

### Dynamic Typing
We switched to dynamic typing in this version. You don't need to specify variable types anymore:

```kaos
var age = 23;
var pi = 3.14;
var isActive = true;
var message = "Hello, Kaos!";

// Changing a variable is easy
age = 24;
```

### Operators
- Math stuff: `+`, `-`, `*`, `/`
- Comparisons: `==`, `!=`, `<`, `<=`, `>`, `>=`
- Negation: `-`

### Control Structures

#### If-Else Statements
Previous if else statement:

```kaos
if x > 10 {
    print("x is greater than 10");
} elif x == 10 {
    print("x is exactly 10");
} else {
    print("x is less than 10");
}
```
The current if else statement:
```kaos
if (x > 10) {
    print("x is greater than 10");
} else {
    print("x is less than or equal to 10");
    
// Using logical operators
if (x > 5 and x < 15) {
    print("x is between 5 and 15");
}

if (x < 0 or x > 100) {
    print("x is out of range");
}
}
```
We don't use elif anymore

#### While Loops
```kaos
while (age < 18) {
    print("You are not old enough!");
    age = age + 1;
}
```

### Functions
```kaos
function add(x, y) {
    return x + y;
}

// Function with no parameters
function giveOne() {
    return 1;
}

// Using functions
var result = add(5, 3);
```

### Arrays
```kaos
// Empty array
var emptyList = [];

// Array with elements
var numbers = [1, 2, 3, 4, 5];
var mixed = [1, "hello", true];

// Getting array elements
var firstElement = numbers[0];

// Changing array elements
numbers[2] = 10;
```

### Exception Handling
```kaos
try {
    // Code that might cause errors
    var result = someFunction();
} catch (error) {
    // Handle the error
    print("Oops: " + error);
} finally {
    // This always runs
    print("Clean up time");
}

// Throwing errors
function divide(a, b) {
    if (b == 0) {
        throw "Can't divide by zero!";
    }
    return a / b;
}
```

### Input/Output
```kaos
print("Hello, World!");
print("The sum is: " + sum);
```

## What's New

### 1. Dynamic Typing
- No more type declarations
- Variables just take whatever type you give them

### 2. Arrays
- Added arrays with `[]` syntax
- You can access elements with `array[index]`
- You can change elements with `array[index] = value`

### 3. Exception Handling
- Added `try`, `catch`, and `finally` blocks
- You can `throw` errors when something goes wrong
- Makes error handling much easier

### 4. Grammar Changes
- Cleaned up some rules
- Made expressions simpler
- Better block structure

### 5. Removed Stuff
- Got rid of type declarations
- Removed constants (`const`)
- Removed the input statement

## Design Decisions

We built KAOS with these goals:

1. **Keep it simple**: Easy to learn and use
2. **Dynamic typing**: Less fussy about types
3. **Clean blocks**: Curly braces keep code organized
4. **Arrays**: You need lists of things in any real program
5. **Error handling**: Programs crash less with good exception handling
6. **Readability**: Code should be easy to understand

KAOS is great for learning but still powerful enough for real programming.

## Running KAOS Programs

1. Write your code in a `.kaos` file
2. Build and run it:

```bash
make
./myprog example.kaos
```

## Language Grammar Reference

Check BNF.txt for the complete grammar if you're into that kind of thing.

## Example Program

Here's a sample program showing off our new features:

```kaos
function fibonacci(n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n-1) + fibonacci(n-2);
}

var numbers = [];
var i = 0;

while (i < 10) {
    numbers[i] = fibonacci(i);
    i = i + 1;
}

try {
    print("Fibonacci sequence:");
    var j = 0;
    while (j < 10) {
        print(numbers[j]);
        j = j + 1;
    }
} catch (error) {
    print("Oops: " + error);
} finally {
    print("All done!");
}
```