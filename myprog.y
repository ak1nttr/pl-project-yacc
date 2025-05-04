%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern FILE* yyin;
void yyerror(const char* s);

int line_num = 1;

// Value types for runtime evaluation
typedef enum {
    VAL_INTEGER,
    VAL_FLOAT,
    VAL_STRING,
    VAL_BOOLEAN,
    VAL_FUNCTION,  
    VAL_EXCEPTION,
    VAL_ARRAY      
} ValueType;

typedef struct Value Value;

// Value structure for runtime evaluation
struct Value {
    ValueType type;
    union {
        int ival;
        double fval;
        char* sval;
        int bval;
        struct {
            struct ASTNode* func_def;  
            char* name;
        } func;
        struct {
            char* message;
            char* type;                
        } exception;
        struct {
            Value* elements;    // Array elements
            int length;         // Array length
            int capacity;       // Array capacity
        } array;
    } data;
};

// For returning from functions and exception handling
typedef struct {
    int has_return;      // Flag to indicate if return occurred
    int has_exception;   // Flag to indicate if exception was thrown
    Value return_value;  // Value returned or exception object
} ReturnValue;

// Symbol table structure
typedef struct {
    char* name;
    Value value;
} Symbol;

// Symbol table for current scope
typedef struct SymbolTable {
    Symbol* symbols;
    int count;
    int capacity;
    struct SymbolTable* parent;  // For nested scopes
} SymbolTable;

// Global symbol table
SymbolTable* global_symbols;

// Current symbol table (for current scope)
SymbolTable* current_symbols;

// AST node types
typedef enum {
    NODE_INTEGER,
    NODE_FLOAT,
    NODE_STRING,
    NODE_BOOLEAN,
    NODE_IDENTIFIER,
    NODE_BINARY_OP,
    NODE_UNARY_OP,
    NODE_ASSIGNMENT,
    NODE_DECLARATION,
    NODE_IF,
    NODE_WHILE,
    NODE_PRINT,
    NODE_BLOCK,
    NODE_FUNCTION_DEF,
    NODE_FUNCTION_CALL,
    NODE_RETURN,      
    NODE_TRY_CATCH,  
    NODE_THROW,    
    NODE_ARRAY_LITERAL,  
    NODE_ARRAY_ACCESS    
} NodeType;

// AST node structure
typedef struct ASTNode {
    NodeType type;
    union {
        int ival;                  // For integer literals
        double fval;               // For floating point literals
        char* sval;                // For strings and identifiers
        int bval;                  // For booleans
        
        struct {                   // For binary operations
            struct ASTNode* left;
            struct ASTNode* right;
            int op;                // Token type for the operator
        } binary_op;
        
        struct {                   // For unary operations
            struct ASTNode* operand;
            int op;                // Token type for the operator
        } unary_op;
        
        struct {                   // For assignments
            char* name;
            struct ASTNode* value;
        } assignment;
        
        struct {                   // For variable declarations
            char* name;
            struct ASTNode* initial_value;
        } declaration;
        
        struct {                   // For if statements
            struct ASTNode* condition;
            struct ASTNode* if_branch;
            struct ASTNode* else_branch; // Can be NULL
        } if_stmt;
        
        struct {                   // For while loops
            struct ASTNode* condition;
            struct ASTNode* body;
        } while_loop;
        
        struct {                   // For print statements
            struct ASTNode* expr;
        } print_stmt;
        
        struct {                   // For blocks of statements
            struct ASTNode** statements;
            int count;
            int capacity;
        } block;
        
        struct {                   // For function definitions
            char* name;            // Function name
            char** parameters;     // Array of parameter names
            int param_count;       // Number of parameters
            struct ASTNode* body;  // Function body
        } func_def;
        
        struct {                   // For function calls
            char* name;            // Function name
            struct ASTNode** arguments; // Array of argument expressions
            int arg_count;         // Number of arguments
        } func_call;
        
        struct {                   // For return statements
            struct ASTNode* expr;  // Expression to return
        } return_stmt;
        
        struct {                   // For try-catch-finally statements
            struct ASTNode* try_block;    // Try block
            struct ASTNode* catch_block;  // Catch block
            char* exception_var;          // Exception variable name
            struct ASTNode* finally_block; // Finally block (can be NULL)
        } try_catch;
        
        struct {                   // For throw statements
            struct ASTNode* expr;  // Exception expression to throw
        } throw_stmt;
        
        struct {                   // For array literals
            struct ASTNode** elements;  // Array of expression nodes
            int count;             // Number of elements
        } array_literal;
        
        struct {                   // For array access
            struct ASTNode* array; // Array expression (can be identifier or another expression)
            struct ASTNode* index; // Index expression
        } array_access;
    } data;
} ASTNode;

// Forward declarations for AST functions
ASTNode* create_integer_node(int value);
ASTNode* create_float_node(double value);
ASTNode* create_string_node(char* value);
ASTNode* create_boolean_node(int value);
ASTNode* create_identifier_node(char* name);
ASTNode* create_binary_op_node(ASTNode* left, int op, ASTNode* right);
ASTNode* create_unary_op_node(int op, ASTNode* operand);
ASTNode* create_assignment_node(char* name, ASTNode* value);
ASTNode* create_declaration_node(char* name, ASTNode* initial_value);
ASTNode* create_if_node(ASTNode* condition, ASTNode* if_branch, ASTNode* else_branch);
ASTNode* create_while_node(ASTNode* condition, ASTNode* body);
ASTNode* create_print_node(ASTNode* expr);
ASTNode* create_block_node();
ASTNode* create_function_def_node(char* name, char** parameters, int param_count, ASTNode* body);
ASTNode* create_function_call_node(char* name);
ASTNode* create_return_node(ASTNode* expr);
ASTNode* create_try_catch_node(ASTNode* try_block, ASTNode* catch_block, char* exception_var, ASTNode* finally_block);
ASTNode* create_throw_node(ASTNode* expr);
ASTNode* create_array_literal_node();
void add_element_to_array_literal(ASTNode* array_node, ASTNode* element);
ASTNode* create_array_access_node(ASTNode* array, ASTNode* index);
void add_statement_to_block(ASTNode* block, ASTNode* statement);
void add_parameter_to_function(ASTNode* func_def, char* param);
void add_argument_to_function_call(ASTNode* func_call, ASTNode* arg);
void free_ast(ASTNode* node);

// Symbol table functions
SymbolTable* create_symbol_table();
void free_symbol_table(SymbolTable* table);
int add_symbol(SymbolTable* table, char* name, Value value);
int find_symbol_in_table(SymbolTable* table, char* name);
int find_symbol(char* name);
void declare_variable(char* name, Value value);
void set_variable(char* name, Value value);
Value get_variable(char* name);
void push_scope();
void pop_scope();

// Evaluation functions
Value evaluate_expression(ASTNode* expr);
Value evaluate_array_literal(ASTNode* expr);
Value evaluate_array_access(ASTNode* expr);
ReturnValue interpret(ASTNode* node);
ReturnValue interpret_block(ASTNode* block, int new_scope);
ReturnValue call_function(ASTNode* func_def, ASTNode** arguments, int arg_count);
void print_value(Value val);
void print_value_ln(Value val);
int value_to_boolean(Value val);
Value copy_value(Value val);
void free_value(Value val);

// Root node of the AST
ASTNode* program_root = NULL;
%}

%union {
    int ival;
    double fval;
    char* sval;
    int bval;
    struct ASTNode* node;
    struct {
        char** parameters;
        int count;
    } param_list;
    struct {
        struct ASTNode** arguments;
        int count;
    } arg_list;
}

/* Token definitions */
%token VAR IF ELSE WHILE PRINT FUNCTION RETURN
%token TRY CATCH FINALLY THROW
%token PLUS MINUS MULTIPLY DIVIDE
%token AND OR NOT
%token ASSIGN
%token EQUAL NOT_EQUAL LESS_THAN LESS_EQUAL GREATER_THAN GREATER_EQUAL
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET SEMICOLON COMMA

%token <ival> INTEGER
%token <fval> FLOAT
%token <sval> STRING IDENTIFIER
%token <bval> BOOLEAN

/* Define types for non-terminals */
%type <node> program statement_list statement
%type <node> declaration assignment if_statement while_statement print_statement
%type <node> expression term factor block function_definition function_call return_statement
%type <node> try_statement catch_block finally_block throw_statement
%type <node> array_literal array_access array_element_list
%type <param_list> parameter_list optional_parameter_list
%type <arg_list> argument_list optional_argument_list

/*  operator precedences */

%left EQUAL NOT_EQUAL
%left LESS_THAN LESS_EQUAL GREATER_THAN GREATER_EQUAL
%left PLUS MINUS
%left MULTIPLY DIVIDE
%left OR      
%left AND       
%right NOT    
%left LBRACKET 
%nonassoc UMINUS

%%

program:
    statement_list {
        program_root = $1;
    }
    ;

statement_list:
    statement {
        $$ = create_block_node();
        add_statement_to_block($$, $1);
    }
    | statement_list statement {
        $$ = $1;
        add_statement_to_block($$, $2);
    }
    ;

statement:
    declaration SEMICOLON { $$ = $1; }
    | assignment SEMICOLON { $$ = $1; }
    | if_statement { $$ = $1; }
    | while_statement { $$ = $1; }
    | print_statement SEMICOLON { $$ = $1; }
    | function_definition { $$ = $1; }
    | function_call SEMICOLON { $$ = $1; }
    | return_statement SEMICOLON { $$ = $1; }
    | try_statement { $$ = $1; }
    | throw_statement SEMICOLON { $$ = $1; }
    | block { $$ = $1; }
    ;

block:
    LBRACE statement_list RBRACE {
        $$ = $2;
    }
    ;

declaration:
    VAR IDENTIFIER ASSIGN expression {
        $$ = create_declaration_node($2, $4);
        free($2); // Free the identifier string
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        $$ = create_assignment_node($1, $3);
        free($1); // Free the identifier string
    }
    | factor LBRACKET expression RBRACKET ASSIGN expression {
        // Create an array access node
        ASTNode* access = create_array_access_node($1, $3);
        
        // Create a special binary op node for array assignment
        $$ = create_binary_op_node(access, ASSIGN, $6);
    }
    ;

if_statement:
    IF LPAREN expression RPAREN block {
        $$ = create_if_node($3, $5, NULL);
    }
    | IF LPAREN expression RPAREN block ELSE block {
        $$ = create_if_node($3, $5, $7);
    }
    ;

while_statement:
    WHILE LPAREN expression RPAREN block {
        $$ = create_while_node($3, $5);
    }
    ;

print_statement:
    PRINT LPAREN expression RPAREN {
        $$ = create_print_node($3);
    }
    ;

function_definition:
    FUNCTION IDENTIFIER LPAREN optional_parameter_list RPAREN block {
        $$ = create_function_def_node($2, $4.parameters, $4.count, $6);
        free($2); // Free the identifier string
    }
    ;

optional_parameter_list:
    /* empty */ {
        $$.parameters = NULL;
        $$.count = 0;
    }
    | parameter_list {
        $$ = $1;
    }
    ;

parameter_list:
    IDENTIFIER {
        $$.parameters = malloc(sizeof(char*));
        $$.parameters[0] = $1;
        $$.count = 1;
    }
    | parameter_list COMMA IDENTIFIER {
        $$ = $1;
        $$.parameters = realloc($$.parameters, sizeof(char*) * ($$.count + 1));
        $$.parameters[$$.count] = $3;
        $$.count++;
    }
    ;

function_call:
    IDENTIFIER LPAREN optional_argument_list RPAREN {
        $$ = create_function_call_node($1);
        free($1); // Free the identifier string
        
        // Add all arguments to the function call
        for (int i = 0; i < $3.count; i++) {
            add_argument_to_function_call($$, $3.arguments[i]);
        }
        
        // Free the argument list array (not the arguments themselves)
        if ($3.arguments) free($3.arguments);
    }
    ;

optional_argument_list:
    /* empty */ {
        $$.arguments = NULL;
        $$.count = 0;
    }
    | argument_list {
        $$ = $1;
    }
    ;

argument_list:
    expression {
        $$.arguments = malloc(sizeof(ASTNode*));
        $$.arguments[0] = $1;
        $$.count = 1;
    }
    | argument_list COMMA expression {
        $$ = $1;
        $$.arguments = realloc($$.arguments, sizeof(ASTNode*) * ($$.count + 1));
        $$.arguments[$$.count] = $3;
        $$.count++;
    }
    ;

return_statement:
    RETURN expression {
        $$ = create_return_node($2);
    }
    ;

try_statement:
    TRY block catch_block {
        $$ = create_try_catch_node($2, $3, ((ASTNode*)$3)->data.try_catch.exception_var, NULL);
    }
    | TRY block catch_block finally_block {
        $$ = create_try_catch_node($2, $3, ((ASTNode*)$3)->data.try_catch.exception_var, $4);
    }
    ;

catch_block:
    CATCH LPAREN IDENTIFIER RPAREN block {
        // We temporarily store the exception variable name in the catch block node
        // It will be moved to the try-catch node when we create it
        $$ = create_try_catch_node($5, NULL, $3, NULL);
        free($3); // Free the identifier string
    }
    ;

finally_block:
    FINALLY block {
        $$ = $2;
    }
    ;

throw_statement:
    THROW expression {
        $$ = create_throw_node($2);
    }
    ;

array_literal:
    LBRACKET RBRACKET {
        $$ = create_array_literal_node();
    }
    | LBRACKET array_element_list RBRACKET {
        $$ = $2;
    }
    ;

array_element_list:
    expression {
        $$ = create_array_literal_node();
        add_element_to_array_literal($$, $1);
    }
    | array_element_list COMMA expression {
        $$ = $1;
        add_element_to_array_literal($$, $3);
    }
    ;

array_access:
    factor LBRACKET expression RBRACKET {
        $$ = create_array_access_node($1, $3);
    }
    ;

expression:
    term { $$ = $1; }
    | expression PLUS term {
        $$ = create_binary_op_node($1, PLUS, $3);
    }
    | expression MINUS term {
        $$ = create_binary_op_node($1, MINUS, $3);
    }
    | expression LESS_THAN term {
        $$ = create_binary_op_node($1, LESS_THAN, $3);
    }
    | expression LESS_EQUAL term {
        $$ = create_binary_op_node($1, LESS_EQUAL, $3);
    }
    | expression GREATER_THAN term {
        $$ = create_binary_op_node($1, GREATER_THAN, $3);
    }
    | expression GREATER_EQUAL term {
        $$ = create_binary_op_node($1, GREATER_EQUAL, $3);
    }
    | expression EQUAL term {
        $$ = create_binary_op_node($1, EQUAL, $3);
    }
    | expression NOT_EQUAL term {
        $$ = create_binary_op_node($1, NOT_EQUAL, $3);
    }
    | expression AND expression {
        $$ = create_binary_op_node($1, AND, $3);
    }
    | expression OR expression {
        $$ = create_binary_op_node($1, OR, $3);
    }
    | NOT expression {
        $$ = create_unary_op_node(NOT, $2);
    }
    ;

term:
    factor { $$ = $1; }
    | term MULTIPLY factor {
        $$ = create_binary_op_node($1, MULTIPLY, $3);
    }
    | term DIVIDE factor {
        $$ = create_binary_op_node($1, DIVIDE, $3);
    }
    ;

factor:
    IDENTIFIER { 
        $$ = create_identifier_node($1);
        free($1); // Free the identifier string
    }
    | INTEGER { 
        $$ = create_integer_node($1);
    }
    | FLOAT { 
        $$ = create_float_node($1);
    }
    | STRING { 
        $$ = create_string_node($1);
        free($1); // Free the string
    }
    | BOOLEAN { 
        $$ = create_boolean_node($1);
    }
    | LPAREN expression RPAREN { 
        $$ = $2;
    }
    | MINUS factor %prec UMINUS {
        $$ = create_unary_op_node(MINUS, $2);
    }
    | function_call {
        $$ = $1;
    }
    | array_literal {
        $$ = $1;
    }
    | array_access {
        $$ = $1;
    }
    ;

%%

// Print a value with newline
void print_value_ln(Value val) {
    print_value(val);
    printf("\n");
}

// AST node creation functions
ASTNode* create_integer_node(int value) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_INTEGER;
    node->data.ival = value;
    return node;
}

ASTNode* create_float_node(double value) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_FLOAT;
    node->data.fval = value;
    return node;
}

ASTNode* create_string_node(char* value) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_STRING;
    node->data.sval = strdup(value);
    return node;
}

ASTNode* create_boolean_node(int value) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_BOOLEAN;
    node->data.bval = value;
    return node;
}

ASTNode* create_identifier_node(char* name) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_IDENTIFIER;
    node->data.sval = strdup(name);
    return node;
}

ASTNode* create_binary_op_node(ASTNode* left, int op, ASTNode* right) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_BINARY_OP;
    node->data.binary_op.left = left;
    node->data.binary_op.right = right;
    node->data.binary_op.op = op;
    return node;
}

ASTNode* create_unary_op_node(int op, ASTNode* operand) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_UNARY_OP;
    node->data.unary_op.operand = operand;
    node->data.unary_op.op = op;
    return node;
}

ASTNode* create_assignment_node(char* name, ASTNode* value) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_ASSIGNMENT;
    node->data.assignment.name = strdup(name);
    node->data.assignment.value = value;
    return node;
}

ASTNode* create_declaration_node(char* name, ASTNode* initial_value) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_DECLARATION;
    node->data.declaration.name = strdup(name);
    node->data.declaration.initial_value = initial_value;
    return node;
}

ASTNode* create_if_node(ASTNode* condition, ASTNode* if_branch, ASTNode* else_branch) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_IF;
    node->data.if_stmt.condition = condition;
    node->data.if_stmt.if_branch = if_branch;
    node->data.if_stmt.else_branch = else_branch;
    return node;
}

ASTNode* create_while_node(ASTNode* condition, ASTNode* body) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_WHILE;
    node->data.while_loop.condition = condition;
    node->data.while_loop.body = body;
    return node;
}

ASTNode* create_print_node(ASTNode* expr) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_PRINT;
    node->data.print_stmt.expr = expr;
    return node;
}

ASTNode* create_block_node() {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_BLOCK;
    node->data.block.statements = malloc(sizeof(ASTNode*) * 10); // Initial capacity
    node->data.block.count = 0;
    node->data.block.capacity = 10;
    return node;
}

ASTNode* create_function_def_node(char* name, char** parameters, int param_count, ASTNode* body) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_FUNCTION_DEF;
    node->data.func_def.name = strdup(name);
    node->data.func_def.parameters = parameters;
    node->data.func_def.param_count = param_count;
    node->data.func_def.body = body;
    return node;
}

ASTNode* create_function_call_node(char* name) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_FUNCTION_CALL;
    node->data.func_call.name = strdup(name);
    node->data.func_call.arguments = malloc(sizeof(ASTNode*) * 10); // Initial capacity
    node->data.func_call.arg_count = 0;
    return node;
}

ASTNode* create_return_node(ASTNode* expr) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_RETURN;
    node->data.return_stmt.expr = expr;
    return node;
}

ASTNode* create_try_catch_node(ASTNode* try_block, ASTNode* catch_block, char* exception_var, ASTNode* finally_block) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_TRY_CATCH;
    node->data.try_catch.try_block = try_block;
    node->data.try_catch.catch_block = catch_block;
    node->data.try_catch.exception_var = exception_var ? strdup(exception_var) : NULL;
    node->data.try_catch.finally_block = finally_block;
    return node;
}

ASTNode* create_throw_node(ASTNode* expr) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_THROW;
    node->data.throw_stmt.expr = expr;
    return node;
}

ASTNode* create_array_literal_node() {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_ARRAY_LITERAL;
    node->data.array_literal.elements = malloc(sizeof(ASTNode*) * 10); // Initial capacity
    node->data.array_literal.count = 0;
    return node;
}

void add_element_to_array_literal(ASTNode* array_node, ASTNode* element) {
    if (array_node->type != NODE_ARRAY_LITERAL) {
        fprintf(stderr, "Error: Not an array literal node\n");
        return;
    }
    
    array_node->data.array_literal.elements[array_node->data.array_literal.count++] = element;
}

ASTNode* create_array_access_node(ASTNode* array, ASTNode* index) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_ARRAY_ACCESS;
    node->data.array_access.array = array;
    node->data.array_access.index = index;
    return node;
}

void add_statement_to_block(ASTNode* block, ASTNode* statement) {
    if (block->type != NODE_BLOCK) {
        fprintf(stderr, "Error: Not a block node\n");
        return;
    }
    
    // Resize if needed
    if (block->data.block.count >= block->data.block.capacity) {
        block->data.block.capacity *= 2;
        block->data.block.statements = realloc(
            block->data.block.statements, 
            sizeof(ASTNode*) * block->data.block.capacity
        );
    }
    
    block->data.block.statements[block->data.block.count++] = statement;
}

void add_argument_to_function_call(ASTNode* func_call, ASTNode* arg) {
    if (func_call->type != NODE_FUNCTION_CALL) {
        fprintf(stderr, "Error: Not a function call node\n");
        return;
    }
    
    func_call->data.func_call.arguments[func_call->data.func_call.arg_count++] = arg;
}

// Memory management
void free_ast(ASTNode* node) {
    if (!node) return;
    
    switch (node->type) {
        case NODE_STRING:
        case NODE_IDENTIFIER:
            free(node->data.sval);
            break;
            
        case NODE_BINARY_OP:
            free_ast(node->data.binary_op.left);
            free_ast(node->data.binary_op.right);
            break;
            
        case NODE_UNARY_OP:
            free_ast(node->data.unary_op.operand);
            break;
            
        case NODE_ASSIGNMENT:
            free(node->data.assignment.name);
            free_ast(node->data.assignment.value);
            break;
            
        case NODE_DECLARATION:
            free(node->data.declaration.name);
            free_ast(node->data.declaration.initial_value);
            break;
            
        case NODE_IF:
            free_ast(node->data.if_stmt.condition);
            free_ast(node->data.if_stmt.if_branch);
            if (node->data.if_stmt.else_branch) {
                free_ast(node->data.if_stmt.else_branch);
            }
            break;
            
        case NODE_WHILE:
            free_ast(node->data.while_loop.condition);
            free_ast(node->data.while_loop.body);
            break;
            
        case NODE_PRINT:
            free_ast(node->data.print_stmt.expr);
            break;
            
        case NODE_BLOCK:
            for (int i = 0; i < node->data.block.count; i++) {
                free_ast(node->data.block.statements[i]);
            }
            free(node->data.block.statements);
            break;
            
        case NODE_FUNCTION_DEF:
            free(node->data.func_def.name);
            for (int i = 0; i < node->data.func_def.param_count; i++) {
                free(node->data.func_def.parameters[i]);
            }
            if (node->data.func_def.parameters) free(node->data.func_def.parameters);
            free_ast(node->data.func_def.body);
            break;
            
        case NODE_FUNCTION_CALL:
            free(node->data.func_call.name);
            for (int i = 0; i < node->data.func_call.arg_count; i++) {
                free_ast(node->data.func_call.arguments[i]);
            }
            free(node->data.func_call.arguments);
            break;
            
        case NODE_RETURN:
            free_ast(node->data.return_stmt.expr);
            break;
        
        case NODE_TRY_CATCH:
            free_ast(node->data.try_catch.try_block);
            free_ast(node->data.try_catch.catch_block);
            if (node->data.try_catch.finally_block) {
                free_ast(node->data.try_catch.finally_block);
            }
            if (node->data.try_catch.exception_var) {
                free(node->data.try_catch.exception_var);
            }
            break;
            
        case NODE_THROW:
            free_ast(node->data.throw_stmt.expr);
            break;
            
        case NODE_ARRAY_LITERAL:
            for (int i = 0; i < node->data.array_literal.count; i++) {
                free_ast(node->data.array_literal.elements[i]);
            }
            free(node->data.array_literal.elements);
            break;
            
        case NODE_ARRAY_ACCESS:
            free_ast(node->data.array_access.array);
            free_ast(node->data.array_access.index);
            break;
            
        default:
            break; // No memory to free for other types (INTEGER, FLOAT, BOOLEAN)
    }
    
    free(node);
}

int value_to_boolean(Value val) {
    switch (val.type) {
        case VAL_INTEGER:
            return val.data.ival != 0;
        case VAL_FLOAT:
            return val.data.fval != 0.0;
        case VAL_STRING:
            return val.data.sval != NULL && strlen(val.data.sval) > 0;
        case VAL_BOOLEAN:
            return val.data.bval;
        case VAL_FUNCTION:
            return 1;  // Functions are always "truthy"
        case VAL_EXCEPTION:
            return 1;  // Exceptions are "truthy"
        case VAL_ARRAY:
            return val.data.array.length > 0;  // Arrays are "truthy" if not empty
    }
    return 0;
}

// Symbol table functions
SymbolTable* create_symbol_table() {
    SymbolTable* table = malloc(sizeof(SymbolTable));
    table->symbols = malloc(sizeof(Symbol) * 10); // Initial capacity
    table->count = 0;
    table->capacity = 10;
    table->parent = NULL;
    return table;
}

void free_symbol_table(SymbolTable* table) {
    if (!table) return;
    
    for (int i = 0; i < table->count; i++) {
        free(table->symbols[i].name);
        free_value(table->symbols[i].value);
    }
    
    free(table->symbols);
    free(table);
}

// Free a value (especially strings)
void free_value(Value val) {
    if (val.type == VAL_STRING && val.data.sval) {
        free(val.data.sval);
    } else if (val.type == VAL_FUNCTION && val.data.func.name) {
        free(val.data.func.name);
    } else if (val.type == VAL_EXCEPTION) {
        if (val.data.exception.message) {
            free(val.data.exception.message);
        }
        if (val.data.exception.type) {
            free(val.data.exception.type);
        }
    } else if (val.type == VAL_ARRAY) {
        // Free each element in the array
        for (int i = 0; i < val.data.array.length; i++) {
            free_value(val.data.array.elements[i]);
        }
        // Free the array itself
        free(val.data.array.elements);
    }
}

// Deep copy a value (for assignment, etc.)
Value copy_value(Value val) {
    Value copy = val;
    
    if (val.type == VAL_STRING && val.data.sval) {
        copy.data.sval = strdup(val.data.sval);
    } else if (val.type == VAL_FUNCTION && val.data.func.name) {
        copy.data.func.name = strdup(val.data.func.name);
        copy.data.func.func_def = val.data.func.func_def;
    } else if (val.type == VAL_EXCEPTION) {
        if (val.data.exception.message) {
            copy.data.exception.message = strdup(val.data.exception.message);
        }
        if (val.data.exception.type) {
            copy.data.exception.type = strdup(val.data.exception.type);
        }
    } else if (val.type == VAL_ARRAY) {
        // Copy array elements
        copy.data.array.elements = malloc(sizeof(Value) * val.data.array.capacity);
        copy.data.array.length = val.data.array.length;
        copy.data.array.capacity = val.data.array.capacity;
        
        // Deep copy each element
        for (int i = 0; i < val.data.array.length; i++) {
            copy.data.array.elements[i] = copy_value(val.data.array.elements[i]);
        }
    }
    
    return copy;
}

// Create an empty array with initial capacity
Value create_array(int capacity) {
    Value array;
    array.type = VAL_ARRAY;
    array.data.array.elements = malloc(sizeof(Value) * capacity);
    array.data.array.length = 0;
    array.data.array.capacity = capacity;
    return array;
}

// Get an element from an array
Value get_array_element(Value array, int index) {
    if (array.type != VAL_ARRAY) {
        fprintf(stderr, "Error: Not an array\n");
        Value error;
        error.type = VAL_EXCEPTION;
        error.data.exception.message = strdup("Not an array");
        error.data.exception.type = strdup("TypeError");
        return error;
    }
    
    if (index < 0 || index >= array.data.array.length) {
        fprintf(stderr, "Error: Array index out of bounds\n");
        Value error;
        error.type = VAL_EXCEPTION;
        error.data.exception.message = strdup("Array index out of bounds");
        error.data.exception.type = strdup("IndexError");
        return error;
    }
    
    return copy_value(array.data.array.elements[index]);
}

// Set an element in an array
int set_array_element(Value* array, int index, Value value) {
    if (array->type != VAL_ARRAY) {
        fprintf(stderr, "Error: Not an array\n");
        return 0;
    }
    
    // Check if index is out of bounds
    // Allow setting at array.length (appending), but not beyond
    if (index < 0 || index > array->data.array.length) {
        fprintf(stderr, "Error: Array index out of bounds\n");
        return 0;
    }
    
    // Resize array if needed
    if (index >= array->data.array.capacity) {
        int new_capacity = array->data.array.capacity * 2;
        if (index >= new_capacity) {
            new_capacity = index + 1;
        }
        
        array->data.array.elements = realloc(array->data.array.elements, sizeof(Value) * new_capacity);
        array->data.array.capacity = new_capacity;
    }
    
    // If we're appending to the end
    if (index == array->data.array.length) {
        array->data.array.length++;
    } else {
        // Free old value if replacing an existing element
        free_value(array->data.array.elements[index]);
    }
    
    // Set the new value
    array->data.array.elements[index] = copy_value(value);
    
    return 1;
}

// Create an exception value
Value create_exception(const char* type, const char* message) {
    Value exception;
    exception.type = VAL_EXCEPTION;
    exception.data.exception.type = strdup(type);
    exception.data.exception.message = strdup(message);
    return exception;
}

int add_symbol(SymbolTable* table, char* name, Value value) {
    if (table->count >= table->capacity) {
        table->capacity *= 2;
        table->symbols = realloc(table->symbols, sizeof(Symbol) * table->capacity);
    }
    
    // Look for existing symbol in this scope
    for (int i = 0; i < table->count; i++) {
        if (strcmp(table->symbols[i].name, name) == 0) {
            // Free the old value
            free_value(table->symbols[i].value);
            
            // Update with new value
            table->symbols[i].value = copy_value(value);
            return i;
        }
    }
    
    // Add new symbol
    table->symbols[table->count].name = strdup(name);
    table->symbols[table->count].value = copy_value(value);
    
    return table->count++;
}

int find_symbol_in_table(SymbolTable* table, char* name) {
    for (int i = 0; i < table->count; i++) {
        if (strcmp(table->symbols[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

int find_symbol(char* name) {
    // First look in current scope
    SymbolTable* table = current_symbols;
    
    while (table != NULL) {
        int index = find_symbol_in_table(table, name);
        if (index != -1) {
            return index;
        }
        table = table->parent;
    }
    
    return -1;
}

Value get_symbol_value(SymbolTable* table, char* name) {
    // Search symbol in this scope and parent scopes
    SymbolTable* current = table;
    
    while (current != NULL) {
        int index = find_symbol_in_table(current, name);
        if (index != -1) {
            return copy_value(current->symbols[index].value);
        }
        current = current->parent;
    }
    
    // Not found - return default value (0)
    Value empty;
    empty.type = VAL_INTEGER;
    empty.data.ival = 0;
    fprintf(stderr, "Error: Undefined variable '%s'\n", name);
    return empty;
}

void push_scope() {
    SymbolTable* new_table = create_symbol_table();
    new_table->parent = current_symbols;
    current_symbols = new_table;
}

void pop_scope() {
    if (current_symbols == NULL) return;
    
    SymbolTable* old_table = current_symbols;
    current_symbols = current_symbols->parent;
    
    free_symbol_table(old_table);
}

// Helper functions for variable management
void declare_variable(char* name, Value value) {
    add_symbol(current_symbols, name, value);
}

void set_variable(char* name, Value value) {
    // Look for the variable in all scopes
    SymbolTable* table = current_symbols;
    
    while (table != NULL) {
        int index = find_symbol_in_table(table, name);
        if (index != -1) {
            // Free old value
            free_value(table->symbols[index].value);
            
            // Set new value
            table->symbols[index].value = copy_value(value);
            return;
        }
        table = table->parent;
    }
    
    fprintf(stderr, "Error: Undefined variable '%s'\n", name);
}

Value get_variable(char* name) {
    Value val = get_symbol_value(current_symbols, name);
    
    // Check if symbol was found (assuming a default value of 0)
    if (val.type == VAL_INTEGER && val.data.ival == 0) {
        // Check if it was actually found or just default
        if (find_symbol(name) == -1) {
            // Symbol not found, throw exception
            fprintf(stderr, "Error: Undefined variable '%s'\n", name);
            Value exception = create_exception("ReferenceError", "Undefined variable");
            return exception;
        }
    }
    
    return val;
}

void print_value(Value val) {
    switch (val.type) {
        case VAL_INTEGER:
            printf("%d", val.data.ival);
            break;
        case VAL_FLOAT:
            printf("%g", val.data.fval);
            break;
        case VAL_STRING:
            printf("%s", val.data.sval);
            break;
        case VAL_BOOLEAN:
            printf("%s", val.data.bval ? "true" : "false");
            break;
        case VAL_FUNCTION:
            printf("function %s", val.data.func.name);
            break;
        case VAL_EXCEPTION:
            printf("Exception %s: %s", 
                val.data.exception.type ? val.data.exception.type : "Error",
                val.data.exception.message ? val.data.exception.message : "Unknown error");
            break;
        case VAL_ARRAY:
            printf("[");
            for (int i = 0; i < val.data.array.length; i++) {
                print_value(val.data.array.elements[i]);
                if (i < val.data.array.length - 1) {
                    printf(", ");
                }
            }
            printf("]");
            break;
    }
}

// Evaluate array literal
Value evaluate_array_literal(ASTNode* expr) {
    Value result = create_array(expr->data.array_literal.count);
    
    // Evaluate each element and add to the array
    for (int i = 0; i < expr->data.array_literal.count; i++) {
        Value element = evaluate_expression(expr->data.array_literal.elements[i]);
        
        // Check if element evaluation resulted in an exception
        if (element.type == VAL_EXCEPTION) {
            // Clean up the array we were building
            free_value(result);
            return element;
        }
        
        // Add element to array
        set_array_element(&result, i, element);
        
        // Free the temporary element value
        free_value(element);
    }
    
    return result;
}

// Evaluate array access
Value evaluate_array_access(ASTNode* expr) {
    // Evaluate the array expression
    Value array = evaluate_expression(expr->data.array_access.array);
    
    // Check if array evaluation resulted in an exception
    if (array.type == VAL_EXCEPTION) {
        return array;
    }
    
    // Check if it's an array
    if (array.type != VAL_ARRAY) {
        free_value(array);
        return create_exception("TypeError", "Not an array");
    }
    
    // Evaluate the index expression
    Value index = evaluate_expression(expr->data.array_access.index);
    
    // Check if index evaluation resulted in an exception
    if (index.type == VAL_EXCEPTION) {
        free_value(array);
        return index;
    }
    
    // Check if index is a number
    if (index.type != VAL_INTEGER) {
        free_value(array);
        free_value(index);
        return create_exception("TypeError", "Array index must be an integer");
    }
    
    // Get the array element
    Value result = get_array_element(array, index.data.ival);
    
    // Free temporary values
    free_value(array);
    
    return result;
}

// Runtime evaluation
Value evaluate_expression(ASTNode* expr) {
    Value result;
    
    switch (expr->type) {
        case NODE_INTEGER:
            result.type = VAL_INTEGER;
            result.data.ival = expr->data.ival;
            break;
            
        case NODE_FLOAT:
            result.type = VAL_FLOAT;
            result.data.fval = expr->data.fval;
            break;
            
        case NODE_STRING:
            result.type = VAL_STRING;
            result.data.sval = strdup(expr->data.sval);
            break;
            
        case NODE_BOOLEAN:
            result.type = VAL_BOOLEAN;
            result.data.bval = expr->data.bval;
            break;
            
        case NODE_IDENTIFIER: {
            result = get_variable(expr->data.sval);
            break;
        }
        
        case NODE_ARRAY_LITERAL:
            result = evaluate_array_literal(expr);
            break;
            
        case NODE_ARRAY_ACCESS:
            result = evaluate_array_access(expr);
            break;
        
        case NODE_BINARY_OP: {
            // Special case for array assignment
            if (expr->data.binary_op.op == ASSIGN && expr->data.binary_op.left->type == NODE_ARRAY_ACCESS) {
                // Get the array and index
                ASTNode* array_access = expr->data.binary_op.left;
                ASTNode* array_expr = array_access->data.array_access.array;
                ASTNode* index_expr = array_access->data.array_access.index;
                
                // Evaluate the array
                Value array = evaluate_expression(array_expr);
                
                // Check if array evaluation resulted in an exception
                if (array.type == VAL_EXCEPTION) {
                    return array;
                }
                
                // Check if it's an array
                if (array.type != VAL_ARRAY) {
                    free_value(array);
                    return create_exception("TypeError", "Cannot index non-array value");
                }
                
                // Evaluate the index
                Value index = evaluate_expression(index_expr);
                
                // Check if index evaluation resulted in an exception
                if (index.type == VAL_EXCEPTION) {
                    free_value(array);
                    return index;
                }
                
                // Check if index is an integer
                if (index.type != VAL_INTEGER) {
                    free_value(array);
                    free_value(index);
                    return create_exception("TypeError", "Array index must be an integer");
                }
                
                // Evaluate the right side (value to assign)
                Value value = evaluate_expression(expr->data.binary_op.right);
                
                // Check if value evaluation resulted in an exception
                if (value.type == VAL_EXCEPTION) {
                    free_value(array);
                    free_value(index);
                    return value;
                }
                
                // Get variable name if the array is an identifier
                if (array_expr->type == NODE_IDENTIFIER) {
                    char* var_name = array_expr->data.sval;
                    
                    // Get the current array value
                    Value current_array = get_variable(var_name);
                    
                    // Set the element in the array
                    int success = set_array_element(&current_array, index.data.ival, value);
                    if (!success) {
                        // Free temporary arrays
                        free_value(current_array);
                        free_value(array);
                        free_value(index);
                        free_value(value);
                        
                        // Return an exception
                        return create_exception("IndexError", "Array index out of bounds");
                    }
                    // Update the variable with the modified array
                    set_variable(var_name, current_array);
                    
                    // Free temporary array
                    free_value(current_array);
                    
                    // Return the assigned value
                    result = copy_value(value);
                } else {
                    // Cannot assign to a non-variable array
                    free_value(array);
                    free_value(index);
                    free_value(value);
                    return create_exception("TypeError", "Cannot assign to a non-variable array");
                }
                
                // Free temporary values
                free_value(array);
                free_value(index);
                free_value(value);
                
                break;
            }
            
            Value left = evaluate_expression(expr->data.binary_op.left);
            Value right = evaluate_expression(expr->data.binary_op.right);
            
            // Handle string concatenation
            if (expr->data.binary_op.op == PLUS && 
                (left.type == VAL_STRING || right.type == VAL_STRING)) {
                
                char left_str[256] = "";
                char right_str[256] = "";
                
                // Convert left to string
                if (left.type == VAL_STRING) {
                    strncpy(left_str, left.data.sval, 255);
                } else if (left.type == VAL_INTEGER) {
                    sprintf(left_str, "%d", left.data.ival);
                } else if (left.type == VAL_FLOAT) {
                    sprintf(left_str, "%g", left.data.fval);
                } else if (left.type == VAL_BOOLEAN) {
                    sprintf(left_str, "%s", left.data.bval ? "true" : "false");
                } else if (left.type == VAL_FUNCTION) {
                    sprintf(left_str, "function %s", left.data.func.name);
                } else if (left.type == VAL_EXCEPTION) {
                    // Convert exception to string
                    sprintf(left_str, "%s", left.data.exception.message ? 
                            left.data.exception.message : "Unknown error");
                } else if (left.type == VAL_ARRAY) {
                    // Convert array to string representation
                    char* temp = malloc(1024); // Temporary buffer
                    temp[0] = '\0';
                    strcat(temp, "[");
                    
                    for (int i = 0; i < left.data.array.length; i++) {
                        char elem_str[64];
                        
                        // Convert element to string
                        if (left.data.array.elements[i].type == VAL_INTEGER) {
                            sprintf(elem_str, "%d", left.data.array.elements[i].data.ival);
                        } else if (left.data.array.elements[i].type == VAL_FLOAT) {
                            sprintf(elem_str, "%g", left.data.array.elements[i].data.fval);
                        } else if (left.data.array.elements[i].type == VAL_STRING) {
                            sprintf(elem_str, "\"%s\"", left.data.array.elements[i].data.sval);
                        } else if (left.data.array.elements[i].type == VAL_BOOLEAN) {
                            sprintf(elem_str, "%s", left.data.array.elements[i].data.bval ? "true" : "false");
                        } else {
                            strcpy(elem_str, "...");
                        }
                        
                        // Add to buffer
                        strcat(temp, elem_str);
                        
                        // Add separator if not last element
                        if (i < left.data.array.length - 1) {
                            strcat(temp, ", ");
                        }
                    }
                    
                    strcat(temp, "]");
                    strncpy(left_str, temp, 255);
                    free(temp);
                }
                
                // Convert right to string
                if (right.type == VAL_STRING) {
                    strncpy(right_str, right.data.sval, 255);
                } else if (right.type == VAL_INTEGER) {
                    sprintf(right_str, "%d", right.data.ival);
                } else if (right.type == VAL_FLOAT) {
                    sprintf(right_str, "%g", right.data.fval);
                } else if (right.type == VAL_BOOLEAN) {
                    sprintf(right_str, "%s", right.data.bval ? "true" : "false");
                } else if (right.type == VAL_FUNCTION) {
                    sprintf(right_str, "function %s", right.data.func.name);
                } else if (right.type == VAL_EXCEPTION) {
                    // Convert exception to string
                    sprintf(right_str, "%s", right.data.exception.message ? 
                            right.data.exception.message : "Unknown error");
                } else if (right.type == VAL_ARRAY) {
                    // Convert array to string representation
                    char* temp = malloc(1024); // Temporary buffer
                    temp[0] = '\0';
                    strcat(temp, "[");
                    
                    for (int i = 0; i < right.data.array.length; i++) {
                        char elem_str[64];
                        
                        // Convert element to string
                        if (right.data.array.elements[i].type == VAL_INTEGER) {
                            sprintf(elem_str, "%d", right.data.array.elements[i].data.ival);
                        } else if (right.data.array.elements[i].type == VAL_FLOAT) {
                            sprintf(elem_str, "%g", right.data.array.elements[i].data.fval);
                        } else if (right.data.array.elements[i].type == VAL_STRING) {
                            sprintf(elem_str, "\"%s\"", right.data.array.elements[i].data.sval);
                        } else if (right.data.array.elements[i].type == VAL_BOOLEAN) {
                            sprintf(elem_str, "%s", right.data.array.elements[i].data.bval ? "true" : "false");
                        } else {
                            strcpy(elem_str, "...");
                        }
                        
                        // Add to buffer
                        strcat(temp, elem_str);
                        
                        // Add separator if not last element
                        if (i < right.data.array.length - 1) {
                            strcat(temp, ", ");
                        }
                    }
                    
                    strcat(temp, "]");
                    strncpy(right_str, temp, 255);
                    free(temp);
                }
                
                // Allocate and concatenate
                result.type = VAL_STRING;
                result.data.sval = malloc(strlen(left_str) + strlen(right_str) + 1);
                strcpy(result.data.sval, left_str);
                strcat(result.data.sval, right_str);
                
                // Free temporary strings
                if (left.type == VAL_STRING && left.data.sval) {
                    free(left.data.sval);
                }
                if (right.type == VAL_STRING && right.data.sval) {
                    free(right.data.sval);
                }
                
                break;
            }
            
            // Check if either operand is a float
            int use_float = (left.type == VAL_FLOAT || right.type == VAL_FLOAT);
            
            double left_val, right_val;
            
            // Convert to numeric values 
            if (left.type == VAL_INTEGER) {
                left_val = (double)left.data.ival;
            } else if (left.type == VAL_FLOAT) {
                left_val = left.data.fval;
            } else if (left.type == VAL_BOOLEAN) {
                left_val = (double)left.data.bval;
            } else {
                left_val = 0.0;
            }
            
            if (right.type == VAL_INTEGER) {
                right_val = (double)right.data.ival;
            } else if (right.type == VAL_FLOAT) {
                right_val = right.data.fval;
            } else if (right.type == VAL_BOOLEAN) {
                right_val = (double)right.data.bval;
            } else {
                right_val = 0.0;
            }
            
            // Free any string values
            if (left.type == VAL_STRING && left.data.sval) {
                free(left.data.sval);
            }
            if (right.type == VAL_STRING && right.data.sval) {
                free(right.data.sval);
            }
            
            // Set result type based on operands
            if (use_float) {
                result.type = VAL_FLOAT;
            } else {
                result.type = VAL_INTEGER;
            }
            
            switch (expr->data.binary_op.op) {
                case PLUS:
                    if (use_float) {
                        result.data.fval = left_val + right_val;
                    } else {
                        result.data.ival = (int)left_val + (int)right_val;
                    }
                    break;
                case MINUS:
                    if (use_float) {
                        result.data.fval = left_val - right_val;
                    } else {
                        result.data.ival = (int)left_val - (int)right_val;
                    }
                    break;
                case MULTIPLY:
                    if (use_float) {
                        result.data.fval = left_val * right_val;
                    } else {
                        result.data.ival = (int)left_val * (int)right_val;
                    }
                    break;
                case DIVIDE:
                    if (right_val == 0.0) {
                        // Create and return an exception instead of 0
                        result.type = VAL_EXCEPTION;
                        result.data.exception.type = strdup("DivisionByZeroError");
                        result.data.exception.message = strdup("Division by zero");
                    } else {
                        if (use_float) {
                            result.data.fval = left_val / right_val;
                        } else {
                            result.data.ival = (int)left_val / (int)right_val;
                        }
                    }
                    break;
                case LESS_THAN:
                    result.type = VAL_BOOLEAN;
                    result.data.bval = left_val < right_val;
                    break;
                case LESS_EQUAL:
                    result.type = VAL_BOOLEAN;
                    result.data.bval = left_val <= right_val;
                    break;
                case GREATER_THAN:
                    result.type = VAL_BOOLEAN;
                    result.data.bval = left_val > right_val;
                    break;
                case GREATER_EQUAL:
                    result.type = VAL_BOOLEAN;
                    result.data.bval = left_val >= right_val;
                    break;
                case EQUAL:
                    result.type = VAL_BOOLEAN;
                    result.data.bval = left_val == right_val;
                    break;
                case NOT_EQUAL:
                    result.type = VAL_BOOLEAN;
                    result.data.bval = left_val != right_val;
                    break;
                case AND:
                    result.type = VAL_BOOLEAN;
                    result.data.bval = value_to_boolean(left) && value_to_boolean(right);
                    break;
                case OR:
                    result.type = VAL_BOOLEAN;
                    result.data.bval = value_to_boolean(left) || value_to_boolean(right);
                    break;
                default:
                    fprintf(stderr, "Error: Unknown binary operator\n");
                    if (use_float) {
                        result.data.fval = 0.0;
                    } else {
                        result.data.ival = 0;
                    }
            }
            break;
        }
        
        case NODE_UNARY_OP: {
            Value operand = evaluate_expression(expr->data.unary_op.operand);
            
            // Handle float vs integer for unary operations
            if (operand.type == VAL_FLOAT) {
                result.type = VAL_FLOAT;
                
                switch (expr->data.unary_op.op) {
                    case MINUS:
                        result.data.fval = -operand.data.fval;
                        break;
                    case NOT:
                        result.type = VAL_BOOLEAN;
                        result.data.bval = !value_to_boolean(operand);
                        break;
                    default:
                        fprintf(stderr, "Error: Unknown unary operator\n");
                        result.data.fval = 0.0;
                }
            } else {
                // Convert to integer/boolean for non-float operands
                int val = (operand.type == VAL_INTEGER) ? operand.data.ival : 
                         (operand.type == VAL_BOOLEAN) ? operand.data.bval : 0;
                
                switch (expr->data.unary_op.op) {
                    case MINUS:
                        result.type = VAL_INTEGER;
                        result.data.ival = -val;
                        break;
                    case NOT:
                        result.type = VAL_BOOLEAN;
                        result.data.bval = !value_to_boolean(operand);
                        break;
                    default:
                        fprintf(stderr, "Error: Unknown unary operator\n");
                        result.type = VAL_INTEGER;
                        result.data.ival = 0;
                }
            }
            
            // Free string if needed
            if (operand.type == VAL_STRING && operand.data.sval) {
                free(operand.data.sval);
            }
            
            break;
        }
        
        case NODE_FUNCTION_CALL: {
            // Find the function definition
            Value func_val = get_variable(expr->data.func_call.name);
            
            if (func_val.type != VAL_FUNCTION) {
                fprintf(stderr, "Error: '%s' is not a function\n", expr->data.func_call.name);
                // Create an exception instead of returning 0
                result = create_exception("TypeError", "Not a function");
                break;
            }
            
            // Call the function
            ASTNode* func_def = func_val.data.func.func_def;
            
            // Evaluate all arguments
            ASTNode** evaluated_args = expr->data.func_call.arguments;
            int arg_count = expr->data.func_call.arg_count;
            
            // Execute the function and get the return value
            ReturnValue ret = call_function(func_def, evaluated_args, arg_count);
            
            // If the function threw an exception, propagate it
            if (ret.has_exception) {
                result = ret.return_value;
            }
            // If the function returned a value, use it
            else if (ret.has_return) {
                result = ret.return_value;
            } else {
                // Default return value
                result.type = VAL_INTEGER;
                result.data.ival = 0;
            }
            
            break;
        }
        
        default:
            fprintf(stderr, "Error: Invalid expression type\n");
            result.type = VAL_INTEGER;
            result.data.ival = 0;
    }
    
    return result;
}

// Execute a function
ReturnValue call_function(ASTNode* func_def, ASTNode** arguments, int arg_count) {
    ReturnValue ret = {0}; // Initialize with no return value or exception
    
    if (func_def->type != NODE_FUNCTION_DEF) {
        fprintf(stderr, "Error: Not a function definition\n");
        ret.has_exception = 1;
        ret.return_value = create_exception("TypeError", "Not a function definition");
        return ret;
    }
    
    // Create a new scope
    push_scope();
    
    // Evaluate arguments and bind to parameters
    for (int i = 0; i < func_def->data.func_def.param_count && i < arg_count; i++) {
        Value arg = evaluate_expression(arguments[i]);
        
        // Check if argument evaluation threw an exception
        if (arg.type == VAL_EXCEPTION) {
            // Clean up the scope and propagate the exception
            pop_scope();
            ret.has_exception = 1;
            ret.return_value = arg;
            return ret;
        }
        
        declare_variable(func_def->data.func_def.parameters[i], arg);
        
        // Free string values after copying
        if (arg.type == VAL_STRING && arg.data.sval) {
            free(arg.data.sval);
        }
    }
    
    // Execute the function body
    ret = interpret_block(func_def->data.func_def.body, 0); // Don't create a new scope
    
    // Pop the function scope
    pop_scope();
    
    return ret;
}

// Execute a block of statements (with optional new scope)
ReturnValue interpret_block(ASTNode* block, int new_scope) {
    ReturnValue ret = {0}; // Initialize with no return
    
    if (block->type != NODE_BLOCK) {
        fprintf(stderr, "Error: Not a block node\n");
        ret.has_exception = 1;
        ret.return_value = create_exception("TypeError", "Not a block node");
        return ret;
    }
    
    // Create a new scope if requested
    if (new_scope) {
        push_scope();
    }
    
    // Execute each statement in the block
    for (int i = 0; i < block->data.block.count; i++) {
        ret = interpret(block->data.block.statements[i]);
        
        // If a return statement was executed or an exception was thrown, stop
        if (ret.has_return || ret.has_exception) {
            break;
        }
    }
    
    // Pop the scope if we created one
    if (new_scope) {
        pop_scope();
    }
    
    return ret;
}

// Execute a statement
ReturnValue interpret(ASTNode* node) {
    ReturnValue ret = {0}; // Initialize with no return or exception
    
    if (!node) return ret;
    
    switch (node->type) {
        case NODE_BLOCK:
            ret = interpret_block(node, 1); // Create a new scope
            break;
            
        case NODE_DECLARATION: {
            Value value = evaluate_expression(node->data.declaration.initial_value);
            
            // Check if evaluation resulted in an exception
            if (value.type == VAL_EXCEPTION) {
                ret.has_exception = 1;
                ret.return_value = value;
                return ret;
            }
            
            declare_variable(node->data.declaration.name, value);
            
            // Free string if needed (after copying)
            if (value.type == VAL_STRING && value.data.sval) {
                free(value.data.sval);
            }
            break;
        }
        
        case NODE_ASSIGNMENT: {
            Value value = evaluate_expression(node->data.assignment.value);
            
            // Check if evaluation resulted in an exception
            if (value.type == VAL_EXCEPTION) {
                ret.has_exception = 1;
                ret.return_value = value;
                return ret;
            }
            
            set_variable(node->data.assignment.name, value);
            
            // Free string if needed (after copying)
            if (value.type == VAL_STRING && value.data.sval) {
                free(value.data.sval);
            }
            break;
        }
        
        case NODE_IF: {
            Value condition = evaluate_expression(node->data.if_stmt.condition);
            
            // Check if evaluation resulted in an exception
            if (condition.type == VAL_EXCEPTION) {
                ret.has_exception = 1;
                ret.return_value = condition;
                return ret;
            }
            
            if (value_to_boolean(condition)) {
                ret = interpret(node->data.if_stmt.if_branch);
            } else if (node->data.if_stmt.else_branch) {
                ret = interpret(node->data.if_stmt.else_branch);
            }
            
            // Free string if needed
            if (condition.type == VAL_STRING && condition.data.sval) {
                free(condition.data.sval);
            }
            break;
        }
        
        case NODE_WHILE: {
            Value condition = evaluate_expression(node->data.while_loop.condition);
            
            // Check if evaluation resulted in an exception
            if (condition.type == VAL_EXCEPTION) {
                ret.has_exception = 1;
                ret.return_value = condition;
                return ret;
            }
            
            while (value_to_boolean(condition) && !ret.has_return && !ret.has_exception) {
                // Free previous condition value if it's a string
                if (condition.type == VAL_STRING && condition.data.sval) {
                    free(condition.data.sval);
                }
                
                ret = interpret(node->data.while_loop.body);
                
                // If a return or exception was encountered, break out
                if (ret.has_return || ret.has_exception) {
                    break;
                }
                
                // Re-evaluate condition
                condition = evaluate_expression(node->data.while_loop.condition);
                
                // Check if re-evaluation resulted in an exception
                if (condition.type == VAL_EXCEPTION) {
                    ret.has_exception = 1;
                    ret.return_value = condition;
                    return ret;
                }
            }
            
            // Free final condition value if it's a string
            if (condition.type == VAL_STRING && condition.data.sval) {
                free(condition.data.sval);
            }
            break;
        }
        
        case NODE_PRINT: {
            Value value = evaluate_expression(node->data.print_stmt.expr);
            
            // Check if evaluation resulted in an exception
            if (value.type == VAL_EXCEPTION) {
                ret.has_exception = 1;
                ret.return_value = value;
                return ret;
            }
            
            print_value_ln(value);
            
            // Free string if needed
            if (value.type == VAL_STRING && value.data.sval) {
                free(value.data.sval);
            }
            break;
        }
        
        case NODE_FUNCTION_DEF: {
            // Create a function value
            Value func_val;
            func_val.type = VAL_FUNCTION;
            func_val.data.func.func_def = node;
            func_val.data.func.name = strdup(node->data.func_def.name);
            
            // Add to symbol table
            declare_variable(node->data.func_def.name, func_val);
            
            // Free the temporary function value (it was copied in declare_variable)
            free(func_val.data.func.name);
            break;
        }
        
        case NODE_FUNCTION_CALL: {
            // Evaluate the function call (result is discarded for standalone calls)
            Value result = evaluate_expression(node);
            
            // Check if call resulted in an exception
            if (result.type == VAL_EXCEPTION) {
                ret.has_exception = 1;
                ret.return_value = result;
                return ret;
            }
            
            // Free value if needed
            if (result.type == VAL_STRING && result.data.sval) {
                free(result.data.sval);
            }
            break;
        }
        
        case NODE_RETURN: {
            // Evaluate the return expression
            Value return_val = evaluate_expression(node->data.return_stmt.expr);
            
            // Check if evaluation resulted in an exception
            if (return_val.type == VAL_EXCEPTION) {
                ret.has_exception = 1;
                ret.return_value = return_val;
                return ret;
            }
            
            // Set the return flag and value
            ret.has_return = 1;
            ret.return_value = return_val; // No need to free, it will be returned
            break;
        }
        
        case NODE_TRY_CATCH: {
            // Execute the try block
            ReturnValue try_result = interpret(node->data.try_catch.try_block);
            
            // If an exception occurred in the try block, handle it in the catch block
            if (try_result.has_exception) {
                // First, save the exception value for the catch block
                Value exception = try_result.return_value;
                
                // Create a new scope for the catch block
                push_scope();
                
                // Bind the exception to the catch variable name
                declare_variable(node->data.try_catch.exception_var, exception);
                
                // Execute the catch block
                ReturnValue catch_result = interpret(node->data.try_catch.catch_block);
                
                // Pop the catch scope
                pop_scope();
                
                // Use the result from the catch block (either normal, return, or new exception)
                ret = catch_result;
            } else {
                // No exception, use the try block result
                ret = try_result;
            }
            
            // Always execute the finally block if there is one
            if (node->data.try_catch.finally_block) {
                // Save the current return or exception status
                int had_return = ret.has_return;
                int had_exception = ret.has_exception;
                Value old_value = ret.return_value;
                
                // Execute the finally block
                ReturnValue finally_result = interpret(node->data.try_catch.finally_block);
                
                // If the finally block has a return or exception, it overrides the previous one
                if (finally_result.has_return || finally_result.has_exception) {
                    // Free the old return value if it was a string or exception
                    if (had_return || had_exception) {
                        free_value(old_value);
                    }
                    
                    // Use the finally result
                    ret = finally_result;
                } else if (had_return || had_exception) {
                    // Restore the original return or exception
                    ret.has_return = had_return;
                    ret.has_exception = had_exception;
                    ret.return_value = old_value;
                }
            }
            
            break;
        }
        
        case NODE_THROW: {
            // Evaluate the exception expression
            Value expr_value = evaluate_expression(node->data.throw_stmt.expr);
            
            // If the expression is already an exception, use it directly
            if (expr_value.type == VAL_EXCEPTION) {
                ret.has_exception = 1;
                ret.return_value = expr_value;
            } else {
                // Convert the value to a string for the exception message
                char message[256] = "";
                char type[64] = "Exception";
                
                // Format message based on value type
                if (expr_value.type == VAL_STRING) {
                    strncpy(message, expr_value.data.sval, 255);
                } else if (expr_value.type == VAL_INTEGER) {
                    sprintf(message, "%d", expr_value.data.ival);
                } else if (expr_value.type == VAL_FLOAT) {
                    sprintf(message, "%g", expr_value.data.fval);
                } else if (expr_value.type == VAL_BOOLEAN) {
                    sprintf(message, "%s", expr_value.data.bval ? "true" : "false");
                } else if (expr_value.type == VAL_FUNCTION) {
                    sprintf(message, "function %s", expr_value.data.func.name);
                }
                
                // Free the original value
                free_value(expr_value);
                
                // Create and set the exception
                ret.has_exception = 1;
                ret.return_value = create_exception(type, message);
            }
            
            break;
        }

case NODE_BINARY_OP: {
    // Special case for array assignment
    if (node->data.binary_op.op == ASSIGN && 
        node->data.binary_op.left->type == NODE_ARRAY_ACCESS) {
        
        // Get the array access node
        ASTNode* access = node->data.binary_op.left;
        
        // Evaluate the array
        Value array = evaluate_expression(access->data.array_access.array);
        
        // Check if array evaluation resulted in an exception
        if (array.type == VAL_EXCEPTION) {
            ret.has_exception = 1;
            ret.return_value = array;
            return ret;
        }
        
        // Check if it's an array
        if (array.type != VAL_ARRAY) {
            free_value(array);
            ret.has_exception = 1;
            ret.return_value = create_exception("TypeError", "Cannot index non-array value");
            return ret;
        }
        
        // Evaluate the index
        Value index = evaluate_expression(access->data.array_access.index);
        
        // Check if index evaluation resulted in an exception
        if (index.type == VAL_EXCEPTION) {
            free_value(array);
            ret.has_exception = 1;
            ret.return_value = index;
            return ret;
        }
        
        // Check if index is an integer
        if (index.type != VAL_INTEGER) {
            free_value(array);
            free_value(index);
            ret.has_exception = 1;
            ret.return_value = create_exception("TypeError", "Array index must be an integer");
            return ret;
        }
        
        // Evaluate the right side (value to assign)
        Value value = evaluate_expression(node->data.binary_op.right);
        
        // Check if value evaluation resulted in an exception
        if (value.type == VAL_EXCEPTION) {
            free_value(array);
            free_value(index);
            ret.has_exception = 1;
            ret.return_value = value;
            return ret;
        }
        
        // Get variable name if the array is an identifier
        if (access->data.array_access.array->type == NODE_IDENTIFIER) {
            char* var_name = access->data.array_access.array->data.sval;
            
            // Get the current array value
            Value current_array = get_variable(var_name);
            
            // Set the element in the array
            int success = set_array_element(&current_array, index.data.ival, value);
            if (!success) {
                // Free temporary values
                free_value(current_array);
                free_value(array);
                free_value(index);
                free_value(value);
                
                // Create and propagate an exception
                ret.has_exception = 1;
                ret.return_value = create_exception("IndexError", "Array index out of bounds");
                return ret;
            }
            
            // Update the variable with the modified array
            set_variable(var_name, current_array);
            
            // Free temporary values
            free_value(current_array);
            free_value(array);
            free_value(index);
            free_value(value);
        } else {
            // Cannot assign to a non-variable array
            free_value(array);
            free_value(index);
            free_value(value);
            ret.has_exception = 1;
            ret.return_value = create_exception("TypeError", "Cannot assign to a non-variable array");
            return ret;
        }
    } else {
        // For other binary operations, just evaluate the expression and discard the result
        Value result = evaluate_expression(node);
        
        // Check if evaluation resulted in an exception
        if (result.type == VAL_EXCEPTION) {
            ret.has_exception = 1;
            ret.return_value = result;
            return ret;
        }
        
        // Free the result if needed
        if (result.type == VAL_STRING && result.data.sval) {
            free(result.data.sval);
            } else if (result.type == VAL_ARRAY) {
            free_value(result);
            }
        }
        break;
    }

        default:
            // For expression nodes that appear as statements, evaluate and discard
            if (node->type == NODE_INTEGER || node->type == NODE_FLOAT || 
                node->type == NODE_STRING || node->type == NODE_BOOLEAN || 
                node->type == NODE_IDENTIFIER || node->type == NODE_UNARY_OP || 
                node->type == NODE_BINARY_OP || node->type == NODE_ARRAY_LITERAL || 
                node->type == NODE_ARRAY_ACCESS) {
                
                Value result = evaluate_expression(node);
                
                // Check if evaluation resulted in an exception
                if (result.type == VAL_EXCEPTION) {
                    ret.has_exception = 1;
                    ret.return_value = result;
                    return ret;
                }
                
                // Free the temporary value if needed
                if (result.type == VAL_STRING && result.data.sval) {
                    free(result.data.sval);
                } else if (result.type == VAL_ARRAY) {
                    free_value(result);
                }
            } else {
                fprintf(stderr, "Error: Unknown node type %d\n", node->type);
            }
            break;
    }
    
    return ret;
}

void yyerror(const char* s) {
    fprintf(stderr, "Error at line %d: %s\n", line_num , s);
}

int main(int argc, char** argv) {
    if (argc != 2) {
        printf("please add example file as argument: %s <input_file>\n", argv[0]);
        return 1;
    }
    
    FILE* input_file = fopen(argv[1], "r");
    if (!input_file) {
        printf("error opening file: %s\n", argv[1]);
        return 1;
    }
    
    yyin = input_file;
    
    // Initialize symbol tables
    global_symbols = create_symbol_table();
    current_symbols = global_symbols;
    
    // Parse the input file to build the AST
    yyparse();
    
    // Now interpret the AST
    if (program_root) {
        ReturnValue result = interpret(program_root);
        
        // Check if the program ended with an uncaught exception
        if (result.has_exception) {
            fprintf(stderr, "Uncaught exception:\n");
            print_value_ln(result.return_value);
            free_value(result.return_value);
            free_ast(program_root);
            free_symbol_table(global_symbols);
            fclose(input_file);
            return 1; // Exit with error code
        }
        
        free_ast(program_root);
    }
    
    fclose(input_file);
    
    // Free symbol tables
    free_symbol_table(global_symbols);
    
    return 0;
}