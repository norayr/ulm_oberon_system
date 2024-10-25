/* Ulm's Oberon Compiler
   Modified tof2elf.c for compatibility with modern libelf versions
*/

#include <stdio.h>
#include <stdlib.h>
#include <gelf.h>   // Use gelf.h instead of elf.h
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

#define BUG(X) do { fprintf(stderr, "%s: input format error %d\n", cmdname, (X)); exit(1); } while (0);
#define UNEXPECTED_EOF do { fprintf(stderr, "%s: unexpected EOF in input\n", cmdname); exit(1); } while (0);

#define R_386_32	1
#define R_386_GLOB_DAT	6

typedef struct scntbl {
	Elf_Scn * scn;
	size_t off;
} scntbl;

struct scntbl strings;

static FILE* in; /* input text in TOF */
static char* cmdname;
#define LINESIZE 1024

Elf *elf; // Declare elf globally

size_t newstr (char * s) {
	size_t ret;
	Elf_Data * data;

	ret = strings.off;
	data = elf_newdata (strings.scn);
	if (!data) {
		fprintf(stderr, "%s: elf_newdata failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	data->d_buf = strdup(s);
	data->d_type = ELF_T_BYTE;
	data->d_size = strlen(s)+1;
	data->d_align = 1;
	data->d_off = ret;
	strings.off += data->d_size;
	return ret;
}

struct scntbl syms;

int newsym (int index, int section, int value) {
    GElf_Sym sym_mem;
    Elf_Data * data;

    memset(&sym_mem, 0, sizeof(GElf_Sym));
    sym_mem.st_name = index;
    sym_mem.st_value = value;
    sym_mem.st_size = 0;
    sym_mem.st_info = GELF_ST_INFO(STB_GLOBAL, STT_OBJECT);
    sym_mem.st_other = 0;
    sym_mem.st_shndx = section;

    data = elf_getdata(syms.scn, NULL);
    if (data == NULL) {
        data = elf_newdata(syms.scn);
        if (data == NULL) {
            fprintf(stderr, "%s: elf_newdata failed: %s\n", cmdname, elf_errmsg(-1));
            exit(1);
        }
        data->d_type = ELF_T_SYM;
        data->d_size = 0;
        data->d_align = gelf_fsize(elf, ELF_T_ADDR, 1, EV_CURRENT);
    }
    size_t nsyms = data->d_size / gelf_fsize(elf, ELF_T_SYM, 1, EV_CURRENT);
    if (gelf_update_sym(data, nsyms, &sym_mem) == 0) {
        fprintf(stderr, "%s: gelf_update_sym failed: %s\n", cmdname, elf_errmsg(-1));
        exit(1);
    }
    data->d_size += gelf_fsize(elf, ELF_T_SYM, 1, EV_CURRENT);
    syms.off = data->d_size;
    return nsyms;
}

void initscn (Elf_Scn * scn, char * name, int type, int flags, int link, int info, size_t entsize) {
    GElf_Shdr shdr_mem;
    GElf_Shdr * shdr = &shdr_mem;

    if (gelf_getshdr(scn, shdr) == NULL) {
        fprintf(stderr, "%s: gelf_getshdr failed: %s\n", cmdname, elf_errmsg(-1));
        exit(1);
    }
    if (name)
        shdr->sh_name = newstr (name);
    shdr->sh_type = type;
    shdr->sh_flags = flags;
    shdr->sh_addr = 0;
    shdr->sh_link = link;
    shdr->sh_info = info;
    shdr->sh_addralign = 1;
    shdr->sh_entsize = entsize;
    if (gelf_update_shdr(scn, shdr) == 0) {
        fprintf(stderr, "%s: gelf_update_shdr failed: %s\n", cmdname, elf_errmsg(-1));
        exit(1);
    }
}

void scnname (Elf_Scn * scn, char * name)
{
	GElf_Shdr shdr_mem;
	GElf_Shdr * shdr = &shdr_mem;
	if (gelf_getshdr(scn, shdr) == NULL) {
		fprintf(stderr, "%s: gelf_getshdr failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	shdr->sh_name = newstr (name);
	if (gelf_update_shdr(scn, shdr) == 0) {
		fprintf(stderr, "%s: gelf_update_shdr failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
}

struct scntbl * relocscn (Elf * elf, int index) {
	Elf_Scn * scn;
	scntbl * ret;

	ret = malloc (sizeof (struct scntbl));
	if (!ret) {
		perror("malloc");
		exit(1);
	}
	scn = elf_newscn (elf);
	if (!scn) {
		fprintf(stderr, "%s: elf_newscn failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	ret->off = 0;
	ret->scn = scn;
	initscn (scn, NULL, SHT_REL, 0, elf_ndxscn (syms.scn),
	         index, gelf_fsize(elf, ELF_T_REL, 1, EV_CURRENT));
	return ret;
}

void newreloc (struct scntbl * tbl, char * symname, int off, int add) {
    GElf_Rel rel_mem;
    Elf_Data * data;
    int idx;

    idx = newsym(newstr(symname), SHN_UNDEF, 0);

    memset(&rel_mem, 0, sizeof(GElf_Rel));
    rel_mem.r_offset = off;
    rel_mem.r_info = GELF_R_INFO(idx, add ? R_386_32 : R_386_GLOB_DAT);

    data = elf_getdata(tbl->scn, NULL);
    if (data == NULL) {
        data = elf_newdata(tbl->scn);
        if (data == NULL) {
            fprintf(stderr, "%s: elf_newdata failed: %s\n", cmdname, elf_errmsg(-1));
            exit(1);
        }
        data->d_type = ELF_T_REL;
        data->d_size = 0;
        data->d_align = gelf_fsize(elf, ELF_T_ADDR, 1, EV_CURRENT);
    }
    size_t nrels = data->d_size / gelf_fsize(elf, ELF_T_REL, 1, EV_CURRENT);
    if (gelf_update_rel(data, nrels, &rel_mem) == 0) {
        fprintf(stderr, "%s: gelf_update_rel failed: %s\n", cmdname, elf_errmsg(-1));
        exit(1);
    }
    data->d_size += gelf_fsize(elf, ELF_T_REL, 1, EV_CURRENT);
    tbl->off = data->d_size;
}

void addblock (Elf * elf) {
	Elf_Data * data;
	char line[LINESIZE];
	char * name;
	Elf_Scn * scn;
	scntbl * rel = NULL;
	int i, bss, len, val, add, flags, type, align, datalen, memlen;
	char * buf;
	unsigned short shrt;

	scn = elf_newscn (elf);
	if (!scn) {
		fprintf(stderr, "%s: elf_newscn failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	while (1) {
		if (fgets(line, sizeof line, in) == 0) {
			UNEXPECTED_EOF;
		}
		if (strncmp(line, "SYM", 3) != 0)
			break;
		name = malloc (strlen(line) * sizeof (char));
		if (!name) {
			perror("malloc");
			exit(1);
		}
		sscanf (line+5, "%s %d", name, &val);
		newsym (newstr (name), elf_ndxscn (scn), val);
	}
	while (1) {
		if (strncmp(line, "REL", 3) != 0)
			break;
		add = (line[7] == 'A');
		if (!add && line[7] != 'S')
			BUG(4);
		name = malloc (strlen(line) * sizeof (char));
		if (!name) {
			perror("malloc");
			exit(1);
		}
		sscanf (line+11, "%d %d %s", &val, &len, name);
		if (len != 4)
			BUG(3);
		if (!rel)
			rel = relocscn (elf, elf_ndxscn (scn));
		newreloc (rel, name, val, add);
		if (fgets(line, sizeof line, in) == 0) {
			UNEXPECTED_EOF;
		}
	}
	flags = 0;
	if (line[1] == 'w')
		flags |= SHF_WRITE;
	if (line[2] == 'x')
		flags |= SHF_EXECINSTR;
	sscanf (line+6, " %d %d %d", &datalen, &memlen, &align);
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
			/* Normal program text */
			name = ".text";
			flags = SHF_ALLOC|SHF_EXECINSTR;
			type = SHT_PROGBITS;
		}
	} else if (!datalen && memlen && line[1] == 'w') {
		/* read/write data zero initialized */
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
	initscn (scn, name, type, flags, SHN_UNDEF, 0, 0);
	if (rel) {
		buf = malloc (1 + strlen (".rel") + strlen (name));
		if (!buf) {
			perror("malloc");
			exit(1);
		}
		strcpy (buf, ".rel");
		strcat (buf, name);
		scnname (rel->scn, buf);
		free (buf);
	}
	if (fgets(line, sizeof line, in) == 0) {
		UNEXPECTED_EOF;
	}
	if (strcmp (line, "{\n") != 0)
		BUG(7);
	if (!bss) {
		if (datalen > memlen) {
			buf = malloc (datalen);
		} else {
			buf = malloc (memlen);
		}
		if (!buf) {
			perror("malloc");
			exit(1);
		}
		for (i=0; i<datalen; ++i) {
			shrt = 0;
			fscanf (in, "%hu ", &shrt);
			buf[i] = shrt;
		}
		for (; i<memlen; ++i) {
			buf[i] = 0;
		}
		data = elf_newdata (scn);
		if (!data) {
			fprintf(stderr, "%s: elf_newdata failed: %s\n", cmdname, elf_errmsg(-1));
			exit(1);
		}
		data->d_buf = buf;
		data->d_type = ELF_T_BYTE;
		data->d_off = 0;
		data->d_size = i;
		data->d_align = align;
	} else {
		data = elf_newdata (scn);
		if (!data) {
			fprintf(stderr, "%s: elf_newdata failed: %s\n", cmdname, elf_errmsg(-1));
			exit(1);
		}
		data->d_buf = NULL;
		data->d_type = ELF_T_BYTE;
		data->d_off = 0;
		data->d_size = memlen;
		data->d_align = align;
	}
	if (fgets(line, sizeof line, in) == 0) {
		UNEXPECTED_EOF;
	}
	if (strcmp (line,"}\n") != 0) {
		BUG(10);
	}
}

int main (int argc, char ** argv) {
	int fd;
	// Elf * elf; // Remove local declaration
	GElf_Ehdr ehdr_mem;
	GElf_Ehdr * ehdr = &ehdr_mem;
	Elf_Scn * scn;
	char line[LINESIZE];
	char* usage = "Usage: %s [-o outfile] [infile]\n";
	char* outfile = 0;
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
	/* Initialize ELF library */
	if (elf_version (EV_CURRENT) == EV_NONE) {
		fprintf(stderr, "%s: ELF library initialization failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	elf = elf_begin (fd, ELF_C_WRITE, NULL);
	if (!elf) {
		fprintf(stderr, "%s: elf_begin failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	if (gelf_newehdr(elf, ELFCLASS32) == NULL) {
		fprintf(stderr, "%s: gelf_newehdr failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	if (gelf_getehdr(elf, ehdr) == NULL) {
		fprintf(stderr, "%s: gelf_getehdr failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	/* Set ELF header fields */
	memset(ehdr, 0, sizeof(GElf_Ehdr));
	ehdr->e_ident[EI_MAG0] = ELFMAG0;
	ehdr->e_ident[EI_MAG1] = ELFMAG1;
	ehdr->e_ident[EI_MAG2] = ELFMAG2;
	ehdr->e_ident[EI_MAG3] = ELFMAG3;
	ehdr->e_ident[EI_CLASS] = ELFCLASS32;
	ehdr->e_ident[EI_DATA] = ELFDATA2LSB;
	ehdr->e_ident[EI_VERSION] = EV_CURRENT;
	ehdr->e_ident[EI_OSABI] = ELFOSABI_SYSV;
	ehdr->e_ident[EI_ABIVERSION] = 0;
	ehdr->e_type = ET_REL;
	ehdr->e_machine = EM_386;
	ehdr->e_version = EV_CURRENT;
	ehdr->e_entry = 0;
	ehdr->e_phoff = 0;
	ehdr->e_shoff = 0; // Will be set by elf_update
	ehdr->e_flags = 0;
	ehdr->e_ehsize = sizeof(GElf_Ehdr);
	ehdr->e_phentsize = 0;
	ehdr->e_phnum = 0;
	ehdr->e_shentsize = sizeof(GElf_Shdr);
	ehdr->e_shnum = 0; // Will be set by elf_update
	ehdr->e_shstrndx = SHN_UNDEF; // Will be set later

	/* String Table */
	scn = elf_newscn(elf);
	if (!scn) {
		fprintf(stderr, "%s: elf_newscn failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	strings.off = 0;
	strings.scn = scn;
	ehdr->e_shstrndx = elf_ndxscn(scn);
	newstr("");
	initscn(scn, ".strtab", SHT_STRTAB, 0, SHN_UNDEF, 0, 0);

	/* Symbol table */
	size_t sym_ent_size = gelf_fsize(elf, ELF_T_SYM, 1, EV_CURRENT);
	scn = elf_newscn(elf);
	if (!scn) {
		fprintf(stderr, "%s: elf_newscn failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	syms.off = 0;
	syms.scn = scn;
	initscn(scn, ".symtab", SHT_SYMTAB, 0, elf_ndxscn(strings.scn), 0, sym_ent_size);
	newsym (0, 0, 0);

	/* data */
	for (;;) {
		if (fgets(line, sizeof line, in) == 0) {
			UNEXPECTED_EOF;
		}
		if (strcmp (line, "END\n") == 0)
			break;
		if (strcmp (line, "NEW BLOCK\n") != 0) {
			BUG(2);
		}
		addblock (elf);
	}
	/* Update ELF to compute sizes and offsets */
	if (elf_update(elf, ELF_C_NULL) < 0) {
		fprintf(stderr, "%s: elf_update failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	/* Write ELF to file */
	if (elf_update(elf, ELF_C_WRITE) < 0) {
		fprintf(stderr, "%s: elf_update failed: %s\n", cmdname, elf_errmsg(-1));
		exit(1);
	}
	elf_end (elf);
	if (outfile)
		close(fd);
	return 0;
}
