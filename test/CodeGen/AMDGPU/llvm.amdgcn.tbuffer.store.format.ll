; RUN: llc -march=amdgcn -mcpu=tahiti -verify-machineinstrs < %s | FileCheck -check-prefixes=GCN %s
; RUN: llc -march=amdgcn -mcpu=tonga -verify-machineinstrs < %s | FileCheck -check-prefixes=GCN %s

; GCN-LABEL: test_types:
; GCN: tbuffer_store_format_x v{{[0-9]+}}, 0x0, 0, 0, 0, 0, 3, 4, v{{[0-9]+}}, s[{{[0-9]+:[0-9]+}}], 0, 0, 0
; GCN: tbuffer_store_format_xy v[{{[0-9]+:[0-9]+}}], 0x0, 0, 0, 0, 0, 3, 4, v{{[0-9]+}}, s[{{[0-9]+:[0-9]+}}], -1, 0, 0
; GCN: tbuffer_store_format_xyzw v[{{[0-9]+:[0-9]+}}], 0x0, 0, 0, -1, 0, 3, 4, v{{[0-9]+}}, s[{{[0-9]+:[0-9]+}}], 0, 0, 0
; GCN: s_endpgm

define void @test_types(i32 addrspace(41)* %out0, <2 x i32> addrspace(41)* %out1, <4 x i32> addrspace(41)* %out2, <4 x i32> addrspace(41)* %out3) {
  call void @llvm.amdgcn.tbuffer.store.format.i32(i32 0, i32 addrspace(41)* %out0, i32 0, i32 0, i32 0, i32 3, i32 4, i1 false, i1 false)
  call void @llvm.amdgcn.tbuffer.store.format.v2i32(<2 x i32> zeroinitializer, <2 x i32> addrspace(41)* %out1, i32 0, i32 0, i32 0, i32 3, i32 4, i1 false, i1 true)
;  call void @llvm.amdgcn.tbuffer.store.format.v3.v4i32(i32 0, i32 addrspace(41)* %out2, i32 0, i32 0, i32 0, i32 0, i1 0, i1 0)
  call void @llvm.amdgcn.tbuffer.store.format.v4i32(<4 x i32> zeroinitializer, <4 x i32> addrspace(41)* %out3, i32 0, i32 0, i32 0, i32 3, i32 4, i1 true, i1 false)
  ret void
}

; GCN-LABEL: test_no_offset:
; GCN-NOT: v_mov_b32_e32 v{{[0-9]+}}, 0
; GCN: tbuffer_store_format_x v{{[0-9]+}}, 0x0, 0, 0, -1, 0, 4, 4, v0, s[{{[0-9]+:[0-9]+}}], -1, 0, s{{[0-9]+}}
define void @test_no_offset(i32 addrspace(41)* %out0, i32 %soffset) {
  call void @llvm.amdgcn.tbuffer.store.format.i32(i32 42, i32 addrspace(41)* %out0, i32 0, i32 0, i32 %soffset, i32 4, i32 4, i1 true, i1 true)
  ret void
}

; GCN-LABEL: test_offset:
; GCN: tbuffer_store_format_x v{{[0-9]+}}, 0x4, 0, 0, -1, 0, 4, 4, v0, s[{{[0-9]+:[0-9]+}}], -1, 0, s{{[0-9]+}}
define void @test_offset(i32 addrspace(41)* %out0, i32 %soffset) {
  call void @llvm.amdgcn.tbuffer.store.format.i32(i32 0, i32 addrspace(41)* %out0, i32 0, i32 4, i32 %soffset, i32 4, i32 4, i1 true, i1 true)
  ret void
}

define void @test_offset_s(<4 x i32> addrspace(41)* %out, i32 %s_offset) {
  call void @llvm.amdgcn.tbuffer.store.format.v4i32(<4 x i32> zeroinitializer, <4 x i32> addrspace(41)* %out, i32 0, i32 0, i32 %s_offset, i32 14, i32 4, i1 true, i1 true)
  ret void
}

declare void @llvm.amdgcn.tbuffer.store.format.i32(i32, i32 addrspace(41)*, i32, i32, i32, i32, i32, i1, i1)
declare void @llvm.amdgcn.tbuffer.store.format.v2i32(<2 x i32>, <2 x i32> addrspace(41)*, i32, i32, i32, i32, i32, i1, i1)
declare void @llvm.amdgcn.tbuffer.store.format.v3.v4i32(<4 x i32>, <4 x i32> addrspace(41)*, i32, i32, i32, i32, i32, i1, i1)
declare void @llvm.amdgcn.tbuffer.store.format.v4i32(<4 x i32> , <4 x i32> addrspace(41)*, i32, i32, i32, i32, i32, i1, i1)
