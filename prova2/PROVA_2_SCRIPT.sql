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
BEFORE INSERT ON produto
FOR EACH ROW
EXECUTE FUNCTION inserir_produto()

CREATE OR REPLACE FUNCTION inserir_produto()
RETURNS TRIGGER AS $$
DECLARE
BEGIN

	IF NEW.e_combo = 's' THEN
		INSERT INTO produto(nome_prod, valor_venda, e_combo)
		VALUES (NEW.nome_prod, 0, NEW.e_combo);
	END IF;

	RETURN NEW;

END;
$$ LANGUAGE plpgsql;

--trigger da tabela combo
CREATE OR REPLACE VIEW produtos_n_combo as
select * from produto where e_combo = 'n'

SELECT valor_venda FROM produto WHERE cod_prod = NEW.cod_prod_compoe

CREATE OR REPLACE VIEW produtos_combo as
select cod_prod from produto where e_combo = 's'

CREATE OR REPLACE FUNCTION verifica_se_eh_combo()
RETURNS TRIGGER AS $$
DECLARE
	valor int;
BEGIN
	IF (NEW.cod_prod_combo NOT IN (select cod_prod from produto where e_combo = 's') THEN
		RAISE EXCEPTION 'produto não é combo :c';
	END IF;

	IF NEW.cod_prod_combo IN (produtos_combo) THEN
		INSERT INTO combo(cod_prod_combo, cod_prod_compoe, quant)
		VALUES(NEW.cod_prod_combo, NEW.cod_prod_compoe, NEW.quant)

		SET INTO valor = SELECT valor_venda FROM produto WHERE cod_prod = NEW.cod_prod_compoe

		UPDATE produto
		SET valor_venda += (valor * quant) * 0.8
		WHERE cod_prod = NEW.cod_prod_combo
	END IF;
	
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER insere_combo;

CREATE TRIGGER insere_combo
BEFORE INSERT ON combo
FOR EACH ROW
EXECUTE FUNCTION verifica_se_eh_combo()