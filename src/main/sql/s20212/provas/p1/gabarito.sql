DO $$ BEGIN
    PERFORM drop_functions();
    PERFORM drop_tables();
END $$;

create table cidade(
numero int not null primary key,
nome varchar not null
);

create table bairro(
numero int not null primary key,
nome varchar not null,
cidade int not null,
foreign key (cidade) references cidade(numero)
);

create table pesquisa(
numero int not null,
descricao varchar not null,
primary key (numero)
);

create table pergunta(
pesquisa int not null,
numero int not null,
descricao varchar not null,
primary key (pesquisa,numero),
foreign key (pesquisa) references pesquisa(numero)
);

create table resposta(
pesquisa int not null,
pergunta int not null,
numero int not null,
descricao varchar not null,
primary key (pesquisa,pergunta,numero),
foreign key (pesquisa,pergunta) references pergunta(pesquisa,numero)
);

create table entrevista(
numero int not null primary key,
data_hora timestamp not null,
bairro int not null,
foreign key (bairro) references bairro(numero)
);

create table escolha(
entrevista int not null,
pesquisa int not null,
pergunta int not null,
resposta int not null,
primary key (entrevista,pesquisa,pergunta),
foreign key (entrevista) references entrevista(numero),
foreign key (pesquisa,pergunta,resposta) references resposta(pesquisa,pergunta,numero)
);

insert into cidade values (1,'Rio de Janeiro');
insert into cidade values (2,'Niterói');
insert into cidade values (3,'São Paulo');

insert into bairro values (1,'Tijuca',1);
insert into bairro values (2,'Centro',1);
insert into bairro values (3,'Lagoa',1);
insert into bairro values (4,'Icaraí',2);
insert into bairro values (5,'São Domingos',2);
insert into bairro values (6,'Santa Rosa',2);
insert into bairro values (7,'Moema',3);
insert into bairro values (8,'Jardim Paulista',3);
insert into bairro values (9,'Higienópolis',3);


insert into pesquisa values (1,'Pesquisa 1');

insert into pergunta values (1,1,'Pergunta 1');
insert into pergunta values (1,2,'Pergunta 2');
insert into pergunta values (1,3,'Pergunta 3');
insert into pergunta values (1,4,'Pergunta 4');

insert into resposta values (1,1,1,'Resposta 1 da pergunta 1');
insert into resposta values (1,1,2,'Resposta 2 da pergunta 1');
insert into resposta values (1,1,3,'Resposta 3 da pergunta 1');
insert into resposta values (1,1,4,'Resposta 4 da pergunta 1');
insert into resposta values (1,1,5,'Resposta 5 da pergunta 1');

insert into resposta values (1,2,1,'Resposta 1 da pergunta 2');
insert into resposta values (1,2,2,'Resposta 2 da pergunta 2');
insert into resposta values (1,2,3,'Resposta 3 da pergunta 2');
insert into resposta values (1,2,4,'Resposta 4 da pergunta 2');
insert into resposta values (1,2,5,'Resposta 5 da pergunta 2');
insert into resposta values (1,2,6,'Resposta 5 da pergunta 2');

insert into resposta values (1,3,1,'Resposta 1 da pergunta 3');
insert into resposta values (1,3,2,'Resposta 2 da pergunta 3');
insert into resposta values (1,3,3,'Resposta 3 da pergunta 3');

insert into resposta values (1,4,1,'Resposta 1 da pergunta 4');
insert into resposta values (1,4,2,'Resposta 2 da pergunta 4');

insert into entrevista values (1,'2020-03-01'::timestamp,1);
insert into escolha values (1,1,1,2);
insert into escolha values (1,1,2,2);
insert into escolha values (1,1,3,1);

insert into entrevista values (2,'2020-03-01'::timestamp,1);
insert into escolha values (2,1,1,3);
insert into escolha values (2,1,2,1);
insert into escolha values (2,1,3,2);

insert into entrevista values (3,'2020-03-01'::timestamp,1);
insert into escolha values (3,1,1,4);
insert into escolha values (3,1,2,1);
insert into escolha values (3,1,3,1);

insert into entrevista values (4,'2020-03-01'::timestamp,1);
insert into escolha values (4,1,1,2);
insert into escolha values (4,1,2,1);
insert into escolha values (4,1,3,1);

insert into entrevista values (5,'2020-03-01'::timestamp,1);
insert into escolha values (5,1,1,2);
insert into escolha values (5,1,2,1);
insert into escolha values (5,1,3,1);

create or replace function resultado(p_pesquisa int, p_bairros varchar[], p_cidades varchar[])
returns table (pergunta int, histograma float[][]) as $$
declare
begin
    return query
    with
        t1 as (select b.numero as bairro
               from bairro b inner join cidade c on b.cidade = c.numero
               where (p_bairros is null or array_position(p_bairros,b.nome) is not null)
                      and (p_cidades is null or array_position(p_cidades,c.nome) is not null)),

        t2 as (select t22.pesquisa, t22.pergunta, t22.resposta, count(*) as frequencia
               from
                    (entrevista t21 natural join t1)
                    inner join escolha t22 on t21.numero = t22.entrevista
               where t22.pesquisa = p_pesquisa
               group by t22.pesquisa, t22.pergunta, t22.resposta),

        t3 as (select t33.pesquisa, t33.pergunta, t33.numero, 0::int as frequencia
               from (entrevista t31 natural join t1)
                    inner join escolha t32 on t32.entrevista = t31.numero
                    right join resposta t33 on t33.pesquisa = t32.pesquisa and t33.pergunta = t32.pergunta and t33.numero = t32.resposta
               where t33.pesquisa = p_pesquisa and t32.pesquisa is null),

        t4 as (select * from t2 union select * from t3),

        t5 as (select t4.pesquisa, t4.pergunta, sum(frequencia) as total
               from t4
               group by t4.pesquisa, t4.pergunta)

    -- https://www.postgresql.org/docs/13/sql-expressions.html
    select t4.pergunta, array_agg(array[t4.resposta,(coalesce(t4.frequencia*1.0/nullif(t5.total,0),0))::float] order by t4.resposta) as histograma
    from t4 natural join t5
    group by t4.pesquisa, t4.pergunta;

end;
$$ language plpgsql;

select * from resultado(1,null,null);

