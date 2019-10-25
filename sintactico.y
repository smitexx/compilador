%{
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "listaCodigo.h"
#include "listaSimbolos.h"
Tipo tipoId;
Lista l;
ListaC lc;
int contCadenas=0;
int regs[10] = {0,0,0,0,0,0,0,0,0,0};
int numEtiquetas = 0;
int erroresSemanticos = 0;
int erroresSintacticos = 0;
FILE * fp ;
void yyerror();
void imprimirTabla(Lista l);
int anadeEntradaCadena(Lista l, char * string);
int comprobarInsertar(Lista l, char * nombre);
int comprobarConstante(char * nombre );
void liberarRegistro(char * registro);
void imprimirCodigo(ListaC lista);
void imprimirDatos();
char * conseguirReg();
extern int yylex();
extern int yylineno;
extern int erroresLexicos;
%}

%union{
char * cad;
ListaC ensamblador;
}
%type<ensamblador> expression asig read_list print_item print_list statement statement_list identifier_list declarations 
%token<cad> ID
%token<cad> STRING
%token<cad> INTLITERAL
%token FUNC READ LPAREN RPAREN SEMICOLON COMMA EQUALS PRINT LLLAVES RLLAVES VAR CONST IF ELSE WHILE DO
%left PLUSOP MINUSOP
%left MULT DIV 
%left UMENOS
%% 
program: {l=creaLS();}FUNC ID LPAREN RPAREN LLLAVES declarations statement_list RLLAVES {
									printf ("ELexico = %d, Esintac =  %d, Esemant = %d\n",erroresLexicos,erroresSintacticos,erroresSemanticos);
									if (erroresSintacticos == 0 && erroresSemanticos == 0 && erroresLexicos ==0){
												fp = fopen ("codigo.s","w");
												//imprimirTabla(l);
												fprintf(fp,"##################\n# Seccion de datos\n\t.data\n\n");
												imprimirDatos();
												concatenaLC($7,$8);
									            fprintf(fp,"###################\n# Seccion de codigo\n\t.text\n\t.globl main\nmain:\n");
												imprimirCodigo($7);
											    liberaLC($8);
												liberaLC($7);
												fprintf(fp,"##############\n# Fin\n\tjr $ra\n");
												liberaLS(l);
												fclose(fp);
												printf("Código generado correctamente en fichero codigo.s .\n");
													}
									else{
										printf ("Código no generado debido a errores en el código fuente.\n");
											}};
;
declarations: declarations VAR {tipoId=VARIABLE;} identifier_list SEMICOLON {concatenaLC($1, $4);
																			 $$=$1;
																			 liberaLC($4);}
| declarations CONST {tipoId=CONSTANTE;} identifier_list SEMICOLON {concatenaLC($1, $4);
																	$$=$1;
																	liberaLC($4);}
| {$$=creaLC();}
;
identifier_list: asig {$$=$1;}
| identifier_list COMMA asig {
								concatenaLC($1, $3);
								$$=$1;
								liberaLC($3);
							 }
;
asig: ID {if(comprobarInsertar(l,$1)==1){$$=creaLC();}}

| ID EQUALS expression { //sw $t_,id(dir_mem)
						 $$ = creaLC();
						 if (comprobarInsertar(l,$1)==1){
							$$=$3;
							Operacion op;
							op.op = "sw";
							op.res = recuperaResLC($3);
							char buff[20];
							sprintf(buff,"_%s",$1);
							op.arg1 = strdup(buff);
							op.arg2 = NULL;
							guardaResLC($$,op.res);
							insertaLC($$,finalLC($$),op);
							liberarRegistro(op.res);
						 }
					   }
;							
statement_list: statement_list statement {concatenaLC($1,$2);
										  $$=$1;
										  liberaLC($2);}
|{$$ = creaLC();}
;

statement: ID EQUALS expression SEMICOLON {$$=creaLC();if(comprobarConstante($1)==1){
												concatenaLC($$,$3);
												Operacion op;
												op.op = "sw";
												op.res = recuperaResLC($3);
												char buff[20];
												sprintf(buff,"_%s",$1);
												op.arg1 = strdup(buff);
												op.arg2 = NULL;
												guardaResLC($$,op.res);
												insertaLC($$,finalLC($$),op);
												liberarRegistro(op.res);
												liberaLC($3);
											}
										} 

| LLLAVES statement_list RLLAVES {$$=$2;}

| IF LPAREN expression RPAREN statement ELSE statement {//expresion
														 $$=$3;
														//beqz $t_,et1
														 Operacion op;
										 				 op.op = "beqz";
										 				 op.res = recuperaResLC($3);
														 char buff[20];
										 				 sprintf(buff,"et%d",numEtiquetas++);
														 op.arg1 = strdup(buff);
										 				 op.arg2 = NULL;
														 insertaLC($$,finalLC($$),op);
														//Statement1
														 concatenaLC($$,$5);
														//b et2
														 Operacion op2;
										 				 op2.op = "b";
														 char buff2[20];
										 				 sprintf(buff2,"et%d",numEtiquetas++);
														 op2.res = strdup(buff2);
										 				 op2.arg1 = NULL;
										 				 op2.arg2 = NULL;
														 insertaLC($$,finalLC($$),op2);
														//et1:
														 op.op = "etiq";
										 				 op.res = op.arg1;
										 				 op.arg1 = NULL;
														 op.arg2 = NULL;
														 insertaLC($$,finalLC($$),op);
														//statement2
														concatenaLC($$,$7);
														//et2:
														 op2.op = "etiq";
										 				 op2.res = op2.res;
										 				 op2.arg1 = NULL;
														 op2.arg2 = NULL;
														 insertaLC($$,finalLC($$),op2);
														//Liberar
														 liberaLC($5);
														 liberaLC($7);
														}

| IF LPAREN expression RPAREN statement {//expresion
										 $$ = $3;
										 //beqz $t_,et1
										 Operacion op;
										 op.op = "beqz";
										 op.res = recuperaResLC($3);
										 char buff[20];
										 sprintf(buff,"et%d",numEtiquetas++);
										 op.arg1 = strdup(buff);
										 op.arg2 = NULL;
										 insertaLC($$,finalLC($$),op);
										 //statement
										 concatenaLC($$,$5);
										 //et1:
										 op.op = "etiq";
										 op.res = op.arg1;
										 op.arg1 = op.arg2 = NULL;
										 insertaLC($$,finalLC($$),op);
										 liberaLC($5);}
|DO statement WHILE LPAREN expression RPAREN {
												//et1
												$$=creaLC();
												Operacion op;
												op.op = "etiq";
												char buff[20];
												sprintf(buff,"et%d",numEtiquetas++);
												op.res = strdup(buff);
												op.arg1 = op.arg2 = NULL;
												insertaLC($$,finalLC($$),op);
												//statement
												concatenaLC($$,$2);
												//expresion	
												concatenaLC($$,$5);
												//bnez $t_,et1
			 									Operacion op2;
												op2.op = "bneqz";
												op2.res = recuperaResLC($5);
												op2.arg1 = op.res;
												op2.arg2 = NULL;
												insertaLC($$,finalLC($$),op2);
												//liberar
												liberaLC($2);
												liberaLC($5);
											}

| WHILE LPAREN expression RPAREN statement {//et1:
											$$ = creaLC();
											Operacion op;
										    op.op = "etiq";
											char buff[20];
										 	sprintf(buff,"et%d",numEtiquetas++);
											op.res = strdup(buff);
											op.arg1 = op.arg2 = NULL;
											insertaLC($$,finalLC($$),op);
											//expresion
											concatenaLC($$,$3);
											//beqz $t_,et2
											Operacion op2;
											op2.op = "beqz";
											op2.res = recuperaResLC($3);
											char buff2[20];
										 	sprintf(buff2,"et%d",numEtiquetas++);
											op2.arg1 = strdup(buff2);
											op2.arg2 = NULL;
											insertaLC($$,finalLC($$),op2);
											//statement
											concatenaLC($$,$5);
											//b et1
											Operacion op3;
											op3.op = "b";
											op3.res = op.res;
											op3.arg1 = op3.arg2 = NULL;
											insertaLC($$,finalLC($$),op3);
											//et2:
											Operacion op4;
											op4.op = "etiq";
											op4.res = op2.arg1;	
											op4.arg1 = op4.arg2 = NULL;
											insertaLC($$,finalLC($$),op4);
											//Liberar
											liberaLC($3);
											liberaLC($5);
										   }

| PRINT print_list SEMICOLON {$$=$2;}

| READ read_list SEMICOLON {$$=$2;}
;
print_list: print_item {$$=$1;}
| print_list COMMA print_item {
								//Puede ser que haya que crear una lista en $1;
								concatenaLC($1,$3);
								$$ = $1;
								liberaLC($3);
							  }
;
print_item: expression {
							$$=$1;
							Operacion op;
							op.op = "move";
							op.res = "$a0";
							op.arg1 = recuperaResLC($1);
							op.arg2 = NULL;
							insertaLC($$,finalLC($$),op);
							op.op = "li";
							op.res = "$v0";
							op.arg1 = "1";
							op.arg2 = NULL;
							insertaLC($$,finalLC($$),op);
							op.op = "syscall";
							op.res = NULL;
							op.arg1 = NULL;
							op.arg2 = NULL;
							insertaLC($$,finalLC($$),op);

						}

| STRING {
			$$= creaLC();
			tipoId=CADENA;
			int numCadena = anadeEntradaCadena(l,$1);
			Operacion op;
			op.op = "la";
			op.res = "$a0";
			char buff[20];
			sprintf(buff,"$str%d", numCadena);
			op.arg1 = strdup(buff);
			op.arg2 = NULL;
			insertaLC($$,finalLC($$),op);
			op.op = "li";
			op.res = "$v0";
			op.arg1 = "4";
			op.arg2 = NULL;
			insertaLC($$,finalLC($$),op);
			op.op = "syscall";
			op.res = NULL;
			op.arg1 = NULL;
			op.arg2 = NULL;
			insertaLC($$,finalLC($$),op);

		 }
;
read_list: ID {$$=creaLC();if(comprobarConstante($1)==1){
							Operacion op;
							op.op = "li";
							op.res = "$v0";
							op.arg1 = "5";
							op.arg2 = NULL;
							insertaLC($$,finalLC($$),op);
							op.op = "syscall";
							op.res = NULL;
							op.arg1 = NULL;
							op.arg2 = NULL;
							insertaLC($$,finalLC($$),op);
							op.op = "sw";
							op.res = "$v0";
							char buff[20];
							sprintf(buff,"_%s", $1);
							op.arg1 = strdup(buff);
							op.arg2 = NULL;
							insertaLC($$,finalLC($$),op);
						}}

| read_list COMMA ID {
						//Puede ser que haya que crear una lista en $1 y concatenarla con $3;
						ListaC aux =creaLC();
						if(comprobarConstante($3)==1){
							Operacion op;
							op.op = "li";
							op.res = "$v0";
							op.arg1 = "5";
							op.arg2 = NULL;
							insertaLC(aux,finalLC(aux),op);
							op.op = "syscall";
							op.res = NULL;
							op.arg1 = NULL;
							op.arg2 = NULL;
							insertaLC(aux,finalLC(aux),op);
							op.op = "sw";
							op.res = "$v0";
							char buff[20];
							sprintf(buff,"_%s", $3);
							op.arg1 = strdup(buff);
							op.arg2 = NULL;
							insertaLC(aux,finalLC(aux),op);
							concatenaLC($$,aux);
							liberaLC(aux);
						}
					 }
;

expression: expression PLUSOP expression {Operacion op;
								op.op = "add";
								op.arg1 = recuperaResLC($1);
								op.arg2 = recuperaResLC($3);
								op.res = conseguirReg();
								concatenaLC($1,$3);
								guardaResLC($1,op.res);
								$$ = $1;
								insertaLC($$,finalLC($$),op);
								liberarRegistro(op.arg1);
								liberarRegistro(op.arg2);
								liberaLC($3);}

| expression MINUSOP expression {Operacion op;
								op.op = "sub";
								op.arg1 = recuperaResLC($1);
								op.arg2 = recuperaResLC($3);
								op.res = conseguirReg();
								concatenaLC($1,$3);
								guardaResLC($1,op.res);
								$$ = $1;
								insertaLC($$,finalLC($$),op);
								liberarRegistro(op.arg1);
								liberarRegistro(op.arg2);
								liberaLC($3);}

| expression MULT expression {  Operacion op;
								op.op = "mul";
								op.arg1 = recuperaResLC($1);
								op.arg2 = recuperaResLC($3);
								op.res = conseguirReg();
								concatenaLC($1,$3);
								guardaResLC($1,op.res);
								$$ = $1;
								insertaLC($$,finalLC($$),op);
								liberarRegistro(op.arg1);
								liberarRegistro(op.arg2);
								liberaLC($3);
								}

| expression DIV expression {	Operacion op;
								op.op = "div";
								op.arg1 = recuperaResLC($1);
								op.arg2 = recuperaResLC($3);
								op.res = conseguirReg();
								concatenaLC($1,$3);
								guardaResLC($1,op.res);
								$$ = $1;
								insertaLC($$,finalLC($$),op);
								liberarRegistro(op.arg1);
								liberarRegistro(op.arg2);
								liberaLC($3);}

| MINUSOP expression %prec UMENOS {Operacion op;
								   op.op = "neg";
								   op.arg1 = recuperaResLC($2);
								   op.res = conseguirReg();
								   guardaResLC($$,op.res);
								   $$ = $2;
								   insertaLC($$,finalLC($$),op);
								   liberarRegistro(op.arg1);}

| LPAREN expression RPAREN {$$ = $2;}

| ID         {  $$ = creaLC();
				if(buscaLS(l,$1) == finalLS(l)) {
                    printf("Variable no declarada\n");
                }
                else {
	                Operacion op;
	                op.op = "lw";
	                op.res = conseguirReg();
					char buff[20];
					sprintf(buff,"_%s", $1);
					op.arg1 = strdup(buff);
                    op.arg2 = NULL;
					guardaResLC($$, op.res);
	                insertaLC($$,finalLC($$),op);
                }    
             }

| INTLITERAL { $$ = creaLC();
	      		Operacion op;
	      		op.op = "li";
	      		op.res = conseguirReg();
	     	    op.arg1 = $1;
                op.arg2 = NULL;
	      		guardaResLC($$, op.res);
	      		insertaLC($$,finalLC($$),op);
	         }
;
%%
void imprimirCodigo(ListaC lista){
	PosicionListaC p = inicioLC(lista);
	while(p != finalLC(lista)){
		Operacion op = recuperaLC(lista,p);
		if(strcmp("etiq",op.op) == 0){
			fprintf(fp,"%s",op.res);
		}
		else{
			fprintf(fp,"\t%s ",op.op);
			if (op.res!=NULL) fprintf (fp,"%s",op.res);
			if (op.arg1!=NULL) fprintf (fp,", %s",op.arg1);
			if (op.arg2!=NULL) fprintf (fp,", %s",op.arg2);
		}
		fprintf(fp,"\n");
		p = siguienteLC(lista, p);
	}
}
void imprimirDatos(){
	//Cadenas
	PosicionLista p = inicioLS(l);
	while (p!=finalLS(l)){
		Simbolo s = recuperaLS(l, p);
		if(s.tipo == CADENA){
			fprintf(fp,"$str%d:\n\t.asciiz %s\n", s.valor,s.nombre);
		}
		p = siguienteLS(l, p);
	}
	//Variables y constantes
	p = inicioLS(l);
	while (p!=finalLS(l)){
		Simbolo s = recuperaLS(l, p);
		if(s.tipo != CADENA){
			fprintf(fp,"_%s:\n\t.word %i\n", s.nombre,s.valor);
		}
		p = siguienteLS(l, p);
	}
	fprintf(fp,"\n\n");
}
char * conseguirReg(){
    //Se mira si hay registros libres;
    for (int i = 0; i< 10 ; i++){
        if (regs[i] == 0){
            //Registro $ti
	        char registro[4];
	        sprintf(registro,"$t%d",i);
	        regs[i] = 1;
	        return strdup(registro);
        }
        //Comprobacion de que todos estan ocupados.
        else if (i == 9){
		printf("No hay ningún registro libre\n");
		exit(1);
	    }   
	}
}
void liberarRegistro(char * registro){
    regs[registro[2]-'0'] = 0;
}
void imprimirTabla(Lista l){
    fprintf(fp,"Imprimiendo lista de %d símbolos\n", longitudLS(l));
    PosicionLista p = inicioLS(l);
    while(p != finalLS(l)){
        Simbolo aux = recuperaLS(l,p);
        fprintf(fp,"%s %s %d\n", aux.nombre, (aux.tipo == VARIABLE ? "variable" : aux.tipo == CONSTANTE ? "constante" : 
        aux.tipo == CADENA ? "cadena" : "nada"), aux.valor);
        p = siguienteLS(l,p);
    }
}

int anadeEntradaCadena(Lista l, char * string){
    contCadenas++;
    Simbolo aux;
    strncpy(aux.nombre,string,100);
    aux.tipo = CADENA;
    aux.valor = contCadenas;
    insertaLS(l,finalLS(l),aux);
	return contCadenas;
}

int comprobarInsertar(Lista l, char * nombre){
    PosicionLista p = buscaLS(l,nombre);
    if(p == finalLS(l)){
        Simbolo aux; 
        strncpy(aux.nombre,nombre,16); 
        aux.tipo = tipoId;
        aux.valor = 0;
        insertaLS(l,finalLS(l),aux);
		return 1;
    } 
    else{
		printf("Variable ya declarada\n");
		erroresSemanticos++;
	}
return 0;
}

int comprobarConstante(char * nombre ){
    PosicionLista p = buscaLS(l,nombre);
    if(p == finalLS(l)){
        printf("Variable no declarada\n");
		erroresSemanticos++;
		return 0;
	}
    else{
        Simbolo aux = recuperaLS(l,p);
		if(aux.tipo == CONSTANTE){
	    	printf("Asignación a constante\n");
			erroresSemanticos++;
			return 0;
		}	
    } 
return 1;
}

void yyerror(){
	erroresSintacticos++;
    printf("Error sintáctico en línea número: %d \n", yylineno);
}
