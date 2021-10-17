./a.out: lex.yy.o asgn3_19CS10045.o
	gcc lex.yy.o asgn3_19CS10045.o -ll
lex.yy.o: lex.yy.c
	gcc -c lex.yy.c
asgn3_19CS10045.o: asgn3_19CS10045.c
	gcc -c asgn3_19CS10045.c
lex.yy.c: ass3_19CS10045.l
	flex ass3_19CS10045.l
clean: lex.yy.o asgn3_19CS10045.o a.out lex.yy.c 
	rm lex.yy.o asgn3_19CS10045.o a.out lex.yy.c
