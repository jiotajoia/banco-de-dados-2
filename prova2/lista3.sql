--CRIANDO TABELAS

CREATE TABLE Fornecedor (
	cod_fornecedor SERIAL NOT NULL PRIMARY KEY, 
	nome_fornecedor VARCHAR(50) NOT NULL, 
	endereco_fornecedor VARCHAR(50)
);

CREATE TABLE Livro (
	cod_livro SERIAL NOT NULL PRIMARY KEY, 
	cod_titulo INT, 
	quant_estoque INT NOT NULL, 
	valor_unitario INT NOT NULL,
	FOREIGN KEY (cod_titulo) REFERENCES Titulo (cod_titulo)
);

CREATE TABLE Titulo (
	cod_titulo SERIAL NOT NULL PRIMARY KEY, 
	descr_titulo VARCHAR(100)
);

CREATE TABLE Pedido (
	cod_pedido INT, 
	cod_fornecedor INT, 
	data_pedido TIMESTAMP DEFAULT CURRENT_DATE, 
	hora_pedido TIMESTAMP DEFAULT NOW(), 
	valor_total_pedido INT,
	quant_itens_pedidos INT
);

CREATE TABLE Item_pedido (
	cod_livro INT, 
	cod_pedido INT, 
	quantidade_item INT, 
	valor_total_item INT
);

--POVOANDO AS TABELAS
INSERT INTO Titulo (descr_titulo) VALUES 
('O Senhor dos Anéis'),
('Harry Potter e a Pedra Filosofal'),
('Dom Casmurro');

INSERT INTO Fornecedor (nome_fornecedor, endereco_fornecedor) VALUES 
('Livraria Central', 'Rua das Flores, 123'),
('Editora ABC', 'Avenida Brasil, 456'),
('Distribuidora XYZ', 'Praça da Sé, 789');

INSERT INTO Livro (cod_titulo, quant_estoque, valor_unitario) VALUES 
(1, 50, 40),  -- O Senhor dos Anéis
(2, 100, 30), -- Harry Potter e a Pedra Filosofal
(3, 75, 25);  -- Dom Casmurro

INSERT INTO Pedido (cod_pedido, cod_fornecedor, data_pedido, hora_pedido, valor_total_pedido, quant_itens_pedidos) VALUES 
(1, 1, '2024-09-08', '2024-09-08 10:00:00', 200, 5),
(2, 2, '2024-09-09', '2024-09-09 14:30:00', 150, 3);

INSERT INTO Item_pedido (cod_livro, cod_pedido, quantidade_item, valor_total_item) VALUES 
(1, 1, 2, 80),   -- O Senhor dos Anéis
(2, 1, 1, 30),   -- Harry Potter e a Pedra Filosofal
(3, 2, 3, 75);   -- Dom Casmurro

SELECT * FROM PEDIDO
SELECT * FROM FORNECEDOR

--Mostre o nome dos fornecedores que venderam mais de X reais no mês de fevereiro de
--2024.

SELECT f.nome_fornecedor
FROM Fornecedor f
NATURAL JOIN Pedido p
WHERE EXTRACT(MONTH FROM p.data_pedido) = 09
  AND EXTRACT(YEAR FROM p.data_pedido) = 2024
GROUP BY f.nome_fornecedor
HAVING SUM(p.valor_total_pedido) > 150;

--Mostre o nome de um dos fornecedores que mais vendeu no mês de fevereiro de 2024.

SELECT f.nome_fornecedor
FROM Fornecedor f
NATURAL JOIN Pedido p
WHERE EXTRACT(MONTH FROM p.data_pedido) = 09
  AND EXTRACT(YEAR FROM p.data_pedido) = 2024
GROUP BY f.nome_fornecedor
ORDER BY SUM(p.valor_total_pedido) DESC
LIMIT 1;


--Qual o nome do(s) fornecedor(es) que mais vendeu(eram) no mês de fevereiro de 2024?

SELECT f.nome_fornecedor
FROM Fornecedor f
NATURAL JOIN Pedido p
WHERE EXTRACT(MONTH FROM p.data_pedido) = 09
  AND EXTRACT(YEAR FROM p.data_pedido) = 2024
GROUP BY f.nome_fornecedor
ORDER BY SUM(p.valor_total_pedido) DESC
LIMIT 3;

--trigger para criar restrição de chave primária, chave estrangeira e valores não nulos

DROP FUNCTION VERIFICA_CODIGO_EXISTENTE
CREATE FUNCTION verifica_codigo_existente(codigo_informado INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    codigo_existe BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM pedido WHERE cod_pedido = codigo_informado)
    INTO codigo_existe;

    RETURN codigo_existe;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION verifica_codigo_f_existente(codigo_informado INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    codigo_existe BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM fornecedor WHERE cod_fornecedor = codigo_informado)
    INTO codigo_existe;

    RETURN codigo_existe;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cria_restricoes_pedido()
RETURNs TRIGGER AS $$
BEGIN

	IF NEW.cod_pedido IS NULL OR NEW.cod_fornecedor IS NULL THEN
		RAISE EXCEPTION 'Valores para códigos não podem ser nulos :c';
	END IF;
	
	IF verifica_codigo_existente(NEW.cod_pedido) THEN
		RAISE EXCEPTION 'Código já existente :c';
	END IF;

	IF verifica_codigo_f_existente(NEW.cod_fornecedor) = 'FALSE' THEN
		RAISE EXCEPTION 'CódiGo de fornecedor não encontrado :c';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql

SELECT * FROM FORNECEDOR
SELECT * FROM PEDIDO
INSERT INTO PEDIDO VALUES (5, 1, DEFAULT, DEFAULT, 50, 1)

CREATE TRIGGER restricoes
BEFORE INSERT ON pedido
FOR EACH ROW
EXECUTE FUNCTION cria_restricoes_pedido();


CREATE FUNCTION verifica_codigo_l_existente(codigo_informado INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    codigo_existe BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM livro WHERE cod_livro = codigo_informado)
    INTO codigo_existe;

    RETURN codigo_existe;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cria_restricoes_item_pedido()
RETURNs TRIGGER AS $$
BEGIN
	IF NEW.cod_livro IS NULL OR NEW.cod_pedido IS NULL THEN
		RAISE EXCEPTION 'Valores para códigos não podem ser nulos :c';
	END IF;

	IF verifica_codigo_l_existente(NEW.cod_livro) = 'FALSE' THEN
		RAISE EXCEPTION 'Código de livro não encontrado :c';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql


CREATE TRIGGER restricoes_item_pedido
BEFORE INSERT ON item_pedido
FOR EACH ROW
EXECUTE FUNCTION cria_restricoes_item_pedido();

SELECT * FROM FORNECEDOR
SELECT * FROM ITEM_PEDIDO