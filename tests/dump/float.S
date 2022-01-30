	.file	"float.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
 #APP
	li sp, 0x00FFFFFC; j main
 #NO_APP
	.section	.sdata,"aw"
	.align	2
	.type	pi, @object
	.size	pi, 4
pi:
	.word	1078530008
	.align	2
	.type	e, @object
	.size	e, 4
e:
	.word	1076754513
	.align	2
	.type	sqr2, @object
	.size	sqr2, 4
sqr2:
	.word	1068827886
	.local	res
	.comm	res,4,4
	.globl	__mulsf3
	.globl	__divsf3
	.globl	__addsf3
	.globl	__subsf3
	.globl	__extendsfdf2
	.globl	__truncdfsf2
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	lui	a5,%hi(pi)
	lw	a4,%lo(pi)(a5)
	lui	a5,%hi(e)
	lw	a5,%lo(e)(a5)
	mv	a1,a5
	mv	a0,a4
	call	__mulsf3
	mv	a5,a0
	mv	a4,a5
	lui	a5,%hi(res)
	sw	a4,%lo(res)(a5)
	lui	a5,%hi(res)
	lw	a4,%lo(res)(a5)
	lui	a5,%hi(pi)
	lw	a5,%lo(pi)(a5)
	mv	a1,a5
	mv	a0,a4
	call	__mulsf3
	mv	a5,a0
	mv	a4,a5
	lui	a5,%hi(res)
	sw	a4,%lo(res)(a5)
	lui	a5,%hi(res)
	lw	a4,%lo(res)(a5)
	lui	a5,%hi(.LC0)
	lw	a1,%lo(.LC0)(a5)
	mv	a0,a4
	call	__divsf3
	mv	a5,a0
	mv	a4,a5
	lui	a5,%hi(res)
	sw	a4,%lo(res)(a5)
	lui	a5,%hi(sqr2)
	lw	a4,%lo(sqr2)(a5)
	lui	a5,%hi(res)
	lw	a5,%lo(res)(a5)
	mv	a1,a5
	mv	a0,a4
	call	__addsf3
	mv	a5,a0
	mv	a4,a5
	lui	a5,%hi(res)
	sw	a4,%lo(res)(a5)
	lui	a5,%hi(res)
	lw	a4,%lo(res)(a5)
	lui	a5,%hi(.LC1)
	lw	a1,%lo(.LC1)(a5)
	mv	a0,a4
	call	__subsf3
	mv	a5,a0
	mv	a4,a5
	lui	a5,%hi(res)
	sw	a4,%lo(res)(a5)
	lui	a5,%hi(res)
	lw	a5,%lo(res)(a5)
	mv	a0,a5
	call	__extendsfdf2
	mv	a4,a0
	mv	a5,a1
	mv	a0,a4
	mv	a1,a5
	call	cos
	mv	a4,a0
	mv	a5,a1
	mv	a0,a4
	mv	a1,a5
	call	__truncdfsf2
	mv	a4,a0
	lui	a5,%hi(res)
	sw	a4,%lo(res)(a5)
	li	a5,131072
	lui	a4,%hi(res)
	lw	a4,%lo(res)(a4)
	sw	a4,0(a5)
 #APP
# 19 "src/float.c" 1
	lui x31, 0x80; jalr zero, 0(x31)
# 0 "" 2
 #NO_APP
	li	a5,0
	mv	a0,a5
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	main, .-main
	.section	.rodata
	.align	2
.LC0:
	.word	1073741824
	.align	2
.LC1:
	.word	1065353216
	.ident	"GCC: (Arch Linux Repositories) 11.1.0"
