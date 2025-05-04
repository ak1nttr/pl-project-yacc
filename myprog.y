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
    VAL_STRING,
    VAL_BOOLEAN
} ValueType;

// Value structure for runtime evaluation
typedef struct {
    ValueType type;
    union {
        int ival;
        char* sval;
        int bval;
    } data;
} Value;

// Symbol table structure
typedef struct {
    char* name;
    Value value;
} Symbol;

// Symbol table globals
#define MAX_SYMBOLS 100
Symbol symbol_table[MAX_SYMBOLS];
int symbol_count = 0;

// AST node types
typedef enum {
    NODE_INTEGER,
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
    NODE_BLOCK
} NodeType;

// AST node structure
typedef struct ASTNode {
    NodeType type;
    union {
        int ival;                  // For integer literals
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
    } data;
} ASTNode;

// Forward declarations for AST functions
ASTNode* create_integer_node(int value);
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
void add_statement_to_block(ASTNode* block, ASTNode* statement);
void free_ast(ASTNode* node);
Value evaluate_expression(ASTNode* expr);
void interpret(ASTNode* node);
int add_symbol(char* name, Value value);
int find_symbol(char* name);
void declare_variable(char* name, Value value);
void set_variable(char* name, Value value);
Value get_variable(char* name);
void print_value(Value val);
int value_to_boolean(Value val);

// Root node of the AST
ASTNode* program_root = NULL;
%}

%union {
    int ival;
    char* sval;
    int bval;
    struct ASTNode* node;
}

/* Token definitions */
%token VAR IF ELSE WHILE PRINT
%token PLUS MINUS MULTIPLY DIVIDE
%token ASSIGN
%token EQUAL NOT_EQUAL LESS_THAN LESS_EQUAL GREATER_THAN GREATER_EQUAL
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON

%token <ival> INTEGER
%token <sval> STRING IDENTIFIER
%token <bval> BOOLEAN

/* Define types for non-terminals */
%type <node> program statement_list statement
%type <node> declaration assignment if_statement while_statement print_statement
%type <node> expression term factor block

/* Define operator precedence */
%left EQUAL NOT_EQUAL
%left LESS_THAN LESS_EQUAL GREATER_THAN GREATER_EQUAL
%left PLUS MINUS
%left MULTIPLY DIVIDE
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
    ;

%%

// AST node creation functions
ASTNode* create_integer_node(int value) {
    ASTNode* node = malloc(sizeof(ASTNode));
    node->type = NODE_INTEGER;
    node->data.ival = value;
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
            
        default:
            break; // No memory to free for other types
    }
    
    free(node);
}

// Coerce a value to boolean (for conditions)
int value_to_boolean(Value val) {
    switch (val.type) {
        case VAL_INTEGER:
            return val.data.ival != 0;
        case VAL_STRING:
            return val.data.sval != NULL && strlen(val.data.sval) > 0;
        case VAL_BOOLEAN:
            return val.data.bval;
    }
    return 0;
}

// Symbol table functions
int add_symbol(char* name, Value value) {
    if (symbol_count >= MAX_SYMBOLS) {
        fprintf(stderr, "Symbol table full\n");
        return -1;
    }
    
    int index = find_symbol(name);
    if (index != -1) {
        // Free old string if needed
        if (symbol_table[index].value.type == VAL_STRING && symbol_table[index].value.data.sval) {
            free(symbol_table[index].value.data.sval);
        }
        
        // Update value
        symbol_table[index].value = value;
        return index;
    }
    
    // Add new symbol
    symbol_table[symbol_count].name = strdup(name);
    
    // Copy value (deep copy for strings)
    symbol_table[symbol_count].value = value;
    if (value.type == VAL_STRING && value.data.sval) {
        symbol_table[symbol_count].value.data.sval = strdup(value.data.sval);
    }
    
    return symbol_count++;
}

int find_symbol(char* name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

// Runtime evaluation
Value evaluate_expression(ASTNode* expr) {
    Value result;
    
    switch (expr->type) {
        case NODE_INTEGER:
            result.type = VAL_INTEGER;
            result.data.ival = expr->data.ival;
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
            int index = find_symbol(expr->data.sval);
            if (index == -1) {
                fprintf(stderr, "Error: Undefined variable '%s'\n", expr->data.sval);
                result.type = VAL_INTEGER;
                result.data.ival = 0;
            } else {
                result = symbol_table[index].value;
                
                // Deep copy for strings
                if (result.type == VAL_STRING && result.data.sval) {
                    result.data.sval = strdup(result.data.sval);
                }
            }
            break;
        }
        
        case NODE_BINARY_OP: {
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
                } else if (left.type == VAL_BOOLEAN) {
                    sprintf(left_str, "%s", left.data.bval ? "true" : "false");
                }
                
                // Convert right to string
                if (right.type == VAL_STRING) {
                    strncpy(right_str, right.data.sval, 255);
                } else if (right.type == VAL_INTEGER) {
                    sprintf(right_str, "%d", right.data.ival);
                } else if (right.type == VAL_BOOLEAN) {
                    sprintf(right_str, "%s", right.data.bval ? "true" : "false");
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
            
            // For other operations, convert to integers
            int left_val = (left.type == VAL_INTEGER) ? left.data.ival : 
                          (left.type == VAL_BOOLEAN) ? left.data.bval : 0;
                          
            int right_val = (right.type == VAL_INTEGER) ? right.data.ival : 
                           (right.type == VAL_BOOLEAN) ? right.data.bval : 0;
            
            // Free any string values
            if (left.type == VAL_STRING && left.data.sval) {
                free(left.data.sval);
            }
            if (right.type == VAL_STRING && right.data.sval) {
                free(right.data.sval);
            }
            
            result.type = VAL_INTEGER;
            
            switch (expr->data.binary_op.op) {
                case PLUS:
                    result.data.ival = left_val + right_val;
                    break;
                case MINUS:
                    result.data.ival = left_val - right_val;
                    break;
                case MULTIPLY:
                    result.data.ival = left_val * right_val;
                    break;
                case DIVIDE:
                    if (right_val == 0) {
                        fprintf(stderr, "Error: Division by zero\n");
                        result.data.ival = 0;
                    } else {
                        result.data.ival = left_val / right_val;
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
                default:
                    fprintf(stderr, "Error: Unknown binary operator\n");
                    result.data.ival = 0;
            }
            break;
        }
        
        case NODE_UNARY_OP: {
            Value operand = evaluate_expression(expr->data.unary_op.operand);
            
            // Convert to integer/boolean
            int val = (operand.type == VAL_INTEGER) ? operand.data.ival : 
                     (operand.type == VAL_BOOLEAN) ? operand.data.bval : 0;
            
            // Free string if needed
            if (operand.type == VAL_STRING && operand.data.sval) {
                free(operand.data.sval);
            }
            
            switch (expr->data.unary_op.op) {
                case MINUS:
                    result.type = VAL_INTEGER;
                    result.data.ival = -val;
                    break;
                default:
                    fprintf(stderr, "Error: Unknown unary operator\n");
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

// Helper functions for variable management
void declare_variable(char* name, Value value) {
    int index = find_symbol(name);
    if (index != -1) {
        fprintf(stderr, "Error: Variable '%s' already declared\n", name);
        return;
    }
    
    add_symbol(name, value);
}

void set_variable(char* name, Value value) {
    int index = find_symbol(name);
    if (index == -1) {
        fprintf(stderr, "Error: Undefined variable '%s'\n", name);
        return;
    }
    
    // Free old string value if needed
    if (symbol_table[index].value.type == VAL_STRING && 
        symbol_table[index].value.data.sval) {
        free(symbol_table[index].value.data.sval);
    }
    
    // Copy the value
    symbol_table[index].value = value;
    
    // Create a deep copy for strings
    if (value.type == VAL_STRING && value.data.sval) {
        symbol_table[index].value.data.sval = strdup(value.data.sval);
    }
}

Value get_variable(char* name) {
    int index = find_symbol(name);
    Value result;
    
    if (index == -1) {
        fprintf(stderr, "Error: Undefined variable '%s'\n", name);
        result.type = VAL_INTEGER;
        result.data.ival = 0;
        return result;
    }
    
    return symbol_table[index].value;
}

void print_value(Value val) {
    switch (val.type) {
        case VAL_INTEGER:
            printf("%d\n", val.data.ival);
            break;
        case VAL_STRING:
            printf("%s\n", val.data.sval);
            break;
        case VAL_BOOLEAN:
            printf("%s\n", val.data.bval ? "true" : "false");
            break;
    }
}

// Execute a statement
void interpret(ASTNode* node) {
    if (!node) return;
    
    switch (node->type) {
        case NODE_BLOCK:
            for (int i = 0; i < node->data.block.count; i++) {
                interpret(node->data.block.statements[i]);
            }
            break;
            
        case NODE_DECLARATION: {
            Value value = evaluate_expression(node->data.declaration.initial_value);
            declare_variable(node->data.declaration.name, value);
            break;
        }
        
        case NODE_ASSIGNMENT: {
            Value value = evaluate_expression(node->data.assignment.value);
            set_variable(node->data.assignment.name, value);
            break;
        }
        
        case NODE_IF: {
            Value condition = evaluate_expression(node->data.if_stmt.condition);
            if (value_to_boolean(condition)) {
                interpret(node->data.if_stmt.if_branch);
            } else if (node->data.if_stmt.else_branch) {
                interpret(node->data.if_stmt.else_branch);
            }
            
            // Free string if needed
            if (condition.type == VAL_STRING && condition.data.sval) {
                free(condition.data.sval);
            }
            break;
        }
        
        case NODE_WHILE: {
            Value condition = evaluate_expression(node->data.while_loop.condition);
            
            while (value_to_boolean(condition)) {
                // Free previous condition value if it's a string
                if (condition.type == VAL_STRING && condition.data.sval) {
                    free(condition.data.sval);
                }
                
                interpret(node->data.while_loop.body);
                
                // Re-evaluate condition
                condition = evaluate_expression(node->data.while_loop.condition);
            }
            
            // Free final condition value if it's a string
            if (condition.type == VAL_STRING && condition.data.sval) {
                free(condition.data.sval);
            }
            break;
        }
        
        case NODE_PRINT: {
            Value value = evaluate_expression(node->data.print_stmt.expr);
            print_value(value);
            
            // Free string if needed
            if (value.type == VAL_STRING && value.data.sval) {
                free(value.data.sval);
            }
            break;
        }
    }
}

void yyerror(const char* s) {
    fprintf(stderr, "Error at line %d: %s\n", line_num, s);
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
    
    // Parse the input file to build the AST
    yyparse();
    
    // Now interpret the AST
    if (program_root) {
        interpret(program_root);
        free_ast(program_root);
    }
    
    fclose(input_file);
    
    // Free symbol table
    for (int i = 0; i < symbol_count; i++) {
        free(symbol_table[i].name);
        if (symbol_table[i].value.type == VAL_STRING && symbol_table[i].value.data.sval) {
            free(symbol_table[i].value.data.sval);
        }
    }
    
    return 0;
}