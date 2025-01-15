--ex13
/* se considera un pachet care gestioneaza vanzarile, continand 2 proceduri si 2 functii
ce folosesc ca variabile globale cursoare si tablouri:
un tablou va descrie materialele pieselor de mobilier (tip_material, unitati, pret_productie(=pret_unitate*unitati))
un alt tablou care ofera informatii despre comenzile unor clienti dati care sunt la oferta
*/

drop package gestionare_vanzari;
create or replace package gestionare_vanzari as
    -- 2 tipuri complexe ca variabile globale
-- tablou indexat cu materialele pieselor de mobilier pentru procedura afiseaza_materiale_produse_la_oferta
    type info_productie is record (
        nume_produs piesa_mobilier.nume%type,
        pret_produs piesa_mobilier.pret%type,
        pret_productie_produs number,
        profit number
    );
    type temp_materiale is table of info_productie index by binary_integer;
    t_lista_m temp_materiale;

-- tablou imbricat care ofera informatii despre comenzi aflate la oferta pentru procedura afiseaza_procent_clienti_cu_oferte
    type info_comenzi_oferta is record (
        id_client client.id_client%type,
        id_comanda comanda.id_comanda%type,
        id_produs piesa_mobilier.id_produs%type,
        pret_produs piesa_mobilier.pret%type,
        cantitate adauga_comanda.cantitate%type,
        pret_neredus_total number,
        oferta_discount oferta.discount%type,
        pret_discounted_unitate number,
        pret_discounted_total number,
        oferta_inceput oferta.data_inceput%type,
        oferta_sfarsit oferta.data_sfarsit%type
    );
    type lista_comenzi is table of info_comenzi_oferta;
    t_comenzi lista_comenzi;

    function verifica_oferta_client(p_id_client in client.id_client%type) return boolean;
    function calcul_total_produse_la_oferta(p_id_comanda in comanda.id_comanda%type) return number;
    procedure afiseaza_materiale_produse_la_oferta(p_id_comanda in comanda.id_comanda%type);
    procedure afiseaza_clienti_cu_oferte;
    
end gestionare_vanzari;
/
create or replace package body gestionare_vanzari as

    function verifica_oferta_client
    (
        p_id_client in client.id_client%type
    ) return boolean
    is
        count_comenzi_oferta number;
    begin
        select count(distinct ac.id_comanda) -- distinct e necesar altfel se considera o comanda de mai multe ori daca sunt mai multe produse din acea comanda la oferta
        into count_comenzi_oferta
        from adauga_comanda ac
        join comanda co on(ac.id_comanda = co.id_comanda)
        join oferta o on(ac.id_produs = o.id_produs)
        where co.data_achizitie>=o.data_inceput and co.data_achizitie<=o.data_sfarsit
        and co.id_client = p_id_client;

        if count_comenzi_oferta > 0
            then
                return true;
        end if;
        return false;
    end verifica_oferta_client;
    
    function calcul_total_produse_la_oferta
    (
        p_id_comanda in comanda.id_comanda%type
    ) return number
    is
        count_produse_oferta number;
    begin
        select nvl(sum(a.cantitate), 0)
        into count_produse_oferta
        from adauga_comanda a
        join comanda co on(a.id_comanda = co.id_comanda)
        join oferta o on(a.id_produs = o.id_produs)
        where co.data_achizitie>=o.data_inceput and co.data_achizitie<=o.data_sfarsit
        and a.id_comanda = p_id_comanda;

        return count_produse_oferta;
    end calcul_total_produse_la_oferta;
    
    procedure afiseaza_materiale_produse_la_oferta
    (
        p_id_comanda in comanda.id_comanda%type
    )
    is
    begin
        t_lista_m := temp_materiale();
        dbms_output.put_line('  Ma aflu in afiseaza_materiale_produse_la_oferta');
        -- verific daca comanda data are sau nu produse la oferta
        if calcul_total_produse_la_oferta(p_id_comanda) > 0  then
            -- mereu se reseteaza inainte de a se popula pentru a nu retine materialele dintr-o alta comanda (in cazul in care se apeleaza procedura de mai mult de o data) 
            t_lista_m.delete;

            select p.nume, p.pret, sum(to_number(m.pret_unitate)*to_number(pd.unitati)), p.pret-sum(to_number(m.pret_unitate)*to_number(pd.unitati))
            bulk collect into t_lista_m
            from piesa_mobilier p
            -- sectiune join pt productie materiale
            join produsa_din pd on(p.id_produs = pd.id_produs)
            join materie_prima m on(pd.id_material = m.id_material)
            -- sectiune join pt oferta
            join adauga_comanda a on(a.id_produs = p.id_produs)
            join oferta o on(p.id_produs = o.id_produs)
            join comanda co on(a.id_comanda = co.id_comanda)
            where co.data_achizitie>=o.data_inceput and co.data_achizitie<=o.data_sfarsit-- oferta in vigoare
            and co.id_comanda = p_id_comanda
            group by p.nume, p.pret;

            if t_lista_m.count = 0
                then
                    dbms_output.put_line('      Comanda '||p_id_comanda||' are produse la oferta, insa acestea nu au materiale asociate');
            else
                for i in 1..t_lista_m.count loop
                    dbms_output.put_line('      Cu toate ca exista produsul '||t_lista_m(i).nume_produs||' la oferta in comanda '||p_id_comanda||', profitul firmei pentru produsul curent este '||t_lista_m(i).profit);
                    dbms_output.put_line('          nume produs: '||t_lista_m(i).nume_produs);
                    dbms_output.put_line('          pret unitar produs: '||t_lista_m(i).pret_produs||', pret productie produs: '||t_lista_m(i).pret_productie_produs);
                    dbms_output.put_line('          profit: '||t_lista_m(i).profit);
                end loop;
            end if;
            
        else
            dbms_output.put_line('      Comanda '||p_id_comanda||' nu are produse la oferta');
        end if;
    end afiseaza_materiale_produse_la_oferta;
    
    procedure afiseaza_clienti_cu_oferte
    is
        cursor c_clienti is
            select id_client from client;
    begin
        t_comenzi := lista_comenzi();
        
        for rec in c_clienti loop-- cursor ciclu
            if verifica_oferta_client(rec.id_client)
                then
                    dbms_output.put_line('Clientul '||rec.id_client||' a beneficiat de cel putin o oferta');
                    
                    select co.id_client, co.id_comanda, p.id_produs, p.pret, a.cantitate, p.pret*a.cantitate, o.discount, round(p.pret*(100-o.discount)/100, 2), round(p.pret*(100-o.discount)/100, 2)*a.cantitate, o.data_inceput, o.data_sfarsit
                    bulk collect into t_comenzi
                    from comanda co
                    join adauga_comanda a on(a.id_comanda = co.id_comanda)
                    join piesa_mobilier p on(a.id_produs = p.id_produs)
                    join oferta o on p.id_produs = o.id_produs
                    where co.data_achizitie>=o.data_inceput and co.data_achizitie<=o.data_sfarsit
                    and co.id_client = rec.id_client
                    order by co.id_comanda, p.id_produs;
                    
                    for i in 1..t_comenzi.count loop
                        if i = 1 or t_comenzi(i).id_comanda != t_comenzi(i-1).id_comanda-- daca id-ul comenzii s-a schimbat
                            then
                                dbms_output.put_line('Ma aflu in afiseaza_clienti_cu_oferte');
                                dbms_output.put_line('  id client: '||t_comenzi(i).id_client||', id comanda: '||t_comenzi(i).id_comanda||', id produs: '||t_comenzi(i).id_produs);
                                dbms_output.put_line('  pret produs unitate: '||t_comenzi(i).pret_produs||', pret produs discounted unitate: '||t_comenzi(i).pret_discounted_unitate);
                                dbms_output.put_line('  cantitate produs in comanda: '||t_comenzi(i).cantitate);
                                dbms_output.put_line('  pret produs * cantitate: '||t_comenzi(i).pret_neredus_total||', pret produs discounted * cantitate: '||t_comenzi(i).pret_discounted_total);
                                dbms_output.put_line('  inceput oferta: '||t_comenzi(i).oferta_inceput||', sfarsit oferta: '||t_comenzi(i).oferta_sfarsit);
                                afiseaza_materiale_produse_la_oferta(t_comenzi(i).id_comanda);-- se apeleaza procedura afiseaza_materiale_produse_la_oferta pentru fiecare comanda distincta
                                dbms_output.put_line('');
                        end if;
                    end loop;
            else
                dbms_output.put_line('Clientul '||rec.id_client||' nu a beneficiat de nicio oferta');
            end if;
            dbms_output.put_line('');
            dbms_output.put_line('');
        end loop;
        
    end afiseaza_clienti_cu_oferte;
    
end gestionare_vanzari;
/
declare
    total_produse number;
begin
    gestionare_vanzari.afiseaza_clienti_cu_oferte;
    if gestionare_vanzari.verifica_oferta_client(10000090) then
        dbms_output.put_line('Clientul a beneficiat de cel putin o oferta');
    else
        dbms_output.put_line('Clientul nu a beneficiat de nicio oferta');
    end if;
    total_produse := gestionare_vanzari.calcul_total_produse_la_oferta(1000000026);
    dbms_output.put_line(total_produse);
    gestionare_vanzari.afiseaza_materiale_produse_la_oferta(1000000026);
end;
/