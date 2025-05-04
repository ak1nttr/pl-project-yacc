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
"function"      { return FUNCTION; }
"return"        { return RETURN; }
"try"           { return TRY; }
"catch"         { return CATCH; }
"finally"       { return FINALLY; }
"throw"         { return THROW; }


"and"           { return AND; }
"or"            { return OR; }
"not"           { return NOT; }

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
"["             { return LBRACKET; }
"]"             { return RBRACKET; }
";"             { return SEMICOLON; }
","             { return COMMA; }

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
                  char* str = strdup(yytext+1);
                  
                  // Process escape sequences
                  int len = strlen(str);
                  char* processed = malloc(len + 1);
                  int j = 0;
                  
                  for (int i = 0; i < len; i++) {
                      if (str[i] == '\\' && i + 1 < len) {
                          // Handle escape sequences
                          switch (str[i + 1]) {
                              case 'n':  // Newline
                                  processed[j++] = '\n';
                                  break;
                              case 't':  // Tab
                                  processed[j++] = '\t';
                                  break;
                              case 'r':  // Carriage return
                                  processed[j++] = '\r';
                                  break;
                              case '\\': // Backslash
                                  processed[j++] = '\\';
                                  break;
                              case '\"': // Double quote
                                  processed[j++] = '\"';
                                  break;
                              default:   // Unknown escape sequence - keep as is
                                  processed[j++] = '\\';
                                  processed[j++] = str[i + 1];
                                  break;
                          }
                          i++; // Skip the next character as we've already processed it
                      } else {
                          // Regular character
                          processed[j++] = str[i];
                      }
                  }
                  
                  processed[j] = '\0'; // Null-terminate the processed string
                  free(str);           // Free the orig string
                  
                  yylval.sval = processed;
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