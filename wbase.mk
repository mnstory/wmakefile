#make file template create by mnstory.net
#version 1.0 @20150226

#manual reference to https://www.gnu.org/software/make/manual/html_node/index.html
#to see pre-define vars, use make -p https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html
#to see Special-Variables, https://www.gnu.org/software/make/manual/html_node/Special-Variables.html#Special-Variables

#color
C0=\033[00m
CRED=\033[01;31m
CGREEN=\033[01;32m
CYELLOW=\033[01;33m
CPURPLE=\033[01;35m
CBLUE=\033[01;34m
CCYAN=\033[01;36m
CWHITE=\033[01;37m
CBOLD=\033[1m
CUNDERLINE=\033[4m
CBLINK=\033[5m

CWARN=$(CBOLD)
CNOTICE=$(CPURPLE)
CERROR=$(CRED)
COK=$(CGREEN)

#user args
#if define SUBDIRS, call SUBDIRS's makefile
SUBDIRS     ?=
#else for single program
TARGET      ?= program
INSTALLDIR  ?= /usr/bin
CPPFLAGS    ?= -I. -Wall -Werror
SRCDIRS     ?= .
LDFLAGS     ?= -L.
LINKSTATIC  ?=
LINKDYNAMIC ?=

#trim args
TARGET      := $(strip $(TARGET))
SUBDIRS     := $(strip $(SUBDIRS))
INSTALLDIR  := $(strip $(INSTALLDIR))
LINKSTATIC  := $(strip $(LINKSTATIC))
LINKDYNAMIC := $(strip $(LINKDYNAMIC))

#expend sources, objects, depends
_SFIX    := .c .cpp .cc .cxx
_SOURCES := $(foreach x, ${SRCDIRS}, $(wildcard $(addprefix ${x}/*,${_SFIX})))
_OBJS    := $(addsuffix .o ,$(basename ${_SOURCES}))
_DEPENDS := $(addsuffix .d ,$(basename ${_SOURCES}))
_HASCXX  := $(strip $(filter-out %.c, ${_SOURCES}))
ifdef _HASCXX
	CC     = ${CXX}
	CFLAGS = ${CXXFLAGS}
endif

#static only or dynamic only link
ifneq (${LINKSTATIC},)
	LDFLAGS += -WI,-Bstatic ${LINKSTATIC}
else ifneq (${LINKDYNAMIC},)
	LDFLAGS += -WI,-Bdynamic ${LINKDYNAMIC}
endif

#judge link type
ifeq ($(filter %.so, ${TARGET}),${TARGET})
	CPPFLAGS += -fPIC
	_LINK.target = $(CC) -shared $(LDFLAGS) -o
else ifeq ($(filter %.a, ${TARGET}),${TARGET})
	CPPFLAGS += -fPIC
	_LINK.target = $(AR) rc
else
	_LINK.target = $(CC) $(LDFLAGS) -o
endif

#_DEPENDS
%.d : %.c
	@${CC} -MM -MF $(addsuffix .d ,$(basename $<)) ${CFLAGS} ${CPPFLAGS} $<

%.d : %.cc
	@${CXX} -MM -MF $(addsuffix .d ,$(basename $<)) ${CXXFLAGS} ${CPPFLAGS} $<

%.d : %.cpp
	@${CXX} -MM -MF $(addsuffix .d ,$(basename $<)) ${CXXFLAGS} ${CPPFLAGS} $<

ifeq (${SUBDIRS},)
#default target, define ${TPREFIX} to rename this target
${TPREFIX}all: ${TARGET}
	@echo "make ${COK}${TARGET}${C0} success"
${TPREFIX}install: ${TPREFIX}all
	install -d ${INSTALLDIR}
	install ${TARGET} ${INSTALLDIR}
#_OBJS us Implicit rule
${TARGET}: ${_DEPENDS} ${_OBJS}
	$(_LINK.target) $@ ${_OBJS}

#use :: for clean && show, if you want to show something else, just define another target clean:: or show::
clean::
	rm -f ${TARGET} ${_OBJS} ${_DEPENDS} *.o *.d

show::
	$(foreach v, $(sort $(.VARIABLES)), \
		$(if $(filter-out environment%  automatic, $(origin $v)), \
			$(if $(filter-out C0 CRED CGREEN CYELLOW CPURPLE CBLUE CCYAN CWHITE CBOLD CUNDERLINE CBLINK CWARN CNOTICE CERROR COK, $v), \
				$(info $v = $(value $v) => $($v)) \
			)\
		)\
	)
	$(info MAKECMDGOALS = $(MAKECMDGOALS))
	$(info MAKEOVERRIDES = $(MAKEOVERRIDES))
	@echo > /dev/null

#execute these targets every time
.PHONY: ${TPREFIX}all ${TPREFIX}install clean show

#ifneq (${SUBDIRS},)
else

#if not exist goals, use all replace
_TARGETS := $(strip ${MAKECMDGOALS})
ifeq (${_TARGETS},)
	_TARGETS=all
endif

#define template for subdirs
define subdirs
	@for d in ${SUBDIRS}; do \
		echo "${CBOLD}$(MAKE) -C $$d$(1)${C0}"; \
		$(MAKE) -C $$d$(1) || exit $?; done
endef

${_TARGETS}:
	$(call subdirs, ${MAKECMDGOALS} $(MAKEOVERRIDES))
	@echo "make subdirs ${MAKECMDGOALS} $(MAKEOVERRIDES) ${COK}${SUBDIRS}${C0} success"
.PHONY: ${_TARGETS}

#end ifeq (${SUBDIRS},)
endif