--ex 7
/* sa se afiseze numele magazinelor, impreuna cu data aprovizionarii a caror piese de mobilier dintr-o lista data
se afla la oferta in anul 2024/ 2021 si sunt valabile in stocul magazinului respectiv*/

-- variabila globala
create or replace type lista_piese_mobilier as varray(15) of number(6,0);
/
show errors
create or replace type coduri_locatii_table is table of number(6,0);
/
show errors
create or replace procedure magazine_cu_piese_mobilier_la_oferta
(
    v_id_piese_mobilier_cautate in lista_piese_mobilier,
    t_locatii out coduri_locatii_table
)
is
-- cursoarele vor fi pentru magazin si piesa mobilier
    var_id_produs piesa_mobilier.id_produs%type;
    var_nume_piesa_mobilier piesa_mobilier.nume%type;
    -- cursor dinamic
    type piesa_mobilier_rec is record (
        id_produs piesa_mobilier.id_produs%type,
        nume piesa_mobilier.nume%type
    );
    type c is ref cursor return piesa_mobilier_rec;
    c_produse c;
    
    type info_magazin_oferta is record (
        cod_magazin magazin.id_magazin%type,
        id_stoc stoc.id_stoc%type,
        marfa_adusa stoc.data_aprovizionare%type,
        oras adresa.oras%type,
        locatie adresa.strada%type,
        oferta_inceput oferta.data_inceput%type,
        oferta_sfarsit oferta.data_sfarsit%type
    );
    var_magazin info_magazin_oferta;
    -- cursor parametrizat (dependent de cursorul c_produse)
    cursor c_magazine(id piesa_mobilier.id_produs%type) is
        select distinct m.id_magazin, s.id_stoc, ap.data_aprovizionare, a.oras, a.strada, o.data_inceput, o.data_sfarsit
        from piesa_mobilier p
        join oferta o on(o.id_produs = p.id_produs)
        join aprovizioneaza ap on(ap.id_produs = p.id_produs)
        join magazin m on(m.id_magazin = ap.id_magazin)
        join stoc s on(s.id_stoc = ap.id_stoc and ap.data_aprovizionare = s.data_aprovizionare)
        join adresa a on(a.cod_postal = m.cod_postal)
        where ap.id_produs = id
        and ap.cantitate != 0-- eventual la un trigger cand se adauga in comanda poate deveni 0 (in plus ap.cantitate nu va fi niciodata null)
        and (to_char(ap.data_aprovizionare, 'YYYY') = 2024 or to_char(ap.data_aprovizionare, 'YYYY') = 2021)
        and to_char(ap.data_aprovizionare, 'YYYY') = to_char(o.data_inceput, 'YYYY')
        and s.data_aprovizionare >= o.data_inceput and s.data_aprovizionare <= o.data_sfarsit;
        
    piesa_mobilier_gasita_magazin boolean;-- doar pentru o afisare corecta in cazul in care piesa de mobilier nu e in oferta si in stoc la niciun magazin
    
    contor integer := 1;
    cod adresa.cod_postal%type;
    cod_gasit boolean;
begin
    t_locatii := coduri_locatii_table();
    open c_produse for
        select id_produs, nume
        from piesa_mobilier
        where id_produs in ( select * from table(v_id_piese_mobilier_cautate) );
        
        loop
            fetch c_produse into var_id_produs, var_nume_piesa_mobilier;
            exit when c_produse%notfound;-- atunci cand select into nu mai returneaza niciun rand
            
            piesa_mobilier_gasita_magazin := false;
            dbms_output.put_line('Piesa de mobilier '||var_nume_piesa_mobilier||' e disponibila la oferta in stoc la magazinele:');
            -- deschid cursorul parametrizat cu param din primul cursor
            open c_magazine(var_id_produs);
            loop
                fetch c_magazine into var_magazin;
                exit when c_magazine%notfound;
                    
                piesa_mobilier_gasita_magazin := true;
                dbms_output.put_line('  ANUNT '||to_char(var_magazin.marfa_adusa, 'YYYY'));
                dbms_output.put_line('      id_magazin: '||var_magazin.cod_magazin||', id_stoc: '||var_magazin.id_stoc||', data aprovizionare: '||var_magazin.marfa_adusa||', locatie: '||var_magazin.oras||' '||var_magazin.locatie);
                dbms_output.put_line('      data la care a inceput oferta: '||var_magazin.oferta_inceput);
                dbms_output.put_line('      data la care s-a sfarsit/ se va sfarsi oferta: '||var_magazin.oferta_sfarsit);
                
                select cod_postal
                into cod
                from adresa
                where oras = var_magazin.oras and strada = var_magazin.locatie;
                
                cod_gasit := false;
                for i in 1..t_locatii.count loop
                    if t_locatii(i) = cod then
                        cod_gasit := true;-- daca codul exista deja in t_locatii nu mai e adaugat (vreau coduri distincte)
                        exit;-- break
                    end if;
                end loop;
                if cod_gasit = false-- altfel se adauga la t_locatii
                    then
                        t_locatii.extend();
                        t_locatii(contor) := cod;
                        contor := contor + 1;
                end if;
            end loop;
                
            if piesa_mobilier_gasita_magazin = false
                then 
                    dbms_output.put_line('Piesa de mobilier '||var_nume_piesa_mobilier||' nu e in oferta si in stoc la niciun magazin');
            end if;
                
            close c_magazine;
        end loop;
    
    close c_produse;
    
end;
/
declare
    t_coduri_locatii coduri_locatii_table;
    v_lista lista_piese_mobilier := lista_piese_mobilier(400002,400010,400007,400012,400011,400007,400003);
    contor integer;
begin
    magazine_cu_piese_mobilier_la_oferta(v_lista, t_coduri_locatii);
    dbms_output.put_line('Id-urile tuturor locatiilor distincte gasite sunt: ');
    if t_coduri_locatii.count > 0
        then
            for contor in 1..t_coduri_locatii.count loop
                dbms_output.put_line(t_coduri_locatii(contor));
            end loop;
        else
            dbms_output.put_line('Nu a fost gasita nicio locatie');
    end if;
end;
/