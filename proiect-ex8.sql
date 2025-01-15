--ex 8
/* sa se afiseze toate piesele de mobilier care au cel putin o materie prima asociata,
fiind data o lista de comenzi (pot exista comenzi pentru care ar putea sa dea no_data_found la produse
avand materiale asociate, no_data_found daca exista produse fara materiale asociate in comanda curenta verificata din
lista de comenzi) si pentru piesele de mobilier gasite (ca avand materiale asociate in comenzile indicate) sa se afiseze angajatul care a
procesat comanda (doresc exact un rezultat de acest tip - too_many_rows/no_data_found)
*/
create or replace function verifica_procesare_piese_mobilier
(
    var_id_comanda_cautata in comanda.id_comanda%type
) return varchar
is
    var_msg varchar2(5000);-- ce returneaza functia (detalii comenzi cu cel putin un produs care are materia prima asociata)
    
    var_id_comanda comanda.id_comanda%type;
    var_nume_agent agent_vanzari.nume%type;
    
    var_id_produs piesa_mobilier.id_produs%type;
    var_nume_piesa_mobilier piesa_mobilier.nume%type;
    var_piesa_mobilier_material_gasita boolean := false;
    cursor c_produse(id comanda.id_comanda%type) is-- piesele de mobilier asociate cu materii prime pentru comanda curenta
        select p.id_produs, p.nume
        from piesa_mobilier p
        join adauga_comanda ac on(ac.id_produs = p.id_produs)
        where ac.id_comanda = id-- coresp parametru cursor parametrizat
        and exists (-- subcerere corelata
                    select 1
                    from produsa_din pd
                    where pd.id_produs = p.id_produs
                    );
    
    no_materials_associated_for_order exception;-- exceptie definita de mine, rescriu no_data_found deoarece poate sa apara si la agenti 
begin
    select id_comanda
    into var_id_comanda
    from comanda
    where id_comanda = var_id_comanda_cautata;
    
    var_msg := var_msg||'Comanda '||var_id_comanda||' are urmatorele piese de mobilier:'||chr(10);
    open c_produse(var_id_comanda);
    loop
        fetch c_produse into var_id_produs, var_nume_piesa_mobilier;
        exit when c_produse%notfound;
        var_piesa_mobilier_material_gasita := true;
        var_msg := var_msg||'   Procesare validata produse...'||chr(10);
        var_msg := var_msg||'      Produsul '||var_nume_piesa_mobilier||' are cel putin un material asociat'||chr(10);
        begin
            select a.nume
            into var_nume_agent
            from agent_vanzari a
            join comanda c on(c.id_angajat = a.id_angajat)
            join adauga_comanda ac on(ac.id_comanda = c.id_comanda)
            where ac.id_produs = var_id_produs;
            
            var_msg := var_msg||'   Procesare validata pentru exact un agent de vanzari care a prelucrat produsul '||var_nume_piesa_mobilier||'...'||chr(10);
            var_msg := var_msg||'       Produsul a fost procesat (intr-o comanda sau mai multe) de un singur angajat pe nume '||var_nume_agent||chr(10);
            var_msg := var_msg||'      Piesa: '||var_nume_piesa_mobilier||' - Procesata de: '||var_nume_agent||chr(10);
        exception
            when no_data_found then
                var_msg := var_msg||'        Exceptie no_data_found: Nu au fost gasiti angajati care sa fi procesat produsul '||var_nume_piesa_mobilier||chr(10);
            when too_many_rows then
                var_msg := var_msg||'   Exceptie too_many_rows: Prea multi angajati care au procesat piesa de mobilier in doua sau mai multe comenzi'||chr(10);
                var_msg := var_msg||'   Rezolvare exceptie: se ia doar un singur angajat'||chr(10);
                select nume
                into var_nume_agent
                from (  select a.nume
                        from agent_vanzari a
                        join comanda c on(c.id_angajat = a.id_angajat)
                        join adauga_comanda ac on(ac.id_comanda = c.id_comanda)
                        where ac.id_produs = var_id_produs
                        and rownum = 1
                    );
                var_msg := var_msg||'       Produsul a fost procesat (intr-o comanda sau mai multe) de un singur angajat pe nume '||var_nume_agent||chr(10);
        end; 
    end loop;
        
    if not var_piesa_mobilier_material_gasita
        then
            raise no_materials_associated_for_order;
    end if;
    
    return var_msg;
    
exception
    when no_data_found then
    var_msg := 'Exceptie no_data_found: Niciun rezultat intors, no_data_found general';
        return var_msg;
    when no_materials_associated_for_order then
        var_msg := var_msg||'Exceptie no_materials_associated_for_order: Nicio piesa de mobilier din comanda nu are asociata cel putin o materie prima';
        return var_msg;
    when others then
        var_msg := var_msg||'Exceptie necunoscuta: '||sqlerrm;
        return var_msg;
end;
/
declare
    v_id comanda.id_comanda%type;
begin
    v_id := 1000000008;
    -- 1000000008 ramane pt ca nu intalneste nicio exceptie (produsul 400002 ENHET care are cel putin o materie asociata face parte dintr-o singura comanda deci e prelucrata de un singur agent)
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
    dbms_output.put_line('');
    v_id := 1000000000;
    -- 1000000000 ramane pt a arata exceptia no_materials (produsele 400009 si 400012 nu au asociate materiale)(de mentionat ca are produsul 400009 in comun cu 1000000010 si 1000000026 si produsul 400009 cu 10000000026)
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
    dbms_output.put_line('');
    v_id := 1000000030;
    -- 1000000030 ramane pentru a arata exceptia no_data_found (are un singur produs 400024 care are material asociat si care nu se mai regaseste in nicio alta comanda in afara de cea curenta deci daca comanda curenta nu e prelucrata de un angajat inseamna ca produsul nu e prelucrat de nimeni)
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
    dbms_output.put_line('');
    v_id := 1000000026;
    /* 1000000026 ramane pt a arata exceptia too_many_rows (produsul care are cel putin un material asociat 400007 si face parte din comenzile 1000000026 si 1000000016, e prelucrat de angajatii 10000(comanda 1000000026) si 10030(comanda 1000000016))
    de retinut ca la 1000000026 produsul 400008 FINNBY (celalalt care are materie asociata) e in comun cu o alta comanda dar comanda 1000000024 are angajatul null, deci pentru produsul acesta nu va intampina nicio exceptie */
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
    dbms_output.put_line('');
end;
/