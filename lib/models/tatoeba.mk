# -*-makefile-*-
#
# Makefile for running models with data from the Tatoeba Translation Challenge
# https://github.com/Helsinki-NLP/Tatoeba-Challenge
#
#
#---------------------------------------------------------------------
# train and evaluate a single translation pair, for example:
#
#   make SRCLANGS=afr TRGLANGS=epo tatoeba-prepare
#   make SRCLANGS=afr TRGLANGS=epo tatoeba-train
#   make SRCLANGS=afr TRGLANGS=epo tatoeba-eval
#
#
# start job for a single language pair in one direction or
# in both directions, for example:
#
#   make SRCLANGS=afr TRGLANGS=epo tatoeba-job
#   make SRCLANGS=afr TRGLANGS=epo tatoeba-bidirectional-job
#
#
# start jobs for all pairs in an entire subset:
#
#   make tatoeba-subset-lowest
#   make tatoeba-subset-lower
#   make tatoeba-subset-medium
#   make MODELTYPE=transformer tatoeba-subset-higher
#   make MODELTYPE=transformer tatoeba-subset-highest
#
# other jobs to run on the entire subset (example = medium):
#
#   make tatoeba-distsubset-medium .... create release files
#   make tatoeba-evalsubset-medium .... eval all models
#
#
# start jobs for multilingual models from one of the subsets
#
#   make tatoeba-multilingual-subset-zero
#   make tatoeba-multilingual-subset-lowest
#   make tatoeba-multilingual-subset-lower
#   make tatoeba-multilingual-subset-medium
#   make tatoeba-multilingual-subset-higher
#   make tatoeba-multilingual-subset-highest
#
# other jobs to run on the entire subset (example = medium):
#
#   make tatoeba-multilingual-distsubset-medium .... create release files
#   make tatoeba-multilingual-evalsubset-medium .... eval all langpairs
#---------------------------------------------------------------------
#
# generate evaluation tables
#
#   rm -f tatoeba-results* results/*.md
#   make tatoeba-results-md
#---------------------------------------------------------------------


## general parameters for Tatoeba models

TATOEBA_DATAURL = https://object.pouta.csc.fi/Tatoeba-Challenge
TATOEBA_RAWGIT  = https://raw.githubusercontent.com/Helsinki-NLP/Tatoeba-Challenge/master
TATOEBA_WORK    = ${PWD}/work-tatoeba
TATOEBA_DATA    = ${TATOEBA_WORK}/data/${PRE}

TATOEBA_MODEL_CONTAINER = Tatoeba-MT-models

TATOEBA_PARAMS = TRAINSET=Tatoeba-train \
		DEVSET=Tatoeba-dev \
		TESTSET=Tatoeba-test \
		TESTSET_NAME=Tatoeba-test \
		SMALLEST_TRAINSIZE=1000 \
		USE_REST_DEVDATA=0 \
		HELDOUTSIZE=0 \
		DEVSIZE=5000 \
		TESTSIZE=10000 \
		DEVMINSIZE=200 \
		WORKHOME=${TATOEBA_WORK} \
		MODELSHOME=${PWD}/models-tatoeba \
                MODELS_URL=https://object.pouta.csc.fi/${TATOEBA_MODEL_CONTAINER} \
		MODEL_CONTAINER=${TATOEBA_MODEL_CONTAINER} \
		ALT_MODEL_DIR=tatoeba \
		SKIP_DATA_DETAILS=1 \
		MIN_BLEU_SCORE=10 \



## taken from the Tatoeba-Challenge Makefile
## requires local data for setting TATOEBA_LANGS

ISO639         = iso639
GET_ISO_CODE   = ${ISO639} -m
TATOEBA_LANGS  = ${sort ${patsubst %.txt.gz,%,${notdir ${wildcard ${OPUSHOME}/Tatoeba/latest/mono/*.txt.gz}}}}
TATOEBA_LANGS3 = ${sort ${filter-out xxx,${shell ${GET_ISO_CODE} ${TATOEBA_LANGS}}}}
TATOEBA_LANGPARENTS = ${sort ${shell langgroup -p -n ${TATOEBA_LANGS3} 2>/dev/null}}
TATOEBA_LANGGROUPS  = ${shell langgroup -g -n ${TATOEBA_LANGS3} 2>/dev/null | tr " " "\n" | grep '+'}
TATOEBA_LANGGROUPS2 = ${shell langgroup -G -n ${TATOEBA_LANGS3} 2>/dev/null | tr " " "\n" | grep '+'}

## OPUS LANGS
OPUS_LANGS3      = ${sort ${filter-out xxx,${shell ${GET_ISO_CODE} ${OPUSLANGS}}}}
OPUS_LANGPARENTS = ${sort ${shell langgroup -p -n ${OPUS_LANGS3} 2>/dev/null}}
OPUS_LANGGROUPS  = ${shell langgroup -g -n ${OPUS_LANGS3} 2>/dev/null | tr " " "\n" | grep '+'}
OPUS_LANGGROUPS2 = ${shell langgroup -G -n ${OPUS_LANGS3} 2>/dev/null | tr " " "\n" | grep '+'}

## combined (to make sure we don't miss anything)
OPUSTATOEBA_LANGS3       = ${sort ${OPUS_LANGS3} ${TATOEBA_LANGS3}}
OPUSTATOEBA_LANGPARENTS  = ${sort ${OPUS_LANGPARENTS} ${TATOEBA_LANGPARENTS}}
OPUSTATOEBA_LANGGROUPS   = ${shell langgroup -g -n ${OPUSTATOEBA_LANGS3} 2>/dev/null | tr " " "\n" | grep '+'}
OPUSTATOEBA_LANGGROUPS2  = ${shell langgroup -G -n ${OPUSTATOEBA_LANGS3} 2>/dev/null | tr " " "\n" | grep '+'}



# some special language models

TATOEBA_WESTGERMANIC = ${sort eng nld gos hrx swg prg nld yid deu ltz fry nds afr bar ang enm sco}
tatoeba-westgermanic:
	${MAKE} SRCLANGS="${TATOEBA_WESTGERMANIC}" TRGLANGS="${TATOEBA_WESTGERMANIC}" \
		FIT_DATA_SIZE=100000 LANGPAIRSTR=westgermanic \
	tatoeba-multilingual-train

tatoeba-westgermanice-eval:
	${MAKE} SRCLANGS="${TATOEBA_WESTGERMANIC}" TRGLANGS="${TATOEBA_WESTGERMANIC}" \
		FIT_DATA_SIZE=100000 LANGPAIRSTR=westgermanic \
	tatoeba-multilingual-eval
	${MAKE} SRCLANGS="${TATOEBA_WESTGERMANIC}" TRGLANGS="${TATOEBA_WESTGERMANIC}" \
		FIT_DATA_SIZE=100000 LANGPAIRSTR=westgermanic \
	dist-tatoeba


###########################################################################################
# language groups
###########################################################################################

## print language groups
tatoeba-langgroups:
	@echo ${TATOEBA_LANGGROUPS}
	@echo ${TATOEBA_LANGGROUPS2}
	@echo ${TATOEBA_LANGPARENTS}

opus-langgroups:
	@echo ${OPUSTATOEBA_LANGGROUPS}
	@echo ${OPUSTATOEBA_LANGGROUPS2}
	@echo ${OPUSTATOEBA_LANGPARENTS}


# ## multilingual models for language groups
# tatoeba-langgroup:
# 	for g in ${TATOEBA_LANGGROUPS}; do \
# 	  l=`echo $$g | sed 's/\+/ /g'`; \
# 	  n=`langgroup -p $$l | cut -f1 -d' '`; \
# 	  ${MAKE} LANGPAIRSTR="$$n-$$n" TRGLANGS="$$l" SRCLANGS="$$l" \
# 		MODELTYPE=transformer FIT_DATA_SIZE=1000000 tatoeba-multilingual-train; \
# 	done

# ## models for language groups to English
# tatoeba-group2eng:
# 	for g in ${TATOEBA_LANGGROUPS}; do \
# 	  l=`echo $$g | sed 's/\+/ /g'`; \
# 	  n=`langgroup -p $$l | cut -f1 -d' '`; \
# 	  ${MAKE} LANGPAIRSTR="$$n-eng" SRCLANGS="$$l" TRGLANGS=eng \
# 		MODELTYPE=transformer FIT_DATA_SIZE=1000000 tatoeba-multilingual-train; \
# 	done

# ## models for English to language groups
# tatoeba-eng2group:
# 	for g in ${TATOEBA_LANGGROUPS}; do \
# 	  l=`echo $$g | sed 's/\+/ /g'`; \
# 	  n=`langgroup -p $$l | cut -f1 -d' '`; \
# 	  ${MAKE} LANGPAIRSTR="eng-$$n" TRGLANGS="$$l" SRCLANGS=eng \
# 		MODELTYPE=transformer FIT_DATA_SIZE=1000000 tatoeba-multilingual-train; \
# 	done





# ##-------------------------------------------------------------------
# ## multilingual models 
# ## with all OPUS data not only the languages that have Tatoeba data
# ##-------------------------------------------------------------------

# ## multilingual models for language groups
# tatoeba-all-langgroup:
# 	for g in ${OPUSTATOEBA_LANGGROUPS}; do \
# 	  l=`echo $$g | sed 's/\+/ /g'`; \
# 	  n=`langgroup -p $$l | cut -f1 -d' '`; \
# 	  ${MAKE} LANGPAIRSTR="all-$$n-$$n" TRGLANGS="$$l" SRCLANGS="$$l" \
# 		MODELTYPE=transformer FIT_DATA_SIZE=1000000 tatoeba-multilingual-train; \
# 	done

# ## models for language groups to English
# tatoeba-all-group2eng:
# 	for g in ${OPUSTATOEBA_LANGGROUPS}; do \
# 	  l=`echo $$g | sed 's/\+/ /g'`; \
# 	  n=`langgroup -p $$l | cut -f1 -d' '`; \
# 	  ${MAKE} LANGPAIRSTR="all-$$n-eng" SRCLANGS="$$l" TRGLANGS=eng \
# 		MODELTYPE=transformer FIT_DATA_SIZE=1000000 tatoeba-multilingual-train; \
# 	done

# ## models for English to language groups
# tatoeba-all-eng2group:
# 	for g in ${OPUSTATOEBA_LANGGROUPS}; do \
# 	  l=`echo $$g | sed 's/\+/ /g'`; \
# 	  n=`langgroup -p $$l | cut -f1 -d' '`; \
# 	  ${MAKE} LANGPAIRSTR="all-eng-$$n" TRGLANGS="$$l" SRCLANGS=eng \
# 		MODELTYPE=transformer FIT_DATA_SIZE=1000000 tatoeba-multilingual-train; \
# 	done








#### language-group to English

GROUP2ENG_JOB     = $(patsubst %,tatoeba-%2eng-job,${TATOEBA_LANGPARENTS})
GROUP2ENG_TRAIN   = $(patsubst %,tatoeba-%2eng-train,${TATOEBA_LANGPARENTS})
GROUP2ENG_EVAL    = $(patsubst %,tatoeba-%2eng-eval,${TATOEBA_LANGPARENTS})
GROUP2ENG_EVALALL = $(patsubst %,tatoeba-%2eng-evalall,${TATOEBA_LANGPARENTS})
GROUP2ENG_DIST    = $(patsubst %,tatoeba-%2eng-dist,${TATOEBA_LANGPARENTS})

tatoeba-group2eng: ${GROUP2ENG_JOB}

${GROUP2ENG_JOB}:
	${MAKE} $(patsubst %-job,%-train,$@)
	${MAKE} $(patsubst %-job,%-eval,$@)
	${MAKE} $(patsubst %-job,%-evalall,$@)
	${MAKE} $(patsubst %-job,%-dist,$@)

${GROUP2ENG_TRAIN}:
	${MAKE} LANGPAIRSTR=$(patsubst tatoeba-%2eng-train,%,$@)-eng \
		SRCLANGS="${shell langgroup -n $(patsubst tatoeba-%2eng-train,%,$@)}" \
		TRGLANGS=eng MODELTYPE=transformer FIT_DATA_SIZE=1000000 \
	tatoeba-multilingual-train

${GROUP2ENG_EVAL}:
	${MAKE} LANGPAIRSTR=$(patsubst tatoeba-%2eng-eval,%,$@)-eng \
		SRCLANGS="${shell langgroup -n $(patsubst tatoeba-%2eng-eval,%,$@)}" \
		TRGLANGS=eng \
		MODELTYPE=transformer \
		${TATOEBA_PARAMS} \
	compare

${GROUP2ENG_EVALALL}:
	${MAKE} LANGPAIRSTR=$(patsubst tatoeba-%2eng-evalall,%,$@)-eng \
		SRCLANGS="${shell langgroup -n $(patsubst tatoeba-%2eng-evalall,%,$@)}" \
		TRGLANGS=eng MODELTYPE=transformer FIT_DATA_SIZE=1000000 \
	tatoeba-multilingual-eval

${GROUP2ENG_DIST}:
	${MAKE} LANGPAIRSTR=$(patsubst tatoeba-%2eng-dist,%,$@)-eng \
		SRCLANGS="${shell langgroup -n $(patsubst tatoeba-%2eng-dist,%,$@)}" \
		TRGLANGS=eng \
		MODELTYPE=transformer \
		${TATOEBA_PARAMS} \
	best-dist


#### English to language group

ENG2GROUP_JOB     = $(patsubst %,tatoeba-eng2%-job,${TATOEBA_LANGPARENTS})
ENG2GROUP_TRAIN   = $(patsubst %,tatoeba-eng2%-train,${TATOEBA_LANGPARENTS})
ENG2GROUP_EVAL    = $(patsubst %,tatoeba-eng2%-eval,${TATOEBA_LANGPARENTS})
ENG2GROUP_EVALALL = $(patsubst %,tatoeba-eng2%-evalall,${TATOEBA_LANGPARENTS})
ENG2GROUP_DIST    = $(patsubst %,tatoeba-eng2%-dist,${TATOEBA_LANGPARENTS})

tatoeba-eng2group: ${ENG2GROUP_JOB}

${ENG2GROUP_JOB}:
	${MAKE} $(patsubst %-job,%-train,$@)
	${MAKE} $(patsubst %-job,%-eval,$@)
	${MAKE} $(patsubst %-job,%-evalall,$@)
	${MAKE} $(patsubst %-job,%-dist,$@)

${ENG2GROUP_TRAIN}:
	${MAKE} LANGPAIRSTR=eng-$(patsubst tatoeba-eng2%-train,%,$@) \
		TRGLANGS="${shell langgroup -n $(patsubst tatoeba-eng2%-train,%,$@)}" \
		SRCLANGS=eng MODELTYPE=transformer FIT_DATA_SIZE=1000000 \
	tatoeba-multilingual-train

${ENG2GROUP_EVAL}:
	${MAKE} LANGPAIRSTR=eng-$(patsubst tatoeba-eng2%-eval,%,$@) \
		SRCLANGS=eng \
		TRGLANGS="${shell langgroup -n $(patsubst tatoeba-eng2%-eval,%,$@)}" \
		MODELTYPE=transformer \
		${TATOEBA_PARAMS} \
	compare

${ENG2GROUP_EVALALL}:
	${MAKE} LANGPAIRSTR=eng-$(patsubst tatoeba-eng2%-evalall,%,$@) \
		TRGLANGS="${shell langgroup -n $(patsubst tatoeba-eng2%-evalall,%,$@)}" \
		SRCLANGS=eng MODELTYPE=transformer FIT_DATA_SIZE=1000000 \
	tatoeba-multilingual-eval

${ENG2GROUP_DIST}:
	${MAKE} LANGPAIRSTR=eng-$(patsubst tatoeba-eng2%-dist,%,$@) \
		SRCLANGS=eng \
		TRGLANGS="${shell langgroup -n $(patsubst tatoeba-eng2%-dist,%,$@)}" \
		MODELTYPE=transformer \
		${TATOEBA_PARAMS} \
	best-dist



#### multilingual language-group (bi-directional

LANGGROUP_JOB     = $(patsubst %,tatoeba-%-job,${TATOEBA_LANGPARENTS})
LANGGROUP_TRAIN   = $(patsubst %,tatoeba-%-train,${TATOEBA_LANGPARENTS})
LANGGROUP_EVAL    = $(patsubst %,tatoeba-%-eval,${TATOEBA_LANGPARENTS})
LANGGROUP_EVALALL = $(patsubst %,tatoeba-%-evalall,${TATOEBA_LANGPARENTS})
LANGGROUP_DIST    = $(patsubst %,tatoeba-%-dist,${TATOEBA_LANGPARENTS})

tatoeba-langgroup: ${LANGGROUP_JOB}

${LANGGROUP_JOB}:
	${MAKE} $(patsubst %-job,%-train,$@)
	${MAKE} $(patsubst %-job,%-eval,$@)
	${MAKE} $(patsubst %-job,%-evalall,$@)
	${MAKE} $(patsubst %-job,%-dist,$@)


${LANGGROUP_TRAIN}:
	${MAKE} LANGPAIRSTR=$(patsubst tatoeba-%-train,%,$@)-$(patsubst tatoeba-%-train,%,$@) \
		TRGLANGS="${shell langgroup -n $(patsubst tatoeba-%-train,%,$@)}" \
		SRCLANGS="${shell langgroup -n $(patsubst tatoeba-%-train,%,$@)}" \
		MODELTYPE=transformer FIT_DATA_SIZE=1000000 \
	tatoeba-multilingual-train

${LANGGROUP_EVAL}:
	${MAKE} LANGPAIRSTR=$(patsubst tatoeba-%-train,%,$@)-$(patsubst tatoeba-%-eval,%,$@) \
		SRCLANGS="${shell langgroup -n $(patsubst tatoeba-%-eval,%,$@)}" \
		TRGLANGS="${shell langgroup -n $(patsubst tatoeba-%-eval,%,$@)}" \
		MODELTYPE=transformer \
		${TATOEBA_PARAMS} \
	compare

${LANGGROUP_EVALALL}:
	${MAKE} LANGPAIRSTR=$(patsubst tatoeba-%-train,%,$@)-$(patsubst tatoeba-%-evalall,%,$@) \
		TRGLANGS="${shell langgroup -n $(patsubst tatoeba-%-evalall,%,$@)}" \
		SRCLANGS="${shell langgroup -n $(patsubst tatoeba-%-evalall,%,$@)}" \
		MODELTYPE=transformer FIT_DATA_SIZE=1000000 \
	tatoeba-multilingual-eval

${LANGGROUP_DIST}:
	${MAKE} LANGPAIRSTR=$(patsubst tatoeba-%-train,%,$@)-$(patsubst tatoeba-%-dist,%,$@) \
		SRCLANGS="${shell langgroup -n $(patsubst tatoeba-%-dist,%,$@)}" \
		TRGLANGS="${shell langgroup -n $(patsubst tatoeba-%-dist,%,$@)}" \
		MODELTYPE=transformer \
		${TATOEBA_PARAMS} \
	best-dist




###########################################################################################







## start unidirectional training job
## - make data first, then submit a job
.PHONY: tatoeba-job
tatoeba-job:
	${MAKE} tatoeba-prepare
	${MAKE} all-job-tatoeba

## start jobs in both translation directions
.PHONY: tatoeba-bidirectional-job
tatoeba-bidirectional-job:
	${MAKE} tatoeba-prepare
	${MAKE} all-job-tatoeba
ifneq (${SRCLANGS},${TRGLANGS})
	${MAKE} reverse-data-tatoeba
	${MAKE} SRCLANGS="${TRGLANGS}" TRGLANGS="${SRCLANGS}" tatoeba-prepare
	${MAKE} SRCLANGS="${TRGLANGS}" TRGLANGS="${SRCLANGS}" all-job-tatoeba
endif


## prepare data (config, train.dev.test data, labels)
.PHONY: tatoeba-prepare
tatoeba-prepare: ${TATOEBA_DATA}/Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}.gz
	${MAKE} local-config-tatoeba
	${MAKE} data-tatoeba

## train a model
.PHONY: tatoeba-train
tatoeba-train:
	${MAKE} train-tatoeba

## evaluate a model
.PHONY: tatoeba-eval
tatoeba-eval:
	${MAKE} compare-tatoeba

## fetch the essential data and get labels for language variants
## (this is done by the data targets above as well)
.PHONY: tatoeba-data tatoeba-labels
tatoeba-data: ${TATOEBA_DATA}/Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}.gz
tatoeba-labels: ${TATOEBA_DATA}/Tatoeba-train.${LANGPAIRSTR}.clean.${SRCEXT}.labels


.PHONY: tatoeba-results
tatoeba-results:
	rm -f tatoeba-results* results/*.md
	${MAKE} tatoeba-results-md

## create result tables in various variants and for various subsets
## markdown pages are for reading on-line in the Tatoeba Challenge git
## ---> link results dir to the local copy of the Tatoeba Challenge git
.PHONY: tatoeba-results-md
tatoeba-results-md: tatoeba-results-sorted tatoeba-results-sorted-model tatoeba-results-sorted-langpair \
		results/tatoeba-results-sorted.md \
		results/tatoeba-results-sorted-model.md \
		results/tatoeba-results-sorted-langpair.md \
		results/tatoeba-results-BLEU-sorted.md \
		results/tatoeba-results-BLEU-sorted-model.md \
		results/tatoeba-results-BLEU-sorted-langpair.md \
		results/tatoeba-results-chrF2-sorted.md \
		results/tatoeba-results-chrF2-sorted-model.md \
		results/tatoeba-results-chrF2-sorted-langpair.md \
		tatoeba-results-subset-zero \
		tatoeba-results-subset-lowest \
		tatoeba-results-subset-lower \
		tatoeba-results-subset-medium \
		tatoeba-results-subset-higher \
		tatoeba-results-subset-highest \
		results/tatoeba-results-subset-zero.md \
		results/tatoeba-results-subset-lowest.md \
		results/tatoeba-results-subset-lower.md \
		results/tatoeba-results-subset-medium.md \
		results/tatoeba-results-subset-higher.md \
		results/tatoeba-results-subset-highest.md


#################################################################################
# run things for all language pairs in a specific subset
# (zero, lowest, lower, medium, higher, highest)
#################################################################################

## get the markdown page for a specific subset
tatoeba-%.md:
	wget -O $@ ${TATOEBA_RAWGIT}/subsets/${patsubst tatoeba-%,%,$@}


## run all language pairs for a given subset
## in both directions
tatoeba-subset-%: tatoeba-%.md
	for l in `grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']'`; do \
	  s=`echo $$l | cut -f1 -d '-'`; \
	  t=`echo $$l | cut -f2 -d '-'`; \
	  ${MAKE} SRCLANGS=$$s TRGLANGS=$$t tatoeba-bidirectional-job; \
	done

## make dist-packages for all language pairs in a subset
tatoeba-distsubset-%: tatoeba-%.md
	for l in `grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']'`; do \
	  s=`echo $$l | cut -f1 -d '-'`; \
	  t=`echo $$l | cut -f2 -d '-'`; \
	  ${MAKE} SRCLANGS=$$s TRGLANGS=$$t MIN_BLEU_SCORE=10 best-dist-tatoeba; \
	  ${MAKE} SRCLANGS=$$t TRGLANGS=$$s MIN_BLEU_SCORE=10 best-dist-tatoeba; \
	done

## evaluate existing models in a subset
## (this is handy if the model is not converged yet and we need to evaluate the current state)
tatoeba-evalsubset-%: tatoeba-%.md
	for l in `grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']'`; do \
	  s=`echo $$l | cut -f1 -d '-'`; \
	  t=`echo $$l | cut -f2 -d '-'`; \
	  if [ -d ${TATOEBA_WORK}/$$s-$$t ]; then \
	    if  [ `find ${TATOEBA_WORK}/$$s-$$t -name '*.best-perplexity.npz' | wc -l` -gt 0 ]; then \
	      ${MAKE} SRCLANGS=$$s TRGLANGS=$$t compare-tatoeba; \
	    fi \
	  fi; \
	  if [ -d ${TATOEBA_WORK}/$$t-$$s ]; then \
	    if  [ `find ${TATOEBA_WORK}/$$t-$$s -name '*.best-perplexity.npz' | wc -l` -gt 0 ]; then \
	      ${MAKE} SRCLANGS=$$t TRGLANGS=$$s compare-tatoeba; \
	    fi \
	  fi \
	done



###############################################################################
## multilingual models from an entire subset
## (all languages in that subset on both sides)
###############################################################################

## training:
## set FIT_DATA_SIZE to biggest one in subset but at least 10000
## set of languages is directly taken from the markdown page at github
tatoeba-multilingual-subset-%: tatoeba-%.md tatoeba-trainsize-%.txt
	( l="${shell grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']' | tr '-' "\n" | sort -u  | tr "\n" ' ' | sed 's/ *$$//'}"; \
	  s=${shell sort -k2,2nr $(word 2,$^) | head -1 | cut -f2 -d' '}; \
	  if [ $$s -lt 10000 ]; then s=10000; fi; \
	  ${MAKE} SRCLANGS="$$l" \
		  TRGLANGS="$$l" \
		  FIT_DATA_SIZE=$$s \
		  LANGPAIRSTR=${<:.md=} \
	  tatoeba-multilingual-train; )


## TODO: take this target away?
## just start without making data first ...
tatoeba-multilingual-startjob-%: tatoeba-%.md tatoeba-trainsize-%.txt
	( l="${shell grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']' | tr '-' "\n" | sort -u  | tr "\n" ' ' | sed 's/ *$$//'}"; \
	  s=${shell sort -k2,2nr $(word 2,$^) | head -1 | cut -f2 -d' '}; \
	  if [ $$s -lt 10000 ]; then s=10000; fi; \
	  ${MAKE} SRCLANGS="$$l" \
		  TRGLANGS="$$l" \
		  FIT_DATA_SIZE=$$s \
		  LANGPAIRSTR=${<:.md=} \
	  all-job-tatoeba; )


## evaluate all language pairs in both directions
tatoeba-multilingual-evalsubset-%: tatoeba-%.md
	( l="${shell grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']' | tr '-' "\n" | sort -u  | tr "\n" ' ' | sed 's/ *$$//'}"; \
	  ${MAKE} SRCLANGS="$$l" TRGLANGS="$$l" \
		  LANGPAIRSTR=${<:.md=} tatoeba-multilingual-eval )


## make a release package to distribute
tatoeba-multilingual-distsubset-%: tatoeba-%.md tatoeba-trainsize-%.txt
	( l="${shell grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']' | tr '-' "\n" | sort -u  | tr "\n" ' ' | sed 's/ *$$//'}"; \
	  s=${shell sort -k2,2nr $(word 2,$^) | head -1 | cut -f2 -d' '}; \
	  if [ $$s -lt 10000 ]; then s=10000; fi; \
	  ${MAKE} SRCLANGS="$$l" \
		  TRGLANGS="$$l" \
		  FIT_DATA_SIZE=$$s \
		  LANGPAIRSTR=${<:.md=} \
	  dist-tatoeba; )


## print all data sizes in this set
## --> used to set the max data size per lang-pair
##     for under/over-sampling (FIT_DATA_SIZE)
tatoeba-trainsize-%.txt: tatoeba-%.md
	for l in `grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']'`; do \
	  s=`echo $$l | cut -f1 -d '-'`; \
	  t=`echo $$l | cut -f2 -d '-'`; \
	  echo -n "$$l " >> $@; \
	  zcat ${TATOEBA_DATA}/Tatoeba-train.$$l.clean.$$s.gz | wc -l >> $@; \
	done




###############################################################################
## generic targets for working with multilingual models
###############################################################################

.PHONY: tatoeba-multilingual-train
tatoeba-multilingual-train:
	-for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    if [ $$s \< $$t ]; then \
	      ${MAKE} SRCLANGS=$$s TRGLANGS=$$t tatoeba-data; \
	    else \
	      ${MAKE} SRCLANGS=$$t TRGLANGS=$$s tatoeba-data; \
	    fi \
	  done \
	done
	${MAKE} tatoeba-job


## evaluate all individual language pairs for a multilingual model
.PHONY: tatoeba-multilingual-eval
tatoeba-multilingual-eval:
	${MAKE} tatoeba-multilingual-testsets
	for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    if [ -e ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.src ]; then \
	      ${MAKE} SRC=$$s TRG=$$t \
		TRAINSET=Tatoeba-train \
		DEVSET=Tatoeba-dev \
		TESTSET=Tatoeba-test.$$s-$$t \
		TESTSET_NAME=Tatoeba-test.$$s-$$t \
		USE_REST_DEVDATA=0 \
		HELDOUTSIZE=0 \
		DEVSIZE=5000 \
		TESTSIZE=10000 \
		DEVMINSIZE=200 \
		WORKHOME=${TATOEBA_WORK} \
	      compare; \
	    fi \
	  done \
	done

#		USE_TARGET_LABELS=1 \


## copy testsets into the multilingual model's test directory
.PHONY: tatoeba-multilingual-testsets
tatoeba-multilingual-testsets:
	for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    if [ ! -e ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.src ]; then \
	      wget -q -O ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt ${TATOEBA_RAWGIT}/data/test/$$s-$$t/test.txt; \
	      if [ -s ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt ]; then \
	        echo "make Tatoeba-test.$$s-$$t"; \
		if [ "${words ${TRGLANGS}}" == "1" ]; then \
		  cut -f3 ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt \
		  > ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.src; \
		else \
	          cut -f2,3 ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt | \
		  sed 's/^\([^ ]*\)	/>>\1<< /' \
		  > ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.src; \
		fi; \
	        cut -f4 ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt \
		> ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.trg; \
	      else \
	        wget -q -O ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt ${TATOEBA_RAWGIT}/data/test/$$t-$$s/test.txt; \
	        if [ -s ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt ]; then \
	          echo "make Tatoeba-test.$$s-$$t"; \
		  if [ "${words ${TRGLANGS}}" == "1" ]; then \
		    cut -f4 ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt \
		    > ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.src; \
		  else \
	            cut -f1,4 ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt | \
		    sed 's/^\([^ ]*\)	/>>\1<< /' \
		    > ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.src; \
		  fi; \
	          cut -f3 ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt \
		  > ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.trg; \
		fi \
	      fi; \
	      rm -f ${TATOEBA_WORK}/${LANGPAIRSTR}/test/Tatoeba-test.$$s-$$t.txt; \
	    fi \
	  done \
	done



###############################################################################
## generic targets for tatoba models
###############################################################################


## generic target for tatoeba challenge jobs
%-tatoeba: ${TATOEBA_DATA}/Tatoeba-train.${LANGPAIRSTR}.clean.${SRCEXT}.labels
	${MAKE} TRAINSET=Tatoeba-train \
		DEVSET=Tatoeba-dev \
		TESTSET=Tatoeba-test \
		TESTSET_NAME=Tatoeba-test \
		SMALLEST_TRAINSIZE=1000 \
		USE_REST_DEVDATA=0 \
		HELDOUTSIZE=0 \
		DEVSIZE=5000 \
		TESTSIZE=10000 \
		DEVMINSIZE=200 \
		WORKHOME=${TATOEBA_WORK} \
		MODELSHOME=${PWD}/models-tatoeba \
                MODELS_URL=https://object.pouta.csc.fi/${TATOEBA_MODEL_CONTAINER} \
		MODEL_CONTAINER=${TATOEBA_MODEL_CONTAINER} \
		ALT_MODEL_DIR=tatoeba \
		SKIP_DATA_DETAILS=1 \
		LANGPAIRSTR=${LANGPAIRSTR} \
		SRCLANGS="${shell cat $<  | sed 's/ *$$//'}" \
		TRGLANGS="${shell cat $(<:.${SRCEXT}.labels=.${TRGEXT}.labels)  | sed 's/ *$$//'}" \
		SRC=${SRC} TRG=${TRG} \
		EMAIL= \
	${@:-tatoeba=}



## all language labels in all language pairs
## (each language pair may include several language variants)
## --> this is necessary to set the languages that are present in a model

${TATOEBA_DATA}/Tatoeba-train.${LANGPAIRSTR}.clean.${SRCEXT}.labels:
	for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    if [ "$$s" \< "$$t" ]; then \
	      ${MAKE} SRCLANGS=$$s TRGLANGS=$$t \
		${TATOEBA_DATA}/Tatoeba-train.$$s-$$t.clean.$$s.gz; \
	    fi \
	  done \
	done
	for s in ${SRCLANGS}; do \
	    for t in ${TRGLANGS}; do \
	      if [ -e ${TATOEBA_DATA}/Tatoeba-train.$$s-$$t.clean.$$s.labels ]; then \
		cat ${TATOEBA_DATA}/Tatoeba-train.$$s-$$t.clean.$$s.labels >> $@.src; \
		echo -n ' ' >> $@.src; \
	      elif [ -e ${TATOEBA_DATA}/Tatoeba-train.$$t-$$s.clean.$$s.labels ]; then \
		cat ${TATOEBA_DATA}/Tatoeba-train.$$t-$$s.clean.$$s.labels >> $@.src; \
		echo -n ' ' >> $@.src; \
	      fi \
	    done \
	done
	for s in ${SRCLANGS}; do \
	    for t in ${TRGLANGS}; do \
	      if [ -e ${TATOEBA_DATA}/Tatoeba-train.$$s-$$t.clean.$$t.labels ]; then \
		cat ${TATOEBA_DATA}/Tatoeba-train.$$s-$$t.clean.$$t.labels >> $@.trg; \
		echo -n ' ' >> $@.trg; \
	      elif [ -e ${TATOEBA_DATA}/Tatoeba-train.$$t-$$s.clean.$$t.labels ]; then \
		cat ${TATOEBA_DATA}/Tatoeba-train.$$t-$$s.clean.$$t.labels >> $@.trg; \
		echo -n ' ' >> $@.trg; \
	      fi \
	    done \
	done
	cat $@.src | tr ' ' "\n" | sort -u | tr "\n" ' ' | sed 's/ *$$//' > $@
	cat $@.trg | tr ' ' "\n" | sort -u | tr "\n" ' ' | sed 's/ *$$//' > $(@:.${SRCEXT}.labels=.${TRGEXT}.labels)
	rm -f $@.src $@.trg



%.${LANGPAIRSTR}.clean.${SRCEXT}.labels: %.${LANGPAIRSTR}.clean.${SRCEXT}.labels
	echo "done"


###############################################################################
## generate data files
###############################################################################


## don't delete those files
.SECONDARY: ${TATOEBA_DATA}/Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}.gz \
	${TATOEBA_DATA}/Tatoeba-train.${LANGPAIR}.clean.${TRGEXT}.gz \
	${TATOEBA_DATA}/Tatoeba-dev.${LANGPAIR}.clean.${SRCEXT}.gz \
	${TATOEBA_DATA}/Tatoeba-dev.${LANGPAIR}.clean.${TRGEXT}.gz \
	${TATOEBA_DATA}/Tatoeba-test.${LANGPAIR}.clean.${SRCEXT}.gz \
	${TATOEBA_DATA}/Tatoeba-test.${LANGPAIR}.clean.${TRGEXT}.gz


## modify language IDs in training data to adjust them to test sets
## --> fix codes for chinese and take away script information (not reliable!)
##     except the distinction betwee traditional and simplified
## --> take away regional codes
## --> take away script extension that may come with some codes
FIXLANGIDS = 	| sed 's/zho\(.*\)_HK/yue\1/g;s/zho\(.*\)_CN/cmn\1/g;s/zho\(.*\)_TW/cmn\1/g;' \
		| sed 's/\_[A-Z][A-Z]//g' \
		| sed 's/\-[a-z]*//g' \
		| sed 's/jpn_[A-Za-z]*/jpn/g' \
		| sed 's/kor_[A-Za-z]*/kor/g' \
		| perl -pe 'if (/(cjy|cmn|gan|lzh|nan|wuu|yue|zho)_([A-Za-z]{4})/){if ($$2 ne "Hans" && $$2 ne "Hant"){s/(cjy|cmn|gan|lzh|nan|wuu|yue|zho)_([A-Za-z]{4})/$$1/} }'


## assume that all zho is Mandarin Chinese?
#		| sed 's/zho/cmn/g'

## take away all script info for Chinese? even tranditional vs simplified?
#		| sed 's/\(cjy\|cmn\|gan\|lzh\|nan\|wuu\|yue\|zho\)_[A-Za-z]*/\1/'




## convert Tatoeba Challenge data into the format we need
## - move the data into the right location with the suitable name
## - create devset if not given (part of training data)
## - divide into individual language pairs 
##   (if there is more than one language pair in the collection)
## 
## TODO: should we do some filtering like bitext-match, OPUS-filter ...
%/Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}.gz:
	mkdir -p $@.d
	wget -q -O $@.d/train.tar ${TATOEBA_DATAURL}/${LANGPAIR}.tar
	tar -C $@.d -xf $@.d/train.tar
	mv $@.d/data/${LANGPAIR}/test.src ${dir $@}Tatoeba-test.${LANGPAIR}.clean.${SRCEXT}
	mv $@.d/data/${LANGPAIR}/test.trg ${dir $@}Tatoeba-test.${LANGPAIR}.clean.${TRGEXT}
	cat $@.d/data/${LANGPAIR}/test.id $(FIXLANGIDS) > ${dir $@}Tatoeba-test.${LANGPAIR}.clean.id
	if [ -e $@.d/data/${LANGPAIR}/dev.src ]; then \
	  mv $@.d/data/${LANGPAIR}/dev.src ${dir $@}Tatoeba-dev.${LANGPAIR}.clean.${SRCEXT}; \
	  mv $@.d/data/${LANGPAIR}/dev.trg ${dir $@}Tatoeba-dev.${LANGPAIR}.clean.${TRGEXT}; \
	  cat $@.d/data/${LANGPAIR}/dev.id $(FIXLANGIDS) > ${dir $@}Tatoeba-dev.${LANGPAIR}.clean.id; \
	  if [ -e $@.d/data/${LANGPAIR}/train.src.gz ]; then \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.src.gz > ${dir $@}Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}; \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.trg.gz > ${dir $@}Tatoeba-train.${LANGPAIR}.clean.${TRGEXT}; \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.id.gz | cut -f2,3 $(FIXLANGIDS) > ${dir $@}Tatoeba-train.${LANGPAIR}.clean.id; \
	  fi; \
	else \
	  if [ -e $@.d/data/${LANGPAIR}/train.src.gz ]; then \
	    echo "no devdata available - get top 1000 from training data!"; \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.src.gz | head -1000 > ${dir $@}Tatoeba-dev.${LANGPAIR}.clean.${SRCEXT}; \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.trg.gz | head -1000 > ${dir $@}Tatoeba-dev.${LANGPAIR}.clean.${TRGEXT}; \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.id.gz  | head -1000 | cut -f2,3 $(FIXLANGIDS) > ${dir $@}Tatoeba-dev.${LANGPAIR}.clean.id; \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.src.gz | tail -n +1001 > ${dir $@}Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}; \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.trg.gz | tail -n +1001 > ${dir $@}Tatoeba-train.${LANGPAIR}.clean.${TRGEXT}; \
	    ${ZCAT} $@.d/data/${LANGPAIR}/train.id.gz  | tail -n +1001 | cut -f2,3 $(FIXLANGIDS) > ${dir $@}Tatoeba-train.${LANGPAIR}.clean.id; \
	  fi \
	fi
## make sure that training data file exists even if it is empty
	touch ${dir $@}Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}
	touch ${dir $@}Tatoeba-train.${LANGPAIR}.clean.${TRGEXT}
#######################################
# labels in the data
# TODO: should we take all in all data sets?
# NOW: only look for the ones in test data
# special treatment for Chinese: 
#    add the generic zho labels as well
#######################################
#	cut -f1 ${dir $@}Tatoeba-*.${LANGPAIR}.clean.id | sort -u | tr "\n" ' ' > $(@:.${SRCEXT}.gz=.${SRCEXT}.labels)
#	cut -f2 ${dir $@}Tatoeba-*.${LANGPAIR}.clean.id | sort -u | tr "\n" ' ' > $(@:.${SRCEXT}.gz=.${TRGEXT}.labels)
	cut -f1 ${dir $@}Tatoeba-test.${LANGPAIR}.clean.id | sort -u | tr "\n" ' ' > $(@:.${SRCEXT}.gz=.${SRCEXT}.labels)
	cut -f2 ${dir $@}Tatoeba-test.${LANGPAIR}.clean.id | sort -u | tr "\n" ' ' > $(@:.${SRCEXT}.gz=.${TRGEXT}.labels)
ifeq (${SRC},zho)
	echo -n 'zho zho_Hans zho_Hant cmn' >> $(@:.${SRCEXT}.gz=.${SRCEXT}.labels)
	tr ' ' "\n" < $(@:.${SRCEXT}.gz=.${SRCEXT}.labels) | sort -u | tr "\n" ' ' >$(@:.${SRCEXT}.gz=.${SRCEXT}.labels).tmp
	mv $(@:.${SRCEXT}.gz=.${SRCEXT}.labels).tmp $(@:.${SRCEXT}.gz=.${SRCEXT}.labels)
endif
ifeq (${TRG},zho)
	echo -n 'zho zho_Hans zho_Hant cmn' >> $(@:.${SRCEXT}.gz=.${TRGEXT}.labels)
	tr ' ' "\n" < $(@:.${SRCEXT}.gz=.${TRGEXT}.labels) | sort -u | tr "\n" ' ' >$(@:.${SRCEXT}.gz=.${TRGEXT}.labels).tmp
	mv $(@:.${SRCEXT}.gz=.${TRGEXT}.labels).tmp $(@:.${SRCEXT}.gz=.${TRGEXT}.labels)
endif
	rm -f $@.d/data/${LANGPAIR}/*
	rmdir $@.d/data/${LANGPAIR}
	rmdir $@.d/data
	rm -f $@.d/train.tar
	rmdir $@.d
#######################################
# make data sets for individual 
# language pairs from the Tatoeba data
# TODO: now we only grep for langpairs 
#       available in test data
# --> should we also include other 
#     training data with a dummy label?
# --> how do we efficiently grep for 
#     everything that is not one of the langpairs?
#     grep -v and a big list of alternative lang-pairs ...
#######################################
	for s in `cat $(@:.${SRCEXT}.gz=.${SRCEXT}.labels)`; do \
	  for t in `cat $(@:.${SRCEXT}.gz=.${TRGEXT}.labels)`; do \
	    if [ "$$s" \< "$$t" ]; then \
	      echo "extract $$s-$$t data"; \
	      for d in dev test train; do \
	        paste ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id \
		      ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT} \
		      ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT} |\
	        grep -P "$$s\t$$t\t" > ${dir $@}Tatoeba-$$d.$$s-$$t; \
	        if [ -s ${dir $@}Tatoeba-$$d.$$s-$$t ]; then \
	          cut -f3 ${dir $@}Tatoeba-$$d.$$s-$$t | ${GZIP} -c > ${dir $@}Tatoeba-$$d.$$s-$$t.clean.$$s.gz; \
	          cut -f4 ${dir $@}Tatoeba-$$d.$$s-$$t | ${GZIP} -c > ${dir $@}Tatoeba-$$d.$$s-$$t.clean.$$t.gz; \
	        fi; \
	        rm -f ${dir $@}Tatoeba-$$d.$$s-$$t; \
	      done \
	    else \
	      echo "extract $$t-$$s data"; \
	      for d in dev test train; do \
	        paste ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id \
		      ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT} \
		      ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT} |\
	        grep -P "$$s\t$$t\t" > ${dir $@}Tatoeba-$$d.$$t-$$s; \
	        if [ -s ${dir $@}Tatoeba-$$d.$$t-$$s ]; then \
	          cut -f3 ${dir $@}Tatoeba-$$d.$$t-$$s | ${GZIP} -c > ${dir $@}Tatoeba-$$d.$$t-$$s.clean.$$t.gz; \
	          cut -f4 ${dir $@}Tatoeba-$$d.$$t-$$s | ${GZIP} -c > ${dir $@}Tatoeba-$$d.$$t-$$s.clean.$$s.gz; \
	        fi; \
	        rm -f ${dir $@}Tatoeba-$$d.$$t-$$s; \
	      done \
	    fi \
	  done \
	done
#######################################
# finally, remove the big data files
# with all the different language variants
#######################################
	for d in dev test train; do \
	  rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}; \
	  rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}; \
	  rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id; \
	done




# #######################################
# # finally, compress the big datafiles
# # and cleanup
# #######################################
# 	for d in dev test train; do \
# 	  if [ ! -e ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.gz ]; then \
# 	    ${GZIP} -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}; \
# 	    ${GZIP} -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}; \
# 	  else \
# 	    rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}; \
# 	    rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}; \
# 	  fi; \
# 	  rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id; \
# 	done



# #######################################
# # special treatment for Chinese
# # - simplified vs traditional script
# #
# # TODO: should not manipulate test data like this!!!!
# # ---> do Chinese script detectiont properl in data releases!
# #######################################
# ifeq ($(filter cjy cmn gan lzh nan wuu yue zho,${SRC}),${SRC})
# 	@echo "treating source language Chinese"
# 	for d in dev test train; do \
# 	  cat ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT} | \
# 	  ${SCRIPTDIR}/detect_chinese_script.pl > ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.script; \
# 	  cut -f1 ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id > ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.langid; \
# 	  paste -d '' ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.langid ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.script \
# 		> ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.id; \
# 	  cut -f2 ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id > ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.id; \
# 	  paste ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.id ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.id \
# 		> ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id; \
# 	  rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.langid ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.script; \
# 	  rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.id ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.id; \
# 	done
# endif
# ifeq ($(filter cjy cmn gan lzh nan wuu yue zho,${TRG}),${TRG})
# 	@echo "treating target language Chinese"
# 	for d in dev test train; do \
# 	  cat ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT} | \
# 	  ${SCRIPTDIR}/detect_chinese_script.pl > ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.script; \
# 	  cut -f2 ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id > ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.langid; \
# 	  paste -d '' ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.langid ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.script \
# 		> ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.id; \
# 	  cut -f1 ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id > ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.id; \
# 	  paste ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.id ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.id \
# 		> ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.id; \
# 	  rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.langid ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.script; \
# 	  rm -f ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${SRCEXT}.id ${dir $@}Tatoeba-$$d.${LANGPAIR}.clean.${TRGEXT}.id; \
# 	done
# endif




%/Tatoeba-train.${LANGPAIR}.clean.${TRGEXT}.gz: %/Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}.gz
	echo "done!"

%/Tatoeba-dev.${LANGPAIR}.clean.${SRCEXT}.gz %/Tatoeba-dev.${LANGPAIR}.clean.${TRGEXT}.gz: %/Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}.gz
	echo "done!"

%/Tatoeba-test.${LANGPAIR}.clean.${SRCEXT}.gz %/Tatoeba-test.${LANGPAIR}.clean.${TRGEXT}.gz: %/Tatoeba-train.${LANGPAIR}.clean.${SRCEXT}.gz
	echo "done!"


## make Tatoeba test files available in testset collection
## --> useful for testing various languages when creating multilingual models
testsets/${LANGPAIR}/Tatoeba-test.${LANGPAIR}.%: ${TATOEBA_DATA}/Tatoeba-test.${LANGPAIR}.clean.%
	mkdir -p ${dir $@}
	cp $< $@



###############################################################################
## generate result tables
###############################################################################

results/tatoeba-results%.md: tatoeba-results% tatoeba-results-BLEU-sorted-model
	mkdir -p ${dir $@}
	echo "# Tatoeba translation results" >$@
	echo "" >>$@
	echo "Note that some links to the actual models below are broken"               >>$@
	echo "because the models are not yet released or their performance is too poor" >> $@
	echo "to be useful for anything."                                               >> $@
	echo "" >>$@
	echo "| Model            | Language Pair   | chrF2      | BLEU     |"           >> $@
	echo "|-----------------:|------------|-----------:|---------:|"                >> $@
	( p=`grep -P 'ref_len = 1?[0-9]?[0-9]\)' tatoeba-results-BLEU-sorted-model | cut -f2 | sort -u | tr "\n" '|' | sed 's/|$$//'`; \
	  grep -v -P "\t($$p)\t" $< |\
	  sed 's#^\([^ 	]*\)#[\1](../models/\1)#' |\
	  sed 's/	/ | /g;s/^/| /;s/$$/ |/'                                 >> $@ )

results/tatoeba-results-chrF2%.md: tatoeba-results-chrF2% tatoeba-results-BLEU-sorted-model
	mkdir -p ${dir $@}
	echo "# Tatoeba translation results" >$@
	echo "" >>$@
	echo "| Model            | Language Pair   | chrF2      |"               >> $@
	echo "|-----------------:|------------|-----------:|"                    >> $@
	( p=`grep -P 'ref_len = 1?[0-9]?[0-9]\)' tatoeba-results-BLEU-sorted-model | cut -f2 | sort -u | tr "\n" '|' | sed 's/|$$//'`; \
	  grep -v -P "\t($$p)\t" $< |\
	  sed 's/	/ | /g;s/^/| /;s/$$/ |/'                                 >> $@ )

results/tatoeba-results-BLEU%.md: tatoeba-results-BLEU% tatoeba-results-BLEU-sorted-model
	mkdir -p ${dir $@}
	echo "# Tatoeba translation results" >$@
	echo "" >>$@
	echo "| Model            | Language Pair   | BLEU       | Details  |"    >> $@
	echo "|-----------------:|------------|-----------:|---------:|"         >> $@
	( p=`grep -P 'ref_len = 1?[0-9]?[0-9]\)' tatoeba-results-BLEU-sorted-model | cut -f2 | sort -u | tr "\n" '|' | sed 's/|$$//'`; \
	  grep -v -P "\t($$p)\t" $< |\
	  sed 's/	/ | /g;s/^/| /;s/$$/ |/'                                 >> $@ )

tatoeba-results-sorted:
	grep chrF2 work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/chrF2.*1.4.2//' | cut -f2- -d'/' | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#' > $@.1
	grep BLEU work-tatoeba/*/Tatoeba-test.*eval | \
	cut -f3 -d' ' > $@.2
	paste $@.1 $@.2 | sort -k3,3nr > $@
	rm -f $@.1 $@.2

## results with chrF and BLEU scores sorted by language pair
tatoeba-results-sorted-langpair:
	grep chrF2 work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/chrF2.*1.4.2//' | cut -f2- -d'/' | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#' > $@.1
	grep BLEU work-tatoeba/*/Tatoeba-test.*eval | \
	cut -f3 -d' ' > $@.2
	paste $@.1 $@.2 | sort -k2,2 -k3,3nr > $@
	rm -f $@.1 $@.2

tatoeba-results-sorted-model:
	grep chrF2 work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/chrF2.*1.4.2//' | cut -f2- -d'/' | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#' > $@.1
	grep BLEU work-tatoeba/*/Tatoeba-test.*eval | \
	cut -f3 -d' ' > $@.2
	paste $@.1 $@.2 | sort -k1,1 -k3,3nr > $@
	rm -f $@.1 $@.2

tatoeba-results-BLEU-sorted:
	grep BLEU work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/BLEU.*1.4.2//' | cut -f2- -d'/' |sort -k3,3nr | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#' | sed 's/\([0-9]\) /\1	/' | grep -v eval > $@

tatoeba-results-BLEU-sorted-model:
	grep BLEU work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/BLEU.*1.4.2//' | cut -f2- -d'/' | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#'  | sed 's/\([0-9]\) /\1	/' | \
	grep -v eval | sort -k1,1 -k3,3nr > $@

tatoeba-results-BLEU-sorted-langpair:
	grep BLEU work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/BLEU.*1.4.2//' | cut -f2- -d'/' | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#'  | sed 's/\([0-9]\) /\1	/' | \
	grep -v eval | sort -k2,2 -k3,3nr > $@

tatoeba-results-chrF2-sorted:
	grep chrF2 work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/chrF2.*1.4.2//' | cut -f2- -d'/' |sort -k3,3nr | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#' > $@

tatoeba-results-chrF2-sorted-model:
	grep chrF2 work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/chrF.*1.4.2//' | cut -f2- -d'/' | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#' | sort -k1,1 -k3,3nr > $@

tatoeba-results-chrF2-sorted-langpair:
	grep chrF2 work-tatoeba/*/Tatoeba-test.*eval | \
	sed 's/chrF2.*1.4.2//' | cut -f2- -d'/' | \
	sed 's/Tatoeba.*\(transformer-align\.\|transformer\.\)/\./' | \
	sed "s#/.#\t#" | \
	sed 's#.eval: = #\t#' | sort -k2,2 -k3,3nr > $@

## scores per subset
tatoeba-results-subset-%: tatoeba-%.md tatoeba-results-sorted-langpair
	( l="${shell grep '\[' $< | cut -f2 -d '[' | cut -f1 -d ']' | sort -u  | tr "\n" '|' | tr '-' '.' | sed 's/|$$//;s/\./\\\./g'}"; \
	  grep -P "$$l" ${word 2,$^} > $@ )

tatoeba-results-langgroup: tatoeba-results-sorted-langpair
	grep -P "${subst ${SPACE},-eng|,${OPUSTATOEBA_LANGPARENTS}}-eng" $< >> $@
	grep -P "eng-${subst ${SPACE},|eng-,${OPUSTATOEBA_LANGPARENTS}}" $< >> $@
	grep -P "`echo '${OPUSTATOEBA_LANGPARENTS}' | sed 's/\([^ ][^ ]*\)/\1-\1/g;s/ /\|/g'`" $< >> $@


###############################################################################
# auxiliary functions
###############################################################################


WRONGFILES = ${patsubst %.eval,%,${wildcard work-tatoeba/*/Tatoeba-test.opus*.eval}}

move-wrong:
	for f in ${WRONGFILES}; do \
	  s=`echo $$f | cut -f2 -d'/' | cut -f1 -d'-'`; \
	  t=`echo $$f | cut -f2 -d'/' | cut -f2 -d'-'`; \
	  c=`echo $$f | sed "s/align.*$$/align.$$s.$$t/"`; \
	  if [ "$$f" != "$$c" ]; then \
	    echo "fix $$f"; \
	    mv $$f $$c; \
	    mv $$f.compare $$c.compare; \
	    mv $$f.eval $$c.eval; \
	  fi \
	done
