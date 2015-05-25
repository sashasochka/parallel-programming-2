
----------------------------------------------------------------
--              Paralel and distributed computing             --
--             Laboratory work #1. Ada. Semaphores            --
--              Func: A = (B*MC)*(MO*MK) + a*E                --
--                            IP-22                           --
--                        Sochka Oleksandr                    --
--                          12.02.2015                        --
----------------------------------------------------------------

with Package1; use Package1;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

-- pragma Storage_Size (3_000_000);

procedure Lab1 is
    MC, MO, MK: Matr;
    Q: Vec := (others => 0);
    A, E, B: Vec;
    alpha: Integer;

    --semaphores
    S21, S22, S11, S12, S13, SharedAccess: Suspension_Object;

    procedure Task_start is
        task T1;
        task body T1 is
            B1: Vec;
            Q1: Vec;
            alpha1: Integer;
            MO1: Matr;
        begin
            Put_Line("T1 start");
            --1. Ввод MK, B, E
            Matr_Input(MK);
            Vec_Input(B);
            Vec_Input(E);
            --2. Сигнал задаче Т2 о завершении ввода
            Set_True(S21);                   --S2-1
            --3. Ждать введения
            Suspend_Until_True(S11);
            --4. Копія B1 = B
            --КРИТИЧЕСКАЯ СЕКЦИЯ
            Suspend_Until_True(SharedAccess);
            B1 := B;
            Set_True(SharedAccess);
            --5.Підрахунок Qh = B1*MCh
            for i in 1 .. H loop
              for j in 1 .. N loop
                Q(i) := Q(i) + B1(i) * MC(j)(i);
              end loop;
            end loop;
            --6.Сигнал Т2 про підрахунок Qh
            Set_True(S22);
            --7.Очікування сигналу від Т2 про підрахунок Qh
            Suspend_Until_True(S12);
            --8.Копія Q1 = Q, a1 = a
            Suspend_Until_True(SharedAccess);
            Q1 := Q;
            alpha1 := alpha;
            MO1 := MO;
            Set_true(SharedAccess);
            --9 Підрахунок Ah = Q1 * (MO1 * MKh) + a1 * Eh
            for k in 1 .. H loop
              A(k) := alpha1 * E(k);
              for i in 1 .. N loop
                for j in 1 .. N loop
                  A(k) := A(k) + Q1(k) * (MO1(i)(j) * MK(j)(k));
                end loop;
              end loop;
            end loop;
            --10. Очікування сигналу від T2 про підрахунок Ah
            Suspend_Until_True(S13);
            --11. Вивід Ah
            Vec_Print(A);
            New_Line;
            Put_Line("T1 stop");
        end T1;

        task T2;
        task body T2 is
            B2: Vec;
            Q2: Vec;
            alpha2: Integer;
            MO2: Matr;
        begin
            Put_Line("T2 start");
            --1. Ввід a, MO, MC
            alpha := 1;
            Matr_Input(MO);
            Matr_Input(MC);
            --2. Сигнал задаче Т2 о завершении ввода
            Set_True(S11);                   --S2-1
            --3. Ждать введения
            Suspend_Until_True(S21);
            --4. Копія B2 = B
            --КРИТИЧЕСКАЯ СЕКЦИЯ
            Suspend_Until_True(SharedAccess);
            B2 := B;
            Set_True(SharedAccess);
            --5.Підрахунок Qh = B2*MCh
            for i in H + 1 .. N loop
              for j in 1 .. N loop
                Q(i) := Q(i) + B2(i) * MC(j)(i);
              end loop;
            end loop;
            --6.Сигнал Т2 про підрахунок Qh
            Set_True(S12);
            --7.Очікування сигналу від Т2 про підрахунок Qh
            Suspend_Until_True(S22);
            --8.Копія Q2 = Q, a2 = a
            Suspend_Until_True(SharedAccess);
            Q2 := Q;
            alpha2 := alpha;
            MO2 := MO;
            Set_true(SharedAccess);
            --9 Підрахунок Ah = Q2 * (MO1 * MKh) + a2 * Eh
            for k in H + 1 .. N loop
              A(k) := alpha2 * E(k);
              for i in 1 .. N loop
                for j in 1 .. N loop
                  A(k) := A(k) + Q2(k) * (MO2(i)(j) * MK(j)(k));
                end loop;
              end loop;
            end loop;
            --10. Очікування сигналу від T2 про підрахунок Ah
            Set_True(S13);
            Put_Line("T2 stop");
        end T2;

    begin
        null;
    end Task_start;
begin
    Set_True(SharedAccess);
    Task_start;
end Lab1;
