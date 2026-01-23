Q ?= @
O ?= out
CFLAGS ?=
LDFLAGS ?=
INST ?= /usr

all:  $(O)/bin/lrtest $(O)/lib/liblrtest.a $(O)/lib/liblrtest.so.0 $(O)/lib/liblrtest.so

Makefile: lrbuild.ox sub1/lrbuild.ox sub2/lrbuild.ox
	$(Q)$(info GEN  $@)
	$(Q)"lordrabbit" "--nocache"

-include $(O)/intermediate/lrtest-exe-main.dep $(O)/intermediate/lrtest-lib-lib.dep $(O)/intermediate/lrtest-lib-gen.dep $(O)/intermediate/sub1/sub1-lib-sub1.dep $(O)/intermediate/sub2/sub2-lib-sub2.dep

$(O)/bin/lrtest: $(O)/intermediate/lrtest-exe-main.o  $(O)/lib/liblrtest.so
	$(Q)$(info EXE  $@ <- $^)
	$(Q)mkdir -p $(dir $@)
	$(Q)gcc -o $(O)/bin/lrtest $(O)/intermediate/lrtest-exe-main.o -L$(O)/lib -llrtest $(LDFLAGS)  -lcurl -lncursesw -ltinfo -lSDL

$(O)/lib/liblrtest.a: $(O)/intermediate/lrtest-lib-lib.o $(O)/intermediate/lrtest-lib-gen.o  $(O)/intermediate/sub1/libsub1.a $(O)/intermediate/sub2/libsub2.a
	$(Q)$(info SLIB $@ <- $^)
	$(Q)mkdir -p $(dir $@)
	$(Q)ar rcs $(O)/lib/liblrtest.a $(O)/intermediate/lrtest-lib-lib.o $(O)/intermediate/lrtest-lib-gen.o
	$(Q)ranlib $(O)/lib/liblrtest.a

$(O)/lib/liblrtest.so.0: $(O)/intermediate/lrtest-lib-lib.o $(O)/intermediate/lrtest-lib-gen.o  $(O)/intermediate/sub1/libsub1.a $(O)/intermediate/sub2/libsub2.a
	$(Q)$(info DLIB $@ <- $^)
	$(Q)mkdir -p $(O)/lib
	$(Q)gcc -o $(O)/lib/liblrtest.so.0 $(O)/intermediate/lrtest-lib-lib.o $(O)/intermediate/lrtest-lib-gen.o -shared -L$(O)/intermediate/sub1 -L$(O)/intermediate/sub2 -lsub1 -lsub2 $(LDFLAGS)  -lSDL -Wl,-soname,liblrtest.so.0

$(O)/lib/liblrtest.so: $(O)/lib/liblrtest.so.0
	$(Q)$(info LN   $@ <- liblrtest.so.0)
	$(Q)ln -s -f liblrtest.so.0 $@

$(O)/intermediate/gen.c: gen.ox
	$(Q)$(info GEN  $@ <- $^)
	$(Q)ox gen.ox > $(O)/intermediate/gen.c

$(O)/intermediate/sub1/libsub1.a: $(O)/intermediate/sub1/sub1-lib-sub1.o 
	$(Q)$(info SLIB $@ <- $^)
	$(Q)mkdir -p $(dir $@)
	$(Q)ar rcs $(O)/intermediate/sub1/libsub1.a $(O)/intermediate/sub1/sub1-lib-sub1.o
	$(Q)ranlib $(O)/intermediate/sub1/libsub1.a

$(O)/intermediate/sub2/libsub2.a: $(O)/intermediate/sub2/sub2-lib-sub2.o 
	$(Q)$(info SLIB $@ <- $^)
	$(Q)mkdir -p $(dir $@)
	$(Q)ar rcs $(O)/intermediate/sub2/libsub2.a $(O)/intermediate/sub2/sub2-lib-sub2.o
	$(Q)ranlib $(O)/intermediate/sub2/libsub2.a

$(O)/intermediate/lrtest-exe-main.o: main.c
	$(Q)$(info CC   $@ <- main.c)
	$(Q)mkdir -p $(dir $@)
	$(Q)gcc -c -o $(O)/intermediate/lrtest-exe-main.o main.c -MMD -MF $(O)/intermediate/lrtest-exe-main.dep  -DVERSION=0 -I$(O)/intermediate $(CFLAGS)  -I/usr/include/x86_64-linux-gnu -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=600 -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 

$(O)/intermediate/lrtest-lib-lib.o: lib.c
	$(Q)$(info CC   $@ <- lib.c)
	$(Q)mkdir -p $(dir $@)
	$(Q)gcc -c -o $(O)/intermediate/lrtest-lib-lib.o lib.c -MMD -MF $(O)/intermediate/lrtest-lib-lib.dep -fPIC   $(CFLAGS)  -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 

$(O)/intermediate/lrtest-lib-gen.o: $(O)/intermediate/gen.c
	$(Q)$(info CC   $@ <- $(O)/intermediate/gen.c)
	$(Q)mkdir -p $(dir $@)
	$(Q)gcc -c -o $(O)/intermediate/lrtest-lib-gen.o $(O)/intermediate/gen.c -MMD -MF $(O)/intermediate/lrtest-lib-gen.dep -fPIC   $(CFLAGS)  -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 

$(O)/intermediate/sub1/sub1-lib-sub1.o: sub1/sub1.c
	$(Q)$(info CC   $@ <- sub1/sub1.c)
	$(Q)mkdir -p $(dir $@)
	$(Q)gcc -c -o $(O)/intermediate/sub1/sub1-lib-sub1.o sub1/sub1.c -MMD -MF $(O)/intermediate/sub1/sub1-lib-sub1.dep    $(CFLAGS)  -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 

$(O)/intermediate/sub2/sub2-lib-sub2.o: sub2/sub2.c
	$(Q)$(info CC   $@ <- sub2/sub2.c)
	$(Q)mkdir -p $(dir $@)
	$(Q)gcc -c -o $(O)/intermediate/sub2/sub2-lib-sub2.o sub2/sub2.c -MMD -MF $(O)/intermediate/sub2/sub2-lib-sub2.dep    $(CFLAGS)  -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -Wall -O2 



install:  $(O)/bin/lrtest $(O)/lib/liblrtest.a $(O)/lib/liblrtest.so.0 $(O)/lib/liblrtest.so uninstall
	$(Q)$(info INSTALL)
	$(Q)mkdir -p $(INST)/bin
	$(Q)mkdir -p $(INST)/lib
	$(Q)mkdir -p $(INST)/include/lrtest
	$(Q)install -T -m 755  $(O)/bin/lrtest $(INST)/bin/lrtest
	$(Q)install -T -m 644  $(O)/lib/liblrtest.a $(INST)/lib/liblrtest.a
	$(Q)install -T -m 644 -s $(O)/lib/liblrtest.so.0 $(INST)/lib/liblrtest.so.0
	$(Q)ln -s -f liblrtest.so.0 $(INST)/lib/liblrtest.so
	$(Q)install -T -m 644  test.h $(INST)/include/lrtest/test.h
	$(Q)install -T -m 644  $(O)/intermediate/config.h $(INST)/include/lrtest/config.h

uninstall:
	$(Q)$(info UNINSTALL)
	$(Q)rm -f $(INST)/bin/lrtest
	$(Q)rm -f $(INST)/lib/liblrtest.a
	$(Q)rm -f $(INST)/lib/liblrtest.so.0
	$(Q)rm -f $(INST)/lib/liblrtest.so
	$(Q)rm -f $(INST)/include/lrtest/test.h
	$(Q)rm -f $(INST)/include/lrtest/config.h

clean:
	$(Q)$(info CLEAN)
	$(Q)rm -f  $(O)/bin/lrtest $(O)/lib/liblrtest.a $(O)/lib/liblrtest.so.0 $(O)/lib/liblrtest.so $(O)/intermediate/lrtest-exe-main.o $(O)/intermediate/lrtest-lib-lib.o $(O)/intermediate/lrtest-lib-gen.o $(O)/intermediate/sub1/sub1-lib-sub1.o $(O)/intermediate/sub2/sub2-lib-sub2.o

cleanall:
	$(Q)$(info CLEAN ALL)
	$(Q)rm -f  $(O)/bin/lrtest $(O)/lib/liblrtest.a $(O)/lib/liblrtest.so.0 $(O)/lib/liblrtest.so $(O)/intermediate/lrtest-exe-main.o $(O)/intermediate/lrtest-lib-lib.o $(O)/intermediate/lrtest-lib-gen.o $(O)/intermediate/sub1/sub1-lib-sub1.o $(O)/intermediate/sub2/sub2-lib-sub2.o  $(O)/intermediate/lrtest-exe-main.dep $(O)/intermediate/lrtest-lib-lib.dep $(O)/intermediate/lrtest-lib-gen.dep $(O)/intermediate/sub1/sub1-lib-sub1.dep $(O)/intermediate/sub2/sub2-lib-sub2.dep  $(O)/intermediate/gen.c $(O)/intermediate/gen.c $(O)/intermediate/sub1/libsub1.a $(O)/intermediate/sub2/libsub2.a

cleanout:
	$(Q)$(info CLEAN OUT)
	$(Q)rm -rf $(O)

.PHONY: all clean cleanall cleanout install uninstall