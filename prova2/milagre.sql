-- Implemente o banco de dados que controla as compras de livros de uma livraria em seus 
-- respectivos fornecedores, de acordo com o esquema abaixo. Os domínios dos atributos ficarão 
-- a seu critério. Não se esqueça de povoar as tabelas. 
-- Obs: Durante a criação das tabelas, não implemente restrições de chaves primárias e 
-- estrangeiras e nem restrições de valores não nulos nas tabelas Pedido e Item_pedido. 
-- Tabela Fornecedor
CREATE TABLE FORNECEDOR (
	COD_FORNECEDOR SERIAL PRIMARY KEY,
	NOME_FORNECEDOR VARCHAR(255) NOT NULL,
	ENDERECO_FORNECEDOR VARCHAR(255)
);

-- Tabela Titulo
CREATE TABLE TITULO (
	COD_TITULO SERIAL PRIMARY KEY,
	DESCR_TITULO VARCHAR(255) NOT NULL
);

-- Tabela Livro
CREATE TABLE LIVRO (
	COD_LIVRO SERIAL PRIMARY KEY,
	COD_TITULO INT NOT NULL,
	QUANT_ESTOQUE INT NOT NULL,
	VALOR_UNITARIO DECIMAL(10, 2) NOT NULL,
	FOREIGN KEY (COD_TITULO) REFERENCES TITULO (COD_TITULO)
);

-- Tabela Pedido
CREATE TABLE PEDIDO (
	COD_PEDIDO SERIAL PRIMARY KEY,
	COD_FORNECEDOR INT NOT NULL,
	DATA_PEDIDO DATE NOT NULL,
	HORA_PEDIDO TIME NOT NULL,
	VALOR_TOTAL_PEDIDO DECIMAL(10, 2) NOT NULL,
	QUANT_ITENS_PEDIDOS INT NOT NULL,
	FOREIGN KEY (COD_FORNECEDOR) REFERENCES FORNECEDOR (COD_FORNECEDOR)
);

-- Tabela Item_pedido
CREATE TABLE ITEM_PEDIDO (
	COD_LIVRO INT NOT NULL,
	COD_PEDIDO INT NOT NULL,
	QUANTIDADE_ITEM INT NOT NULL,
	VALOR_TOTAL_ITEM DECIMAL(10, 2) NOT NULL,
	PRIMARY KEY (COD_LIVRO, COD_PEDIDO),
	FOREIGN KEY (COD_LIVRO) REFERENCES LIVRO (COD_LIVRO),
	FOREIGN KEY (COD_PEDIDO) REFERENCES PEDIDO (COD_PEDIDO)
);

INSERT INTO
	PEDIDO (
		COD_FORNECEDOR,
		DATA_PEDIDO,
		HORA_PEDIDO,
		VALOR_TOTAL_PEDIDO,
		QUANT_ITENS_PEDIDOS
	)
VALUES
	(30, '2024-02-25', '12:06:00', 399, 12)
	-- b) Mostre o nome de um dos fornecedores que mais vendeu no mês de fevereiro de 2024. 
	-- c) Qual o nome do(s) fornecedor(es) que mais vendeu(eram) no mês de fevereiro de 2024?
DROP FUNCTION GET_FORNECEDORES_MAIORES_VENDAS (VALOR FLOAT) CREATE
OR REPLACE FUNCTION GET_FORNECEDORES_MAIORES_VENDAS (VALOR FLOAT) RETURNS TABLE (NOME VARCHAR, VALOR_TOTAL DECIMAL) AS $$
BEGIN
	RETURN QUERY SELECT f.nome_fornecedor, SUM(p.valor_total_pedido) FROM fornecedor f 
	JOIN pedido p ON p.cod_fornecedor = f.cod_fornecedor
	WHERE p.data_pedido BETWEEN '2024-02-01' AND '2024-02-29'
	GROUP BY f.cod_fornecedor HAVING SUM(p.valor_total_pedido) > valor;	
END;
$$ LANGUAGE PLPGSQL;

SELECT
	*
FROM
	GET_FORNECEDORES_MAIORES_VENDAS (500);

-- a) Crie triggers que implementem todas essas restrições de chave primária, chave estrangeira 
-- e valores não nulos nas tabelas Pedido e Item_pedido. 
SELECT
	1
FROM
	PEDIDO P;

CREATE
OR REPLACE FUNCTION PEDIDO_FUNCAO () RETURNS TRIGGER AS $pedido_funcao$
BEGIN
	IF NEW.cod_pedido IS NULL THEN
		RAISE EXCEPTION 'O id % fornecido é nulo', NEW.cod_pedido;
	END IF;

	IF EXISTS (SELECT 1 FROM pedido p WHERE p.cod_pedido = NEW.cod_pedido) THEN
		RAISE EXCEPTION 'Já existe um pedido com o código %', NEW.cod_pedido;
	END IF;

	IF NOT EXISTS (SELECT 1 FROM fornecedor f WHERE f.cod_fornecedor = NEW.cod_fornecedor) THEN
		RAISE EXCEPTION 'Não existe fornecedor com o ID %', NEW.cod_fornecedor;
	END IF;

	IF NEW.data_pedido IS NULL THEN
		RAISE EXCEPTION 'O valor da data do pedido não pode ser nulo';
	END IF;

	RETURN NEW;
END;
$pedido_funcao$ LANGUAGE PLPGSQL;

CREATE
OR REPLACE TRIGGER PEDIDO_GATILHO BEFORE INSERT ON PEDIDO FOR EACH ROW
EXECUTE FUNCTION PEDIDO_FUNCAO ();

-- Crie um trigger na tabela Livro que não permita quantidade em estoque negativa e sempre 
-- que a quantidade em estoque atingir 10 ou menos unidades, um aviso de quantidade mínima 
-- deve ser emitido ao usuário (para emitir alertas sem interromper a execução da transação, 
-- você pode usar "raise notice" ou "raise info").
CREATE
OR REPLACE FUNCTION LIVRO_FUNCAO () RETURNS TRIGGER AS $livro_funcao$
BEGIN

	IF NEW.quant_estoque < 0 THEN
		RAISE EXCEPTION 'O valor do estoque não pode ser negativo';
	END IF;

	IF NEW.quant_estoque <= 10 THEN
		RAISE INFO 'A quantidade do estoque antigiu 10 ou menos unidades';
	END IF;

	RETURN NEW;
END;
$livro_funcao$ LANGUAGE PLPGSQL;

CREATE
OR REPLACE TRIGGER LIVRO_GATILHO BEFORE
UPDATE
OR INSERT ON LIVRO FOR EACH ROW
EXECUTE FUNCTION LIVRO_FUNCAO ();

-- Crie um trigger que sempre que houver inserções, remoções ou alterações na tabela 
-- "Item_pedido", haja a atualização da "quant_itens_pedidos" e do "valor_total_pedido" da 
-- tabela "pedido", bem como a atualização da quantidade em estoque da tabela Livro
CREATE
OR REPLACE FUNCTION ITEM_PEDIDO_FUNCAO () RETURNS TRIGGER AS $livro_funcao$
BEGIN
	-- TEM QUE SER MAIÚSCULO
	IF TG_OP = 'INSERT' THEN
		UPDATE pedido SET quant_itens_pedidos = quant_itens_pedidos + NEW.quantidade_item WHERE pedido.cod_pedido = NEW.cod_pedido;
		UPDATE pedido SET valor_total_pedido = valor_total_pedido + NEW.valor_total_item WHERE pedido.cod_pedido = NEW.cod_pedido;
		UPDATE livro SET quant_estoque = quant_estoque - NEW.quantidade_item WHERE livro.cod_livro = NEW.cod_livro;

	-- TEM QUE SER MAIÚSCULO
	ELSIF TG_OP = 'UPDATE' THEN
			UPDATE pedido SET quant_itens_pedidos = quant_itens_pedidos + (NEW.quantidade_item - OLD.quantidade_item) WHERE pedido.cod_pedido = NEW.cod_pedido;
			UPDATE pedido SET valor_total_pedido = valor_total_pedido + (NEW.valor_total_item - OLD.valor_total_item) WHERE pedido.cod_pedido = NEW.cod_pedido;
			UPDATE livro SET quant_estoque = quant_estoque - (NEW.quantidade_item - OLD.quantidade_item) WHERE livro.cod_livro = NEW.cod_livro;

	-- TEM QUE SER MAIÚSCULO
	ELSIF TG_OP = 'DELETE' THEN
			UPDATE pedido SET quant_itens_pedidos = quant_itens_pedidos - OLD.quantidade_item WHERE pedido.cod_pedido = OLD.cod_pedido;
			UPDATE pedido SET valor_total_pedido = valor_total_pedido - OLD.valor_total_item WHERE pedido.cod_pedido = OLD.cod_pedido;
			UPDATE livro SET quant_estoque = quant_estoque + NEW.quantidade_item WHERE livro.cod_livro = NEW.cod_livro;
	END IF;
END;
$livro_funcao$ LANGUAGE PLPGSQL;

CREATE
OR REPLACE TRIGGER ITEM_PEDIDO_GATILHO BEFORE
UPDATE
OR INSERT
OR DELETE ON ITEM_PEDIDO FOR EACH ROW
EXECUTE FUNCTION ITEM_PEDIDO_FUNCAO ();

/*
Crie uma tabela chamada "controla_alteracao". Nesta tabela, deverão ser armazenadas as 
alterações (update, delete) feitas na tabela "livro". Deverão ser registrados as seguintes 
informações: operação que foi realizada, a data e hora, além do usuário que realizou a 
modificação. No caso de acontecer uma atualização, deverão ser registrados os valores novos 
e os valores antigos da coluna "cod_titulo" do livro e quantidade em estoque. No caso de 
acontecer uma deleção, basta armazenar o "cod_titulo" do livro e a respectiva quantidade em 
estoque que foi deletada. 
*/

CREATE TABLE controla_alteracao (
	id_alteracao INT PRIMARY KEY,
	alteracao varchar(7) NOT NULL,
	data_alteracao TIMESTAMP NOT NULL,
	usuario_autor varchar(50) NOT NULL,
	cod_titulo_novo int NULL,
	cod_titulo_antigo int NULL,
	quantidade_deletada int NULL
);

CREATE TABLE LIVRO (
	COD_LIVRO SERIAL PRIMARY KEY,
	COD_TITULO INT NOT NULL,
	QUANT_ESTOQUE INT NOT NULL,
	VALOR_UNITARIO DECIMAL(10, 2) NOT NULL,
	FOREIGN KEY (COD_TITULO) REFERENCES TITULO (COD_TITULO)
);


CREATE OR REPLACE FUNCTION controla_alteracao_function() RETURNS TRIGGER AS $controla_alteracao_function$
DECLARE
	ultimo_id_controla_alteracao int;
BEGIN
	RAISE INFO 'TA AQUI';
	SELECT COALESCE(MAX(id_alteracao), 0) INTO ultimo_id_controla_alteracao FROM controla_alteracao;
	
	-- IF TG_OP = 'insert' THEN
	-- 	INSERT ON controla_alteracao(id_alteracao, data_alteracao, usuario_autor) VALUES (ultimo_id_controla_alteracao+1, NOW(), CURRENT_USER);

	-- TEM QUE SER MAIÚSCULO
	IF TG_OP = 'UPDATE' THEN
		RAISE INFO 'UPDATE BRO';
		INSERT INTO controla_alteracao(id_alteracao, alteracao, data_alteracao, usuario_autor) VALUES (ultimo_id_controla_alteracao+1, TG_OP, NOW(), CURRENT_USER);
		IF NEW.COD_TITULO != OLD.COD_TITULO THEN
			UPDATE controla_alteracao SET cod_titulo_novo = NEW.cod_titulo, cod_titulo_antigo = OLD.cod_titulo WHERE id_alteracao = ultimo_id_controla_alteracao+1;
		END IF;

	-- TEM QUE SER MAIÚSCULO
	ELSIF TG_OP = 'DELETE' THEN
		INSERT INTO controla_alteracao(id_alteracao, alteracao, data_alteracao, usuario_autor, cod_titulo_antigo, quantidade_deletada) 
		VALUES (ultimo_id_controla_alteracao+1, TG_OP, NOW(), CURRENT_USER, OLD.cod_titulo, OLD.quant_estoque);

	END IF;

	RETURN NEW;
END;
$controla_alteracao_function$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER controla_livro_gatilho 
BEFORE UPDATE OR DELETE
ON livro
FOR EACH ROW
EXECUTE FUNCTION controla_alteracao_function();

SELECT * FROM controla_alteracao

DELETE FROM LIVRO WHERE COD_LIVRO = 2