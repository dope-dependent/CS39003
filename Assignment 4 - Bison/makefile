a.out: lex.yy.o y.tab.o asgn4_19CS10045_main.o
	gcc lex.yy.o y.tab.o asgn4_19CS10045_main.o -ll

lex.yy.c: asgn4_19CS10045.l y.tab.h
	flex asgn4_19CS10045.l

y.tab.c: asgn4_19CS10045.y
	bison -dty asgn4_19CS10045.y

y.tab.h: asgn4_19CS10045.y
	bison -dty asgn4_19CS10045.y

lex.yy.o: lex.yy.c
	gcc -c lex.yy.c

y.tab.o: y.tab.c
	gcc -c y.tab.c

asgn4_19CS10045_main.o: asgn4_19CS10045_main.c
	gcc -c asgn4_19CS10045_main.c

clean: 
	rm a.out lex.yy.c lex.yy.o y.tab.h y.tab.c y.tab.o asgn4_19CS10045_main.o asgn4_19CS10045_output.txt

test: a.out asgn4_19CS10045_test.c
	./a.out < asgn4_19CS10045_test.c > asgn4_19CS10045_output.txt
