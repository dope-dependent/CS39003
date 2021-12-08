translator: ass6_19CS30037.tab.o ass6_19CS30037_translator.o lex.yy.o ass6_19CS30037_target_translator.o libprint.a
	g++ lex.yy.o ass6_19CS30037.tab.o ass6_19CS30037_translator.o ass6_19CS30037_target_translator.o -lfl -o translator

ass6_19CS30037_target_translator.o: ass6_19CS30037_target_translator.cxx
	g++ -c ass6_19CS30037_target_translator.cxx

ass6_19CS30037_translator.o: ass6_19CS30037_translator.cxx ass6_19CS30037_translator.h
	g++ -c ass6_19CS30037_translator.cxx 

lex.yy.o: lex.yy.c 
	g++ -c lex.yy.c 

ass6_19CS30037.tab.o: ass6_19CS30037.tab.c
	g++ -c ass6_19CS30037.tab.c 

lex.yy.c: ass6_19CS30037.l ass6_19CS30037.tab.h ass6_19CS30037_translator.h
	flex ass6_19CS30037.l

ass6_19CS30037.tab.c: ass6_19CS30037.y 
	bison -dtv ass6_19CS30037.y -W

ass6_19CS30037.tab.h: ass6_19CS30037.y 
	bison -dtv ass6_19CS30037.y -W

libprint.a: ass2_19CS30037.o 
	ar -rcs libprint.a ass2_19CS30037.o

ass2_19CS30037.o: ass2_19CS30037.c myl.h
	gcc -c ass2_19CS30037.c

generateAssembly: translator ass6_19CS30037_test1.c ass6_19CS30037_test2.c ass6_19CS30037_test3.c ass6_19CS30037_test4.c ass6_19CS30037_test5.c
	./translator ass6_19CS30037_test1.c > ass6_19CS30037_quads1.out 
	./translator ass6_19CS30037_test2.c > ass6_19CS30037_quads2.out
	./translator ass6_19CS30037_test3.c > ass6_19CS30037_quads3.out
	./translator ass6_19CS30037_test4.c > ass6_19CS30037_quads4.out
	./translator ass6_19CS30037_test5.c > ass6_19CS30037_quads5.out

compileAssembly: ass6_19CS30037_test1.s ass6_19CS30037_test2.s ass6_19CS30037_test3.s ass6_19CS30037_test4.s ass6_19CS30037_test5.s
	gcc -c ass6_19CS30037_test1.s
	gcc -c ass6_19CS30037_test2.s
	gcc -c ass6_19CS30037_test3.s
	gcc -c ass6_19CS30037_test4.s
	gcc -c ass6_19CS30037_test5.s

linkAssembly: libprint.a ass6_19CS30037_test1.o ass6_19CS30037_test2.o ass6_19CS30037_test3.o ass6_19CS30037_test4.o ass6_19CS30037_test5.o
	g++ ass6_19CS30037_test1.o -o ass6_19CS30037_test1 -L. -lprint
	g++ ass6_19CS30037_test2.o -o ass6_19CS30037_test2 -L. -lprint
	g++ ass6_19CS30037_test3.o -o ass6_19CS30037_test3 -L. -lprint
	g++ ass6_19CS30037_test4.o -o ass6_19CS30037_test4 -L. -lprint
	g++ ass6_19CS30037_test5.o -o ass6_19CS30037_test5 -L. -lprint

clean: 
	rm lex.yy.c \
	lex.yy.o \
	translator \
	ass6_19CS30037.tab.c \
	ass6_19CS30037.tab.h \
	ass6_19CS30037.tab.o \
	ass6_19CS30037_translator.o \
	ass6_19CS30037_target_translator.o \
	ass6_19CS30037.output \
	ass2_19CS30037.o \
	libprint.a \
	ass6_19CS30037_quads1.out \
	ass6_19CS30037_quads2.out \
	ass6_19CS30037_quads3.out \
	ass6_19CS30037_quads4.out \
	ass6_19CS30037_quads5.out \
	ass6_19CS30037_test1.o \
	ass6_19CS30037_test2.o \
	ass6_19CS30037_test3.o \
	ass6_19CS30037_test4.o \
	ass6_19CS30037_test5.o \
	ass6_19CS30037_test1.s \
	ass6_19CS30037_test2.s \
	ass6_19CS30037_test3.s \
	ass6_19CS30037_test4.s \
	ass6_19CS30037_test5.s \
	ass6_19CS30037_test1 \
	ass6_19CS30037_test2 \
	ass6_19CS30037_test3 \
	ass6_19CS30037_test4 \
	ass6_19CS30037_test5