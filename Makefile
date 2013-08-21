PROG=		bcftools

all: $(PROG)

# Adjust $(HTSDIR) to point to your top-level htslib directory
HTSDIR = ../htslib
include $(HTSDIR)/htslib.mk
HTSLIB = $(HTSDIR)/libhts.a

CC=			gcc
CFLAGS=		-g -Wall -Wc++-compat -O2 $(VERSION)
DFLAGS=
OBJS=		main.o vcfview.o bcfidx.o tabix.o \
			vcfcheck.o vcfisec.o vcfmerge.o vcfquery.o vcffilter.o \
            vcfnorm.o vcfgtcheck.o vcfsubset.o \
            vcfcall.o mcall.o
INCLUDES=	-I. -I$(HTSDIR)
SUBDIRS=    .

all-recur lib-recur clean-recur cleanlocal-recur install-recur:
		@target=`echo $@ | sed s/-recur//`; \
		wdir=`pwd`; \
		list='$(SUBDIRS)'; for subdir in $$list; do \
			cd $$subdir; \
			$(MAKE) CC="$(CC)" DFLAGS="$(DFLAGS)" CFLAGS="$(CFLAGS)" \
				HTSDIR="$(HTSDIR)" HTSLIB="$(HTSLIB)" \
				INCLUDES="$(INCLUDES)" LIBPATH="$(LIBPATH)" $$target || exit 1; \
			cd $$wdir; \
		done;

all:$(PROG)

# See htslib/Makefile
PACKAGE_VERSION  = 0.0.1
LIBHTS_SOVERSION = 0
NUMERIC_VERSION  = $(PACKAGE_VERSION)
ifneq "$(wildcard .git)" ""
original_version := $(PACKAGE_VERSION)
PACKAGE_VERSION := $(shell git describe --always --dirty)
ifneq "$(subst ..,.,$(subst 0,,$(subst 1,,$(subst 2,,$(subst 3,,$(subst 4,,$(subst 5,,$(subst 6,,$(subst 7,,$(subst 8,,$(subst 9,,$(PACKAGE_VERSION))))))))))))" "."
empty :=
NUMERIC_VERSION := $(subst $(empty) ,.,$(wordlist 1,2,$(subst ., ,$(original_version))) 255)
endif
version.h: $(if $(wildcard version.h),$(if $(findstring "$(PACKAGE_VERSION)",$(shell cat version.h)),,force))
endif
version.h:
	printf '#define BCFTOOLS_VERSION "$(PACKAGE_VERSION)"\nchar *bcftools_version(void);\n' > $@


.SUFFIXES:.c .o
.PHONY:all lib test force

force:

.c.o:
		$(CC) -c $(CFLAGS) $(DFLAGS) $(INCLUDES) $< -o $@

test:
		./test/test.pl

main.o: version.h $(HTSDIR)/version.h
vcfcall.o: vcfcall.c call.h mcall.c prob1.h $(HTSDIR)/htslib/kfunc.h $(HTSDIR)/htslib/vcf.h

bcftools:lib-recur $(HTSLIB) $(OBJS)
		$(CC) $(CFLAGS) -o $@ $(OBJS) $(HTSLIB) -lpthread -lz -lm

clean:
		rm -fr gmon.out *.o a.out *.dSYM *~ $(PROG)
