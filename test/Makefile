Q ?= @
INST ?= /usr

all: out/lrtest out/liblrtest.a out/liblrtest.so.0 test.h out/config.h

Makefile: lrbuild.ox sub1/lrbuild.ox sub2/lrbuild.ox
	$(info CONFIG $@)
	$(Q)"lordrabbit"

-include  out/lrtest-exe-main.dep out/lrtest-lib-lib.dep out/lrtest-lib-gen.dep out/sub1/sub1-slib-sub1.dep out/sub2/sub2-slib-sub2.dep

out/lrtest: out/lrtest-exe-main.o out/liblrtest.a out/liblrtest.so
	$(info BUILD out/lrtest <= out/lrtest-exe-main.o out/liblrtest.a out/liblrtest.so)
	$(Q)mkdir -p out
	$(Q)gcc -o out/lrtest out/lrtest-exe-main.o -Lout -llrtest  -lcurl -lncursesw -ltinfo -lSDL

out/liblrtest.a: out/lrtest-lib-lib.o out/lrtest-lib-gen.o
	$(info BUILD out/liblrtest.a <= out/lrtest-lib-lib.o out/lrtest-lib-gen.o)
	$(Q)mkdir -p out
	$(Q)ar rcs out/liblrtest.a out/lrtest-lib-lib.o out/lrtest-lib-gen.o
	$(Q)ranlib out/liblrtest.a

out/liblrtest.so.0: out/lrtest-lib-lib.o out/lrtest-lib-gen.o out/sub1/libsub1.a out/sub2/libsub2.a
	$(info BUILD out/liblrtest.so.0 <= out/lrtest-lib-lib.o out/lrtest-lib-gen.o out/sub1/libsub1.a out/sub2/libsub2.a)
	$(Q)mkdir -p out
	$(Q)gcc -o out/liblrtest.so.0 out/lrtest-lib-lib.o out/lrtest-lib-gen.o -shared -Lout/sub1 -Lout/sub2 -lsub1 -lsub2   -lSDL -Wl,-soname,liblrtest.so.0

out/liblrtest.so: out/liblrtest.so.0
	$(info BUILD out/liblrtest.so <= out/liblrtest.so.0)
	$(Q)ln -s -f liblrtest.so.0 out/liblrtest.so

out/gen.c: gen.ox
	$(info BUILD out/gen.c <= gen.ox)
	$(Q)ox gen.ox > out/gen.c

out/sub1/libsub1.a: out/sub1/sub1-slib-sub1.o
	$(info BUILD out/sub1/libsub1.a <= out/sub1/sub1-slib-sub1.o)
	$(Q)mkdir -p out/sub1
	$(Q)ar rcs out/sub1/libsub1.a out/sub1/sub1-slib-sub1.o
	$(Q)ranlib out/sub1/libsub1.a

out/sub2/libsub2.a: out/sub2/sub2-slib-sub2.o
	$(info BUILD out/sub2/libsub2.a <= out/sub2/sub2-slib-sub2.o)
	$(Q)mkdir -p out/sub2
	$(Q)ar rcs out/sub2/libsub2.a out/sub2/sub2-slib-sub2.o
	$(Q)ranlib out/sub2/libsub2.a

out/lrtest-exe-main.o: main.c
	$(info BUILD out/lrtest-exe-main.o <= main.c)
	$(Q)mkdir -p out
	$(Q)gcc -c -o out/lrtest-exe-main.o main.c -MMD -MF out/lrtest-exe-main.dep  -DVERSION=0  -include out/config.h  -I/usr/include/x86_64-linux-gnu -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=600 -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 

out/lrtest-lib-lib.o: lib.c
	$(info BUILD out/lrtest-lib-lib.o <= lib.c)
	$(Q)mkdir -p out
	$(Q)gcc -c -o out/lrtest-lib-lib.o lib.c -MMD -MF out/lrtest-lib-lib.dep    -include out/config.h   -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 

out/lrtest-lib-gen.o: out/gen.c
	$(info BUILD out/lrtest-lib-gen.o <= out/gen.c)
	$(Q)mkdir -p out
	$(Q)gcc -c -o out/lrtest-lib-gen.o out/gen.c -MMD -MF out/lrtest-lib-gen.dep    -include out/config.h   -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 

out/sub1/sub1-slib-sub1.o: sub1/sub1.c
	$(info BUILD out/sub1/sub1-slib-sub1.o <= sub1/sub1.c)
	$(Q)mkdir -p out/sub1
	$(Q)gcc -c -o out/sub1/sub1-slib-sub1.o sub1/sub1.c -MMD -MF out/sub1/sub1-slib-sub1.dep    -include out/config.h   -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 

out/sub2/sub2-slib-sub2.o: sub2/sub2.c
	$(info BUILD out/sub2/sub2-slib-sub2.o <= sub2/sub2.c)
	$(Q)mkdir -p out/sub2
	$(Q)gcc -c -o out/sub2/sub2-slib-sub2.o sub2/sub2.c -MMD -MF out/sub2/sub2-slib-sub2.dep    -include out/config.h   -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 



install: all uninstall
	$(info INSTALL)
	$(Q)install -D -T -m 0755 -s out/lrtest $$(INST)/bin/lrtest
	$(Q)install -D -T -m 0644  out/liblrtest.a $$(INST)/lib/lrtest.a
	$(Q)install -D -T -m 0644 -s out/liblrtest.so.0 $$(INST)/lib/liblrtest.so.0
	$(Q)ln -s -f liblrtest.so.0 $$(INST)/lib/liblrtest.so
	$(Q)install -D   test.h -t $$(INST)/include/lrtest
	$(Q)install -D   out/config.h -t $$(INST)/include/lrtest

uninstall:
	$(info UNINSTALL)
	$(Q)rm -f $$(INST)/bin/lrtest
	$(Q)rm -f $$(INST)/lib/lrtest.a
	$(Q)rm -f $$(INST)/lib/liblrtest.so.0
	$(Q)rm -f $$(INST)/lib/liblrtest.so
	$(Q)rm -f $$(INST)/include/lrtest/test.h
	$(Q)rm -f $$(INST)/include/lrtest/config.h

clean:
	$(info CLEAN)
	$(Q)rm -f  out/lrtest out/liblrtest.a out/liblrtest.so.0 out/liblrtest.so out/gen.c out/sub1/libsub1.a out/sub2/libsub2.a out/lrtest-exe-main.o out/lrtest-exe-main.dep out/lrtest-lib-lib.o out/lrtest-lib-lib.dep out/lrtest-lib-gen.o out/lrtest-lib-gen.dep out/sub1/sub1-slib-sub1.o out/sub1/sub1-slib-sub1.dep out/sub2/sub2-slib-sub2.o out/sub2/sub2-slib-sub2.dep

cleanout:
	$(info CLEAN OUTPUT)
	$(Q)rm -rf out

.PHONY: all clean cleanout install uninstall
