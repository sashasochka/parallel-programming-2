-----------------------------------------------------------
-- Lab7.  Ada. Randevouz
-- Name:  Sochka Oleksandr Oleksandrovich
-- Group: IP-22
-- Date:  26.04.2015
-- MA  =  a * B *(MO*MX) + (Z*E) * R
-----------------------------------------------------------

with Ada.Text_IO, Ada.Integer_Text_IO, Ada.Calendar;
use Ada.Text_IO, Ada.Integer_Text_IO, Ada.Calendar;

procedure Lab7 is
  N: Integer := 400;
  D: Integer := 4;  -- grid dimension
  P: Integer := D * D; -- number of processes
  H: Integer := N / P; 
  S: Integer := D / 2 + 1; 

  StartTime, FinishTime: Time;
  DiffTime: Duration;

  type Vector is array (1..N) of Integer;
  type Matrix is array (1..N) of Vector;

  ---------------------------------------------------------------
  procedure VectorInput(M: out Vector) is
  begin
    for i in 1..N loop
       M(i) := 1;
    end loop;
  end VectorInput;

  procedure VectorOutput(M: in Vector) is
  begin
    if ( N < 20 ) then
       for i in 1..N loop
          Put(M(i));
       end loop;
       New_Line;
    end if;
  end VectorOutput;

  procedure MatrixInput(MA: out Matrix) is
  begin
    for i in 1..N loop
       for j in 1..N loop
          MA(i)(j) := 1;
       end loop;
    end loop;
  end MatrixInput;

  function Max(x, y: in Integer) return Integer is
  begin
    if ( x > y ) then
       return x;
    end if;
    return y;
  end;

  function VectorMax(beginning, ending: in Integer; M: in Vector) return Integer is
    a: Integer;
  begin
    a := Integer'First;
    for i in beginning..ending loop
       a := Max(a, M(i));
    end loop;
    return a;
  end VectorMax;

  procedure CalculateA(beginning, ending, z, alpha: Integer; T, B: in Vector; MO, MK: in Matrix; A: out Vector) is
    tmp: Integer;
  begin
    for i in beginning..ending loop
      A(i) := 0;
      tmp := 0; 
      for j in 1..N loop
        for k in 1..N loop
          tmp := tmp + MO(j)(k) * MK(k)(i);
        end loop;
      end loop;
      A(i) := A(i) + z * T(i) + alpha * B(i) * tmp;
    end loop;
  end CalculateA;

  ---------------------------------------------------------------
  task type Task_I(Tiid, Tjid: Integer) is
    entry DataInput1(Z, T: in Vector);
    entry DataInput2(alpha: in Integer; B: in Vector; MO: in Matrix);
    entry DataInput3(MK: in Matrix);

    entry DataResult_z(z: in Integer);
    entry DataResult_zi(zi: in Integer);

    entry Result_A(A: in Vector);
  end Task_I;
  ---------------------------------------------------------------
  type Task_I_Ptr is access Task_I;

  type Tasks_Array is array (1..N) of Task_I_Ptr;
  type Tasks_Matrix is array (1..N) of Tasks_Array;

  tasksMatrix: Tasks_Matrix;

  ---------------------------------------------------------------
  task body Task_I is
    beginning: Integer := ((Tiid - 1) * D + Tjid - 1) * H + 1;
    ending: Integer := ((Tiid - 1) * D + Tjid) * H;

    Ai, Zi, Ti, Bi: Vector;
    MOi, MKi: Matrix;
    alphai, zl, z1: Integer; -- zl - max in task; z1 - max total
  begin
    Put_Line("task" & Integer'Image((Tiid - 1) * D + Tjid) & " started...");

    -- DATA INPUT START
    if Tiid = 1 then
      -- input 1
      if Tjid = 1 then
        VectorInput(Zi);
        VectorInput(Ti);
      else
        accept DataInput1(Z, T: in Vector) do
          Zi := Z;
          Ti := T;
        end DataInput1;   
      end if;
      if Tjid < D then
         tasksMatrix(Tiid)(Tjid + 1).DataInput1(Zi, Ti);
      end if;
      tasksMatrix(Tiid + 1)(Tjid).DataInput1(Zi, Ti);

      -- input 2
      accept DataInput2(alpha: in Integer; B: in Vector; MO: in Matrix) do
         alphai := alpha;
         Bi := B;
         MOi := MO;
      end DataInput2;

      -- input 3
      if Tjid = D then
        MatrixInput(MKi);
      else
        accept DataInput3(MK: in Matrix) do
          MKi := MK;
        end DataInput3;
      end if;
      if Tjid > 1 then
         tasksMatrix(Tiid)(Tjid - 1).DataInput3(MKi);
      end if;
      tasksMatrix(Tiid + 1)(Tjid).DataInput3(MKi);
    elsif Tiid < D then   
      -- input 1
      accept DataInput1(Z, T: in Vector) do
         Zi := Z;
         Ti := T;
      end DataInput1;   
      tasksMatrix(Tiid + 1)(Tjid).DataInput1(Zi, Ti); 

      -- input 2
      accept DataInput2(alpha: in Integer; B: in Vector; MO: in Matrix) do
          alphai := alpha;
          Bi := B;
          MOi := MO;
      end DataInput2;
      tasksMatrix(Tiid - 1)(Tjid).DataInput2(alphai, Bi, MOi);

      -- input 3
      accept DataInput3(MK: in Matrix) do
        MKi := MK;
      end DataInput3; 
      tasksMatrix(Tiid + 1)(Tjid).DataInput3(MKi); 
    else -- TiiD = D
      -- input 1
      accept DataInput1(Z, T: in Vector) do
        Zi := Z;
        Ti := T;
      end DataInput1;   

      -- input 2 
      if Tjid = D then
        alphai := 1;
        VectorInput(Bi);
        MatrixInput(MOi);
      else
        accept DataInput2(alpha: in Integer; B: in Vector; MO: in Matrix) do
          alphai := alpha;
          Bi := B;
          MOi := MO;
        end DataInput2; 
      end if;
      if Tjid > 1 then
        tasksMatrix(Tiid)(Tjid - 1).DataInput2(alphai, Bi, MOi);
      end if;
      tasksMatrix(Tiid - 1)(Tjid).DataInput2(alphai, Bi, MOi); 

      -- input 3
      accept DataInput3(MK: in Matrix) do
        MKi := MK;
      end DataInput3; 
    end if;
    -- DATA INPUT END
    
    -- Put_Line("task" & Integer'Image((Tiid - 1) * D + Tjid) & " has all input data...");

    zl := VectorMax(beginning, ending, Zi);

    if Tiid = 1 then
       tasksMatrix(Tiid + 1)(Tjid).DataResult_zi(zl);
       accept DataResult_z(z: in Integer) do
          z1 := z;
       end DataResult_z;
    elsif Tiid < S then
       accept DataResult_zi(zi: in Integer) do
          zl := Max(zl, zi);
       end DataResult_zi;
       tasksMatrix(Tiid + 1)(Tjid).DataResult_zi(zl);
       accept DataResult_z(z: in Integer) do
          z1 := z;
       end DataResult_z;
       tasksMatrix(Tiid - 1)(Tjid).DataResult_z(z1);
    elsif Tiid = S then      
       accept DataResult_zi(zi: in Integer) do
          zl := Max(zl, zi);
       end DataResult_zi;
       accept DataResult_zi(zi: in Integer) do
          zl := Max(zl, zi);
       end DataResult_zi;
       if Tjid < S then
          if Tjid > 1 then
             accept DataResult_zi(zi: in Integer) do
                zl := Max(zl, zi);
             end DataResult_zi;
          end if;
          tasksMatrix(Tiid)(Tjid + 1).DataResult_zi(zl);
          accept DataResult_z(z: in Integer) do
             z1 := z;
          end DataResult_z;
          if Tjid > 1 then
             tasksMatrix(Tiid)(Tjid - 1).DataResult_z(z1);
          end if;
       elsif Tjid > S then 
          if Tjid < D then
             accept DataResult_zi(zi: in Integer) do
                zl := Max(zl, zi);
             end DataResult_zi;
          end if;
          tasksMatrix(Tiid)(Tjid - 1).DataResult_zi(zl);
          accept DataResult_z(z: in Integer) do
             z1 := z;
          end DataResult_z;
          if Tjid < D then
             tasksMatrix(Tiid)(Tjid + 1).DataResult_z(z1);
          end if;
       else
          accept DataResult_zi(zi: in Integer) do
             zl := Max(zl, zi);
          end DataResult_zi;
          accept DataResult_zi(zi: in Integer) do
             zl := Max(zl, zi);
          end DataResult_zi;
          z1 := zl;
          tasksMatrix(Tiid)(Tjid - 1).DataResult_z(z1);
          tasksMatrix(Tiid)(Tjid + 1).DataResult_z(z1);               
       end if; 
       tasksMatrix(Tiid - 1)(Tjid).DataResult_z(z1);
       tasksMatrix(Tiid + 1)(Tjid).DataResult_z(z1);  
    elsif Tiid < D then
       accept DataResult_zi(zi: in Integer) do
          zl := Max(zl, zi);
       end DataResult_zi;
       tasksMatrix(Tiid - 1)(Tjid).DataResult_zi(zl);
       accept DataResult_z(z: in Integer) do
          z1 := z;
       end DataResult_z;
       tasksMatrix(Tiid + 1)(Tjid).DataResult_z(z1);
    else
       tasksMatrix(Tiid - 1)(Tjid).DataResult_zi(zl);
       accept DataResult_z(z: in Integer) do
          z1 := z;
       end DataResult_z;
    end if;

    -- Put_Line("task" & Integer'Image((Tiid - 1) * D + Tjid) & " has z1...");

    CalculateA(beginning, ending, z1, alphai, Ti, Bi, MOi, MKi, Ai);

    if Tiid = 1 then
      accept Result_A(A: in Vector) do
        for i in 1..N loop
          Ai(i) := Ai(i) + A(i);  
        end loop;
      end Result_A;
      if Tjid < D then
        accept Result_A(A: in Vector) do
          for i in 1..N loop
            Ai(i) := Ai(i) + A(i);  
          end loop;
        end Result_A;   
      end if;
      if Tjid > 1 then
        tasksMatrix(Tiid)(Tjid - 1).Result_A(Ai);
      end if;
      elsif Tiid < D then
        accept Result_A(A: in Vector) do
          for i in 1..N loop
            Ai(i) := Ai(i) + A(i);  
          end loop;
        end Result_A;
        tasksMatrix(Tiid - 1)(Tjid).Result_A(Ai);
      else
        tasksMatrix(Tiid - 1)(Tjid).Result_A(Ai); 
    end if;

    if Tiid = 1 then
       if Tjid = 1 then
          VectorOutput(Ai);   
       end if;
    end if;

    Put_Line("task" & Integer'Image((Tiid - 1) * D + Tjid) & " finished!!!");

    if Tiid = 1 then
       if Tjid = 1 then
          FinishTime := Clock;
          DiffTime := FinishTime - StartTime;

          Put("Time = ");
          Put(Integer(DiffTime), 1);
          New_Line;
       end if;
    end if;
  end Task_I;

  ---------------------------------------------------------------
  begin
  StartTime := Clock;

  for i in 1..D loop
    for j in 1..D loop
       if i > 1 or j > 1 then
          tasksMatrix(i)(j) := new Task_I(i, j);
       end if;
    end loop;
  end loop;
  tasksMatrix(1)(1) := new Task_I(1, 1);
end Lab7;

