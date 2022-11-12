/*
   Copyright (c) 2015 - 2021 Advanced Micro Devices, Inc. All rights reserved.
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
 */

#include <cstdio>
#include <cstdlib>
#include <chrono>
#include <hip/hip_runtime.h>

#define NUM_SIZE 19  //size up to 16M
#define NUM_ITER 500 //Total GPU memory up to 16M*500=8G

#define Clock() std::chrono::steady_clock::now()

void valSet(int* A, int val, size_t size) {
  size_t len = size / sizeof(int);
  for (size_t i = 0; i < len; i++) {
    A[i] = val;
  }
}

void setup(size_t *size, int &num, int **pA, const size_t totalGlobalMem) {

  for (int i = 0; i < num; i++) {
    size[i] = 1 << (i + 6);
    if((NUM_ITER + 1) * size[i] > totalGlobalMem) {
      num = i;
      break;
    }
  }
  *pA = (int*)malloc(size[num - 1]);
  valSet(*pA, 1, size[num - 1]);
}

void testInit(size_t size, int type) {

  printf("Initial allocation and deallocation\n");

  int *Ad;
  auto start = Clock();
  if (type == 0)
    hipMallocManaged(&Ad, size);
  else if (type == 1)
    hipMalloc(&Ad, size);
  else if (type == 2)
    hipHostMalloc(&Ad, size, hipHostMallocMapped);

  auto end = Clock();
  auto time = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();

  if (type == 0)
    printf("hipMallocManaged(%zu) takes %lf us\n", size, time * 1e-3);
  else if (type == 1)
    printf("hipMalloc(%zu) takes %lf us\n", size, time * 1e-3);
  else if (type == 2)
    printf("hipHostMalloc(%zu) takes %lf us\n", size, time * 1e-3);

  start = Clock();
  hipFree(Ad);
  end = Clock();
  time = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
  printf("hipFree(%zu) takes %lf us\n", size, time * 1e-3);
  printf("\n");
}

int main(int argc, char* argv[])
{
  if (argc != 2) {
    printf("Usage: %s <total global memory size in bytes>\n", argv[0]);
    return 1;
  }
   
  const size_t totalGlobalMem = atol(argv[1]);

  size_t size[NUM_SIZE] = { 0 };
  int *Ad[NUM_ITER] = { nullptr };

  int num = NUM_SIZE;
  int *A;
  setup(size, num, &A, totalGlobalMem);

  printf("\n==== Evaluate hipMallocManaged and hipFree ====\n");
  testInit(size[0], 0);

  for (int i = 0; i < num; i++) {
    auto start = Clock();
    for (int j = 0; j < NUM_ITER; j++) {
      hipMallocManaged(&Ad[j], size[i]);
    }
    auto end = Clock();
    auto time = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    printf("hipMallocManaged(%zu) takes %lf us\n", size[i], time * 1e-3  / NUM_ITER);

    start = Clock();
    for (int j = 0; j < NUM_ITER; j++) {
      hipFree(Ad[j]);
      Ad[j] = nullptr;
    }
    end = Clock();
    time = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    printf("hipFree(%zu) takes %lf us\n", size[i], time * 1e-3  / NUM_ITER);
  }

  printf("\n==== Evaluate hipMalloc and hipFree ====\n");
  testInit(size[0], 1);

  for (int i = 0; i < num; i++) {
    auto start = Clock();
    for (int j = 0; j < NUM_ITER; j++) {
      hipMalloc(&Ad[j], size[i]);
    }
    auto end = Clock();
    auto time = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    printf("hipMalloc(%zu) takes %lf us\n", size[i], time * 1e-3  / NUM_ITER);

    start = Clock();
    for (int j = 0; j < NUM_ITER; j++) {
      hipFree(Ad[j]);
      Ad[j] = nullptr;
    }
    end = Clock();
    time = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    printf("hipFree(%zu) takes %lf us\n", size[i], time * 1e-3  / NUM_ITER);
  }

  printf("\n==== Evaluate hipHostMalloc (hipHostMallocMapped) and hipFree ====\n");
  testInit(size[0], 2);

  for (int i = 0; i < num; i++) {
    auto start = Clock();
    for (int j = 0; j < NUM_ITER; j++) {
      hipHostMalloc(&Ad[j], size[i], hipHostMallocMapped);
    }
    auto end = Clock();
    auto time = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    printf("hipHostMalloc(%zu) takes %lf us\n", size[i], time * 1e-3  / NUM_ITER);

    start = Clock();
    for (int j = 0; j < NUM_ITER; j++) {
      hipFree(Ad[j]);
      Ad[j] = nullptr;
    }
    end = Clock();
    time = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    printf("hipFree(%zu) takes %lf us\n", size[i], time * 1e-3  / NUM_ITER);
  }

  free(A);
  return 0;
}