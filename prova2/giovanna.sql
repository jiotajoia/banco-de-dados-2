----------------TABELA PRODUTO------------------
CREATE TABLE PRODUTO
(COD_PROD INT NOT NULL PRIMARY KEY,
NOME_PROD VARCHAR NOT NULL,
VALOR_VENDA FLOAT NOT NULL,
E_COMBO CHAR(1) NOT NULL CHECK (E_COMBO='s' OR E_COMBO='n'));
/*OBS: O CAMPO 'E_COMBO' INDICARÁ SE O PRODUTO É COMBO OU NÃO
       ELE PODERÁ RECEBER APENAS OS VALORES 's' MINÚSCULO 
	   QUE SIGNIFICARÁ 'SIM' OU 'n' MINÚSCULO QUE 
	   SIGNIFICARÁ 'NÃO'.*/

INSERT INTO PRODUTO VALUES
(1,'refrigerante',10,'n'),
(2,'sanduíche',15,'n'),
(3,'combo da semana',40,'s'),
(4,'mini-pizza',20,'n');

----------------TABELA COMBO------------------
CREATE TABLE COMBO
(COD_PROD_COMBO INT NOT NULL REFERENCES PRODUTO(COD_PROD),
COD_PROD_COMPOE INT NOT NULL REFERENCES PRODUTO(COD_PROD),
QUANT INT NOT NULL,
CONSTRAINT PRI_COMBO PRIMARY KEY(COD_PROD_COMBO,COD_PROD_COMPOE));

INSERT INTO COMBO VALUES
(3,1,2),
(3,2,1);

------------------TABELA FORNECEDOR-------------------
CREATE TABLE FORNECEDOR
(COD_FORN INT NOT NULL PRIMARY KEY,
NOME_FORN VARCHAR NOT NULL);

INSERT INTO FORNECEDOR VALUES
(1,'fornecedor 1'),
(2,'fornecedor 2'),
(3,'fornecedor 3');

--------------TABELA PEDIDO-----------------
CREATE TABLE PEDIDO
(COD_PEDIDO INT NOT NULL PRIMARY KEY,
COD_FORN INT NOT NULL REFERENCES FORNECEDOR(COD_FORN),
DT_PEDIDO DATE NOT NULL);

INSERT INTO PEDIDO VALUES
(1,1,'2024-08-11'),
(2,2,'2024-09-11');

-------------TABELA ITEM_PEDIDO---------------------
CREATE TABLE ITEM_PEDIDO
(COD_ITEM SERIAL NOT NULL PRIMARY KEY,
COD_PEDIDO INT NOT NULL REFERENCES PEDIDO(COD_PEDIDO),
COD_PROD INT NOT NULL REFERENCES PRODUTO(COD_PROD),
QUANTIDADE INT NOT NULL,
VALOR_TOTAL_ITEM FLOAT NOT NULL);

INSERT INTO ITEM_PEDIDO VALUES
(default,1,1,1,10),
(default,1,2,1,15),
(default,1,4,1,20),
(default,2,3,2,80);

-------------------TABELA TAB_PRECOS------------------
CREATE TABLE TAB_PRECOS
(COD_FORN INT NOT NULL REFERENCES FORNECEDOR(COD_FORN),
COD_PROD INT NOT NULL REFERENCES PRODUTO(COD_PROD),
VALOR_COMPRA FLOAT NOT NULL,
CONSTRAINT PRI_TAB_PRECOS PRIMARY KEY(COD_PROD,COD_FORN));

INSERT INTO TAB_PRECOS VALUES
(1,1,8),
(2,1,7.5),
(1,2,12.50),
(2,2,13),
(3,4,15);


--q1

--trigger da tabela produto

CREATE TRIGGER insere_produto
AFTER INSERT ON produto
FOR EACH ROW
EXECUTE FUNCTION inserir_produto()

CREATE OR REPLACE FUNCTION inserir_produto()
RETURNS TRIGGER AS $$
DECLARE
BEGIN

	IF NEW.e_combo = 's' THEN
		UPDATE produto
		SET valor_venda = 0
		WHERE cod_prod = NEW.cod_prod;
	END IF;

	RETURN NEW;

END;
$$ LANGUAGE plpgsql;

--trigger da tabela combo

CREATE OR REPLACE FUNCTION verifica_se_eh_combo()
RETURNS TRIGGER AS $$
DECLARE
	valor int;
BEGIN
	IF NEW.cod_prod_combo NOT IN (select cod_prod from produto where e_combo = 's') THEN
		RAISE EXCEPTION 'produto não é combo :c';
	END IF;

	IF NEW.cod_prod_combo IN (select cod_prod from produto where e_combo = 's') THEN

		SELECT valor_venda INTO valor FROM produto WHERE cod_prod = NEW.cod_prod_compoe;

		UPDATE produto
		SET valor_venda = valor_venda + (valor * NEW.quant) * 0.8
		WHERE cod_prod = NEW.cod_prod_combo;
	END IF;

	RETURN NEW;
	
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER insere_combo;

CREATE TRIGGER insere_combo
BEFORE INSERT ON combo
FOR EACH ROW
EXECUTE FUNCTION verifica_se_eh_combo()

--testando!

INSERT INTO produto(cod_prod, nome_prod, valor_venda, e_combo)
VALUES(5,'COMBO NOVINHO', 10, 's');

SELECT * FROM COMBO

INSERT INTO combo(cod_prod_combo, cod_prod_compoe, quant)
VALUES(2, 1, 3);

SELECT * FROM produto

--q2

SELECT *  FROM FORNECEDOR

SELECT VERIFICA_SE_FORNECEDOR_EXISTE('fornecedor 5')
CREATE OR REPLACE FUNCTION verifica_se_fornecedor_existe(nome_fornecedor varchar)
RETURNS boolean AS $$
DECLARE
BEGIN 
	if nome_fornecedor NOT IN (SELECT nome_forn from fornecedor) then
	return true;
	END IF;

	RETURN false;
END;
$$LANGUAGE plpgsql;

SELECT VERIFICA_SE_FORNECEDOR_EXISTE('fornecedor 5')
CREATE OR REPLACE FUNCTION verifica_se_produto_existe(nome_produto varchar)
RETURNS boolean AS $$
DECLARE
BEGIN 
	if nome_fornecedor NOT IN (SELECT nome_prod from produto) then
	return true;
	END IF;

	RETURN false;
END;
$$LANGUAGE plpgsql;

DROP FUNCTION VERIFICA_SE_EXISTE()

CREATE OR REPLACE FUNCTION verifica_se_existe()
RETURNS TRIGGER AS $$
BEGIN
	IF verifica_se_fornecedor_existe(NEW.nome_fornecedor) THEN
		RAISE EXCEPTION 'fornecedor não encontrado :c';
	END IF;

	IF verifica_se_produto_existe(NEW.nome_prod) THEN
		RAISE EXCEPTION 'produto não encontrado :c';
	END IF;

	IF NEW.nome_fornecedor NOT IN ( SELECT nome_forn FROM fornecedor f FULL JOIN tab_precos t
									ON f.cod_forn = t.cod_forn
									FULL JOIN produto p
									ON t.cod_prod = p.cod_prod
									WHERE t.valor_compra = (select min(valor_compra) from tab_precos WHERE cod_prod = (
												SELECT cod_prod from PRODUTO WHERE nome_prod = NEW.nome_prod))
								) THEN
		RAISE EXCEPTION 'produto não é o mais barato, tente de novo :c';

	END IF;

	IF NEW.cod_pedido IN (SELECT cod_pedido from pedido) THEN
		RAISE NOTICE 'pedido já existe, adicionando novo item c:';
	END IF;
	
	RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER realiza_pedido1
BEFORE INSERT ON pedido
FOR EACH ROW
EXECUTE FUNCTION verifica_se_existe();

select * from fornecedor

SELECT nome_forn FROM fornecedor f FULL JOIN tab_precos t
ON f.cod_forn = t.cod_forn
FULL JOIN produto p
ON t.cod_prod = p.cod_prod
WHERE t.valor_compra = (select min(valor_compra) from tab_precos where cod_prod = 2)

CREATE OR REPLACE FUNCTION realiza_pedidos(cod_pedido int, nome_prod varchar, quant int, nome_fornecedor varchar)
RETURNS void AS $$
DECLARE
	valor1 int;
	cod_prod1 int;
BEGIN
	UPDATE pedido p
	SET dt_pedido = NOW()
	WHERE p.cod_pedido = cod_pedido;

	SELECT cod_prod INTO cod_prod1 from PRODUTO WHERE nome_prod = NEW.nome_prod;
	
	SELECT t.valor_compra INTO valor1 FROM fornecedor f FULL JOIN tab_precos t
									ON f.cod_forn = t.cod_forn
									FULL JOIN produto p
									ON t.cod_prod = p.cod_prod
									WHERE t.valor_compra = (select min(valor_compra) from tab_precos WHERE cod_prod = cod_prod1);
									
	INSERT INTO item_pedido	
	VALUES(DEFAULT, cod_pedido, cod_prod1, quant, 0);

	UPDATE item_pedido
	SET valor_venda = valor_venda + (valor1*qquant)
	WHERE cod_pedido = cod_pedido;
	
	RETURN;
END;
$$ LANGUAGE plpgsql;

