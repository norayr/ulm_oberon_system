/* Linker script for Ulm Oberon i386 binaries.
   Creates a single RWE LOAD segment with ELF headers included,
   which matches the layout of old binutils (pre-2.20) default behavior.
   This is required because the Oberon runtime's MEMINIT code
   assumes a specific single-segment binary layout. */

OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_entry)

PHDRS
{
  oberon PT_LOAD FILEHDR PHDRS FLAGS(7);
}

SECTIONS
{
  . = 0x08048000 + SIZEOF_HEADERS;

  .init   : { *(.init)   } :oberon
  .text   : { *(.text)   }
  .rodata : { *(.rodata) }
  .private : { *(.private) *(.data) *(.got) *(.got.plt) }
  .bss    : { *(.bss) *(COMMON) }

  /DISCARD/ : { *(.note*) *(.comment) *(.eh_frame*) }
}
