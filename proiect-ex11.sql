--ex11
/*pentru o comanda care tocmai a fost inserata in baza de date, sa se modifice angajatul care o proceseaza
numai daca pana in momentul respectiv angajatul are o productivitate mare, adica a procesat mai mult
de media de comenzi per angajat. astfel, acesta va fi inlocuit cu un angajat care a lucrat mai putin,
adica cu cineva care a procesat un numar minim de comenzi pana in acel moment (primul angajat de acest tip
crescator dupa id-ul sau)*/

create or replace trigger update_angajat_trigger
    for insert on comanda
    compound trigger

    type info_procesari is record (
        id_comanda comanda.id_comanda%type,
        id_angajat comanda.id_angajat%type
    );
    type t_procesari is table of info_procesari index by binary_integer;
    t_proc t_procesari;
    count_proc integer := 0;
    var_nr_comenzi_procesate number;

    after each row is-- executata de fiecare data cand un rand e inserat
    -- insereaza o noua linie in t_proc, retinandu-se info despre procesarile obtinute
    begin
        count_proc := count_proc + 1;
        t_proc(count_proc).id_comanda := :new.id_comanda;
        t_proc(count_proc).id_angajat := :new.id_angajat;
    end after each row;

    -- se va face update la angajatii care sunt peste nivelul mediu de productivitate, fiind inlocuiti cu altii
    after statement is-- executata o sg data dupa ce toate randurile au fost procesate
        avg_nr_comenzi_procesate number;
        min_nr_comenzi_procesate number;
    begin
        -- motivul pentru care calculez media imediat dupa ce s-a adaugat linia, e ca trebuie actualizata retinand si informatii despre noua linie
        -- similar pentru min
        select avg(nr)-- media nr de comenzi procesate de fiecare angajat
        into avg_nr_comenzi_procesate
        from (  select count(co.id_comanda) as nr
                from comanda co
                join agent_vanzari a on(co.id_angajat = a.id_angajat)-- pt a evita comenzile cu ang null
                group by a.id_angajat );
        
        select min(nr)-- minimul nr de comenzi procesate de fiecare angajat
        into min_nr_comenzi_procesate
        from (  select count(co.id_comanda) as nr
                from comanda co
                join agent_vanzari a on(co.id_angajat = a.id_angajat)-- pt a evita comenzile cu ang null
                group by a.id_angajat );

        for i in 1..t_proc.count loop-- updatez fiecare comanda cu un angajat foarte productiv (a procesat mai mult de avg de comenzi per ang) cu unul care a procesat un numar minim de comenzi pana in acel moment
            -- nr_comenzi_procesate trebuie sa fie calculat pentru fiecare comanda in parte, in partea de after statement is si nu in after ecah row is (iarasi apare error mutating)
            select count(co.id_comanda)-- nr de comenzi per angajat
            into var_nr_comenzi_procesate
            from comanda co
            join agent_vanzari a on(co.id_angajat = a.id_angajat)-- pt a evita comenzile cu ang null (in cazul in care in clauza where e null, pentru ca nu a fost asignat niciun angajat noii comenzi care nu a fost inca adaugata in baza de date)
            where co.id_angajat = t_proc(i).id_angajat;
            
            if var_nr_comenzi_procesate > avg_nr_comenzi_procesate-- ang productiv
                then
                    update comanda
                    set id_angajat = (  select a.id_angajat
                                        from comanda co
                                        join agent_vanzari a on(co.id_angajat = a.id_angajat)
                                        where a.id_angajat != t_proc(i).id_angajat
                                        group by a.id_angajat
                                        having count(co.id_comanda) = min_nr_comenzi_procesate-- selectez primul ang cu un numar mini de comenzi procesate dupa id_angajat
                                        order by co.id_angajat
                                        fetch first 1 rows only )
                    where id_comanda = t_proc(i).id_comanda;-- doar comanda curenta (adica cea care tocmai a fost adaugata in baza de date)
            end if;
        end loop;
    end after statement;
end;
/

delete from comanda;-- doar pt a vedea mai bine rezultatele, nu afecteaza count()
insert into COMANDA values(1000000048, 0, '29-OCT-24', 10015, 10000090, null);-- avg = 1/1 = 1 dar count pt 15 = 1 NU e mai mare ca avg
insert into COMANDA values(1000000050, 0, '30-NOV-24', 10015, 10000040, null);-- avg = 2/1 = 2 dar count pt 15 = 2 NU e mai mare ca avg
insert into COMANDA values(1000000052, 0, '30-NOV-24', 10015, 10000030, null);-- avg = 3/1 = 3 dar count pt 15 = 3 NU e mai mare ca avg
insert into COMANDA values(1000000054, 0, '30-NOV-24', 10025, 10000030, null);-- avg = 4/2 = 2 dar count pt 25 = 1 NU e mai mare ca avg
insert into COMANDA values(1000000056, 0, '29-OCT-24', 10025, 10000090, null);-- avg = 5/2 = 2.5 dar count pt 25 = 2 NU e mai mare ca avg
insert into COMANDA values(1000000058, 0, '29-OCT-24', 10010, 10000090, null);-- avg = 6/3 = 2 dar count pt 10 = 1 NU e mai mare ca avg
insert into COMANDA values(1000000060, 0, '29-OCT-24', 10005, 10000090, null);-- avg = 7/4 = 1.75 dar count pt 05 = 1 NU e mai mare ca avg
insert into COMANDA values(1000000062, 0, '29-OCT-24', 10020, 10000090, null);-- avg = 8/5 = 1.6 dar count pt 20 = 1 NU e mai mare ca avg
insert into COMANDA values(1000000064, 0, '29-OCT-24', 10015, 10000090, null);-- avg = 9/5 = 1.8 dar count pt 15 = 4 e mai mare ca avg
-- are de ales prima optiune dupa ordonare din (05, 10, 20) care au toate count = 1, adica alege angajatul 10005
insert into COMANDA values(1000000066, 0, '29-OCT-24', 10025, 10000090, null);-- avg = 10/5 = 2 dar count pt 25 = 3 e mai mare ca avg
-- are de ales prima optiune dupa ordonare din (10, 20) care au toate count = 1, adica alege angajatul 10010
insert into COMANDA values(1000000068, 0, '29-OCT-24', 10000, 10000090, null);-- avg = 11/6 = 1.8 dar count pt 00 = 1 NU e mai mare ca avg
insert into COMANDA values(1000000070, 0, '29-OCT-24', 10030, 10000090, null);-- avg = 12/7 = 1.7 dar count pt 30 = 1 NU e mai mare ca avg
insert into COMANDA values(1000000072, 0, '29-OCT-24', 10010, 10000090, null);-- avg = 13/7 = 1.8 dar count pt 10 = 2 e mai mare ca avg
-- are de ales prima optiune dupa ordonare din (00, 20, 30) care au toate count = 1, adica alege angajatul 10000
insert into COMANDA values(1000000074, 0, '29-OCT-24', 10030, 10000090, null);-- avg = 14/7 = 2 dar count pt 30 = 2 NU e mai mare ca avg
insert into COMANDA values(1000000076, 0, '29-OCT-24', 10030, 10000090, null);-- avg = 15/7 = 2.14 dar count pt 30 = 3 e mai mare ca avg
-- are de ales prima optiune dupa ordonare din (20) care au toate count = 1, adica alege angajatul 10020
insert into COMANDA values(1000000078, 0, '29-OCT-24', 10025, 10000090, null);-- avg = 16/7 = 2.28 dar count pt 25 = 4 e mai mare ca avg
-- are de ales prima optiune dupa ordonare din (00, 10, 20, 30) care au toate count = 2, adica alege angajatul 10000

rollback;
drop trigger update_angajat_trigger;