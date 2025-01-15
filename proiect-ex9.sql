-- ex9 nou
/* sa se afiseze pentru o materie prima piesele de mobilier care o contin
si pentru o cantitate achizitionata din piesa de mobilier cea mai vanduta sa se afiseze toate comenzile
(comanda, nr de produse din comanda, client) care o contin pe acea produsa de mobilier selectata */

create or replace procedure piese_materie_asociata_durata_maxima_coresp_comanda
(
    material materie_prima.id_material%type,
    q adauga_comanda.cantitate%type
)
is
    type info_materie_mobilier is record (
        id_prod piesa_mobilier.id_produs%type,
        nume_prod piesa_mobilier.nume%type,
        nume_mat materie_prima.tip_material%type,
        total_vanzari number
    );
    type t_materie_mobilier is table of info_materie_mobilier index by binary_integer;
    t_mobilier_detalii t_materie_mobilier;
    
    cursor c_detalii_mobilier is
        select p.id_produs, p.nume, mp.tip_material, sum(ac.cantitate)
        from adauga_comanda ac
        join piesa_mobilier p on(p.id_produs = ac.id_produs)
        join produsa_din pd on(p.id_produs = pd.id_produs)
        join materie_prima mp on(mp.id_material = pd.id_material)
        where mp.id_material = material
        group by p.id_produs, p.nume, mp.tip_material
        order by p.nume;
        
    -- cursor ciclu fara subcerere
    cursor c_toate_comenzile(id piesa_mobilier.id_produs%type) is
        select distinct(id_comanda), cantitate
        from adauga_comanda
        where id_produs = id;
    
    type info_clienti_comanda is record (
        cod_client client.id_client%type,
        cod_comanda comanda.id_comanda%type,
        data_achiz comanda.data_achizitie%type,
        plata tranzactie.modalitate_plata%type
    );
    type t_clienti_comanda is table of info_clienti_comanda index by binary_integer;
    t_comenzi_detalii t_clienti_comanda;
    
    cursor c_detalii_comenzi(id piesa_mobilier.id_produs%type) is
        select c.id_client, co.id_comanda, co.data_achizitie, t.modalitate_plata
        from client c
        join comanda co on(c.id_client = co.id_client)
        join tranzactie t on(t.id_comanda = co.id_comanda)
        join adauga_comanda ac on(co.id_comanda = ac.id_comanda)-- doar pentru parametrul din cursor, cantitatea cautata si moment_timp
        where ac.id_produs = id
        and ac.cantitate = q
        group by c.id_client, co.id_comanda, co.data_achizitie, t.modalitate_plata
        order by co.id_comanda;
    
    -- computarea maximului de vanzari
    max_total_vanzari number := 0;
    id_produs_selectat piesa_mobilier.id_produs%type;
    
    timestamp_primul_produs adauga_comanda.moment_timp%type;
    timestamp_ultimul_produs adauga_comanda.moment_timp%type;
    durata_plasare_produse interval day to second;
    
    no_furniture exception;
    no_orders exception;
begin
    -- detaliile pieselor de mobilier care contin materia prima
    open c_detalii_mobilier;
    fetch c_detalii_mobilier bulk collect into t_mobilier_detalii;
    
    dbms_output.put_line('Detalii piese mobilier ce contin materialul '||material||': ');
    if t_mobilier_detalii.count = 0
        then
            raise no_furniture;
    end if;
    
    for i in 1..t_mobilier_detalii.count loop
        dbms_output.put_line('  Piesa de mobilier '||t_mobilier_detalii(i).id_prod||' '||t_mobilier_detalii(i).nume_prod||' e asociata materialului '||t_mobilier_detalii(i).nume_mat);
        dbms_output.put_line('  total vanzari: '||t_mobilier_detalii(i).total_vanzari);
        for com in c_toate_comenzile(t_mobilier_detalii(i).id_prod) loop
            dbms_output.put_line('      Comanda '||com.id_comanda||' (cantitate produs = '||com.cantitate||'): ');
            dbms_output.put_line('      Toate produsele din comanda curenta (care sunt aprovizionate la un magazin): ');-- pot exista produse din comanda care sa nu faca parte dintr-un triplet de forma (id_produs, id_magazin, id_stoc), care nu vor fi afisate
            -- cursor ciclu cu o subcerere
            for prod in (select p.nume as produs, p.id_produs as id_prod, a.id_stoc as stoc, a.id_magazin as mag
                     from piesa_mobilier p
                     join adauga_comanda ac on(ac.id_produs = p.id_produs)
                     join comanda co on(co.id_comanda = ac.id_comanda)
                     join aprovizioneaza a on(a.id_produs = p.id_produs)
                     where co.id_comanda = com.id_comanda) loop
            
                dbms_output.put_line('          Produsul '||prod.produs||' (id: '||prod.id_prod||'), se afla in stocul '||prod.stoc||' si magazinul '||prod.mag);
            end loop;
        end loop;
    end loop;

    for i in 1..t_mobilier_detalii.count loop
        if t_mobilier_detalii(i).total_vanzari >= max_total_vanzari
            then
                max_total_vanzari := t_mobilier_detalii(i).total_vanzari;
                id_produs_selectat := t_mobilier_detalii(i).id_prod;
        end if;
    end loop;

    dbms_output.put_line('  Produsul selectat este '||id_produs_selectat||' avand numarul total de vanzari de '||max_total_vanzari);
    
    close c_detalii_mobilier;
    
    -- id-ul produsului a fost gasit si se vor afisa comenzile (via un id ca parametru in cursor) pentru care cantitatea specificata ca parametru in subprogram din acel produs exista
    open c_detalii_comenzi(id_produs_selectat);
    fetch c_detalii_comenzi bulk collect into t_comenzi_detalii;

    if t_comenzi_detalii.count = 0
        then
            raise no_orders;
    end if;

    dbms_output.put_line('cantitate: '||q||', t_comenzi_detalii:');
    for i in 1..t_comenzi_detalii.count loop
        dbms_output.put_line('  Comanda '||t_comenzi_detalii(i).cod_comanda||' a fost plasata de clientul cu id-ul '||t_comenzi_detalii(i).cod_client||', fiind asociata tranzactia cu tipul de plata '||t_comenzi_detalii(i).plata);
        dbms_output.put_line('      data achizitie: '||t_comenzi_detalii(i).data_achiz);
        
        select min(moment_timp), max(moment_timp), (max(moment_timp) - min(moment_timp))
        into timestamp_primul_produs, timestamp_ultimul_produs, durata_plasare_produse
        from adauga_comanda
        where id_comanda = t_comenzi_detalii(i).cod_comanda;
        
        dbms_output.put_line('      timestamp de inceput (plasarea primului produs): '||timestamp_primul_produs||', timestamp de final (plasarea ultimului produs): '||timestamp_ultimul_produs);
        dbms_output.put_line('      durata plasarii tuturor produselor in cos pentru comanda curenta a fost de: '||durata_plasare_produse);
    end loop;
    
    close c_detalii_comenzi;

exception
    when no_furniture then 
        dbms_output.put_line('Nicio piesa de mobilier asociata materialului '||material);
    when no_orders then 
        dbms_output.put_line('Nicio comanda asociata produsului gasit avand cantitatea '||q);
end;
/
begin
    piese_materie_asociata_durata_maxima_coresp_comanda(5000000012, 2);
    -- exceptia no_furniture deoarece 5000000012 nu e material care apartine niciunui produs
    dbms_output.put_line('');
    piese_materie_asociata_durata_maxima_coresp_comanda(5000000036, 2);
    -- nicio exceptie deoarece dintre comenzile care contin 400017, doar 1000000022 are acest produs in cantitatea de 2
    dbms_output.put_line('');
    piese_materie_asociata_durata_maxima_coresp_comanda(5000000021, 1);
    -- am aratat ca pot exista mai multe produse cu acelasi material, 400002 si 400024
    -- nicio exceptie
    dbms_output.put_line('');
    piese_materie_asociata_durata_maxima_coresp_comanda(5000000030, 1);
    -- exceptia no_order deoarece dintre comenzile care contin 400017, doar 1000000022 are acest produs in cantitatea de 2
    dbms_output.put_line('');
    piese_materie_asociata_durata_maxima_coresp_comanda(5000000009, 5);
    -- nicio exceptie, am aratat ca daca 400007, produsul selectat, se gaseste in aceeasi cantitate de 5 in 2 comenzi, ambele comenzi vor fi afisate
    dbms_output.put_line('');
end;
/