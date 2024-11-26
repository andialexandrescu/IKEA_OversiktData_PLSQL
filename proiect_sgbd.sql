-- lab plsql
--e6 lab plsql 1
--a)
variable rezultat varchar2(1000)

begin
    select c.nume
    into :rezultat
    from categorie c
    join piesa_mobilier p on(p.id_categorie = c.id_categorie)
    group by c.nume
    having count(*) = ( select max(count(*))
                        from piesa_mobilier
                        group by id_categorie )
    fetch first 1 rows only;

    dbms_output.put_line('Categoria cu cele mai multe produse este: ' || :rezultat);
end;
/
print rezultat
--b)

set verify off;

declare
    v_cod_client client.id_client%type := &p_cod;
    v_total_comanda comanda.pret%type;
    v_maxim_suma_comenzi comanda.pret%type;
    v_discount number(2);
begin
    select sum(pret)
    into v_total_comanda
    from comanda
    where id_client = v_cod_client
    group by id_client;
    
    select max(total_cheltuieli)
    into v_maxim_suma_comenzi
    from (
        select sum(pret) as total_cheltuieli
        from comanda
        where id_client = v_cod_client
        group by id_client
    );

    if v_total_comanda is null then
        dbms_output.put_line('Nu exista comenzi pentru clientul cu id-ul '||v_cod_client);
    else
        if v_total_comanda>v_maxim_suma_comenzi*0.75 then
            v_discount := 10;
        elsif v_total_comanda>v_maxim_suma_comenzi*0.5 then
            v_discount := 5;
        else
            v_discount := 2;
        end if;

        dbms_output.put_line('Pretul total al comenzilor pentru clientul cu id-ul '||v_cod_client||' este: '||v_total_comanda);
        dbms_output.put_line('Maximul sumei comenzilor pentru clientul curent este: '||v_maxim_suma_comenzi);
        dbms_output.put_line('Discountul aplicat este: '||v_discount||'%');
    end if;
end;
/
set verify on;

--c)
-- var de substitutie
define p_cod_magazin_nou = to_char('7TY6');

declare
    v_cod_magazin_nou magazin.id_magazin%type := &p_cod_magazin_nou;
    v_avg_pret comanda.pret%type;
begin
    select avg(total_pret)
    into v_avg_pret
    from (
        select a.id_angajat, sum(c.pret) as total_pret
        from comanda c
        join agent_vanzari a on a.id_angajat = c.id_angajat
        group by a.id_angajat
    );

    update agent_vanzari
    set id_magazin = v_cod_magazin_nou
    where id_angajat in (
        select c.id_angajat
        from comanda c
        join agent_vanzari a on a.id_angajat = c.id_angajat
        group by c.id_angajat
        having sum(c.pret) > v_avg_pret
    );

    if sql%rowcount = 0 then
        dbms_output.put_line('Nu exista agenti care sa indeplineasca conditiile');
        rollback;
    else
        dbms_output.put_line('Actualizare realizata');
        --commit;
    end if;
end;
/
rollback;
-- lab plsq2
--e4 lab plsql 2
--a)
create or replace type clauze_contract as varray(10) of varchar2(100);
/ 

create table furnizor_detalii as
select 
    id_furnizor,
    nume,
    telefon,
    cast(null as clauze_contract) as clauze
from furnizor;

begin
    update furnizor_detalii 
    set clauze = clauze_contract('Livrare rapida la sediul firmei', 'Nu raspundem in caz de livrare neefectuata')
    where id_furnizor = 'ADS';
    
    update furnizor_detalii 
    set clauze = clauze_contract('Plata in avans pentru materiale care au in compozitie lemn', 'Transport inclus', 'Garantare calitate materiale') 
    where id_furnizor = 'OO03';
    
    update furnizor_detalii 
    set clauze = clauze_contract('Pentru o intelegere de parteneriat e nevoie de un contract semnat la sediul nostru')
    where id_furnizor = '1S';
    -- restul furnizorilor raman null la clauze_contract
    commit;
end;
/

select * from furnizor_detalii;

declare
    v_clauze clauze_contract;
    v_cod_furnizor varchar2(5);
begin
    v_cod_furnizor := '&cod';
    
    select clauze
    into v_clauze
    from furnizor_detalii
    where id_furnizor = v_cod_furnizor;

    for i in v_clauze.first .. v_clauze.last loop
        dbms_output.put_line('clauza '||i||': ' || v_clauze(i));
    end loop;
end;
/

drop table furnizor_detalii;
drop type clauze_contract;

--b)
create or replace type tip_telefon is table of varchar2(12);

alter table furnizor_detalii-- se adauga campul pt telefoane care e imbricat
add (telefoane tip_telefon)
nested table telefoane store as tabel_telefoane;

insert into furnizor_detalii
values ('G0A1', 'Simona Dureci', '+40741236667', clauze_contract(null), tip_telefon('+40776398888', '+40721654321', '+40772123456'));

update furnizor_detalii
set telefoane = tip_telefon('+07398765143', '+40755533521')
where id_furnizor = 'OO03';

commit;

select a.id_furnizor, a.nume, a.telefon as telefon_principal, a.clauze, b.column_value as telefon_suplimentar
from furnizor_detalii a, table(a.telefoane) b;-- despacheteaza tabelul imbricat a.telefoane in randuri individuale pt fiecare telefon suplimentar existent din lista

drop table furnizor_detalii;
drop type tip_telefon;



--new pt a avea un ex7 frumos
insert into STOC values('DFGTY', '29-MAY-24');
insert into STOC values('OUNDS', '01-JUNE-24');
insert into STOC values('BSJUY', '03-JUNE-24');
insert into STOC values('DFGTY', '24-MAY-24');
insert into STOC values('AGFJK', '06-DECEMBER-21');
insert into STOC values('DFGTY', '07-SEPTEMBER-21');
insert into STOC values('OUNDS', '09-DECEMBER-21');
insert into APROVIZIONEAZA values('56GH', 400002, 'DFGTY', '29-MAY-24', 3);
insert into APROVIZIONEAZA values('09OP', 400010, 'OUNDS', '1-JUN-24', 10);
insert into APROVIZIONEAZA values('234Y', 400007, 'BSJUY', '3-JUN-24', 25);
insert into APROVIZIONEAZA values('45E', 400012, 'DFGTY', '24-MAY-24', 1);
insert into APROVIZIONEAZA values('10UP', 400011, 'AGFJK', '6-DEC-21', 34);
insert into APROVIZIONEAZA values('234Y', 400007, 'DFGTY', '7-SEP-21', 35);
insert into APROVIZIONEAZA values('09OP', 400003, 'OUNDS', '9-DEC-21', 68);
--modif comenzi 08, 10, 26, 28, 24(null)
update comanda set id_angajat = '10010' where id_comanda = 1000000008;
update comanda set id_angajat = '10025' where id_comanda = 1000000010;
update comanda set id_angajat = '10000' where id_comanda = 1000000026;
update comanda set id_angajat = '10030' where id_comanda = 1000000028;
update comanda set id_angajat = null where id_comanda = 1000000024;
insert into PRODUSA_DIN values(400007, 5000000009, 5);
insert into PRODUSA_DIN values(400021, 5000000003, 14);
insert into COMANDA values(seq_comanda.nextval, 249.99, '13-MAY-2018', null, 10000100, null);
insert into TRANZACTIE values(seq_tranzactie.nextval, 'card', 'aprobata', 1000000030);
insert into ADAUGA_COMANDA values(400024, 1000000030, 1, '13-MAY-18 07:19:46');
insert into PRODUSA_DIN values(400024, 5000000021, 2);
commit;
--ex6
/* sa se afiseze detaliile materialelor si a dimensiunilor unui produs pentru fiecare categorie de produse
si fiecare comanda care il contine, fiind afisate doar primele 3 materiale mai scumpe (cumparate de la 
furnizor) pentru produsele din acea categorie
=> categorie -> piesa_mobilier (record pentru lungime latime inaltime) -> materie_prima (tip_material)
                piesa_mobilier -> adauga_comanda -> comanda*/
/*select count(p.id_produs), c.nume
from piesa_mobilier p
join categorie c on(c.id_categorie=p.id_categorie)
group by p.id_categorie, c.nume;

2	Accesorii
2	Paturi
5	Rafturi, dulapuri si unitati de depozitare
3	Unitati de dulapuri pentru bucatarie
5	Scaune, mese si birouri
2	Mobilier de exterior
4	Canapele si fotolii
1	Jucarii si jocuri
1	Gradina */

-- concluzie: nu pot sa fac parametrii cu in/out pentru record-uri, pt ca trebuie tipurile astea declarate local, devenind de fapt un subprogram local in loc de un subprogram independent
-- create type pentru local in cadrul pachetelor
create or replace procedure detalii_mobila_categorie
(
    var_nume_categ in categorie.nume%type,
    --  var_rez la nivel de nr de materiale gasite (0, 1, 2 sau 3) si de comenzi in care se afla produsul
    var_rez in out integer-- numarul de rezultate intoarse, are sens sa fie parametru in out daca as avea mai multe apelari ale procedurii pentru categorii diferite si as vrea sa vad numarul de rezultate din toate categoriile insumate
)
is
-- tablou indexat care retine produsele din fiecare categorie
    type lista_piese_mobilier is table of piesa_mobilier.nume%type index by binary_integer;
    t_piese_mobilier lista_piese_mobilier;
    
-- sectiune productie piesa mobilier
    type info_productie is record (
        q produsa_din.unitati%type,
        material materie_prima.tip_material%type
    );
    -- varray cu detaliile de productie (dpdv al materiei prime) (q=unitati, material=tip_material)
    type lista_materiale is varray(3) of info_productie;
    v_materiale lista_materiale := lista_materiale();
    -- tablou indexat cu toate materialele care pot sa fie retrieved
    type temp_materiale is table of info_productie index by binary_integer;
    t_lista_m temp_materiale;
    
-- sectiune comenzi
    -- tablou imbricat coresp comenzilor in care au fost achizitionate piesele de mobilier
    type lista_comenzi is table of comanda.id_comanda%type;
    t_comenzi lista_comenzi;
    
-- sectiune detalii dimensiuni piesa mobilier    
    type dim_mobila is record (-- asemenea unui obiect
        dim1_lungime piesa_mobilier.lungime%type,
        dim2_latime piesa_mobilier.latime%type,
        dim3_inaltime piesa_mobilier.inaltime%type
    );
    var_dimensiuni dim_mobila;
begin
    select p.nume
    bulk collect into t_piese_mobilier-- numele pieselor de mobilier din categoria selectata
    from piesa_mobilier p
    join categorie c on(c.id_categorie = p.id_categorie)
    where c.nume = var_nume_categ;
    
    dbms_output.put_line('Categoria '||var_nume_categ||' are urmatoarele piese de mobilier:');
    for i in 1..t_piese_mobilier.count loop
        dbms_output.put_line('  '||t_piese_mobilier(i)||' ');
        -- pt fiecare produs ii reprezint dimensiunea si adaug detalii referitoare la primele 3 materiale
        --pas 1: dimensiuni
        select lungime, latime, inaltime
        into var_dimensiuni.dim1_lungime, var_dimensiuni.dim2_latime, var_dimensiuni.dim3_inaltime
        from piesa_mobilier
        where piesa_mobilier.nume = t_piese_mobilier(i);
        dbms_output.put_line('      lungime: '||var_dimensiuni.dim1_lungime||', latime: '||var_dimensiuni.dim2_latime||', inaltime: '||var_dimensiuni.dim3_inaltime);
        
        --pas 2: materiale
        select pd.unitati, m.tip_material
        bulk collect into t_lista_m
        from materie_prima m
        join produsa_din pd on(m.id_material = pd.id_material)-- nu e nevoie de join si cu piesa_mobilier
        and pd.id_produs = ( select id_produs-- subcerere necorelata pentru corespondenta la produsul curent din tabloul indexat
                            from piesa_mobilier
                            where nume = t_piese_mobilier(i))
        order by m.pret_unitate desc;
        /*for j in 1..t_lista_m.count loop
            dbms_output.put_line(t_lista_m(j).q||' '||t_lista_m(j).material);
        end loop;*/-- arat clar ca pot sa fie mai multe materiale decat 3
        v_materiale.delete;-- e nevoie sa fie sterse toate elementele, altfel raman materialele de la produsul anterior
        if t_lista_m.count > 0
            then 
                for j in 1..least(v_materiale.limit, t_lista_m.count) loop-- ma asigur ca nu se intrece dimensiunea maxima a varray-ului
                    v_materiale.extend;
                    v_materiale(j).material := t_lista_m(j).material;
                    v_materiale(j).q := t_lista_m(j).q;
                end loop;
        end if;
        var_rez := var_rez + v_materiale.count;-- nr de materiale dintr-o piesa de mobilier (0, 1, 2 sau 3 maxim)
        dbms_output.put_line('  Detaliile primelor 3 materiale cele mai scumpe (de la furnizor):');
        if v_materiale.count > 0
            then
                for j in 1..v_materiale.count loop
                    dbms_output.put_line('          tip material: '|| v_materiale(j).material||', cantitate: '||v_materiale(j).q);
                end loop;
            else
                dbms_output.put_line('  Produsul nu are specificatii legate de materiale');
        end if;
        
        -- toate comenzile care contin produsul
        select c.id_comanda
        bulk collect into t_comenzi
        from comanda c
        join adauga_comanda ac on(c.id_comanda = ac.id_comanda)
        join piesa_mobilier p on(p.id_produs = ac.id_produs)
        where p.nume = t_piese_mobilier(i);-- coresp
        var_rez := var_rez + t_comenzi.count;-- nr de comenzi care includ piesa de mobilier (0 sau mai multe)
        dbms_output.put_line('  Comenzi care contin piesa '||lower(t_piese_mobilier(i))||': ');
        if t_comenzi.count > 0
            then
                for j in 1..t_comenzi.count loop
                    dbms_output.put('   id_comanda: '||t_comenzi(j));
                    dbms_output.put_line('');-- spatiere in plus
                end loop;
            else
                dbms_output.put_line('  Produsul nu face parte din nicio comanda');
        end if;

    end loop;

end;
/
declare
    var_total_rez integer := 0;
begin
    detalii_mobila_categorie('Rafturi, dulapuri si unitati de depozitare', var_total_rez);
    dbms_output.put_line('Totalul rezultatelor la nivel de numar de materiale si comenzi pentru categoria `Rafturi, dulapuri si unitati de depozitare`:');
    dbms_output.put_line(var_total_rez);
    detalii_mobila_categorie('Canapele si fotolii', var_total_rez);
    dbms_output.put_line('Totalul rezultatelor la nivel de numar de materiale si comenzi pentru categoria `Canapele si fotolii`:');
    dbms_output.put_line(var_total_rez);
end;
/

/*verificare
create or replace procedure produs
(
    var_nume_piesa in piesa_mobilier.nume%type,
    var_rez in out integer
)
is    
-- sectiune productie piesa mobilier
    type info_productie is record (
        q produsa_din.unitati%type,
        material materie_prima.tip_material%type
    );
    -- varray cu detaliile de productie (dpdv al materiei prime) (q=unitati, material=tip_material)
    type lista_materiale is varray(3) of info_productie;
    v_materiale lista_materiale := lista_materiale();
    -- tablou indexat cu toate materialele care pot sa fie retrieved
    type temp_materiale is table of info_productie index by binary_integer;
    t_lista_m temp_materiale;
begin
    dbms_output.put_line('Produsul '||var_nume_piesa||' are urmatoarele materiale:');
    -- materiale
    select pd.unitati, m.tip_material
    bulk collect into t_lista_m
    from materie_prima m
    join produsa_din pd on(m.id_material = pd.id_material)
    join piesa_mobilier p on(p.id_produs = pd.id_produs)
    where p.nume = var_nume_piesa
    order by m.pret_unitate desc;
    for j in 1..t_lista_m.count loop
        dbms_output.put_line(t_lista_m(j).q||' '||t_lista_m(j).material);
    end loop;-- arat clar ca pot sa fie mai multe materiale decat 3
    v_materiale.delete;-- e nevoie sa fie sterse toate elementele, altfel raman materialele de la produsul anterior
    if t_lista_m.count > 0
        then 
            for j in 1..least(v_materiale.limit, t_lista_m.count) loop-- ma asigur ca nu se intrece dimensiunea maxima a varray-ului
                v_materiale.extend;
                v_materiale(j).material := t_lista_m(j).material;
                v_materiale(j).q := t_lista_m(j).q;
            end loop;
    end if;
    var_rez := var_rez + v_materiale.count;
    dbms_output.put_line('  Detaliile primelor 3 materiale cele mai scumpe (de la furnizor):');
    if v_materiale.count > 0
        then
            for j in 1..v_materiale.count loop
                dbms_output.put_line('          tip material: '|| v_materiale(j).material||', cantitate: '||v_materiale(j).q);
            end loop;
        else
            dbms_output.put_line('  Produsul nu are specificatii legate de materiale');
    end if;

end;
/
declare
    var_total_rez integer := 0;
begin
    produs('EKET', var_total_rez);
    dbms_output.put_line(var_total_rez);
    produs('BILLY', var_total_rez);
    dbms_output.put_line(var_total_rez);
    produs('KALLAX', var_total_rez);
    dbms_output.put_line(var_total_rez);
    produs('FINNBY', var_total_rez);
    dbms_output.put_line(var_total_rez);
    produs('BRIMNES', var_total_rez);
    dbms_output.put_line(var_total_rez);
end;
/

select *
from piesa_mobilier p
join categorie c on(c.id_categorie=p.id_categorie)
where c.nume='Rafturi, dulapuri si unitati de depozitare';

select m.tip_material, p.unitati, m.pret_unitate
from materie_prima m
join produsa_din p on(m.id_material = p.id_material)-- nu e nevoie de join si cu piesa_mobilier
and p.id_produs = ( select id_produs-- subcerere necorelata pentru corespondenta la produsul curent din tabloul indexat
                    from piesa_mobilier
                    where nume = 'EKET')--rafturi
order by m.pret_unitate desc
fetch first 3 rows only;

select c.id_comanda, p.nume
from comanda c
join adauga_comanda ac on(ac.id_comanda=c.id_comanda)
join piesa_mobilier p on(ac.id_produs=p.id_produs)
where p.nume = 'EKET' or p.nume = 'BILLY' or p.nume = 'KALLAX' or p.nume = 'FINNBY' or p.nume = 'BRIMNES';
*/

--ex 7
/* sa se afiseze numele magazinelor, impreuna cu data aprovizionarii a caror piese de mobilier dintr-o lista data
se afla la oferta in anul 2024/ 2021 si sunt valabile in stocul magazinului respectiv*/

-- variabila globala
create or replace type lista_piese_mobilier as varray(15) of number(6,0);
/
show errors
create or replace procedure magazine_cu_piese_mobilier_la_oferta
(
    v_id_piese_mobilier_cautate lista_piese_mobilier
)
is
-- cursoarele vor fi pentru magazin si piesa mobilier
    
    var_id_produs piesa_mobilier.id_produs%type;
    var_nume_piesa_mobilier piesa_mobilier.nume%type;
    -- cursor simplu
    cursor c_produse is
        select id_produs, nume
        from piesa_mobilier
        where id_produs in ( select * from table(v_id_piese_mobilier_cautate) );
    
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
        and to_char(ap.data_aprovizionare, 'YYYY')=to_char(o.data_inceput, 'YYYY')
        and s.data_aprovizionare>=o.data_inceput and s.data_aprovizionare<=o.data_sfarsit;
        
    piesa_mobilier_gasita_magazin integer := 0;-- doar pentru o afisare corecta in cazul in care piesa de mobilier nu e in oferta si in stoc la niciun magazin
    
begin
    open c_produse;
    loop
        fetch c_produse into var_id_produs, var_nume_piesa_mobilier;
        exit when c_produse%notfound;-- atunci cand select into nu mai returneaza niciun rand
        
        piesa_mobilier_gasita_magazin := 0;
        dbms_output.put_line('Piesa de mobilier '||var_nume_piesa_mobilier||' e disponibila la oferta in stoc la magazinele:');
        -- deschid cursorul parametrizat cu param din primul cursor
        open c_magazine(var_id_produs);
        loop
            fetch c_magazine into var_magazin;
            exit when c_magazine%notfound;
                
            piesa_mobilier_gasita_magazin := 1;
            dbms_output.put_line('  ANUNT '||to_char(var_magazin.marfa_adusa, 'YYYY'));
            dbms_output.put_line('      id_magazin: '||var_magazin.cod_magazin||', id_stoc: '||var_magazin.id_stoc||', data aprovizionare: '||var_magazin.marfa_adusa||', locatie: '||var_magazin.oras||' '||var_magazin.locatie);
            dbms_output.put_line('      data la care a inceput oferta: '||var_magazin.oferta_inceput);
            dbms_output.put_line('      data la care s-a sfarsit/ se va sfarsi oferta: '||var_magazin.oferta_sfarsit);
        end loop;
            
        if piesa_mobilier_gasita_magazin = 0
            then 
                dbms_output.put_line('Piesa de mobilier '||var_nume_piesa_mobilier||' nu e in oferta si in stoc la niciun magazin');
        end if;
            
        close c_magazine;
    end loop;
    
    close c_produse;
    
end;
/
declare
    v_lista lista_piese_mobilier := lista_piese_mobilier(400002,400010,400007,400012,400011,400007,400003);
begin
    magazine_cu_piese_mobilier_la_oferta(v_lista);
end;
/

/*select distinct p.id_produs, m.id_magazin, s.id_stoc, ap.data_aprovizionare, a.oras, a.strada, o.data_inceput, o.data_sfarsit
from piesa_mobilier p
join oferta o on(o.id_produs = p.id_produs)
join aprovizioneaza ap on(ap.id_produs = p.id_produs)
join magazin m on(m.id_magazin = ap.id_magazin)
join stoc s on(s.id_stoc = ap.id_stoc and ap.data_aprovizionare = s.data_aprovizionare)
join adresa a on(a.cod_postal = m.cod_postal)
where (to_char(ap.data_aprovizionare, 'YYYY') = 2024 or to_char(ap.data_aprovizionare, 'YYYY') = 2021)
and to_char(ap.data_aprovizionare, 'YYYY')=to_char(o.data_inceput, 'YYYY')
and s.data_aprovizionare>=o.data_inceput and s.data_aprovizionare<=o.data_sfarsit;*/

--ex 8
/* sa se afiseze toate piesele de mobilier care au cel putin o materie prima asociata,
fiind data o lista de comenzi (pot exista comenzi pentru care ar putea sa dea no_data_found la produse
avand materiale asociate, no_data_found daca exista produse fara materiale asociate in comanda curenta verificata din
lista de comenzi) si pentru piesele de mobilier gasite (ca avand materiale asociate in comenzile indicate) sa se afiseze angajatul care a
procesat comanda (doresc exact un rezultat de acest tip - too_many_rows/no_data_found)
*/
create or replace function verifica_procesare_piese_mobilier
(
    var_id_comanda_cautata comanda.id_comanda%type
) return varchar
is
    var_msg varchar2(1000);-- ce returneaza functia (detalii comenzi cu cel putin un produs care are materia prima asociata)
    
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
    
    dbms_output.put_line('Comanda '||var_id_comanda||' are urmatorele piese de mobilier:');
    open c_produse(var_id_comanda);
    loop
        fetch c_produse into var_id_produs, var_nume_piesa_mobilier;
        exit when c_produse%notfound;
        var_piesa_mobilier_material_gasita := true;
        var_msg := var_msg||'   Procesare validata produse...'||chr(10);
        dbms_output.put_line('      Produsul '||var_nume_piesa_mobilier||' are cel putin un material asociat');
        begin
            select a.nume
            into var_nume_agent
            from agent_vanzari a
            join comanda c on(c.id_angajat = a.id_angajat)
            join adauga_comanda ac on(ac.id_comanda = c.id_comanda)
            where ac.id_produs = var_id_produs;
            
            var_msg := var_msg||'   Procesare validata pentru exact un agent de vanzari care a prelucrat produsul '||var_nume_piesa_mobilier||'...'||chr(10);
            var_msg := var_msg||'       Produsul a fost procesat (intr-o comanda sau mai multe) de un singur angajat pe nume '||var_nume_agent||chr(10);
            dbms_output.put_line('      Piesa: ' || var_nume_piesa_mobilier || ' - Procesata de: ' || var_nume_agent);
            dbms_output.put_line(chr(10));
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
    v_id := 1000000000;
    -- 1000000000 ramane pt a arata exceptia no_materials (produsele 400009 si 400012 nu au asociate materiale)(de mentionat ca are produsul 400009 in comun cu 1000000010 si 1000000026 si produsul 400009 cu 10000000026)
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
end;
/
declare
    v_id comanda.id_comanda%type;
begin
    v_id := 1000000008;
    -- 1000000008 ramane pt ca nu intalneste nicio exceptie (produsul 400002 ENHET care are cel putin o materie asociata face parte dintr-o singura comanda deci e prelucrata de un singur agent)
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
end;
/
declare
    v_id comanda.id_comanda%type;
begin
    v_id := 1;
    -- no_data_found general deoarece nu exista o zona de memorie a cursorului pentru o comanda inexistenta
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
end;
/
declare
    v_id comanda.id_comanda%type;
begin
    v_id := 1000000030;
    -- 1000000030 ramane pentru a arata exceptia no_data_found (are un singur produs 400024 care are material asociat si care nu se mai regaseste in nicio alta comanda in afara de cea curenta deci daca comanda curenta nu e prelucrata de un angajat inseamna ca produsul nu e prelucrat de nimeni)
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
end;
/
declare
    v_id comanda.id_comanda%type;
begin
    v_id := 1000000026;
    /* 1000000026 ramane pt a arata exceptia too_many_rows (produsul care are cel putin un material asociat 400007 si face parte din comenzile 1000000026 si 1000000016, e prelucrat de angajatii 10000(comanda 1000000026) si 10030(comanda 1000000016))
    de retinut ca la 1000000026 produsul 400008 FINNBY (celalalt care are materie asociata) e in comun cu o alta comanda dar comanda 1000000024 are angajatul null, deci pentru produsul acesta nu va intampina nicio exceptie */
    dbms_output.put_line(verifica_procesare_piese_mobilier(v_id));
end;
/

/*
-- pas 1: asociere materie prima
select p.id_produs, p.nume
from piesa_mobilier p
where not exists (
    select 1
    from produsa_din pd
    where pd.id_produs = p.id_produs
);
-- concluzia este ca da, exista produse care nu au o materie prima asociata deci ar putea genera eroarea no_data_found
-- acum incerc sa gasesc o comanda care contine doar produse pentru care nu exista materia prima asociata ca sa pasez ca parametru un id_comanda de acest tip ca sa genereze eroarea
select c.id_comanda
from comanda c
where not exists (-- nu exista niciun produs din comanda care are materiale asociate, comanda respecta conditia
    select 1-- exista produse din comanda curenta (subcerere corelata) care au materiale asociate
    from adauga_comanda ac
    join produsa_din pd on ac.id_produs = pd.id_produs
    where ac.id_comanda = c.id_comanda
);
-- SAU
select c.id_comanda
from comanda c
join adauga_comanda ac on c.id_comanda = ac.id_comanda
where ac.id_produs in (
    select p.id_produs
    from piesa_mobilier p
    where not exists (
        select 1
        from produsa_din pd
        where pd.id_produs = p.id_produs
    )
)
group by c.id_comanda
having count(*) = (-- verific ca corespunde cu fiecare produs adaugat la comanda (nr total piese mobilier)
    select count(*)
    from adauga_comanda ac2
    where ac2.id_comanda = c.id_comanda
);-- deci exista comenzi pentru care ar putea sa dea no_data_found la produse avand materiale asociate

-- verificare exercitiu - intr-o anumita comanda
select p.id_produs, p.nume
from piesa_mobilier p
join adauga_comanda ac on(ac.id_produs = p.id_produs)
where ac.id_comanda = 1000000026;
select p.id_produs, p.nume
from piesa_mobilier p
join adauga_comanda ac on ac.id_produs = p.id_produs
where ac.id_comanda = 1000000026
and not exists (
    select 1
    from produsa_din pd
    where pd.id_produs = p.id_produs
);
select distinct p.id_produs, p.nume
from adauga_comanda ac
join piesa_mobilier p on ac.id_produs = p.id_produs
join produsa_din pd on pd.id_produs = p.id_produs
where ac.id_comanda = 1000000026;
-- 1000000000 ramane pt a arata exceptia no_materials (produsele 400009 si 400012 nu au asociate materiale)(de mentionat ca are produsul 400009 in comun cu 1000000010 si 1000000026 si produsul 400009 cu 10000000026)
-- 1000000026 ramane pt a arata exceptia too_many_rows (produsul care are cel putin un material asociat 400007 si face parte din comenzile 1000000026 si 1000000016, e prelucrat de angajatii 10000(comanda 1000000026) si 10030(comanda 1000000016))
-- de retinut ca la 1000000026 produsul 400008 FINNBY (celalalt care are materie asociata) e in comun cu o alta comanda dar comanda 1000000024 are angajatul null, deci pentru produsul acesta nu va intampina nicio exceptie
-- 1000000008 ramane pt ca nu intalneste nicio exceptie (produsul 400002 ENHET care are cel putin o materie asociata face parte dintr-o singura comanda deci e prelucrata de un singur agent)
-- 1000000030 ramane pentru a arata exceptia no_data_found

-- pas 2: un singur angajat prelucreaza un produs de tipul de mai sus
-- pt too_many_rows
-- functioneaza pt ca m-am asigurat ca fiecare comanda care are produse in comun si e procesata de angajati diferiti (not null)
-- totusi e doar pentru a contura o idee deoarece daca sunt mai mult de un produs in comun cu o alta comanda, va da rateu
select distinct least(c1.id_comanda, c2.id_comanda) as comanda_1, greatest(c1.id_comanda, c2.id_comanda) as comanda_2, ac1.id_produs, least(a1.id_angajat, a2.id_angajat) as ang1_random, greatest(a1.id_angajat, a2.id_angajat) as ang2_random
--least si greatest elimina doar duplicatul (c2, c1) tuplului de forma (c1, c2)  similar pentru (ang2, ang1) cu (ang1, ang2) (atentie: ang1 nu va prelucre neaparat c1, poate sa faca prelucrarea comenzii de fapt la c2 similar pentru ang2)
from adauga_comanda ac1
join adauga_comanda ac2 on(ac1.id_produs = ac2.id_produs)
join comanda c1 on(ac1.id_comanda = c1.id_comanda)
join comanda c2 on(ac2.id_comanda = c2.id_comanda)
join agent_vanzari a1 on(a1.id_angajat = c1.id_angajat)
join agent_vanzari a2 on(a2.id_angajat = c2.id_angajat)
where c1.id_comanda != c2.id_comanda -- nu ma intereseaza sa verific prod in comun ale unei comenzi cu ea insasi, iar comanda 24 e singura cu angajatul null (care are un produsul 08 in comun cu comanda 26)
group by ac1.id_produs, c1.id_comanda, c2.id_comanda, a1.id_angajat, a2.id_angajat
order by comanda_1, comanda_2, ac1.id_produs;

-- verificare
select a.nume, a.prenume, c.id_comanda, ac.id_produs as piesa_in_comun
from agent_vanzari a
join comanda c on c.id_angajat = a.id_angajat
join adauga_comanda ac on ac.id_comanda = c.id_comanda
where ac.id_produs in (
    select id_produs
    from adauga_comanda
    where id_comanda = 1000000026
);
select a.nume
from agent_vanzari a
join comanda c on(c.id_angajat = a.id_angajat)
join adauga_comanda ac on(ac.id_comanda = c.id_comanda)
where ac.id_produs = 400007
and c.id_comanda = 1000000026;*/