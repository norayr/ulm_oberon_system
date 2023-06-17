#include <stdio.h>
#include <stdlib.h>
#include <libelf/libelf.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

#define BUG(X) do { printf ("OOOPS: %d\n",(X)); exit (0); } while (0);

#define R_386_32	1
#define R_386_GLOB_DAT	6


typedef struct scntbl {
	Elf_Scn * scn;
	size_t off;
} scntbl;


struct scntbl strings;

void dummy () {};

size_t newstr (char * s) {
	size_t ret;
	Elf_Data * data;

	ret = strings.off;
	data = elf_newdata (strings.scn);
	data->d_buf = strdup(s);
	data->d_type = ELF_T_BYTE;
	data->d_size = strlen(s)+1;
	data->d_align = 0;
	data->d_off = ret;
/*	data->d_version; */
	strings.off += data->d_size;
	return ret;
}

struct scntbl syms;

int newsym (int index, int section, int value) {
	Elf32_Sym * sym;
	Elf_Data * data;
	sym = malloc (sizeof (Elf32_Sym));
	sym->st_name = index;
	sym->st_value = value;
	sym->st_size = 0;
	sym->st_info = ELF32_ST_INFO(STB_GLOBAL, STT_OBJECT);
	sym->st_other = 0;
	sym->st_shndx = section;
	data = elf_newdata(syms.scn);
	data->d_buf = sym;
	data->d_type = ELF_T_SYM;
	data->d_off = syms.off;
	data->d_size = sizeof (Elf32_Sym);
	data->d_align = 0;
/*	data->d_version; */
	syms.off += data->d_size;
	return data->d_off / sizeof (Elf32_Sym);
}

void initscn (Elf_Scn * scn, char * name, int type, int flags, int link, int info, int size) {
	Elf32_Shdr * shdr;
	shdr = elf32_getshdr (scn);
	if (name)
		shdr->sh_name = newstr (name);
	shdr->sh_type = type;
	shdr->sh_flags = flags;
	shdr->sh_addr = 0;
	shdr->sh_link = link;
	shdr->sh_info = info;
	shdr->sh_entsize = size;
}

void scnname (Elf_Scn * scn, char * name)
{
	Elf32_Shdr * shdr;
	shdr = elf32_getshdr (scn);
	shdr->sh_name = newstr (name);
}

struct scntbl * relocscn (Elf * elf, int index) {
	Elf_Scn * scn;
	scntbl * ret;

	ret = malloc (sizeof (struct scntbl));
	scn = elf_newscn (elf);
	ret->off = 0;
	ret->scn = scn;
        initscn (scn, NULL, SHT_REL, 0, elf_ndxscn (syms.scn),
	         index, sizeof (Elf32_Rel));
	return ret;
}


void newreloc (struct scntbl * tbl, char * sym, int off, int add) {
	Elf32_Rel * rel;
	Elf_Data * data;
	int idx;

	/* This is probably broken for local symbols */
	idx = newsym (newstr(sym), SHN_UNDEF, 0);

	rel = malloc (sizeof (Elf32_Rel));
	rel->r_offset = off;
	rel->r_info = ELF32_R_INFO(idx, add?R_386_32:R_386_GLOB_DAT);
	data = elf_newdata (tbl->scn);
	data->d_buf = rel;
	data->d_type = ELF_T_REL;
	data->d_size = sizeof (Elf32_Rel);
	data->d_align = 0;
	data->d_off = tbl->off;
	tbl->off += data->d_size;
}

void addblock (Elf * elf) {
	Elf_Data * data;
	char line[500];
	char * name;
	Elf_Scn * scn;
	scntbl * rel;
	int i, bss, len, val, add, flags, type, align, datalen, memlen;
	char * buf;
	unsigned short shrt;

	rel = NULL;
	scn = elf_newscn (elf);
	while (1) {
		fgets (line, 500, stdin);
		if (line[0] != 'S' || line[1] != 'Y' || line[2] != 'M')
			break;
		name = malloc (strlen(line) * sizeof (char));
		sscanf (line+5, "%s %d", name, &val);
		newsym (newstr (name), elf_ndxscn (scn), val);
	}
	while (1) {
		if (line[0] != 'R' || line[1] != 'E' || line[2] != 'L')
			break;
		add = (line[7] == 'A');
		if (!add && line[7] != 'S')
			BUG(4);
		name = malloc (strlen(line) * sizeof (char));
		sscanf (line+11, "%d %d %s", &val, &len, name);
		if (len != 4)
			BUG(3);
		if (!rel)
			rel = relocscn (elf, elf_ndxscn (scn));
		newreloc (rel, name, val, add);
		fgets (line, 500, stdin);
	}
	flags = 0;
	if (line[1] == 'w')
		flags |= SHF_WRITE;
	if (line[2] == 'x')
		flags |= SHF_EXECINSTR;
	sscanf (line+6, " %d %d %d", &datalen, &memlen, &align);
/*
	if (datalen && (datalen != memlen)) {
		printf ("OOOPS: datalen = %d, memlen = %d\n", datalen, memlen);
		BUG(6);
	}
*/
	type = SHT_PROGBITS;
	if (!datalen)
		type = SHT_NOBITS;
	if (!datalen && !memlen)
		type = SHT_NULL;
	if (memlen != 0)
		flags |= SHF_ALLOC;
	bss = 0;
	if (datalen > 0 && line[2] == 'x') {
		/* executable section */
		if (line[1] == 'w') {
			/* writable init section */
			name = ".init";
			flags = SHF_ALLOC|SHF_EXECINSTR|SHF_WRITE;
			type = SHT_PROGBITS;
		} else {
			/* Normal programm text */
			name = ".text";
			flags = SHF_ALLOC|SHF_EXECINSTR;
			type = SHT_PROGBITS;
		}
	} else if (!datalen && memlen && line[1] == 'w') {
		/* read/write data zero initialized */
		/* XXX This is a hack. We should definitely use a bss
		 * section that doesn't need space in the object file. */
		name = ".bss";
		flags = SHF_ALLOC|SHF_WRITE;
		bss = 1;
	} else if (datalen && line[1] != 'w') {
		/* read only data */
		name = ".rodata";
		flags = SHF_ALLOC;
	} else {
		/* others */
		name = ".private";
	}
	initscn (scn, name, type, flags, SHN_UNDEF, 0, memlen);
	if (rel) {
		buf = malloc (1 + strlen (".rel") + strlen (name));
		strcpy (buf, ".rel");
		strcat (buf, name);
		scnname (rel->scn, buf);
		free (buf);
	}
	fgets (line, 1000, stdin);
	if (strcmp (line, "{\n") != 0)
		BUG(7);
	if (!bss) {
		if (datalen > memlen) {
			buf = malloc (datalen);
		} else {
			buf = malloc (memlen);
		}
		for (i=0; i<datalen; ++i) {
			shrt = 0;
			fscanf (stdin, "%hu ", &shrt);
			buf[i] = shrt;
		}
		for (; i<memlen; ++i) {
			buf[i] = 0;
		}
		data = elf_newdata (scn);
		data->d_buf = buf;
		data->d_type = ELF_T_BYTE;
		data->d_off = 0;
		data->d_size = i;
		data->d_align = align;
	} else {
		data = elf_newdata (scn);
		data->d_buf = NULL;
		data->d_type = ELF_T_BYTE;
		data->d_off = 0;
		data->d_size = memlen;
		data->d_align = align;
	}
	fgets (line, 500, stdin);
	if (strcmp (line,"}\n") != 0) {
		printf ("%s", line);
		BUG(10);
	}
}


int main (int argc, char ** argv) {
	int fd;
	Elf * elf;
	Elf32_Ehdr * ehdr;
	Elf_Scn * scn;
	char line[1000];

	fd = open (argv[1], O_RDWR|O_CREAT, 0666);
	if (fd < 0) {
		BUG(1);
	}
	/* Elf Header */
	elf_version (EV_CURRENT);
	elf = elf_begin (fd, ELF_C_WRITE, NULL);
	ehdr = elf32_newehdr (elf);
/*	ehdr->e_type = ET_REL; */
	ehdr->e_machine = EM_386;
	ehdr->e_version = EV_CURRENT;
	ehdr->e_entry = 0;
	/* ehdr->e_flags: No need to set flags. */

	/* String Table */
	scn = elf_newscn(elf);
	strings.off = 0;
	strings.scn = scn;
	ehdr->e_shstrndx = elf_ndxscn (scn);
	newstr ("");
	initscn (scn, ".strtab", SHT_STRTAB, 0, SHN_UNDEF, 0, 0);

	/* Symbol table */
	scn = elf_newscn(elf);
	syms.off = 0;
	syms.scn = scn;
	initscn (scn, ".symtab", SHT_SYMTAB, 0, ehdr->e_shstrndx,
                 0, sizeof (Elf32_Sym));
	newsym (0, 0, 0);

	/* data */
	while (1) {
		fgets (line, 1000, stdin);
		if (strcmp (line, "END\n") == 0)
			break;
		if (strcmp (line, "NEW BLOCK\n") != 0) {
			printf ("%s\n", line);
			BUG(2);
		}
		addblock (elf);
	}
	elf_update (elf, ELF_C_WRITE);
	elf_end (elf);
	dummy ();
	return 0;
}
