# Desafio Playax
Esse desafio foi proposto pela empresa Playax.

**Objetivo**

Importar um aquivo PDF do ECAD com informações sobre obras e autores para análise futura de dados.

**Especificações técnicas**

_Linguagem:_ Ruby

_Entrada de dados:_ PDF

_Saída de dados:_ HASH

## Estrutura e Código

A estrura foi mantida de acordo com o recebido da Playax.

Fazendo a análise do código:
-------

```ruby
1. def initialize(pdf_file_path)
2.   @pdf = PDF::Reader.new(pdf_file_path)
3. end
```

Método inicializador da classe que recebe o caminho do arquivo PDF que devemos importar

---

```ruby
1.  def self.work(line)
2.   source_id = line.match(/^[0-9]{1,20}/).to_s.strip
3.   iswc = line.match(/[T|-]+[[0-9]| ]+.[[0-9]| ]+.[[0-9]| ]+[-|-[0-9]]+/).to_s.strip
4.   title = line[33,60].strip
5.   situation = line.match(/ LB[\w*\/]+ | LB /).to_s.strip
6.   created_at = line.match(/(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[012])\/[12][0-9]{3}/).to_s.strip
7.
8.   return {
9.     iswc: iswc, 
10.    title: title, 
11.     external_ids: [
12.       {
13.         source_name: 'Ecad',
14.         source_id: source_id
15.       }
16.     ],
17.     situation: situation,
18.     created_at: created_at
19.   }
20. end
```

O método Work é responsável por entender e importar as linhas do arquivo referente as obras, recebe como parâmetro uma linha, 
e partir daí utilizando Regex vamos separando os dados que precisamos para a importação dos dados.

Cada Regex tem sua função:

Em **source_id** na linha 2 eu procuro no inicio da linha por numero em quantidades que podem variar de 1 a 20, com isso temos o código da obra.

Em **iswc** eu tento procuro por algum caractere iniciado em T ou - seguido de algum numero ou espaço, levando em consideração obras que não 
contém essa informação, seguido de um ponto(.) e utilizo a mesma lógica até o fim da cadeia

Em **title** eu busco a informação por posição absoluta, o arquivo permite fazer isso em alguns momentos, mas como essa informação não é tão
peculiar a ponto de ter uma Regex apenas pra ela, fiz dessa maneira, haveria outras formas utilizando Regex em combinação com outra
informação, fiz isso em outros casos para exemplificar.

Em **situation** eu busco uma cadeia de caracteres que contenha LB e qualquer outra coisa após isso que seja alphanumérico e contenha barra(/)
OU apenas por LB. LB é a situação que a obra de encontra, podem ser 1 ou várias situações diferentes.

Em **created_at** eu devo informar a data de criação da obra, Regex para validação de data levando em conta cada caractere que pode ser informado.

A partir da linha 8, monto o hash principal da obra baseado nas informações coletadas pelas expressões regulares.

---

```ruby
1.  def self.right_holder(line)
2.    share_and_role = line.match(/[A-Z]*\s{1,3}[0-9]*,[0-9]*/).to_s.split(" ")
3.    return nil unless share_and_role[1]
4.    society_name_and_ipi = line.match(/[0-9]{3}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2} [A-Z]*/).to_s.split(" ")
5.
6.    name = line[12,37].strip
7.    society_name = society_name_and_ipi[1]
8.    pseudo_name = line[49,25].strip.match(/^[A-Z\s]*/).to_s.strip
9.    source_name = "Ecad"
10.   source_id = line.match(/^[0-9]{1,20}/).to_s.strip
11.   ipi = society_name_and_ipi[0] ? society_name_and_ipi[0].gsub(".","") : society_name_and_ipi[0]
12.   share = share_and_role[1].gsub(",",".").to_f
13.   role = CATEGORIES[share_and_role[0]]
14.
15.   return {
16.     name: name,
17.     society_name: society_name,
18.     pseudos: [
19.       {
20.         name: pseudo_name,
21.         main: true
22.       }
23.     ],
24.     external_ids: [
25.       {
26.         source_name: source_name,
27.         source_id: source_id
28.       }
29.     ],
30.     ipi: ipi,
31.     share: share,
32.     role: role
33.   }
34. end
```

O método right_holder tem objetivo de enriquecer o objeto do hash principal criado com o método work com informações dos diretos da
obra. Também recebe uma linha como parâmetro.

Na linha número 2, há uma expressão regular para buscar uma informação em conjunto, solução essa que apresentei mais acima no método work
e foi implementada aqui, como esse desafio tem fins de avaliação, mantive as duas formas como prova de conhecimento. Essa expressão
regular busca uma cadeia de letras maiúsculas em qualquer quantidade seguido de 1, 2 ou 3 espaços, mais uma cadeia de caracteres númerais
em qualquer quantidade seguido de vírgula(,) e mais númerais em qualquer quantidade. Essa expressão irá me retornar qual o papel do integrante
na obra e qual sua participação em percentual da mesma.

Utilizo essa informação para separar a cadeia em 2 posições de uma matriz e ter cada informação separada.

Na linha 3 eu faço um teste se existe uma das posições da matriz criada anteriormente, responsável pela participação percentual, caso não
exista, o método termina aqui retornando nulo.

Na linha 4 eu utilizo uma expressão com objetivo de buscar o nome da associação do integrante e o seu registro.
Busco uma cadeia de caracteres numerais com no máximo 3 posiçoes e um ponto(.) logo depois.
Faço a mesma lógica pros dois próximos blocos, porém utilizando 2 posições de numerais ao invés de 3 e finalizo com uma cadeia alfabetica
maiuscula em qualquer quantidade.

Entre as linhas 6 e 13, faço uso dessas informações utilizando expressão para buscar o pseudo_name em uma cadeia de caracteres que esteja no inicio
da linha que contenham letras maiusculas e espaços e a mesma lógica pra source_id com excessão de serem números e de no máximo 20 posições.

Na linha 15 crio o hash de retorno que irá enriquecer o hash work principal.

---

```ruby
1.  def works
2.    final_hash = []
3.    right_holder_irregular_line_control = false
4.    right_holder_irregular_line_content = ""
5.
6.    @pdf.pages.each do |page|
7.      page.text.each_line do |line|
8.        if line.match(/ [T| ]-+/)
9.          final_hash << self.class.work(line)
10.       else
11.         if line.match(/^[0-9]{3,20}/) or right_holder_irregular_line_control then
12.           if line.match(/[0-9]*\,[0-9]*/) then
13.             if right_holder_irregular_line_control then
14.               line = right_holder_irregular_line_content + line
15.               right_holder_irregular_line_control = false
16.               right_holder_irregular_line_content = ""
17.             end
18.             work = final_hash.last
19.             if work[:right_holders].kind_of?(Array)
20.                 work[:right_holders] << self.class.right_holder(line)
21.             else
22.                 work[:right_holders] = [self.class.right_holder(line)]
23.             end              
24.           else
25.             right_holder_irregular_line_control = true
26.             right_holder_irregular_line_content = line
27.             next
28.           end
29.         end
30.       end        
31.     end
32.   end
33.   return final_hash
34. end
```

Esse é o método prinpipal da classe e onde tá o coração do funcionamento do código.

Na Linha 2 comecei criando uma variavel que armazenará todo o hash de obras e integrantes nele.

Linha 3 uma variavel que fará o controle das linhas dos integrantes, infelizmente os aquivos de importações não são regulares e por conta
disso acaba que no momento da importação alguns integrantes ficaram com as linhas quebradas, para resolver isso, criei essa variável de controle

Linha 4 tem o mesmo objetico de controle, porem guarda o conteudo da linha para que virtualmente eu monte a linha corretamente antes
de passar para os metodos responsaveis.

Linhas 6 e 7 são as iterações pelas paginas e linhas do arquivo PDF.

Linha 8 eu testo se a linha do PDF que estou passando no momento é uma linha de obra, para isso eu uso uma Regex que testa se existe a 
formatação do ISWC.

Linha 9 caso seja uma linha de obra eu invoco o metodo work para inicializar o hash daquela obra.

Linha 11 caso não seja uma linha de obra, começamos por aqui, testamos se essa linha é uma linha que de traz informações sobre um integrante
ou se é uma linha controlado pela quebra irregular.

Linha 12 eu testo com a regex se existe o padrao do percentual dos integrantes, uma forma de ter certeza que estamos analisando uma linha
de integrantes e não de obras, já que apenas integrantes tem percentual da obra.

Linha 13 eu testo se o controle de linha irregular está ativo.

Linhas 14 a 16 eu manipulo esse controle, guardando virtualmente a linha corretamente sem a quebra e desligando o controle de linha irregular.

Linha 18 eu busco a ultima posição inserida no hash final

Linha 19 a 23 eu faço verificações de estrura de dados, para que não haja erro de execução de código por não está na estrutura esperada.

Linha 25 a 27, caso seja uma linha irregular, eu ligo o controle e guardo o conteúdo da linha, iniciando assim a montagem da linha virtual.

Linha 33 eu retorno o resultado final do script.
