with Ada.Text_IO; use Ada.Text_IO;
with Ada.INteger_Text_IO; use Ada.INteger_Text_IO;
with Ada.IO_Exceptions; use Ada.IO_Exceptions;

package Package1 is
    N: integer := 2;   --size of structures
    H: integer := N/2; --size of halve

    type Vec is array (1..N) of Integer;
    type Matr is array (1..N) of Vec;

    procedure Constant_Out(a: integer);
    procedure Vec_print(v: Vec);
    procedure Matr_print(m: Matr);
    procedure Vec_Input(V: in out Vec);
    procedure Matr_Input(M: in out Matr);

end Package1;
