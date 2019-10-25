## Makefile del compilador.
practica:sintactico.tab.c sintactico.tab.h lex.yy.c main.c listaSimbolos.c listaSimbolos.h listaCodigo.c listaCodigo.h
	gcc main.c lex.yy.c sintactico.tab.c listaSimbolos.c listaCodigo.c -lfl -o practica
sintactico.tab.c sintactico.tab.h : sintactico.y
	bison -d -v -t sintactico.y  
lex.yy.c: lexico.l
	flex lexico.l
borrar :
	rm -f lex.yy.c sintactico.tab.c sintactico.tab.h practica
