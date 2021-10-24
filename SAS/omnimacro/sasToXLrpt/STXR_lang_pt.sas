%* Portuguese language X4ML commands.                                                    ;

%macro STXR_lang_pt;

  %let sasnote = NOTA;
  %let saswarning = ADVERT�NCIA;
  %let saserror = ERRO;
    %* Translations of the SAS log keywords NOTE, WARNING and ERROR.                     ;
    %* Above are guesses -- translations are still needed for this language.             ;

  %let c = c;
  %let r = l;
  %let alignment = alinhamento;
  %let appactivate = apl.activar;
  %let appmaximize = apl.maximizar;
  %let average = m�dia;
  %let border = limite;
  %let clear = limpar;
  %let columnwidth = largura.col;
  %let copy = copiar;
  %let editcolor = editar.cor;
  %let error = erro;
  %let false = falso;
  %let fileclose = fich.fechar;
  %let filter = filtro;
  %let fontproperties = propriedades.tipo.de.letra;
  %let formatfont = formatar.tipo.de.letra;
  %let formatnumber = formatar.n�m;
  %let formulareplace = f�rmula.substituir;
  %let freezepanes = fixar.pain�is;
  %let getdocument = obter.documento;
  %let getworkbook = obter.livro;
  %let halt = parar;
  %let max = m�ximo;
  %let median = med;
  %let min = m�nimo;
  %let new = novo;
  %let open = abrir;
  %let pastespecial = colar.especial;
  %let patterns = padr�es;
  %let percentile = percentil;
  %let quit = sair;
  %let rowheight = altura.lin;
  %let run = executa;
  %let saveas = guardar.como;
  %let select = selec;
  %let selection = selec��o;
  %let sendkeys = enviar.teclas;
  %let sendkeycmd = %{o}{e}{a}%{m}{enter};
    %* Key command to merge two adjacent cells together, meaning                         ;
	%* "ALT+O -> E -> A -> ALT+M -> ENTER", which is equivalent to                       ;
    %* "Format -> Cells -> Alignment -> Merge Cells -> OK" in the English version. Above ;
    %* is just a (probably wrong) guess -- translation still needed for this language.   ;
  %let setname = def.nome;
  %let setvalue = def.valor;
  %let sum = soma;
  %let sumproduct = somaproduto;
  %let true = verdadeiro;
  %let windowmaximize = janela.maximizar;
  %let workbookactivate = livro.activar;
  %let workbookcopy = livro.copiar;
  %let workbookdelete = livro.eliminar;
  %let workbookinsert = inserir.livro;
  %let workbookmove = livro.mover;
  %let workbookname = livro.nome;
  %let workbooknext = livro.seg;

%mend STXR_lang_pt;
