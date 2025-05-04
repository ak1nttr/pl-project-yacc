CC = gcc
CFLAGS = -g
YACC = yacc
LEX = lex

kaos: lex.yy.c y.tab.c
	$(CC) $(CFLAGS) -o kaos lex.yy.c y.tab.c -lfl

y.tab.c y.tab.h: myprog.y
	$(YACC) -d myprog.y

lex.yy.c: myprog.l y.tab.h
	$(LEX) myprog.l

clean:
	rm -f kaos lex.yy.c y.tab.c y.tab.h *.o