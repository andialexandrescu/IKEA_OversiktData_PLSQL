--ex10
/*sa se afiseze modificarile dupa inserarea unei linii din tabela adauga_comanda (avand conditia sa fie la un moment de timp
mai mare decat cele introduse in tabela pana in acel moment), care preia id-ul produsului si actualizeaza stocul lui din tabela
detalii_produse, stiind ca stocul va fi actualizat indifrenet daca exista mai multe stocuri pentru acelasi produs
(pt a vedea posibilitatea de aprovizionare a tuturor stocurilor care contin produsul respectiv). in plus, se actualizeaza
si data stocului, deoarece tocmai a fost modificata*/

-- logica e buna ca declansatorul sa fie la nivel de instructiune si nu linie pentru fiecare inregistrare
create or replace trigger modif_stoc
    after insert on adauga_comanda
declare
    var_id_produs piesa_mobilier.id_produs%type;
    
    var_stoc_curent detalii_produse.cantitate_stoc_produs%type;
    var_id_stoc detalii_produse.id_stoc%type;
    
    var_q adauga_comanda.cantitate%type;
    var_timp_plasare adauga_comanda.moment_timp%type;
    
    var_detalii_stoc number;

    cursor c_cantitate_disp (id piesa_mobilier.id_produs%type) is
        select cantitate_stoc_produs, id_stoc-- toate produsele si cantitatea lor la nivel de stoc doar
        from detalii_produse
        where id_produs = id;

begin
    select a.id_produs, a.cantitate, a.moment_timp
    into var_id_produs, var_q, var_timp_plasare
    from adauga_comanda a
    join comanda co on(co.id_comanda = a.id_comanda)
    order by a.moment_timp desc, a.id_produs asc-- nu vor exista doua inregistrari cu acelasi id_produs la aceeasi comanda, deci nu va aparea niciodata too many results fetched
    fetch first 1 rows only;-- se proceseaza ultimul produs adaugat la comanda, la o ultimul moment_timp inregistrat

    open c_cantitate_disp(var_id_produs);
    loop
        fetch c_cantitate_disp into var_stoc_curent, var_id_stoc;
        exit when c_cantitate_disp%notfound;

        if var_stoc_curent >= var_q
            then
                update detalii_produse
                set cantitate_ceruta_produs = cantitate_ceruta_produs + var_q, cantitate_stoc_produs = cantitate_stoc_produs - var_q, data_ultim_stoc = to_char(var_timp_plasare, 'DD-MON-YYYY')
                where id_produs = var_id_produs
                and id_stoc = var_id_stoc;-- modific produsul din stocul respectiv
        else
            raise_application_error(-20001, 'Stoc insuficient pentru produsul '||var_id_produs||' in stocul '||var_id_stoc||' cu o capacitate de '||var_stoc_curent);
        end if;

    end loop;
    close c_cantitate_disp;

end;
/

insert into COMANDA values(1000000046, 0, '29-OCT-24', null, 10000090, null);
insert into TRANZACTIE values(1000000047, 'card', 'in procesare', 1000000046);
--insert into ADAUGA_COMANDA values(400012, 1000000046, 2, '29-OCT-24 10:20:09');
--insert into ADAUGA_COMANDA values(400012, 1000000046, 1, '29-OCT-24 10:20:09');
insert into ADAUGA_COMANDA values(400009, 1000000046, 4, '29-OCT-24 10:20:09');
-- nu se modifica niciuna dintre cele doua inregistrari cu produsul 400009, cu toate ca numai una nu satisface conditia,
-- iar cantitate_ceruta_produs ramane la valoarea 10, nemodificandu-se cu 14
insert into ADAUGA_COMANDA values(400023, 1000000046, 22, '29-OCT-24 10:25:09');
-- se elimina inca 22 de produse cu codul 400023 dintr-un stoc

rollback;
drop trigger modif_stoc;