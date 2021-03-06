//===- FuzzerShmemPosix.cpp - Posix shared memory ---------------*- C++ -* ===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// SharedMemoryRegion
//===----------------------------------------------------------------------===//
#include "FuzzerDefs.h"
#if LIBFUZZER_POSIX

#include "FuzzerIO.h"
#include "FuzzerShmem.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <semaphore.h>
#include <stdio.h>
#include <unistd.h>

namespace fuzzer {

std::string SharedMemoryRegion::Path(const char *Name) {
  return DirPlusFile(TmpDir(), Name);
}

std::string SharedMemoryRegion::SemName(const char *Name, int Idx) {
  std::string Res(Name);
  return Res + (char)('0' + Idx);
}

bool SharedMemoryRegion::Map(int fd) {
  Data = (uint8_t *)mmap(0, Size, PROT_WRITE | PROT_READ, MAP_SHARED, fd, 0);
  if (Data == (uint8_t*)-1)
    return false;
  return true;
}

bool SharedMemoryRegion::Create(const char *Name, size_t Size) {
  int fd = open(Path(Name).c_str(), O_CREAT | O_RDWR, 0777);
  if (fd < 0) return false;
  if (ftruncate(fd, Size) < 0) return false;
  this->Size = Size;
  if (!Map(fd))
    return false;
  for (int i = 0; i < 2; i++) {
    sem_unlink(SemName(Name, i).c_str());
    Semaphore[i] = sem_open(SemName(Name, i).c_str(), O_CREAT, 0644, 0);
    if (Semaphore[i] == (void *)-1)
      return false;
  }
  IAmServer = true;
  return true;
}

bool SharedMemoryRegion::Open(const char *Name) {
  int fd = open(Path(Name).c_str(), O_RDWR);
  if (fd < 0) return false;
  struct stat stat_res;
  if (0 != fstat(fd, &stat_res))
    return false;
  Size = stat_res.st_size;
  if (!Map(fd))
    return false;
  for (int i = 0; i < 2; i++) {
    Semaphore[i] = sem_open(SemName(Name, i).c_str(), 0);
    if (Semaphore[i] == (void *)-1)
      return false;
  }
  IAmServer = false;
  return true;
}

bool SharedMemoryRegion::Destroy(const char *Name) {
  return 0 == unlink(Path(Name).c_str());
}

void SharedMemoryRegion::Post(int Idx) {
  assert(Idx == 0 || Idx == 1);
  sem_post((sem_t*)Semaphore[Idx]);
}

void SharedMemoryRegion::Wait(int Idx) {
  assert(Idx == 0 || Idx == 1);
  if (sem_wait((sem_t*)Semaphore[Idx])) {
    Printf("ERROR: sem_wait failed\n");
    exit(1);
  }
}

}  // namespace fuzzer

#endif  // LIBFUZZER_POSIX
