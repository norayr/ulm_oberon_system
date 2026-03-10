/* Ulm's Oberon Compiler
   Copyright (C) 1989-2004 by University of Ulm, SAI, D-89069 Ulm, Germany
   ----------------------------------------------------------------------------
   Ulm's Oberon Library is free software; you can redistribute it
   and/or modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either version
   2 of the License, or (at your option) any later version.

   Ulm's Oberon Library is distributed in the hope that it will be
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   ----------------------------------------------------------------------------
   E-mail contact: oberon@mathematik.uni-ulm.de
   ----------------------------------------------------------------------------
   $Id: tof2elf.c,v 1.1 2004/09/07 12:57:03 borchert Exp borchert $
   ----------------------------------------------------------------------------
   $Log: tof2elf.c,v $
   Revision 1.1  2004/09/07 12:57:03  borchert
   Initial revision

   ----------------------------------------------------------------------------
*/

/* Original author: Christian Ehrhardt */

/* Fix by Norayr Chilingarian for modern libelf:
   We're now using single Elf_Data buffer per section
   instead of one Elf_Data per item.
   Old libelf respected user-set d_off;
   modern elfutils ignores it and recomputes offsets during elf_update(),
   causing sh_name/symbol-index mismatches in the original multi-chunk code. */

#include <stdio.h>
#include <stdlib.h>
#include <libelf.h>
#include <elf.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

#define BUG(X) do { fprintf(stderr, "%s: input format error %d\n", cmdname, (X)); exit(1); } while (0);
#define UNEXPECTED_EOF do { fprintf(stderr, "%s: unexpected EOF in input\n", cmdname); exit(1); } while (0);

#define R_386_32  1
#define R_386_GLOB_DAT  6

/*
 * String table - single growable buffer, one Elf_Data for the whole section.
 * newstr() appends to strbuf and keeps strdata->d_buf/d_size current.
 * The returned offset is the byte position within the section, suitable
 * for use as sh_name / st_name.
 */
static Elf_Scn  *strscn  = NULL;
static Elf_Data *strdata = NULL;
static char     *strbuf  = NULL;
static size_t    strused = 0;
static size_t    stralloc = 0;

size_t newstr(char *s) {
  size_t len = strlen(s) + 1;
  size_t ret = strused;

  if (strused + len > stralloc) {
    stralloc = (strused + len + 1023) & ~(size_t)1023;
    strbuf = realloc(strbuf, stralloc);
    if (!strbuf) { perror("realloc"); exit(1); }
  }
  memcpy(strbuf + strused, s, len);
  strused += len;

  if (!strdata) {
    strdata = elf_newdata(strscn);
    strdata->d_type    = ELF_T_BYTE;
    strdata->d_align   = 1;
    strdata->d_off     = 0;
    strdata->d_version = EV_CURRENT;
  }
  /* Always refresh the pointer in case realloc moved the buffer. */
  strdata->d_buf  = strbuf;
  strdata->d_size = strused;

  return ret;
}

/*
 * Symbol table - single growable array of Elf32_Sym, one Elf_Data.
 * newsym() appends an entry and returns the zero-based symbol index.
 */
static Elf_Scn   *symscn   = NULL;
static Elf_Data  *symdata  = NULL;
static Elf32_Sym *symbuf   = NULL;
static int        symcount = 0;
static int        symalloc = 0;

int newsym(int name_off, int section, int value) {
  Elf32_Sym sym;
  int ret = symcount;

  sym.st_name  = name_off;
  sym.st_value = value;
  sym.st_size  = 0;
  sym.st_info  = ELF32_ST_INFO(STB_GLOBAL, STT_OBJECT);
  sym.st_other = 0;
  sym.st_shndx = section;

  if (symcount >= symalloc) {
    symalloc = symalloc ? symalloc * 2 : 16;
    symbuf = realloc(symbuf, symalloc * sizeof(Elf32_Sym));
    if (!symbuf) { perror("realloc"); exit(1); }
  }
  symbuf[symcount++] = sym;

  if (!symdata) {
    symdata = elf_newdata(symscn);
    symdata->d_type    = ELF_T_SYM;
    symdata->d_align   = 4;
    symdata->d_off     = 0;
    symdata->d_version = EV_CURRENT;
  }
  symdata->d_buf  = symbuf;
  symdata->d_size = symcount * sizeof(Elf32_Sym);

  return ret;
}

/*
 * Relocation table - one per data section, stored in a scntbl.
 * newreloc() appends an Elf32_Rel entry to the section's buffer.
 */
typedef struct scntbl {
  Elf_Scn  *scn;
  Elf_Data *data;
  Elf32_Rel *relbuf;
  int relcount;
  int relalloc;
} scntbl;

static FILE* in; /* input text in TOF */
static char* cmdname;
#define LINESIZE 1024

void initscn(Elf_Scn *scn, char *name, int type, int flags,
             int link, int info, int size) {
  Elf32_Shdr *shdr = elf32_getshdr(scn);
  if (name)
    shdr->sh_name = newstr(name);
  shdr->sh_type    = type;
  shdr->sh_flags   = flags;
  shdr->sh_addr    = 0;
  shdr->sh_link    = link;
  shdr->sh_info    = info;
  shdr->sh_entsize = size;
}

void scnname(Elf_Scn *scn, char *name) {
  Elf32_Shdr *shdr = elf32_getshdr(scn);
  shdr->sh_name = newstr(name);
}

scntbl *relocscn(Elf *elf, int index) {
  scntbl *ret = calloc(1, sizeof(scntbl));
  if (!ret) { perror("calloc"); exit(1); }
  ret->scn = elf_newscn(elf);
  initscn(ret->scn, NULL, SHT_REL, 0, elf_ndxscn(symscn),
          index, sizeof(Elf32_Rel));
  return ret;
}

void newreloc(scntbl *tbl, char *sym, int off, int add) {
  Elf32_Rel rel;
  int idx = newsym(newstr(sym), SHN_UNDEF, 0);

  rel.r_offset = off;
  rel.r_info   = ELF32_R_INFO(idx, add ? R_386_32 : R_386_GLOB_DAT);

  if (tbl->relcount >= tbl->relalloc) {
    tbl->relalloc = tbl->relalloc ? tbl->relalloc * 2 : 8;
    tbl->relbuf = realloc(tbl->relbuf,
                          tbl->relalloc * sizeof(Elf32_Rel));
    if (!tbl->relbuf) { perror("realloc"); exit(1); }
  }
  tbl->relbuf[tbl->relcount++] = rel;

  if (!tbl->data) {
    tbl->data = elf_newdata(tbl->scn);
    tbl->data->d_type    = ELF_T_REL;
    tbl->data->d_align   = 4;
    tbl->data->d_off     = 0;
    tbl->data->d_version = EV_CURRENT;
  }
  tbl->data->d_buf  = tbl->relbuf;
  tbl->data->d_size = tbl->relcount * sizeof(Elf32_Rel);
}

void addblock(Elf *elf) {
  Elf_Data *data;
  char line[LINESIZE];
  char *name;
  Elf_Scn *scn;
  scntbl *rel;
  int i, bss, len, val, add, flags, type, align, datalen, memlen;
  char *buf;
  unsigned short shrt;

  rel = NULL;
  scn = elf_newscn(elf);
  while (1) {
    if (fgets(line, sizeof line, in) == 0) {
      UNEXPECTED_EOF;
    }
    if (line[0] != 'S' || line[1] != 'Y' || line[2] != 'M')
      break;
    name = malloc(strlen(line) * sizeof(char));
    sscanf(line+5, "%s %d", name, &val);
    newsym(newstr(name), elf_ndxscn(scn), val);
  }
  while (1) {
    if (line[0] != 'R' || line[1] != 'E' || line[2] != 'L')
      break;
    add = (line[7] == 'A');
    if (!add && line[7] != 'S')
      BUG(4);
    name = malloc(strlen(line) * sizeof(char));
    sscanf(line+11, "%d %d %s", &val, &len, name);
    if (len != 4)
      BUG(3);
    if (!rel)
      rel = relocscn(elf, elf_ndxscn(scn));
    newreloc(rel, name, val, add);
    if (fgets(line, sizeof line, in) == 0) {
      UNEXPECTED_EOF;
    }
  }
  flags = 0;
  if (line[1] == 'w')
    flags |= SHF_WRITE;
  if (line[2] == 'x')
    flags |= SHF_EXECINSTR;
  sscanf(line+6, " %d %d %d", &datalen, &memlen, &align);
  type = SHT_PROGBITS;
  if (!datalen)
    type = SHT_NOBITS;
  if (!datalen && !memlen)
    type = SHT_NULL;
  if (memlen != 0)
    flags |= SHF_ALLOC;
  bss = 0;
  if (datalen > 0 && line[2] == 'x') {
    if (line[1] == 'w') {
      name = ".init";
      flags = SHF_ALLOC|SHF_EXECINSTR|SHF_WRITE;
      type = SHT_PROGBITS;
    } else {
      name = ".text";
      flags = SHF_ALLOC|SHF_EXECINSTR;
      type = SHT_PROGBITS;
    }
  } else if (!datalen && memlen && line[1] == 'w') {
    name = ".bss";
    flags = SHF_ALLOC|SHF_WRITE;
    bss = 1;
  } else if (datalen && line[1] != 'w') {
    name = ".rodata";
    flags = SHF_ALLOC;
  } else {
    name = ".private";
  }
  initscn(scn, name, type, flags, SHN_UNDEF, 0, memlen);
  if (rel) {
    buf = malloc(1 + strlen(".rel") + strlen(name));
    strcpy(buf, ".rel");
    strcat(buf, name);
    scnname(rel->scn, buf);
    free(buf);
  }
  if (fgets(line, sizeof line, in) == 0) {
    UNEXPECTED_EOF;
  }
  if (strcmp(line, "{\n") != 0)
    BUG(7);
  if (!bss) {
    buf = malloc(datalen > memlen ? datalen : memlen);
    for (i = 0; i < datalen; ++i) {
      shrt = 0;
      fscanf(in, "%hu ", &shrt);
      buf[i] = shrt;
    }
    for (; i < memlen; ++i)
      buf[i] = 0;
    data = elf_newdata(scn);
    data->d_buf     = buf;
    data->d_type    = ELF_T_BYTE;
    data->d_off     = 0;
    data->d_size    = i;
    data->d_align   = align;
    data->d_version = EV_CURRENT;
  } else {
    data = elf_newdata(scn);
    data->d_buf     = NULL;
    data->d_type    = ELF_T_BYTE;
    data->d_off     = 0;
    data->d_size    = memlen;
    data->d_align   = align;
    data->d_version = EV_CURRENT;
  }
  if (fgets(line, sizeof line, in) == 0) {
    UNEXPECTED_EOF;
  }
  if (strcmp(line, "}\n") != 0) {
    BUG(10);
  }
}


int main(int argc, char **argv) {
  int fd;
  Elf *elf;
  Elf32_Ehdr *ehdr;
  Elf_Scn *scn;
  char line[LINESIZE];
  char *usage = "Usage: %s [-o outfile] [infile]\n";
  char *outfile = 0;
  int flag;

  cmdname = *argv;
  while ((flag = getopt(argc, argv, ":o:")) != -1) {
    switch (flag) {
    case 'o':
      outfile = optarg;
      break;
    default:
      fprintf(stderr, usage, cmdname); return 1;
    }
  }
  if (optind >= argc) {
    in = stdin;
  } else if (optind == argc-1) {
    if ((in = fopen(argv[optind], "r")) == 0) {
      perror(argv[optind]);
      return 1;
    }
  } else {
    fprintf(stderr, usage, cmdname); return 1;
  }
  if (outfile) {
    fd = open(outfile, O_RDWR|O_CREAT|O_TRUNC, 0666);
    if (fd < 0) {
      perror(outfile);
      return 1;
    }
  } else {
    fd = 1; /* stdout */
  }

  elf_version(EV_CURRENT);
  elf = elf_begin(fd, ELF_C_WRITE, NULL);
  ehdr = elf32_newehdr(elf);
  ehdr->e_machine = EM_386;
  ehdr->e_version = EV_CURRENT;
  ehdr->e_entry   = 0;

  /* String table section - must be first so e_shstrndx is set before
     any initscn() calls that need to add names. */
  strscn = elf_newscn(elf);
  ehdr->e_shstrndx = elf_ndxscn(strscn);
  newstr("");                               /* mandatory empty string at 0 */
  initscn(strscn, ".strtab", SHT_STRTAB, 0, SHN_UNDEF, 0, 0);

  /* Symbol table section */
  scn = elf_newscn(elf);
  symscn = scn;
  initscn(scn, ".symtab", SHT_SYMTAB, 0, elf_ndxscn(strscn),
          0, sizeof(Elf32_Sym));
  newsym(0, 0, 0);   /* mandatory null symbol at index 0 */

  /* Data sections (one per "NEW BLOCK" in the TOF input) */
  for (;;) {
    if (fgets(line, sizeof line, in) == 0) {
      UNEXPECTED_EOF;
    }
    if (strcmp(line, "END\n") == 0)
      break;
    if (strcmp(line, "NEW BLOCK\n") != 0) {
      BUG(2);
    }
    addblock(elf);
  }

  elf_update(elf, ELF_C_WRITE);
  elf_end(elf);
  return 0;
}
