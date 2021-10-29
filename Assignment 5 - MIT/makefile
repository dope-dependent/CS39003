a.out: ass5_19CS30037.tab.o ass5_19CS30037_translator.o lex.yy.o 
	g++ lex.yy.o ass5_19CS30037.tab.o ass5_19CS30037_translator.o -lfl

ass5_19CS30037_translator.o: ass5_19CS30037_translator.cxx ass5_19CS30037_translator.h
	g++ -c ass5_19CS30037_translator.h
	g++ -c ass5_19CS30037_translator.cxx 

lex.yy.o: lex.yy.c 
	g++ -c lex.yy.c 

ass5_19CS30037.tab.o: ass5_19CS30037.tab.c
	g++ -c ass5_19CS30037.tab.c 

lex.yy.c: ass5_19CS30037.l ass5_19CS30037.tab.h ass5_19CS30037_translator.h
	flex ass5_19CS30037.l

ass5_19CS30037.tab.c: ass5_19CS30037.y 
	bison -dtv ass5_19CS30037.y -W

ass5_19CS30037.tab.h: ass5_19CS30037.y 
	bison -dtv ass5_19CS30037.y -W

clean: 
	rm lex.yy.c\
		  lex.yy.o\
		  a.out\
		  ass5_19CS30037.tab.c\
		  ass5_19CS30037.tab.h\
		  ass5_19CS30037.tab.o\
		  ass5_19CS30037_translator.o\
		  ass5_19CS30037_translator.h.gch\
		  ass5_19CS30037.output

test:
	./a.out < ass5_19CS30037_test1.c > ass5_19CS30037_test1_output.txt
	./a.out < ass5_19CS30037_test2.c > ass5_19CS30037_test2_output.txt
	./a.out < ass5_19CS30037_test3.c > ass5_19CS30037_test3_output.txt
	./a.out < ass5_19CS30037_test4.c > ass5_19CS30037_test4_output.txt
	./a.out < ass5_19CS30037_test5.c > ass5_19CS30037_test5_output.txt
	./a.out < ass5_19CS30037_test6.c > ass5_19CS30037_test6_output.txt