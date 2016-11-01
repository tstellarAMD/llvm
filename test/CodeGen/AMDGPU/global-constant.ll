; RUN: llc -march=amdgcn -verify-machineinstrs < %s | FileCheck -check-prefix=GCN -check-prefix=NOHSA %s
; RUN: llc -mtriple=amdgcn--amdhsa -mcpu=kaveri -verify-machineinstrs < %s | FileCheck -check-prefix=GCN -check-prefix=HSA %s

@private1 = private unnamed_addr addrspace(2) constant [4 x float] [float 0.0, float 1.0, float 2.0, float 3.0]
@private2 = private unnamed_addr addrspace(2) constant [4 x float] [float 4.0, float 5.0, float 6.0, float 7.0]
@available_externally = available_externally addrspace(2) global [256 x i32] zeroinitializer
@internal_priv_as = internal unnamed_addr constant [4 x float] [float 0.0, float 1.0, float 2.0, float 3.0]
@internal_global_as = internal unnamed_addr addrspace(1) constant [4 x float] [float 0.0, float 1.0, float 2.0, float 3.0]

; GCN-LABEL: {{^}}private_test:
; GCN: s_getpc_b64 s{{\[}}[[PC0_LO:[0-9]+]]:[[PC0_HI:[0-9]+]]{{\]}}

; Non-HSA OSes use fixup into .text section.
; NOHSA: s_add_u32 s{{[0-9]+}}, s[[PC0_LO]], private1
; NOHSA: s_addc_u32 s{{[0-9]+}}, s[[PC0_HI]], 0

; HSA OSes use relocations.
; HSA: s_add_u32 s{{[0-9]+}}, s[[PC0_LO]], private1@rel32@lo+4
; HSA: s_addc_u32 s{{[0-9]+}}, s[[PC0_HI]], private1@rel32@hi+4

; GCN: s_getpc_b64 s{{\[}}[[PC1_LO:[0-9]+]]:[[PC1_HI:[0-9]+]]{{\]}}

; Non-HSA OSes use fixup into .text section.
; NOHSA: s_add_u32 s{{[0-9]+}}, s[[PC1_LO]], private2
; NOHSA: s_addc_u32 s{{[0-9]+}}, s[[PC1_HI]], 0

; HSA OSes use relocations.
; HSA: s_add_u32 s{{[0-9]+}}, s[[PC1_LO]], private2@rel32@lo+4
; HSA: s_addc_u32 s{{[0-9]+}}, s[[PC1_HI]], private2@rel32@hi+4

; GCN: s_getpc_b64 s{{\[}}[[PC2_LO:[0-9]+]]:[[PC2_HI:[0-9]+]]{{\]}}

; Non-HSA OSes use fixup into .text section.
; NOHSA: s_add_u32 s{{[0-9]+}}, s[[PC2_LO]], internal_priv_as
; NOHSA: s_addc_u32 s{{[0-9]+}}, s[[PC2_HI]], 0

; HSA OSes use relocations.
; HSA: s_add_u32 s{{[0-9]+}}, s[[PC2_LO]], internal_priv_as@rel32@lo+4
; HSA: s_addc_u32 s{{[0-9]+}}, s[[PC2_HI]], internal_priv_as@rel32@hi+4

; GCN: s_getpc_b64 s{{\[}}[[PC3_LO:[0-9]+]]:[[PC3_HI:[0-9]+]]{{\]}}

; Non-HSA OSes use fixup into .text section.
; NOHSA: s_add_u32 s{{[0-9]+}}, s[[PC3_LO]], internal_global_as
; NOHSA: s_addc_u32 s{{[0-9]+}}, s[[PC3_HI]], 0

; HSA OSes use relocations.
; HSA: s_add_u32 s{{[0-9]+}}, s[[PC3_LO]], internal_global_as@rel32@lo+4
; HSA: s_addc_u32 s{{[0-9]+}}, s[[PC3_HI]], internal_global_as@rel32@hi+4

define void @private_test(i32 %index, float addrspace(1)* %out) {
  %ptr = getelementptr [4 x float], [4 x float] addrspace(2) * @private1, i32 0, i32 %index
  %val = load float, float addrspace(2)* %ptr
  store volatile float %val, float addrspace(1)* %out
  %ptr2 = getelementptr [4 x float], [4 x float] addrspace(2) * @private2, i32 0, i32 %index
  %val2 = load float, float addrspace(2)* %ptr2
  store volatile float %val2, float addrspace(1)* %out
  %ptr3 = getelementptr [4 x float], [4 x float]* @internal_priv_as, i32 0, i32 %index
  %val3 = load float, float* %ptr3
  store volatile float %val3, float addrspace(1)* %out
  %ptr4 = getelementptr [4 x float], [4 x float] addrspace(1)* @internal_global_as, i32 0, i32 %index
  %val4 = load float, float addrspace(1)* %ptr4
  store volatile float %val4, float addrspace(1)* %out
  ret void
}

; HSA-LABEL: {{^}}available_externally_test:
; HSA: s_getpc_b64 s{{\[}}[[PC0_LO:[0-9]+]]:[[PC0_HI:[0-9]+]]{{\]}}
; HSA: s_add_u32 s{{[0-9]+}}, s[[PC0_LO]], available_externally@gotpcrel32@lo+4
; HSA: s_addc_u32 s{{[0-9]+}}, s[[PC0_HI]], available_externally@gotpcrel32@hi+4
define void @available_externally_test(i32 addrspace(1)* %out) {
  %ptr = getelementptr [256 x i32], [256 x i32] addrspace(2)* @available_externally, i32 0, i32 1
  %val = load i32, i32 addrspace(2)* %ptr
  store i32 %val, i32 addrspace(1)* %out
  ret void
}

; NOHSA: .text
; HSA: .section .rodata

; GCN: private1:
; GCN: private2:
