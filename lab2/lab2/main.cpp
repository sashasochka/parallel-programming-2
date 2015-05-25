/*
---------------------------------------------------------------------------------
--      Лабораторна робота №2 з дисципліни ПП-2
--      Lab2. Win32
--      ПІБ       Сочка Олександр Олександрович
--      Група     ІП-22
--      Дата      26.02.2015р
--      A = max(MO) * MK * MT * a + b * MK * MR
---------------------------------------------------------------------------------
*/
#define NOMINMAX
#include <Windows.h>
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

typedef std::vector<int> Vector;
typedef std::vector<Vector> Matrix;

const int N = 4;
const int P = 4;

Matrix MA(N, Vector(N)), MO, MK, MT, MR;
int alpha, beta;

HANDLE ev_io1; // IO is finished in t1
HANDLE ev_io3; // IO is finished in t3
HANDLE ev_io4; // IO is finished in t4
HANDLE Sem1_1;
HANDLE Sem1_2;
HANDLE Sem1_3;
HANDLE Sem1_4;
HANDLE Sem2_1;
HANDLE Sem2_2;
HANDLE Sem2_3;
CRITICAL_SECTION CS1; // copy1 & copy2

int t1, t2, t3, t4;

void read_matrix(Matrix& m) {
	m = Matrix(N, Vector(N, 1));
}

void read_num(int& value) {
	value = 1;
}

void F1() {
	cout << "T1 started" << endl;
	read_matrix(MO);
	read_matrix(MK);

	SetEvent(ev_io1);
	WaitForSingleObject(ev_io3, INFINITE);
	WaitForSingleObject(ev_io4, INFINITE);

	EnterCriticalSection(&CS1);
	int alpha_c = alpha, beta_c = beta;
	cout << "T1 copied shared variables" << endl;
	LeaveCriticalSection(&CS1);


	for (int r = 0; r < N / 4; ++r) {
		t1 = max(t1, *max_element(MO[r].begin(), MO[r].end()));
	}

	ReleaseSemaphore(Sem1_1, 1, NULL);
	WaitForSingleObject(Sem1_2, INFINITE);
	ReleaseSemaphore(Sem1_2, 1, NULL);
	WaitForSingleObject(Sem1_3, INFINITE);
	ReleaseSemaphore(Sem1_3, 1, NULL);
	WaitForSingleObject(Sem1_4, INFINITE);
	ReleaseSemaphore(Sem1_4, 1, NULL);

	int t = max(max(t1, t2), max(t3, t4));

	// main calculation
	for (int i = 0; i < N / 2; ++i) {
		for (int j = 0; j < N; ++j) {
			for (int k = 0; k < N / 2; ++k) {
				MA[i][k] += t * MK[i][j] * MT[j][k] * alpha_c + beta_c * MK[i][j] * MR[j][k];
			}
		}
	}

	ReleaseSemaphore(Sem2_1, 1, NULL);
	// end of main calculation
	cout << "T1 finished" << endl;
}

void F2() {
	cout << "T2 started" << endl;

	WaitForSingleObject(ev_io1, INFINITE);
	WaitForSingleObject(ev_io3, INFINITE);
	WaitForSingleObject(ev_io4, INFINITE);

	EnterCriticalSection(&CS1);
	int alpha_c = alpha, beta_c = beta;
	cout << "T2 copied shared variables" << endl;
	LeaveCriticalSection(&CS1);

	for (int r = N / 4; r < N / 2; ++r) {
		t2 = max(t1, *max_element(MO[r].begin(), MO[r].end()));
	}

	ReleaseSemaphore(Sem1_2, 1, NULL);
	WaitForSingleObject(Sem1_1, INFINITE);
	ReleaseSemaphore(Sem1_1, 1, NULL);
	WaitForSingleObject(Sem1_3, INFINITE);
	ReleaseSemaphore(Sem1_3, 1, NULL);
	WaitForSingleObject(Sem1_4, INFINITE);
	ReleaseSemaphore(Sem1_4, 1, NULL);

	int t = max(max(t1, t2), max(t3, t4));

	// main calculation
	for (int i = N / 2; i < N; ++i) {
		for (int j = 0; j < N; ++j) {
			for (int k = 0; k < N / 2; ++k) {
				MA[i][k] += t * MK[i][j] * MT[j][k] * alpha_c + beta_c * MK[i][j] * MR[j][k];
			}
		}
	}

	// end of main calculation
	ReleaseSemaphore(Sem2_2, 1, NULL);
	cout << "T2 finished" << endl;
}

void F3() {
	cout << "T3 started" << endl;
	read_matrix(MT);
	read_num(alpha);

	SetEvent(ev_io3);

	// cout << "T3 waits for other threads input..." << endl;
	WaitForSingleObject(ev_io1, INFINITE);
	WaitForSingleObject(ev_io4, INFINITE);

	// cout << "T3 enters critical section for copying globals" << endl;

	EnterCriticalSection(&CS1);
	int alpha_c = alpha, beta_c = beta;
	cout << "T3 copied shared variables" << endl;
	LeaveCriticalSection(&CS1);

	for (int r = N / 2; r < N / 4 * 3; ++r) {
		t3 = max(t1, *max_element(MO[r].begin(), MO[r].end()));
	}

	ReleaseSemaphore(Sem1_3, 1, NULL);
	WaitForSingleObject(Sem1_2, INFINITE);
	ReleaseSemaphore(Sem1_2, 1, NULL);
	WaitForSingleObject(Sem1_1, INFINITE);
	ReleaseSemaphore(Sem1_1, 1, NULL);
	WaitForSingleObject(Sem1_4, INFINITE);
	ReleaseSemaphore(Sem1_4, 1, NULL);

	int t = max(max(t1, t2), max(t3, t4));

	// main calculation
	for (int i = 0; i < N / 2; ++i) {
		for (int j = 0; j < N; ++j) {
			for (int k = N / 2; k < N; ++k) {
				MA[i][k] += t * MK[i][j] * MT[j][k] * alpha_c + beta_c * MK[i][j] * MR[j][k];
			}
		}
	}

	// end of main calculation

	ReleaseSemaphore(Sem2_3, 1, NULL);
	cout << "T3 finished" << endl;
}

void F4() {
	cout << "T4 started" << endl;
	read_matrix(MR);
	read_num(beta);

	SetEvent(ev_io4);
	WaitForSingleObject(ev_io1, INFINITE);
	WaitForSingleObject(ev_io3, INFINITE);

	EnterCriticalSection(&CS1);
	int alpha_c = alpha, beta_c = beta;
	cout << "T4 copied shared variables" << endl;
	LeaveCriticalSection(&CS1);

	for (int r = N / 4 * 3; r < N; ++r) {
		t4 = max(t1, *max_element(MO[r].begin(), MO[r].end()));
	}

	ReleaseSemaphore(Sem1_4, 1, NULL);
	WaitForSingleObject(Sem1_2, INFINITE);
	ReleaseSemaphore(Sem1_2, 1, NULL);
	WaitForSingleObject(Sem1_3, INFINITE);
	ReleaseSemaphore(Sem1_3, 1, NULL);
	WaitForSingleObject(Sem1_1, INFINITE);
	ReleaseSemaphore(Sem1_1, 1, NULL);

	int t = max(max(t1, t2), max(t3, t4));

	// main calculation
	for (int i = N / 2; i < N; ++i) {
		for (int j = 0; j < N; ++j) {
			for (int k = N / 2; k < N; ++k) {
				MA[i][k] += t * MK[i][j] * MT[j][k] * alpha_c + beta_c * MK[i][j] * MR[j][k];
			}
		}
	}

	// end of main calculation

	WaitForSingleObject(Sem2_1, INFINITE);
	WaitForSingleObject(Sem2_2, INFINITE);
	WaitForSingleObject(Sem2_3, INFINITE);

	if (N <= 10) {
		for (int i = 0; i < N; ++i) {
			for (int j = 0; j < N; ++j) {
				cout << MA[i][j] << ' ';
			}
			cout << endl;
		}
	}

	cout << "T4 finished" << endl;
}

int main() {

	InitializeCriticalSection(&CS1);
	ev_io1 = CreateEvent(NULL, TRUE, FALSE, NULL);
	ev_io3 = CreateEvent(NULL, TRUE, FALSE, NULL);
	ev_io4 = CreateEvent(NULL, TRUE, FALSE, NULL);

	Sem1_1 = CreateSemaphore(NULL, 0, 1, NULL);
	Sem1_2 = CreateSemaphore(NULL, 0, 1, NULL);
	Sem1_3 = CreateSemaphore(NULL, 0, 1, NULL);
	Sem1_4 = CreateSemaphore(NULL, 0, 1, NULL);
	Sem2_1 = CreateSemaphore(NULL, 0, 1, NULL);
	Sem2_2 = CreateSemaphore(NULL, 0, 1, NULL);
	Sem2_3 = CreateSemaphore(NULL, 0, 1, NULL);

	DWORD thread_id;
	HANDLE T1 = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)F1, NULL, 0, &thread_id);
	HANDLE T2 = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)F2, NULL, 0, &thread_id);
	HANDLE T3 = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)F3, NULL, 0, &thread_id);
	HANDLE T4 = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)F4, NULL, 0, &thread_id);

	WaitForSingleObject(T1, INFINITE);
	WaitForSingleObject(T2, INFINITE);
	WaitForSingleObject(T3, INFINITE);
	WaitForSingleObject(T4, INFINITE);
	CloseHandle(T1);
	CloseHandle(T2);
	CloseHandle(T3);
	CloseHandle(T4);
	CloseHandle(ev_io1);
	CloseHandle(ev_io3);
	CloseHandle(ev_io4);
	CloseHandle(Sem1_1);
	CloseHandle(Sem1_2);
	CloseHandle(Sem1_3);
	CloseHandle(Sem1_4);
	CloseHandle(Sem2_1);
	CloseHandle(Sem2_2);
	CloseHandle(Sem2_3);
	DeleteCriticalSection(&CS1);
}
