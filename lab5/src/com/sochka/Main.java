package com.sochka;

import java.util.Arrays;

/*****************************************************************
 *      Лабораторна робота №5 з дисципліни ПП-2
 *      Lab5. Java. Монітори
 *      ПІБ         Сочка Олександр Олександрович
 *      Група       ІП-22
 *      Дата        10.04.2015
 *      MA = a*B*(MO*MX) + (Z*E) * R
 ***************************************************************/

public class Main {
    // Processor setup
    public static final int N = 6;
    public static final int H = N / 6;


    // Input and output data
    private static int[] Z, E, R;
    private static int[] A = new int[N];
    private static int[][] MX;

    // Monitor
    private static final Monitor monitor = new Monitor();

    static class IO {
        static int readInt() {
            return 1;
        }

        static int[] readVector() {
            int[] result = new int[N];
            Arrays.fill(result, 1);
            return result;
        }

        static int[][] readMatrix() {
            int[][] result = new int[N][];
            for (int i = 0; i < result.length; i++) {
                result[i] = new int[N];
                Arrays.fill(result[i], 1);
            }
            return result;
        }

        static synchronized void output(int[] A) {
            for (int i : A) {
                System.out.print(i);
                System.out.print(' ');
            }
        }
    }

    static class Monitor {
        private int cntInputs = 0;
        private int cntCalc1 = 0;
        private int cntCalc2 = 0;

        private int a, q = 0;
        private int[] B;
        private int[][] MO;

        public synchronized void write_a(int a) {
            this.a = a;
        }
        public synchronized void write_B(int[] B) {
            this.B = B;
        }

        public synchronized void write_MO(int[][] MO) {
            this.MO = MO;
        }

        public synchronized void increase_q(int add) {
            this.q += add;
        }

        public synchronized void copy_a_B_MO(Task task) {
            task.a = a;
            task.B = B;
            task.MO = MO;
        }

        public synchronized void copyQ(Task task) {
            task.q_cpy = q;
        }


        public synchronized void waitInput() {
            while (cntInputs != 6) {
                try {
                    wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }

        public synchronized void waitCalc1() {
            while (cntCalc1 != 6) {
                try {
                    wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }

        public synchronized void waitCalc2() {
            while (cntCalc2 != 6) {
                try {
                    wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }

        public synchronized void signalInput() {
            cntInputs++;
            notifyAll();
        }

        public synchronized void signalCalc1() {
            cntCalc1++;
            notifyAll();
        }

        public synchronized void signalCalc2() {
            cntCalc2++;
            notifyAll();
        }
    }

    static class Task implements Runnable {
        protected Monitor monitor;
        protected int t;
        protected int first, last;

        int a, q_cpy;
        int[] B;
        int[][] MO;
        Task(Monitor monitor, int t) {
            this.monitor = monitor;
            this.t = t;
            first = H * t;
            last = first + H - 1;
        }

        protected void input() {}

        protected void calc1() {
            int tmp_q = 0;
            for (int i = first; i <= last; ++i) {
                tmp_q += Z[i] * E[i];
            }
            monitor.increase_q(tmp_q);
        }

        protected void calc2() {
            // Calc A
            for (int j = first; j <= last; ++j) {
                for (int i = 0; i < N; ++i) {
                    for (int k = 0; k < N; ++k) {
                        A[j] += a * B[i] * MO[i][k] * MX[k][j];
                    }
                }
                A[j] += q_cpy * R[j];
            }
        }

        protected void output() {}

        @Override
        public void run () {
            input();
            monitor.signalInput();
            monitor.waitInput();
            monitor.copy_a_B_MO(this);
            calc1();
            monitor.signalCalc1();
            monitor.waitCalc1();

            monitor.copyQ(this);
            calc2();
            monitor.signalCalc2();
            monitor.waitCalc2();
            output();
        }
    }

    static class Task1 extends Task {
        Task1(Monitor monitor) {
            super(monitor, 0);
        }
        @Override
        protected void input() {
            int[] B = IO.readVector();
            Main.MX = IO.readMatrix();
            monitor.write_B(B);
        }

        @Override
        protected void output() {
            monitor.waitCalc2();

            // Output A
            if (A.length <= 24) {
                IO.output(A);
            }
        }
    }

    static class Task4 extends Task {
        Task4(Monitor monitor) {
            super(monitor, 3);
        }
        @Override
        protected void input() {
            int a = IO.readInt();
            Main.Z = IO.readVector();
            Main.R = IO.readVector();
            monitor.write_a(a);
        }
    }

    static class Task6 extends Task {
        Task6(Monitor monitor) {
            super(monitor, 5);
        }
        @Override
        protected void input() {
            int[][] MO = IO.readMatrix();
            monitor.write_MO(MO);
            Main.E = IO.readVector();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Thread[] threads = {
            new Thread(new Task1(monitor   )),
            new Thread(new Task (monitor, 1)),
            new Thread(new Task (monitor, 2)),
            new Thread(new Task4(monitor   )),
            new Thread(new Task (monitor, 4)),
            new Thread(new Task6(monitor   ))
        };

        for (Thread thread : threads) {
            thread.start();
        }

        for (Thread thread : threads) {
            thread.join();
        }
    }
}
