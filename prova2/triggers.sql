--Crie uma tabela aluno com as colunas matrícula e nome.
--Depois crie um trigger que não permita o cadastro de alunos
--cujo nome começa com a letra “a”.

CREATE TABLE aluno (
	MAT INT NOT NULL,
	NOME VARCHAR(50) NOT NULL,
	CONSTRAINT PRI_MAT PRIMARY KEY (MAT)
);

CREATE TRIGGER adiciona_aluno BEFORE INSERT ON aluno
FOR EACH ROW
EXECUTE FUNCTION adiciona_aluno();

CREATE OR REPLACE FUNCTION adiciona_aluno()
RETURNS TRIGGER AS $$
BEGIN
    IF LOWER(NEW.nome) LIKE 'a%' THEN
        RAISE EXCEPTION 'Nomes que começam com a letra "a" não são permitidos.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


--criar tabela funcionário
CREATE TABLE funcionario (
	cod_func int not null primary key,
	nome varchar(30) not null,
	salario int not null,
	data_ultima_atualizacao timestamp default now(),
	usuario_que_atualizou varchar(30) default current_user
);

drop table funcionario

--trigger e função para validar valores recebidos!
CREATE OR REPLACE FUNCTION valida_funcionario()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se o nome é nulo
    IF NEW.nome IS NULL THEN
        RAISE EXCEPTION 'O nome do funcionário não pode ser nulo.';
    END IF;

    -- Verifica se o salário é nulo ou negativo
    IF NEW.salario IS NULL OR NEW.salario < 0 THEN
        RAISE EXCEPTION 'O salário do funcionário não pode ser nulo ou negativo.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_valida_funcionario
BEFORE INSERT OR UPDATE ON Funcionario
FOR EACH ROW
EXECUTE FUNCTION valida_funcionario();

INSERT INTO Funcionario (cod_func, nome, salario) VALUES (1, 'Carlos Silva', 3000);

INSERT INTO Funcionario (cod_func, nome, salario) VALUES (2, NULL, 3000);

select * from funcionario

-- criar a tabela empregado e empregado_autoria
CREATE TABLE empregado(
	nome VARCHAR(30) NOT NULL,
	salario INT NOT NULL
);

CREATE TABLE empregado_auditoria(
	operacao CHAR(1),
	usuario VARCHAR(50),
	data TIMESTAMP DEFAULT NOW(),
	nome VARCHAR(30),
	salario INT
);

--criando a trigger que registra modificação feita na tabela empregado

CREATE OR REPLACE FUNCTION registra_modificacao()
RETURNS TRIGGER AS $$
BEGIN
	-- Inserção
	IF (TG_OP = 'INSERT') THEN
       	INSERT INTO Empregado_auditoria (operacao, usuario, data, nome, salario)
       	VALUES ('I', SESSION_USER, NOW(), NEW.nome, NEW.salario);
    
    -- Atualização
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO Empregado_auditoria (operacao, usuario, data, nome, salario)
        VALUES ('A', SESSION_USER, NOW(), NEW.nome, NEW.salario);

    -- Exclusão
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO Empregado_auditoria (operacao, usuario, data, nome, salario)
        VALUES ('E', SESSION_USER, NOW(), OLD.nome, OLD.salario);

	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_empregado
AFTER INSERT OR UPDATE OR DELETE ON empregado
FOR ROW
EXECUTE PROCEDURE registra_modificacao();


--criar a tabela empregado2 e empregado2_audit

drop table empregado2
CREATE TABLE empregado2(
	cod SERIAL PRIMARY KEY NOT NULL,
	nome VARCHAR(30) NOT NULL,
	salario INT NOT NULL
);

CREATE TABLE empregado2_audit(
	usuario VARCHAR(30),
	data TIMESTAMP DEFAULT NOW(),
	id INT,
	coluna TEXT,
	valor_antigo TEXT,
	valor_novo TEXT
);

--criar trigger que não permmite alterar primary key e insere registro na
--empregado2_audit 

CREATE OR REPLACE FUNCTION registra_modificacao2()
RETURNS TRIGGER AS $$
BEGIN

	IF (TG_OP = 'UPDATE' AND NEW.cod <> OLD.COD) THEN
		RAISE EXCEPTION 'Não pode alterar chave primária :c';
	END IF;
	
	IF OLD.nome IS DISTINCT FROM NEW.nome THEN
        INSERT INTO empregado2_audit (usuario, data, id, coluna, valor_antigo, valor_novo)
        VALUES (SESSION_USER, NOW(), OLD.cod, 'nome', OLD.nome, NEW.nome);
	END IF;
	
	IF OLD.salario IS DISTINCT FROM NEW.salario THEN
        INSERT INTO empregado2_audit (usuario, data, id, coluna, valor_antigo, valor_novo)
        VALUES (SESSION_USER, NOW(), OLD.cod, 'salario', OLD.salario, NEW.salario);
   END IF;

   RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_empregado2
BEFORE UPDATE ON empregado2
FOR EACH ROW
EXECUTE FUNCTION registra_modificacao2();

INSERT INTO Empregado2 (nome, salario) VALUES ('Carlos Silva', 3000);

UPDATE Empregado2 SET cod = 2 WHERE cod = 1;

SELECT * FROM EMPREGADO2_AUDIT



CREATE OR REPLACE FUNCTION nome_funcao
RETURNS (TRIGGER) AS $$
BEGIN
    IF condicao IS talcoisa THEN
        (RAISE EXCEPTION) ;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger
BEFORE/AFTER INSERT/UPDATE/DELETE...OR ON tabela
FOR (EACH) ROW/STATEMENT
EXECUTE FUNCTION/PROCEDURE funcao;
