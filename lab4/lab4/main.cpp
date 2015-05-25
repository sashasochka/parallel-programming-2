/**
* @author Sochka Oleksandr IP-22
* PP-2, Lab #4 (C#)
* P = 8
* A = sort(X) (MT * MK) - a * Z
* 02.04.2015
*/

#include <algorithm>
#include <iostream>
#include <vector>
#include <omp.h>
using namespace std;

const auto P = 8;
const auto N = 8;
const auto H = N / P;

static_assert(N % P == 0, "N should be divisible by P");

int a = 0;
vector<int> A(N);
vector<int> V(N);
vector<int> X;
vector<int> Z;
vector<vector<int>> MK;
vector<vector<int>> MT;

int main() {
	omp_set_dynamic(0);
	omp_set_num_threads(P);

	int Ti;
	#pragma omp parallel shared(a, MT, X) private(Ti)
	{
		Ti = omp_get_thread_num();

		#pragma omp critical
		cout << "T" << Ti << " created" << endl;

		if (Ti == 0) {
			X.assign(N, 1);
		}

		if (Ti == 2) {
			Z.assign(N, 1);
			MT.assign(N, vector<int>(N, 1));
		}

		if (Ti == 4) {
			a = 1;
			MK.assign(N, vector<int>(N, 1));
		}

		#pragma omp barrier
		;
		vector<vector<int>> MT;
		vector<int> X;
		int a;
		#pragma omp critical
		{
			a = ::a;
			MT = ::MT;
			X = ::X;
		}

		#pragma omp for
		for (auto i = 0; i < P; ++i) 
			sort(X.begin() + i*H, X.begin() + i * H + H);

		#pragma omp for
		for (auto i = 0; i < P; i += 2) {
			vector<int> part(H * 2);
			const auto it = X.begin() + i * H;
			merge(it, it + H, it + H, it + 2 * H, part.begin());
			copy(part.begin(), part.end(), it);
		}

		#pragma omp for
		for (auto i = 0; i < P; i += 4) {
			vector<int> part(H * 4);
			const auto it = X.begin() + i * H;
			merge(it, it + 2 * H, it + 2 * H, it + 4 * H, part.begin());
			copy(part.begin(), part.end(), it);
		}

		#pragma omp master
		merge(X.begin(), X.begin() + 4 * H, X.begin() + 4 * H, X.end(), V.begin());

		#pragma omp barrier

		#pragma omp for
		for (auto k = 0; k < N; ++k) {
			for (auto i = 0; i < N; ++i) 
				for (auto j = 0; j < N; ++j) 
					A[k] += V[k] * MT[i][j] * MK[j][k];
			A[k] -= a * Z[k];
		}

		#pragma omp master 
		if (N <= 12) {
			cout << '\n';
			for (auto val : A)
				cout << val << ' ';
			cout << '\n' << endl;
		}

		#pragma omp barrier
		#pragma omp critical
		cout << "T" << Ti << " finished it's job" << endl;
	}

	cout << "Press enter to exit..." << endl;
	cin.get();
}