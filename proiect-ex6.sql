--ex6
/* sa se afiseze detaliile materialelor si a dimensiunilor unui produs pentru fiecare categorie de produse
si fiecare comanda care il contine, fiind afisate doar primele 3 materiale mai scumpe (cumparate de la 
furnizor) pentru produsele din acea categorie impreuna cu comenzile din care fac parte piesele de mobilier,
in plus va exista un parametru in out care numara cate rezultate au fost intoarse (numar de materiale si comenzi) 
retinandu-se numarul lui de la apeluri precedente asupra subprogramului.
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