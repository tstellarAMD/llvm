; RUN: opt < %s -S -mtriple=amdgcn-- -early-cse | FileCheck %s

; CHECK-LABEL: @no_cse
; CHECK: call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 0, i1 false)
; CHECK: call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 4, i1 false)
define void @no_cse(i32 addrspace(1)* %out, i32 addrspace(42)* %in) {
  %a = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 0, i1 false)
  %b = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 4, i1 false)
  %c = add i32 %a, %b
  store i32 %c, i32 addrspace(1)* %out
  ret void
}

; CHECK-LABEL: @cse_zero_offset
; CHECK: [[CSE:%[a-z0-9A-Z]+]] = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 0, i1 false)
; CHECK: add i32 [[CSE]], [[CSE]]
define void @cse_zero_offset(i32 addrspace(1)* %out, i32 addrspace(42)* %in) {
  %a = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 0, i1 false)
  %b = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 0, i1 false)
  %c = add i32 %a, %b
  store i32 %c, i32 addrspace(1)* %out
  ret void
}

; CHECK-LABEL: @cse_nonzero_offset
; CHECK: [[CSE:%[a-z0-9A-Z]+]] = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 4, i1 false)
; CHECK: add i32 [[CSE]], [[CSE]]
define void @cse_nonzero_offset(i32 addrspace(1)* %out, i32 addrspace(42)* %in) {
  %a = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 4, i1 false)
  %b = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %in, i32 4, i1 false)
  %c = add i32 %a, %b
  store i32 %c, i32 addrspace(1)* %out
  ret void
}

declare i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* nocapture, i32, i1)
