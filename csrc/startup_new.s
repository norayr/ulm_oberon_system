.global _entry
_entry:
	call SysModules___startup
	call Storage___startup
	call Process___startup
	call RTErrors___startup
	call Coroutines___startup
	call SysInterrupts___startup
	call SysSegments___startup
	call SysStorage___startup
	call SysArgs___startup
	call UnixProcess___startup
	call UnixClock___startup
	call UnixFiles___startup
	call UnixTimezones___startup
	call UnixArguments___startup
	call SysMain___startup
	call __MODULE___startup
	movl (%esp), %eax
	movl %eax, SysArgs_argc
	lea  4(%esp), %ebx
	movl %ebx, SysArgs_argv
	lea  4(%ebx, %eax, 4), %eax
	movl %eax, SysArgs_environ

	xor %ebx, %ebx
	movl $45, %eax
	int $0x80
	mov %eax, %ebx
	addl $0x10ffff, %ebx
	andl $0xffff0000, %ebx
	movl $45, %eax
	int $0x80
	mov %eax, Storage_end
	movl $0x100000, Storage_left
	call SysArgs___init
	call SysModules___init
	call Storage___init
	call Process___init
	call RTErrors___init
	call Coroutines___init
	call SysInterrupts___init
	call SysSegments___init
	mov Storage_end, %eax
	subl $0x100000, %eax
	pushl $0
	pushl %eax
	pushl $0
	call SysSegments_Register
	movl Storage_end, %eax
	subl $0x100000, %eax
	movl $0x100000, 0x4(%esp)
	movl %eax, (%esp)
	movl $0, 0x8(%esp)
	call SysSegments_Register
	movl $-1, 0x8(%esp)
	movl %esp, %edx
	addl $0x0fffffff, %edx
	andl $0xf0000000, %edx
	movl %edx, %eax
	subl %esp, %eax
	andl $0xfffff000, %eax
	addl $0x00100000, %eax
	movl %eax, 0x4(%esp)
	movl %edx, (%esp)
	call SysSegments_Register
	orl %edx,%edx
	jz _skip
	movl $0, 0x8(%esp)
	movl %edx, (%esp)
	negl %edx
	movl %edx, 0x4(%esp)
	call SysSegments_Register
_skip:
	addl $0xc,%esp
	call SysStorage___init
	pushl $0
	movl %esp, %eax
	pushl $0
	pushl $0x10000
	pushl %eax
	call Storage_AllocateStack
	addl $0xc, %esp
	popl %eax
	pushl $0x10000
	pushl $0
	pushl %eax
	movl %esp, %ebx
	movl $0, %ecx
	movl $186, %eax
	int $0x80
	addl $0xc, %esp
	call UnixProcess___init
	call UnixArguments___init
	call UnixClock___init
	call UnixFiles___init
	call UnixTimezones___init
	call SysMain___init
	call Process_Exit
