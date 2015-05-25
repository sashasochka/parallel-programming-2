#include <mpi.h>
#include <iostream>
#include <vector>

using namespace std;

const int N = 1600;
const int Q = 3;
const int K = 4;
const int P = Q * K + Q + 1;
const int HH = N / P;
const int H = (N - HH) / Q;
static_assert((N - HH) % Q == 0, "N should be divisible by Q");
static_assert(N % P == 0, "N should be divisible by P");

void calc(int* MBh, int* MC, int a, int* MOh, int* MAh)
{
    for (int r = 0; r < HH; ++r)
    {
        for (int c = 0; c < N; ++c)
        {
            int tmp = 0;
            for (int k = 0; k < N; ++k)
            {
                tmp += MBh[r*N + k] * MC[k*N + c];
            }
            MAh[r*N + c] = tmp + a * MOh[r * N + c];
        }
    }
}

int main(int argc, char* argv[])
{
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (size != P && rank == 0)
    {
        cerr << "MPI_Comm_size not corresponding to constants in program!" << endl;
        exit(1);
    }

    cout << "Starting process " << rank << endl;

    if (rank == 0)
    {
        // flat 2d arrays
        vector<int>
            MB(N * N, 1),
            MC(N * N, 1),
            MO(N * N, 1),
            MA(N * N);

        int a = 1;

        for (int i = 1; i <= Q; ++i)
        {
            MPI_Send(MB.data() + HH * N + (i - 1) * H * N, H * N, MPI_INT, i, 0, MPI_COMM_WORLD);
            MPI_Send(MC.data(),                        N * N, MPI_INT, i, 0, MPI_COMM_WORLD);
            MPI_Send(MO.data() + HH * N + (i - 1) * H * N, H * N, MPI_INT, i, 0, MPI_COMM_WORLD);
            MPI_Send(&a,                               1,     MPI_INT, i, 0, MPI_COMM_WORLD);
        }

        calc(MB.data(), MC.data(), a, MO.data(), MA.data());


        for (int i = 1; i <= Q; ++i)
        {
            MPI_Recv(MA.data() + HH * N + (i - 1) * H * N, H * N, MPI_INT, i, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }

        if (N <= 50)
        {
            for (int i = 0; i < N; ++i)
            {
                for (int j = 0; j < N; ++j)
                {
                    cout << MA[i * N + j] << ' ';
                }
                cout << endl;
            }
        }
    } 
    else if (rank  <= Q)
    {
        // flat 2d arrays
        vector<int>
            MB(H * N),
            MC(N * N),
            MO(H * N),
            MA(H * N);

        int a;

        MPI_Recv(MB.data(), MB.size(), MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(MC.data(), MC.size(), MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(MO.data(), MO.size(), MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(&a, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        
        for (int i = (rank - 1) * K + Q + 1; i <= (rank - 1) * K + Q + K; ++i)
        {
            int m = (i - Q - 1) % K + 1;
            MPI_Send(MB.data() + m * HH * N, HH * N, MPI_INT, i, 0, MPI_COMM_WORLD);
            MPI_Send(MC.data(),              N  * N, MPI_INT, i, 0, MPI_COMM_WORLD);
            MPI_Send(MO.data() + m * HH * N, HH * N, MPI_INT, i, 0, MPI_COMM_WORLD);
            MPI_Send(&a, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
        }

        calc(MB.data(), MC.data(), a, MO.data(), MA.data());

        for (int i = (rank - 1) * K + Q + 1; i <= (rank - 1) * K + Q + K; ++i)
        {
            int m = (i - Q - 1) % K + 1;
            MPI_Recv(MA.data() + m * HH * N, HH * N, MPI_INT, i, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }

        MPI_Send(MA.data(), MA.size(), MPI_INT, 0, 0, MPI_COMM_WORLD);
    }
    else
    {
        // flat 2d arrays
        vector<int>
            MB(HH * N),
            MC(N * N),
            MO(HH * N),
            MA(HH * N);

        int a = 1;

        const int parent = (rank - Q - 1) / K + 1;
        MPI_Recv(MB.data(), MB.size(), MPI_INT, parent, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(MC.data(), MC.size(), MPI_INT, parent, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(MO.data(), MO.size(), MPI_INT, parent, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Recv(&a, 1, MPI_INT, parent, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        calc(MB.data(), MC.data(), a, MO.data(), MA.data());
        MPI_Send(MA.data(), MA.size(), MPI_INT, parent, 0, MPI_COMM_WORLD);
    }

    cout << "Finishing process " << rank << endl;
    MPI_Finalize();
}
