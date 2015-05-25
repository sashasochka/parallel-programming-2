package body Package1 is
    procedure Matr_Input(M: in out Matr) is 
    begin
        for i in 1 .. N loop
            for j in 1 .. N loop
                M(i)(j) := 1;
            end loop;
        end loop;	
    end Matr_Input;
 
    procedure Vec_Input(V: in out Vec) is 
    begin
        for i in 1 .. N loop
            V(i) := 1;
        end loop;	
    end Vec_Input;
           
    procedure Constant_Out(a: integer) is	
    begin
        Put(a, 4);
        New_Line;
    end Constant_Out;
 
    procedure Vec_print(v: Vec) is
    begin
        for i in 1 .. N loop
            Put(v(i), 4);
        end loop;
    end;
 
    procedure Matr_print(m: Matr) is
    begin
        for i in 1..n loop
            Vec_print(m(i));
            New_Line;
        end loop;
    end Matr_print;
   
end Package1; 
 
