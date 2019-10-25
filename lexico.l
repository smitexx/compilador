%{
#include "listaCodigo.h"
#include "sintactico.tab.h"
#include "math.h"
int aux;
int erroresLexicos = 0;
%}
digito              [0-9]
letra               [a-zA-Z]
entero              {digito}+
%option yylineno
%x COMMENT
%%
[ \n\t\r]+                                  ;
"//"(.*)[\n]                                ;
func					    return FUNC;
read                        		    return READ;
print                       		    return PRINT;
var					    return VAR;
const 					    return CONST;
if 					    return IF;
else 					    return ELSE;
while					    return WHILE;
do					    return DO;
(\"([^\"\n]|\\\")*\")		            yylval.cad= strdup(yytext); return STRING;
(_|{letra})({letra}|{digito}|_)*  if(yyleng > 16){printf("Error cadena demasiado larga linea %d\n", yylineno);} yylval.cad = strdup(yytext); return ID;
{entero}     if(atoll(yytext) > pow(2,31)){printf("Error número entero excedido linea %d\n", yylineno);}yylval.cad = strdup(yytext); return INTLITERAL;
"("                                         yylval.cad = strdup(yytext); return LPAREN;	
")"                                         return RPAREN;
"{"					    return LLLAVES;
"}"					    return RLLAVES;
";"                                         return SEMICOLON;
","                                         return COMMA;
"="                                         return EQUALS;
"+"                                         return PLUSOP;
"-"                                         return MINUSOP;
"*"					    return MULT;
"/"					    return DIV;
[^a-zA-Z0-9(){}"+\-*/=;,\n\t\r ]+           {erroresLexicos++;printf("Error lexico en cadena '%s', linea %d\n", 					     yytext,yylineno);};
"/""*"+					   { aux = yylineno; BEGIN COMMENT;}
<COMMENT>"*"+"/"			    BEGIN 0;
<COMMENT>([^*]|[*]+[^*/])*			   ;
<COMMENT><<EOF>> 		{ printf("Error: comentario sin cerrar en linea %d\n", aux); return 0; }
%%
