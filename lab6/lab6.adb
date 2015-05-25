-----------------------------------------------------------
-- Lab6.  Ada. Protected module
-- Name:  Sochka Oleksandr Oleksandrovich
-- Group: IP-22
-- Date:  19.04.2015
-- MA  =  a * B *(MO*MX) + (Z*E) * R
-----------------------------------------------------------
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_text_iO; use Ada.Integer_Text_IO;

procedure Lab6 is 
  N: constant Integer := 720;
  P: constant Integer := 6;
  H: constant Integer := N/P;

  type Vector is array (1..N) of Integer;
  type Matrix is array (1..N) of Vector;


  Z, E, R: Vector;
  A: Vector := (others => 0);
  MX: Matrix; 

  protected SynchroAndOP is
    entry wait_input;
    entry wait_calc1;
    entry wait_calc2;

    function copy_alpha return Integer;
    function copy_q return Integer;
    function copy_B return Vector;
    function copy_MO return Matrix;
    procedure increase_q(var: in Integer);
    procedure write_alpha(var: in Integer);
    procedure write_B(var: in Vector);
    procedure write_MO(var: in Matrix);
    procedure signal_input;
    procedure signal_calc1;
    procedure signal_calc2;
  private
    alpha: Integer;
    q: Integer := 0;
    B: Vector;
    MO: Matrix;
    cnt_inputs: Integer := 0;
    cnt_calc1: Integer := 0;
    cnt_calc2: Integer := 0;
  end SynchroAndOP;

  protected body SynchroAndOP is
    entry wait_input when cnt_inputs = 3 is
    begin
     null;
    end wait_input;

    entry wait_calc1 when cnt_calc1 = P is
    begin
     null;
    end wait_calc1;

    entry wait_calc2 when cnt_calc2 = P is
    begin
     null;
    end wait_calc2;

    function copy_alpha return Integer is
    begin
     return alpha;
    end;
    function copy_q return Integer is
    begin
     return q;
    end;
    function copy_B return Vector is
    begin
     return B;
    end;
    function copy_MO return Matrix is
    begin
     return MO;
    end;

    procedure increase_q(var: in Integer) is
    begin
      q := q + var;
    end increase_q;
    procedure write_alpha(var: in Integer) is
    begin
      alpha := var;
    end write_alpha;
    procedure write_B(var: in Vector) is
    begin
      B := var;
    end write_B;
    procedure write_MO(var: in Matrix) is
    begin
      MO := var;
    end write_MO;
    procedure signal_input is
    begin
     cnt_inputs := cnt_inputs + 1;
    end;
    procedure signal_calc1 is
    begin
     cnt_calc1 := cnt_calc1 + 1;
    end;
    procedure signal_calc2 is
    begin
     cnt_calc2 := cnt_calc2 + 1;
    end;
  end SynchroAndOP;

  task type GenericTask is
    pragma Storage_Size(10000000);
    entry start(tt: Integer);
  end GenericTask;

  task body GenericTask is
    t, first, last, alpha, q: Integer;
    tmp_q: Integer := 0;
    B: Vector;
    MO: Matrix;
  begin
    accept start(tt: Integer) do
      t := tt;
    end start;

    put_line("Process GenericTask" & Integer'Image(t) &  " started");

    first := H * (t - 1) + 1;
    last := first + H - 1;

    -- Input start;
    case t is
      when 1 => 
        MX := (others => (others => 1));
        declare 
          B_input: Vector := (others => 1);
        begin
          SynchroAndOP.write_B(B_input);
        end;  
        SynchroAndOP.signal_input;
      when 4 =>
        Z := (others => 1);
        R := (others => 1);
        SynchroAndOP.write_alpha(1);
        SynchroAndOP.signal_input;
      when 6 =>
        E := (others => 1);
        declare 
          MO_input: Matrix := (others => (others => 1));
        begin
          SynchroAndOP.write_MO(MO_input);
        end;  
        SynchroAndOP.signal_input;
      when others =>
        null;
    end case; 
    -- Input end;

    put_line("Process GenericTask" & Integer'Image(t) &  " waiting for input...");
    SynchroAndOP.wait_input;
    put_line("Process GenericTask" & Integer'Image(t) &  " received input");
    alpha := SynchroAndOP.copy_alpha;
    B := SynchroAndOP.copy_B;
    MO := SynchroAndOP.copy_MO;

    -- calc1 start;
    for i in first..last loop
      tmp_q := tmp_q + Z(i) * E(i);
    end loop;
    SynchroAndOP.increase_q(tmp_q);
    -- calc1 end;

    SynchroAndOP.signal_calc1;
    SynchroAndOP.wait_calc1;

    q := SynchroAndOP.copy_q;
    -- calc2 start;
    for j in first..last loop
      for i in 1..N loop
        for k in 1..N loop
          A(j) := A(j) + alpha * B(i) * MO(i)(k) * MX(k)(j);
        end loop;
      end loop;
      A(j) := A(j) + q * R(j);
    end loop;
    -- calc2 end;
    SynchroAndOP.signal_calc2;
    -- output start;
    if t = 1 then
      SynchroAndOP.wait_calc2;
      if N <= 30 then
        for i in A'Range loop
          put(A(i), 7);
        end loop;
        put_line("");
      end if; 
    end if;
    -- output end;
   put_line("Process GenericTask" & Integer'Image(t) &  " finished");
  end GenericTask;

  Tasks: array (1..P) of GenericTask;
begin
  put_line("Main procedure started");
  for i in Tasks'Range loop
    Tasks(i).start(i);
  end loop;
end Lab6;
pragma main(stack_size=>200000000);
