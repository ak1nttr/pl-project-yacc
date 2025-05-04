%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

extern int line_num;


typedef enum {
    VAL_INTEGER,
    VAL_FLOAT,   
    VAL_STRING,
    VAL_BOOLEAN
} ValueType;


typedef struct {
    ValueType type;
    union {
        int ival;
        double fval;  
        char* sval;
        int bval;
    } data;
} Value;

%}

/* Regular Definitions */
DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INT         {DIGIT}+
FLOAT       ({DIGIT}+\.{DIGIT}*)|({DIGIT}*\.{DIGIT}+)
STRING      \"[^\"]*\"
WHITESPACE  [ \t]+
NEWLINE     \n|\r|\r\n

%%

{WHITESPACE}    { /* ignore whitespace */ }

{NEWLINE}       { line_num++; } 

"#".*{NEWLINE}  { line_num++; /* skip comments */ }

"var"           { return VAR; }
"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"print"         { return PRINT; }

"true"          { 
                  yylval.bval = 1;
                  return BOOLEAN; 
                }
"false"         { 
                  yylval.bval = 0;
                  return BOOLEAN; 
                }

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULTIPLY; }
"/"             { return DIVIDE; }
"="             { return ASSIGN; }
"=="            { return EQUAL; }
"!="            { return NOT_EQUAL; }
"<"             { return LESS_THAN; }
"<="            { return LESS_EQUAL; }
">"             { return GREATER_THAN; }
">="            { return GREATER_EQUAL; }

"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
";"             { return SEMICOLON; }

{ID}            { 
                  yylval.sval = strdup(yytext);
                  return IDENTIFIER; 
                }

{FLOAT}         { 
                  yylval.fval = atof(yytext);  
                  return FLOAT;                
                }

{INT}           { 
                  yylval.ival = atoi(yytext);
                  return INTEGER; 
                }

{STRING}        { 
                  // Remove quotes from the string
                  yytext[strlen(yytext)-1] = '\0';
                  yylval.sval = strdup(yytext+1);
                  return STRING; 
                }

.               { 
                  fprintf(stderr, "Error: Unrecognized character %s at line %d\n", 
                          yytext, line_num); 
                }

%%

int yywrap() {
    return 1;
}