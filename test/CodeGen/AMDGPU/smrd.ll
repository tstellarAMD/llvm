; RUN: llc < %s -march=amdgcn -show-mc-encoding -verify-machineinstrs | FileCheck --check-prefix=SI --check-prefix=GCN --check-prefix=SIVI %s
; RUN: llc < %s -march=amdgcn -mcpu=bonaire -show-mc-encoding -verify-machineinstrs | FileCheck --check-prefix=CI --check-prefix=GCN  %s
; RUN: llc < %s -march=amdgcn -mcpu=tonga -show-mc-encoding -verify-machineinstrs | FileCheck --check-prefix=VI --check-prefix=GCN --check-prefix=SIVI %s

; SMRD load with an immediate offset.
; GCN-LABEL: {{^}}smrd0:
; SICI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x1 ; encoding: [0x01
; VI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x4
define void @smrd0(i32 addrspace(1)* %out, i32 addrspace(2)* %ptr) {
entry:
  %0 = getelementptr i32, i32 addrspace(2)* %ptr, i64 1
  %1 = load i32, i32 addrspace(2)* %0
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; SMRD load with the largest possible immediate offset.
; GCN-LABEL: {{^}}smrd1:
; SICI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0xff ; encoding: [0xff,0x{{[0-9]+[137]}}
; VI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x3fc
define void @smrd1(i32 addrspace(1)* %out, i32 addrspace(2)* %ptr) {
entry:
  %0 = getelementptr i32, i32 addrspace(2)* %ptr, i64 255
  %1 = load i32, i32 addrspace(2)* %0
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; SMRD load with an offset greater than the largest possible immediate.
; GCN-LABEL: {{^}}smrd2:
; SI: s_movk_i32 s[[OFFSET:[0-9]]], 0x400
; SI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], s[[OFFSET]] ; encoding: [0x0[[OFFSET]]
; CI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x100
; VI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x400
; GCN: s_endpgm
define void @smrd2(i32 addrspace(1)* %out, i32 addrspace(2)* %ptr) {
entry:
  %0 = getelementptr i32, i32 addrspace(2)* %ptr, i64 256
  %1 = load i32, i32 addrspace(2)* %0
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; SMRD load with a 64-bit offset
; GCN-LABEL: {{^}}smrd3:
; FIXME: There are too many copies here because we don't fold immediates
;        through REG_SEQUENCE
; SI: s_load_dwordx2 s[{{[0-9]:[0-9]}}], s[{{[0-9]:[0-9]}}], 0xb ; encoding: [0x0b
; TODO: Add VI checks
; GCN: s_endpgm
define void @smrd3(i32 addrspace(1)* %out, i32 addrspace(2)* %ptr) {
entry:
  %0 = getelementptr i32, i32 addrspace(2)* %ptr, i64 4294967296 ; 2 ^ 32
  %1 = load i32, i32 addrspace(2)* %0
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; SMRD load with the largest possible immediate offset on VI
; GCN-LABEL: {{^}}smrd4:
; SI: s_mov_b32 [[OFFSET:s[0-9]+]], 0xffffc
; SI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], [[OFFSET]]
; CI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x3ffff
; VI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0xffffc
define void @smrd4(i32 addrspace(1)* %out, i32 addrspace(2)* %ptr) {
entry:
  %0 = getelementptr i32, i32 addrspace(2)* %ptr, i64 262143
  %1 = load i32, i32 addrspace(2)* %0
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; SMRD load with an offset greater than the largest possible immediate on VI
; GCN-LABEL: {{^}}smrd5:
; SIVI: s_mov_b32 [[OFFSET:s[0-9]+]], 0x100000
; SIVI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], [[OFFSET]]
; CI: s_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x40000
; GCN: s_endpgm
define void @smrd5(i32 addrspace(1)* %out, i32 addrspace(2)* %ptr) {
entry:
  %0 = getelementptr i32, i32 addrspace(2)* %ptr, i64 262144
  %1 = load i32, i32 addrspace(2)* %0
  store i32 %1, i32 addrspace(1)* %out
  ret void
}

; SMRD load using the load.const intrinsic with an immediate offset
; GCN-LABEL: {{^}}smrd_load_const0:
; SICI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x4 ; encoding: [0x04
; SICI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x4 ; encoding: [0x04
; VI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x10
; VI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x10
define amdgpu_ps void @smrd_load_const0(<16 x i8> addrspace(2)* inreg, <16 x i8> addrspace(2)* inreg, <32 x i8> addrspace(2)* inreg, i32 inreg, <2 x i32>, <2 x i32>, <2 x i32>, <3 x i32>, <2 x i32>, <2 x i32>, <2 x i32>, float, float, float, float, float, float, float, float, float, i32 addrspace(42)* addrspace(2)* inreg %in) {
main_body:
  %20 = getelementptr <16 x i8>, <16 x i8> addrspace(2)* %0, i32 0
  %21 = load <16 x i8>, <16 x i8> addrspace(2)* %20
  %22 = call float @llvm.SI.load.const(<16 x i8> %21, i32 16)
  %23 = load i32 addrspace(42)*, i32 addrspace(42)* addrspace(2)* %in
  %s.buffer = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %23, i32 16, i1 false)
  %s.buffer.float = bitcast i32 %s.buffer to float
  call void @llvm.SI.export(i32 15, i32 1, i32 1, i32 0, i32 0, float %22, float %22, float %22, float %s.buffer.float)
  ret void
}

; SMRD load using the load.const intrinsic with the largest possible immediate
; offset.
; GCN-LABEL: {{^}}smrd_load_const1:
; SICI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0xff ; encoding: [0xff
; SICI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0xff ; encoding: [0xff
; VI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x3fc
; VI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x3fc
define amdgpu_ps void @smrd_load_const1(<16 x i8> addrspace(2)* inreg, <16 x i8> addrspace(2)* inreg, <32 x i8> addrspace(2)* inreg, i32 inreg, <2 x i32>, <2 x i32>, <2 x i32>, <3 x i32>, <2 x i32>, <2 x i32>, <2 x i32>, float, float, float, float, float, float, float, float, float, i32 addrspace(42)* addrspace(2)* inreg %in) {
main_body:
  %20 = getelementptr <16 x i8>, <16 x i8> addrspace(2)* %0, i32 0
  %21 = load <16 x i8>, <16 x i8> addrspace(2)* %20
  %22 = call float @llvm.SI.load.const(<16 x i8> %21, i32 1020)
  %23 = load i32 addrspace(42)*, i32 addrspace(42)* addrspace(2)* %in
  %s.buffer = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %23, i32 1020, i1 false)
  %s.buffer.float = bitcast i32 %s.buffer to float
  call void @llvm.SI.export(i32 15, i32 1, i32 1, i32 0, i32 0, float %22, float %22, float %22, float %s.buffer.float)
  ret void
}
; SMRD load using the load.const intrinsic with an offset greater than the
; largets possible immediate.
; immediate offset.
; GCN-LABEL: {{^}}smrd_load_const2:
; SI: s_movk_i32 s[[OFFSET:[0-9]]], 0x400
; SI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], s[[OFFSET]] ; encoding: [0x0[[OFFSET]]
; SI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], s[[OFFSET]] ; encoding: [0x0[[OFFSET]]
; CI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x100
; CI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x100
; VI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x400
; VI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x400
define amdgpu_ps void @smrd_load_const2(<16 x i8> addrspace(2)* inreg, <16 x i8> addrspace(2)* inreg, <32 x i8> addrspace(2)* inreg, i32 inreg, <2 x i32>, <2 x i32>, <2 x i32>, <3 x i32>, <2 x i32>, <2 x i32>, <2 x i32>, float, float, float, float, float, float, float, float, float, i32 addrspace(42)* addrspace(2)* inreg %in) {
main_body:
  %20 = getelementptr <16 x i8>, <16 x i8> addrspace(2)* %0, i32 0
  %21 = load <16 x i8>, <16 x i8> addrspace(2)* %20
  %22 = call float @llvm.SI.load.const(<16 x i8> %21, i32 1024)
  %23 = load i32 addrspace(42)*, i32 addrspace(42)* addrspace(2)* %in
  %s.buffer = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %23, i32 1024, i1 false)
  %s.buffer.float = bitcast i32 %s.buffer to float
  call void @llvm.SI.export(i32 15, i32 1, i32 1, i32 0, i32 0, float %22, float %22, float %22, float %s.buffer.float)
  ret void
}

; SMRD load with the largest possible immediate offset on VI
; GCN-LABEL: {{^}}smrd_load_const3:
; SI: s_mov_b32 [[OFFSET:s[0-9]+]], 0xffffc
; SI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], [[OFFSET]]
; SI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], [[OFFSET]]
; CI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x3ffff
; CI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x3ffff
; VI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0xffffc
; VI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0xffffc
define amdgpu_ps void @smrd_load_const3(<16 x i8> addrspace(2)* inreg, <16 x i8> addrspace(2)* inreg, <32 x i8> addrspace(2)* inreg, i32 inreg, <2 x i32>, <2 x i32>, <2 x i32>, <3 x i32>, <2 x i32>, <2 x i32>, <2 x i32>, float, float, float, float, float, float, float, float, float, i32 addrspace(42)* addrspace(2)* inreg %in) {
main_body:
  %20 = getelementptr <16 x i8>, <16 x i8> addrspace(2)* %0, i32 0
  %21 = load <16 x i8>, <16 x i8> addrspace(2)* %20
  %22 = call float @llvm.SI.load.const(<16 x i8> %21, i32 1048572)
  %23 = load i32 addrspace(42)*, i32 addrspace(42)* addrspace(2)* %in
  %s.buffer = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %23, i32 1048572, i1 false)
  %s.buffer.float = bitcast i32 %s.buffer to float
  call void @llvm.SI.export(i32 15, i32 1, i32 1, i32 0, i32 0, float %22, float %22, float %22, float %s.buffer.float)
  ret void
}

; SMRD load with an offset greater than the largest possible immediate on VI
; GCN-LABEL: {{^}}smrd_load_const4:
; SIVI: s_mov_b32 [[OFFSET:s[0-9]+]], 0x100000
; SIVI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], [[OFFSET]]
; SIVI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], [[OFFSET]]
; CI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x40000
; CI: s_buffer_load_dword s{{[0-9]}}, s[{{[0-9]:[0-9]}}], 0x40000
; GCN: s_endpgm
define amdgpu_ps void @smrd_load_const4(<16 x i8> addrspace(2)* inreg, <16 x i8> addrspace(2)* inreg, <32 x i8> addrspace(2)* inreg, i32 inreg, <2 x i32>, <2 x i32>, <2 x i32>, <3 x i32>, <2 x i32>, <2 x i32>, <2 x i32>, float, float, float, float, float, float, float, float, float, i32 addrspace(42)* addrspace(2)* inreg %in) {
main_body:
  %20 = getelementptr <16 x i8>, <16 x i8> addrspace(2)* %0, i32 0
  %21 = load <16 x i8>, <16 x i8> addrspace(2)* %20
  %22 = call float @llvm.SI.load.const(<16 x i8> %21, i32 1048576)
  %23 = load i32 addrspace(42)*, i32 addrspace(42)* addrspace(2)* %in
  %s.buffer = call i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* %23, i32 1048576, i1 false)
  %s.buffer.float = bitcast i32 %s.buffer to float
  call void @llvm.SI.export(i32 15, i32 1, i32 1, i32 0, i32 0, float %22, float %22, float %22, float %s.buffer.float)
  ret void
}

; Function Attrs: nounwind readnone
declare float @llvm.SI.load.const(<16 x i8>, i32) #0

declare void @llvm.SI.export(i32, i32, i32, i32, i32, float, float, float, float)

declare i32 @llvm.amdgcn.s.buffer.load.i32(i32 addrspace(42)* nocapture, i32, i1)

attributes #0 = { nounwind readnone }
