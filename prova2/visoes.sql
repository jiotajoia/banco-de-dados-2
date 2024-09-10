--criando tabela venda

CREATE TABLE venda (
  cod_venda SERIAL NOT NULL PRIMARY KEY,
  nome_vendedor VARCHAR(50) NOT NULL,
  data_venda timestamp default CURRENT_DATE,
  valor_vendido INT
);

--povoando tabela venda
INSERT INTO venda (nome_vendedor, data_venda, valor_vendido) VALUES
('Ana', '2024-09-01 10:00:00', 150),
('Carlos', '2024-09-02 11:30:00', 200),
('João', '2024-09-03 14:00:00', 250),
('Maria', '2024-09-04 09:45:00', 300),
('Ana', '2024-09-05 16:00:00', 175),
('Carlos', '2024-09-06 12:00:00', 225),
('João', '2024-09-07 13:30:00', 275),
('Maria', '2024-09-08 10:30:00', 350),
('Ana', '2024-09-09 15:00:00', 125),
('Carlos', '2024-09-10 11:15:00', 275);

--selecionando vendedores que venderam mais de x reais no mes de setembro em 2024

SELECT v.nome_vendedor, SUM(v.valor_vendido) AS total_vendido
FROM venda v
WHERE EXTRACT(MONTH FROM v.data_venda) = 9
  AND EXTRACT(YEAR FROM v.data_venda) = 2024
GROUP BY v.nome_vendedor
HAVING SUM(v.valor_vendido) > 150;

--criando a visão a partir do select criado previamente

CREATE OR REPLACE VIEW vendedores_setembro AS
SELECT v.nome_vendedor, SUM(v.valor_vendido) AS total_vendido
FROM venda v
WHERE EXTRACT(MONTH FROM v.data_venda) = 9
  AND EXTRACT(YEAR FROM v.data_venda) = 2024
GROUP BY v.nome_vendedor
HAVING SUM(v.valor_vendido) > 150

-- criando a visão para mostrar apenas o vendedor que mais vendeu no mês de setembro
  
CREATE OR REPLACE VIEW vendedor_setembro AS
SELECT *
FROM vendedores_setembro
ORDER BY total_vendido DESC
LIMIT 1;
