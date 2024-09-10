--CASE
(CASE WHEN
	CONDICAO TAL THEN FAZ TAL COISA
	ELSE FAZ TAL COISA
	END)

--CAST ALTERA VALORES, TIPO=
	CAST (NUM AS VARCHAR)
	


--LISTA!

	

--Listagem dos hóspedes contendo nome e data de nascimento, ordenada em ordem crescente por nome e decrescente por data 
--de nascimento.

SELECT NOME, DT_NASC FROM HOSPEDE ORDER BY NOME ASC, DT_NASC DESC;

--Listagem contendo os nomes das categorias, ordenados alfabeticamente. A coluna de nomes deve ter a palavra ‘Categoria’
--como título.

SELECT NOME CATEGORIA FROM CATEGORIA ORDER BY NOME;

--Listagem contendo os valores de diárias e os números dos apartamentos, ordenada em ordem decrescente de valor.

SELECT NOME, VALOR_DIA FROM CATEGORIA ORDER BY VALOR_DIA DESC;

--Categorias que possuem apenas um apartamento.

SELECT NOME FROM CATEGORIA NATURAL JOIN APARTAMENTO GROUP BY NOME HAVING COUNT(*)= 1;

--Listagem dos nomes dos hóspedes brasileiros com mês e ano de nascimento, por ordem decrescente de idade e por ordem
--crescente de nome do hóspede.

SELECT NOME FROM HOSPEDE WHERE NACIONALIDADE ILIKE '%BRASILEIRO%' ORDER BY DT_NASC DESC, NOME ASC;

--Listagem com 3 colunas, nome do hóspede, número do apartamento e quantidade (número de vezes que aquele hóspede se hospedou
--naquele apartamento), em ordem decrescente de quantidade.

SELECT NOME, NUM, COUNT(*) QUANTIDADE FROM HOSPEDAGEM NATURAL JOIN HOSPEDE GROUP BY NOME, NUM ORDER BY QUANTIDADE DESC;

--Categoria cujo nome tenha comprimento superior a 15 caracteres

SELECT NOME FROM CATEGORIA WHERE LENGTH(NOME) > 15;

--Número dos apartamentos ocupados no ano de 2017 com o respectivo nome da sua categoria.
SELECT NUM, NOME FROM CATEGORIA NATURAL JOIN APARTAMENTO NATURAL JOIN HOSPEDAGEM WHERE EXTRACT(YEAR FROM DT_ENT) = 2017;

--Crie a tabela funcionário com as atributos: cod_func, nome, dt_nascimento e salário. Depois disso, acrescente o cod_func
--como chave estrangeira nas tabelas hospedagem e reserva.
CREATE TABLE FUNCIONARIO
(COD_FUNC INT NOT NULL PRIMARY KEY,
NOME VARCHAR(20) NOT NULL,
DT_NASC DATE,
SALARIO FLOAT NOT NULL
);

INSERT INTO FUNCIONARIO VALUES
(1, 'JOAZINHO', '2000-03-03', 10000);

ALTER TABLE HOSPEDAGEM 
ADD COLUMN COD_FUNC INT NOT NULL DEFAULT 1
REFERENCES FUNCIONARIO(COD_FUNC);

ALTER TABLE RESERVA 
ADD COLUMN COD_FUNC INT NOT NULL DEFAULT 1
REFERENCES FUNCIONARIO(COD_FUNC);

--Mostre o nome e o salário de cada funcionário. Extraordinariamente, cada funcionário receberá um acréscimo neste salário
--de 10 reais para cada hospedagem realizada.

SELECT NOME, SALARIO FROM FUNCIONARIO

SELECT NOME, SALARIO + 
        (CASE 
            WHEN COUNT(COD_HOSPEDA) IS NULL THEN 0 
            ELSE 10 * COUNT(COD_HOSPEDA) 
        END) 
FROM FUNCIONARIO F LEFT JOIN HOSPEDAGEM H ON F.COD_FUNC = H.COD_FUNC GROUP BY NOME, SALARIO;

--Listagem das categorias cadastradas e para aquelas que possuem apartamentos, relacionar também o número do apartamento,
--ordenada pelo nome da categoria e pelo número do apartamento.

SELECT NOME, NUM FROM CATEGORIA CAT LEFT JOIN APARTAMENTO AP ON CAT.COD_CAT = AP.COD_CAT GROUP BY NOME, NUM ORDER BY NOME ASC;

--Listagem das categorias cadastradas e para aquelas que possuem apartamentos, relacionar também o número do apartamento,
--ordenada pelo nome da categoria e pelo número do apartamento. Para aquelas que não possuem apartamentos associados,
--escrever "não possui apartamento".

SELECT NOME,
    CASE 
	WHEN NUM IS NOT NULL THEN CAST(NUM AS VARCHAR)
        ELSE 'não possui apartamento'
    END NUM
FROM CATEGORIA CAT LEFT JOIN APARTAMENTO AP ON CAT.COD_CAT = AP.COD_CAT ORDER BY NOME ASC, NUM ASC;

--O nome dos funcionário que atenderam o João (hospedando ou reservando) ou que hospedaram ou reservaram apartamentos da
--categoria luxo.

SELECT NOME FROM FUNCIONARIO WHERE COD_FUNC IN(
	SELECT COD_FUNC FROM FUNCIONARIO NATURAL JOIN HOSPEDAGEM WHERE COD_HOSP IN(
	SELECT COD_HOSP FROM HOSPEDE WHERE NOME ILIKE '%JOÃO%'
	)
) 
	UNION

SELECT NOME FROM FUNCIONARIO WHERE COD_FUNC IN(
	SELECT COD_FUNC FROM FUNCIONARIO NATURAL JOIN RESERVA WHERE COD_HOSP IN(
	SELECT COD_HOSP FROM HOSPEDE WHERE NOME ILIKE '%JOÃO%'
	)
)
	UNION
	
SELECT NOME FROM FUNCIONARIO WHERE COD_FUNC IN(
	SELECT COD_FUNC FROM FUNCIONARIO NATURAL JOIN HOSPEDAGEM NATURAL JOIN APARTAMENTO AP JOIN CATEGORIA CA ON AP.COD_CAT = CA.COD_CAT
	WHERE CA.NOME ILIKE '%LUXO%'
	)

	UNION
	
SELECT NOME FROM FUNCIONARIO WHERE COD_FUNC IN(
	SELECT COD_FUNC FROM FUNCIONARIO NATURAL JOIN RESERVA NATURAL JOIN APARTAMENTO AP JOIN CATEGORIA CA ON AP.COD_CAT = CA.COD_CAT
	WHERE CA.NOME ILIKE '%LUXO%'
	)
;	

SELECT * FROM CATEGORIA

--O código das hospedagens realizadas pelo hóspede mais velho que se hospedou no apartamento mais caro.

SELECT COD_HOSP FROM HOSPEDE WHERE DT_NASC IN (
	SELECT MIN(DT_NASC) FROM HOSPEDE WHERE COD_HOSP IN(
	SELECT COD_HOSP FROM HOSPEDAGEM NATURAL JOIN APARTAMENTO WHERE COD_CAT IN(
	SELECT COD_CAT FROM CATEGORIA WHERE VALOR_DIA IN(
	SELECT MAX(VALOR_DIA) FROM CATEGORIA
))));

SELECT COD_HOSP FROM HOSPEDE WHERE DT_NASC IN(
SELECT MIN(DT_NASC) FROM HOSPEDE H JOIN HOSPEDAGEM HP ON H.COD_HOSP = HP.COD_HOSP
	JOIN APARTAMENTO A ON A.NUM = HP.NUM JOIN CATEGORIA C ON A.COD_CAT = C.COD_CAT 
	WHERE C.VALOR_DIA = (SELECT MAX(VALOR_DIA) FROM CATEGORIA));

--Sem usar subquery, o nome dos hóspedes que nasceram na mesma data do hóspede de código 2.
SELECT H.NOME FROM HOSPEDE H JOIN HOSPEDE HO ON H.COD_HOSP <> HO.COD_HOSP WHERE HO.COD_HOSP = 2 AND H.DT_NASC = HO.DT_NASC;

--O nome do hóspede mais velho que se hospedou na categoria mais cara mo ano de 2017.
SELECT NOME FROM HOSPEDE WHERE DT_NASC IN(
SELECT MIN(DT_NASC) FROM HOSPEDE NATURAL JOIN HOSPEDAGEM WHERE NUM IN (
SELECT NUM FROM APARTAMENTO NATURAL JOIN HOSPEDAGEM WHERE EXTRACT(YEAR FROM DT_ENT) = 2017
INTERSECT
SELECT NUM FROM APARTAMENTO WHERE COD_CAT IN(	
SELECT COD_CAT FROM CATEGORIA WHERE VALOR_DIA IN(
SELECT MAX(VALOR_DIA) FROM CATEGORIA))))

SELECT DISTINCT H.NOME FROM HOSPEDE H JOIN HOSPEDAGEM HOSP ON H.COD_HOSP = HOSP.COD_HOSP
JOIN APARTAMENTO A ON HOSP.NUM = A.NUM JOIN CATEGORIA C ON A.COD_CAT = C.COD_CAT
WHERE EXTRACT(YEAR FROM HOSP.DT_ENT) = 2017 AND C.VALOR_DIA = (SELECT MAX(VALOR_DIA) FROM CATEGORIA) 
	AND H.DT_NASC = (SELECT MIN(DT_NASC) FROM HOSPEDE)

--O nome das categorias que foram reservadas pela Maria ou que foram ocupadas pelo João quando ele foi atendido pelo Joaquim.

SELECT NOME FROM APARTAMENTO NATURAL JOIN CATEGORIA WHERE COD_HOSP IN(HOSPEDE NATURAL JOIN RESERVA WHERE NOME ILIKE '%MARIA%')
	UNION
SELECT NOME FROM APARTAMENTO NATURAL JOIN CATEGORIA WHERE COD_HOSP IN(HOSPEDE H NATURAL JOIN HOSPEDAGEM NATURAL JOIN FUNCIONARIO F
	WHERE H.NOME ILIKE '%JOÃO%' AND F.NOME ILIKE '%JOAQUIM%');

--O nome e a data de nascimento dos funcionários, além do valor de diária mais cara reservado por cada um deles.

SELECT F.NOME, F.DT_NASC, MAX(CAT.VALOR_DIA) FROM CATEGORIA CAT JOIN APARTAMENTO AP ON CAT.COD_CAT = AP.COD_CAT 
JOIN RESERVA R ON R.NUM = AP.NUM JOIN FUNCIONARIO F ON R.COD_FUNC = F.COD_FUNC
GROUP BY F.NOME, F.DT_NASC;

--A quantidade de apartamentos ocupados por cada um dos hóspedes (mostrar o nome).

SELECT COUNT(*) QTD, H.NOME FROM HOSPEDE H NATURAL JOIN HOSPEDAGEM GROUP BY H.NOME;

--A relação com o nome dos hóspedes, a data de entrada, a data de saída e o valor total pago em diárias
--(não é necessário considerar a hora de entrada e saída, apenas as datas).

SELECT H.NOME, HP.DT_ENT, HP.DT_SAI, (HP.DT_SAI - HP.DT_ENT) QTD_DIARIA, ((HP.DT_SAI - HP.DT_ENT) * CAT.VALOR_DIA) VALOR
FROM HOSPEDE H JOIN HOSPEDAGEM HP ON H.COD_HOSP = HP.COD_HOSP JOIN APARTAMENTO AP ON AP.NUM = HP.NUM JOIN CATEGORIA CAT ON AP.COD_CAT = CAT.COD_CAT;

SELECT * FROM HOSPEDE
--O nome dos hóspedes que já se hospedaram em todos os apartamentos do hotel.

SELECT DISTINCT H.NOME
FROM HOSPEDE H
WHERE NOT EXISTS (
    SELECT *
    FROM APARTAMENTO A
    WHERE NOT EXISTS (
        SELECT *
        FROM HOSPEDAGEM HOSP
        WHERE H.COD_HOSP = HOSP.COD_HOSP
          AND HOSP.NUM = A.NUM
    )
);

