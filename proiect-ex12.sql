--ex12
/* sa se inregistreze intr-un tabel ddl_log toate operatiile efectuate cu succes
si daca obiectul la care s-a dat create/ drop sau alter sa ii fie afisate coloanele */

create table ddl_log
(
    moment timestamp,
    user_name varchar2(30),
    ddl_event varchar2(25),
    object_name varchar2(100)
);
create or replace trigger ddl_log_trigger
    after create or alter or drop on schema
declare
    cursor c_col is
        select column_name, data_type 
        from user_tab_columns 
        where table_name = sys.dictionary_obj_name;-- dictionar care retine numele obiectului alterat curent
        -- nu o sa se vada modificarile imediat dupa ce alterez daca adaug coloane la tabel
    var_denumiri_coloane varchar2(1000) := '';
begin
    if sys.dictionary_obj_type = 'TABLE'
        then
            for i in c_col loop-- cursor ciclu
                var_denumiri_coloane := var_denumiri_coloane||i.column_name||' ('||i.data_type||'), ';
            end loop;
            -- in cazul in care adaug o coloana la tabelul asuora caruia lucrez, nu e afisata denumirea ei
            -- in mesajul dat de mine, doar daca dau describe va fi in regula
            dbms_output.put_line('Coloanele din tabela '||sys.dictionary_obj_name||' sunt : '||var_denumiri_coloane);
    end if;
-- user
    insert into ddl_log values (systimestamp, sys_context('userenv', 'session_user'), sys.sysevent, sys.dictionary_obj_name);
end;
/

create table test
(
    id number primary key,
    nume varchar2(50),
    telefon varchar2(12),
    varsta number
);
alter table test add (descriere varchar2(100));
desc test;
alter table test drop column id;
drop table test;

drop trigger ddl_log_trigger;
drop table ddl_log;