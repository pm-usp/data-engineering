/* ModeloLogico: */

CREATE TABLE Item (
    Nome varchar(40),
    Quantidade int,
    Destinatario varchar(40),
    Destino varchar(120),
    Prioridade varchar(10),
    Codigo_Pedido int,
    id int PRIMARY KEY,
    fk_Lojista_id int
);

CREATE TABLE Pacote (
    Peso real,
    Fragil int,
    id int PRIMARY KEY
);

CREATE TABLE Entrega (
    status varchar(10),
    Data date,
    id int PRIMARY KEY,
    fk_Entregador_id int
);

CREATE TABLE Entregador (
    Nome varchar(40),
    Veiculo varchar(40),
    Nivel int,
    id int PRIMARY KEY
);

CREATE TABLE Lojista (
    CNPJ varchar(40),
    Nome varchar(40),
    Endereco varchar(120),
    id int PRIMARY KEY
);

CREATE TABLE ChangeLog (
    act varchar(10) not null,
    Tabela varchar(40) not null,
    Valor_anterior varchar(120),
    Valor_atual varchar(120),
    Campo varchar(40),
    Timestamp timestamp with time zone not null default current_timestamp
);

CREATE TABLE Item_Pacote (
    fk_Pacote_id int,
    fk_Item_id int
);

CREATE TABLE Pacote_Entrega (
    fk_Pacote_id int,
    fk_Entrega_id int
);
 
ALTER TABLE Item ADD CONSTRAINT FK_Item_2
    FOREIGN KEY (fk_Lojista_id)
    REFERENCES Lojista (id)
    ON DELETE CASCADE;
 
ALTER TABLE Entrega ADD CONSTRAINT FK_Entrega_2
    FOREIGN KEY (fk_Entregador_id)
    REFERENCES Entregador (id)
    ON DELETE CASCADE;
 
ALTER TABLE Item_Pacote ADD CONSTRAINT FK_Item_Pacote_1
    FOREIGN KEY (fk_Pacote_id)
    REFERENCES Pacote (id)
    ON DELETE RESTRICT;
 
ALTER TABLE Item_Pacote ADD CONSTRAINT FK_Item_Pacote_2
    FOREIGN KEY (fk_Item_id)
    REFERENCES Item (id)
    ON DELETE RESTRICT;
 
ALTER TABLE Pacote_Entrega ADD CONSTRAINT FK_Pacote_Entrega_1
    FOREIGN KEY (fk_Pacote_id)
    REFERENCES Pacote (id)
    ON DELETE RESTRICT;
 
ALTER TABLE Pacote_Entrega ADD CONSTRAINT FK_Pacote_Entrega_2
    FOREIGN KEY (fk_Entrega_id)
    REFERENCES Entrega (id)
    ON DELETE RESTRICT;
	
CREATE OR REPLACE FUNCTION if_modified() RETURNS trigger AS $body$
DECLARE
	valor_anterior VARCHAR(120);
	valor_atual VARCHAR(120);
	temprow record;
BEGIN
	IF (TG_OP = 'UPDATE') THEN
		valor_anterior = ROW(OLD.*);
		valor_atual = ROW(NEW.*);
		FOR temprow IN SELECT pre.key AS columname, pre.value AS prevalue, post.value AS postvalue 
						FROM jsonb_each(to_jsonb(OLD)) AS pre 
						CROSS JOIN jsonb_each(to_jsonb(NEW)) AS post 
						WHERE pre.key = post.key AND pre.value IS DISTINCT FROM post.value
		LOOP
			INSERT INTO ChangeLog (act, Tabela, Valor_anterior, Valor_atual, Campo)
			VALUES (TG_OP, TG_TABLE_NAME, temprow.prevalue, temprow.postvalue, temprow.columname);
		END LOOP;
		RETURN NEW;
	ELSIF (TG_OP = 'INSERT') THEN
		valor_atual = ROW(NEW.*);
		INSERT INTO ChangeLog (act, Tabela, Valor_atual, Campo)
		VALUES (TG_OP, TG_TABLE_NAME, valor_atual, 'all');
		RETURN NEW;
	ELSIF (TG_OP = 'DELETE') THEN
		valor_anterior = ROW(OLD.*);
		INSERT INTO ChangeLog (act, Tabela, Valor_anterior, Campo)
		VALUES (TG_OP, TG_TABLE_NAME, valor_anterior, 'all');
		RETURN OLD;
	END IF;
END;
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER item_change 
AFTER INSERT OR UPDATE OR DELETE ON Item
FOR EACH ROW
EXECUTE FUNCTION if_modified();

CREATE OR REPLACE TRIGGER pacote_change 
AFTER INSERT OR UPDATE OR DELETE ON Pacote
FOR EACH ROW
EXECUTE FUNCTION if_modified();

CREATE OR REPLACE TRIGGER entrega_change 
AFTER INSERT OR UPDATE OR DELETE ON Entrega
FOR EACH ROW
EXECUTE FUNCTION if_modified();

CREATE OR REPLACE TRIGGER entregador_change 
AFTER INSERT OR UPDATE OR DELETE ON Entregador
FOR EACH ROW
EXECUTE FUNCTION if_modified();

CREATE OR REPLACE TRIGGER lojista_change 
AFTER INSERT OR UPDATE OR DELETE ON Lojista
FOR EACH ROW
EXECUTE FUNCTION if_modified();

CREATE OR REPLACE TRIGGER item_pacote_change 
AFTER INSERT OR UPDATE OR DELETE ON Item_Pacote
FOR EACH ROW
EXECUTE FUNCTION if_modified();

CREATE OR REPLACE TRIGGER pacote_entrega_change 
AFTER INSERT OR UPDATE OR DELETE ON Pacote_Entrega
FOR EACH ROW
EXECUTE FUNCTION if_modified();