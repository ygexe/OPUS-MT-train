# -*-makefile-*-

ifndef SRCLANGS
  SRCLANGS=${SRC}
endif

ifndef SRCLANGS
  TRGLANGS=${TRG}
endif

ifndef THREADS
  THREADS=${HPC_CORES}
endif


## SKIP_LANGPAIRS can be used to skip certain language pairs
## in data preparation for multilingual models
## ---> this can be good to skip BIG language pairs
##      that would very much dominate all the data
## must be a pattern that can be matched by egrep
## e.g. en-de|en-fr

ifndef SKIP_LANGPAIRS
  SKIP_LANGPAIRS = "nothing"
endif


## look for cleanup scripts and put them into a pipe
## they should be executable and should basically read STDIN and print to STDOUT
## no further arguments are supported

ifneq (${wildcard scripts/cleanup/${SRC}},)
  SRC_CLEANUP_SCRIPTS = | ${subst ${SPACE}, | ,${shell find scripts/cleanup/${SRC} -executable -type f}}
endif

ifneq (${wildcard scripts/cleanup/${TRG}},)
  TRG_CLEANUP_SCRIPTS = | ${subst ${SPACE}, | ,${shell find scripts/cleanup/${TRG} -executable -type f}}
endif


## back translation data
## - use only the latest backtranslations
##   if such a subdir exists

ifneq (${wildcard backtranslate/${TRG}-${SRC}/latest},)
  BACKTRANS_DIR = backtranslate/${TRG}-${SRC}/latest
else
  BACKTRANS_DIR = backtranslate/${TRG}-${SRC}
endif

BACKTRANS_SRC = ${sort ${wildcard ${BACKTRANS_DIR}/*.${SRCEXT}.gz}}
BACKTRANS_TRG = ${patsubst %.${SRCEXT}.gz,%.${TRGEXT}.gz,${BACKTRANS_SRC}}


## data sets (train/dev/test)

ifeq (${USE_BACKTRANS},1)
  CLEAN_TRAIN_SRC = ${patsubst %,${DATADIR}/${PRE}/%.${LANGPAIR}.clean.${SRCEXT}.gz,${TRAINSET}} ${BACKTRANS_SRC}
  CLEAN_TRAIN_TRG = ${patsubst %.${SRCEXT}.gz,%.${TRGEXT}.gz,${CLEAN_TRAIN_SRC}}
else
  CLEAN_TRAIN_SRC = ${patsubst %,${DATADIR}/${PRE}/%.${LANGPAIR}.clean.${SRCEXT}.gz,${TRAINSET}}
  CLEAN_TRAIN_TRG = ${patsubst %.${SRCEXT}.gz,%.${TRGEXT}.gz,${CLEAN_TRAIN_SRC}}
endif

CLEAN_TUNE_SRC  = ${patsubst %,${DATADIR}/${PRE}/%.${LANGPAIR}.clean.${SRCEXT}.gz,${TUNESET}}
CLEAN_TUNE_TRG  = ${patsubst %.${SRCEXT}.gz,%.${TRGEXT}.gz,${CLEAN_TUNE_SRC}}

CLEAN_DEV_SRC   = ${patsubst %,${DATADIR}/${PRE}/%.${LANGPAIR}.clean.${SRCEXT}.gz,${DEVSET}}
CLEAN_DEV_TRG   = ${patsubst %.${SRCEXT}.gz,%.${TRGEXT}.gz,${CLEAN_DEV_SRC}}

CLEAN_TEST_SRC  = ${patsubst %,${DATADIR}/${PRE}/%.${LANGPAIR}.clean.${SRCEXT}.gz,${TESTSET}}
CLEAN_TEST_TRG  = ${patsubst %.${SRCEXT}.gz,%.${TRGEXT}.gz,${CLEAN_TEST_SRC}}

DATA_SRC := ${sort ${CLEAN_TRAIN_SRC} ${CLEAN_TUNE_SRC} ${CLEAN_DEV_SRC} ${CLEAN_TEST_SRC}}
DATA_TRG := ${sort ${CLEAN_TRAIN_TRG} ${CLEAN_TUNE_TRG} ${CLEAN_DEV_TRG} ${CLEAN_TEST_TRG}}



## make data in reverse direction without re-doing word alignment etc ...
## ---> this is dangerous when things run in parallel
## ---> only works for bilingual models

REV_LANGSTR = ${subst ${SPACE},+,$(TRGLANGS)}-${subst ${SPACE},+,$(SRCLANGS)}
REV_WORKDIR = ${WORKHOME}/${REV_LANGSTR}



reverse-data:
ifeq (${PRE_SRC},${PRE_TRG})
ifeq (${words ${SRCLANGS}},1)
ifeq (${words ${TRGLANGS}},1)
	-if [ -e ${TRAIN_SRC}.clean.${PRE_SRC}.gz ]; then \
	  mkdir -p ${REV_WORKDIR}/train; \
	  ln -s ${TRAIN_SRC}.clean.${PRE_SRC}.gz ${REV_WORKDIR}/train/${notdir ${TRAIN_TRG}.clean.${PRE_TRG}.gz}; \
	  ln -s ${TRAIN_TRG}.clean.${PRE_TRG}.gz ${REV_WORKDIR}/train/${notdir ${TRAIN_SRC}.clean.${PRE_SRC}.gz}; \
	fi
	-if [ -e ${SPMSRCMODEL} ]; then \
	  ln -s ${SPMSRCMODEL} ${REV_WORKDIR}/train/${notdir ${SPMTRGMODEL}}; \
	  ln -s ${SPMTRGMODEL} ${REV_WORKDIR}/train/${notdir ${SPMSRCMODEL}}; \
	fi
	if [ -e ${BPESRCMODEL} ]; then \
	  ln -s ${BPESRCMODEL} ${REV_WORKDIR}/train/${notdir ${BPETRGMODEL}}; \
	  ln -s ${BPETRGMODEL} ${REV_WORKDIR}/train/${notdir ${BPESRCMODEL}}; \
	fi
	-if [ -e ${TRAIN_ALG} ]; then \
	  if [ ! -e ${REV_WORKDIR}/train/${notdir ${TRAIN_ALG}} ]; then \
	    zcat ${TRAIN_ALG} | ${MOSESSCRIPTS}/generic/reverse-alignment.perl |\
	    gzip -c > ${REV_WORKDIR}/train/${notdir ${TRAIN_ALG}}; \
	  fi \
	fi
	-if [ -e ${DEV_SRC}.${PRE_SRC} ]; then \
	  mkdir -p ${REV_WORKDIR}/val; \
	  ln -s ${DEV_SRC}.${PRE_SRC} ${REV_WORKDIR}/val/${notdir ${DEV_TRG}.${PRE_TRG}}; \
	  ln -s ${DEV_TRG}.${PRE_TRG} ${REV_WORKDIR}/val/${notdir ${DEV_SRC}.${PRE_SRC}}; \
	  ln -s ${DEV_SRC} ${REV_WORKDIR}/val/${notdir ${DEV_TRG}}; \
	  ln -s ${DEV_TRG} ${REV_WORKDIR}/val/${notdir ${DEV_SRC}}; \
	  ln -s ${DEV_SRC}.shuffled.gz ${REV_WORKDIR}/val/${notdir ${DEV_SRC}.shuffled.gz}; \
	  ln -s ${DEV_SRC}.notused.gz ${REV_WORKDIR}/val/${notdir ${DEV_TRG}.notused.gz}; \
	  ln -s ${DEV_TRG}.notused.gz ${REV_WORKDIR}/val/${notdir ${DEV_SRC}.notused.gz}; \
	fi
	-if [ -e ${TEST_SRC} ]; then \
	  mkdir -p ${REV_WORKDIR}/test; \
	  ln -s ${TEST_SRC} ${REV_WORKDIR}/test/${notdir ${TEST_TRG}}; \
	  ln -s ${TEST_TRG} ${REV_WORKDIR}/test/${notdir ${TEST_SRC}}; \
	fi
	-if [ -e ${MODEL_VOCAB} ]; then \
	  ln -s ${MODEL_VOCAB} ${REV_WORKDIR}/${notdir ${MODEL_VOCAB}}; \
	fi
endif
endif
endif




ifndef OLDMODELTYPE
  OLDMODELTYPE=transformer-align
endif

ifndef NEWMODELTYPE
  NEWMODELTYPE=transformer
endif


## TODO: this does not seem to work as the config does not match
## (optmiser cannot contintue to run ....)
## move model files to a new name
## (useful if using as starting point for another modeltyp
##  for example, continue training without guided alignment)

OLDMODEL_BASE  = ${WORKDIR}/${MODEL}.${OLDMODELTYPE}.model${NR}
NEWMODEL_BASE  = ${WORKDIR}/${MODEL}.${NEWMODELTYPE}.model${NR}

move-model:
ifeq (${wildcard ${NEWMODEL_BASE}.npz},)
	cp ${OLDMODEL_BASE}.npz ${NEWMODEL_BASE}.npz
	cp ${OLDMODEL_BASE}.npz.best-perplexity.npz ${NEWMODEL_BASE}.npz.best-perplexity.npz
	cp ${OLDMODEL_BASE}.npz.optimizer.npz ${NEWMODEL_BASE}.npz.optimizer.npz
	cp ${OLDMODEL_BASE}.npz.orig.npz ${NEWMODEL_BASE}.npz.orig.npz
	cp ${OLDMODEL_BASE}.npz.progress.yml ${NEWMODEL_BASE}.npz.progress.yml
	cp ${OLDMODEL_BASE}.npz.yml ${NEWMODEL_BASE}.npz.yml
	sed 's/${OLDMODELTYPE}/${NEWMODELTYPE}/' \
		< ${OLDMODEL_BASE}.npz.decoder.yml \
		> ${NEWMODEL_BASE}.npz.decoder.yml
	sed 's/${OLDMODELTYPE}/${NEWMODELTYPE}/' \
		< ${OLDMODEL_BASE}.npz.best-perplexity.npz.decoder.yml \
		> ${NEWMODEL_BASE}.npz.best-perplexity.npz.decoder.yml
else
	@echo "new model ${NEWMODEL_BASE}.npz exists already!"
endif


clean-data:
	for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    ${MAKE} SRC=$$s TRG=$$t clean-data-source; \
	  done \
	done

clean-data-source: ${DATA_SRC} ${DATA_TRG}

## monolingual data sets (for sentence piece models)
mono-data: ${LOCAL_MONO_DATA}.${PRE}

.INTERMEDIATE: ${LOCAL_MONO_DATA}.${PRE} ${LOCAL_MONO_DATA}.raw ${LOCAL_MONO_DATA}.${PRE}.charfreq


## word alignment used for guided alignment

.INTERMEDIATE: ${LOCAL_TRAIN_SRC}.algtmp ${LOCAL_TRAIN_TRG}.algtmp 

${LOCAL_TRAIN_SRC}.algtmp: ${TRAIN_SRC}.clean.${PRE_SRC}${TRAINSIZE}.gz
	mkdir -p ${dir $@}
	gzip -cd < $< > $@

${LOCAL_TRAIN_TRG}.algtmp: ${TRAIN_TRG}.clean.${PRE_TRG}${TRAINSIZE}.gz
	mkdir -p ${dir $@}
	gzip -cd < $< > $@



## max number of lines in a corpus for running word alignment
## (split into chunks of max that size before aligning)

MAX_WORDALIGN_SIZE = 5000000
# MAX_WORDALIGN_SIZE = 10000000
# MAX_WORDALIGN_SIZE = 25000000

${TRAIN_ALG}: 	${TRAIN_SRC}.clean.${PRE_SRC}${TRAINSIZE}.gz \
		${TRAIN_TRG}.clean.${PRE_TRG}${TRAINSIZE}.gz
	${MAKE} ${LOCAL_TRAIN_SRC}.algtmp ${LOCAL_TRAIN_TRG}.algtmp
	if  [ `head $(LOCAL_TRAIN_SRC).algtmp | wc -l` -gt 0 ]; then \
	  mkdir -p $(LOCAL_TRAIN_SRC).algtmp.d; \
	  mkdir -p $(LOCAL_TRAIN_TRG).algtmp.d; \
	  split -l ${MAX_WORDALIGN_SIZE} $(LOCAL_TRAIN_SRC).algtmp $(LOCAL_TRAIN_SRC).algtmp.d/; \
	  split -l ${MAX_WORDALIGN_SIZE} $(LOCAL_TRAIN_TRG).algtmp $(LOCAL_TRAIN_TRG).algtmp.d/; \
	  for s in `ls $(LOCAL_TRAIN_SRC).algtmp.d`; do \
	    echo "align part $$s"; \
	    ${WORDALIGN} --overwrite \
		-s $(LOCAL_TRAIN_SRC).algtmp.d/$$s \
		-t $(LOCAL_TRAIN_TRG).algtmp.d/$$s \
		-f $(LOCAL_TRAIN_SRC).algtmp.d/$$s.fwd \
		-r $(LOCAL_TRAIN_TRG).algtmp.d/$$s.rev; \
	  done; \
	  echo "merge and symmetrize"; \
	  cat $(LOCAL_TRAIN_SRC).algtmp.d/*.fwd > $(LOCAL_TRAIN_SRC).fwd; \
	  cat $(LOCAL_TRAIN_TRG).algtmp.d/*.rev > $(LOCAL_TRAIN_TRG).rev; \
	  ${ATOOLS} -c grow-diag-final -i $(LOCAL_TRAIN_SRC).fwd -j $(LOCAL_TRAIN_TRG).rev |\
	  gzip -c > $@; \
	  rm -f ${LOCAL_TRAIN_SRC}.algtmp.d/*; \
	  rm -f ${LOCAL_TRAIN_TRG}.algtmp.d/*; \
	  rmdir ${LOCAL_TRAIN_SRC}.algtmp.d; \
	  rmdir ${LOCAL_TRAIN_TRG}.algtmp.d; \
	  rm -f $(LOCAL_TRAIN_SRC).fwd $(LOCAL_TRAIN_TRG).rev; \
	fi
	rm -f ${LOCAL_TRAIN_SRC}.algtmp ${LOCAL_TRAIN_TRG}.algtmp


## old way of word alignment with all the data in one process
## --> this may take a long time for very large corpora
## --> may also take a lot of memory (split instead, see above)

# ${TRAIN_ALG}: 	${TRAIN_SRC}.${PRE_SRC}${TRAINSIZE}.gz \
# 		${TRAIN_TRG}.${PRE_TRG}${TRAINSIZE}.gz
# 	${MAKE} ${LOCAL_TRAIN_SRC}.algtmp ${LOCAL_TRAIN_TRG}.algtmp
# 	if  [ `head $(LOCAL_TRAIN_SRC).algtmp | wc -l` -gt 0 ]; then \
# 	  ${WORDALIGN} -s $(LOCAL_TRAIN_SRC).algtmp -t $(LOCAL_TRAIN_TRG).algtmp \
# 		--overwrite -f $(LOCAL_TRAIN_SRC).fwd -r $(LOCAL_TRAIN_TRG).rev; \
# 	  ${ATOOLS} -c grow-diag-final -i $(LOCAL_TRAIN_SRC).fwd -j $(LOCAL_TRAIN_TRG).rev |\
# 	  gzip -c > $@; \
# 	fi
# 	rm -f ${LOCAL_TRAIN_SRC}.algtmp ${LOCAL_TRAIN_TRG}.algtmp
# 	rm -f $(LOCAL_TRAIN_SRC).fwd $(LOCAL_TRAIN_TRG).rev





## copy OPUS data
## (check that the OPUS file really exists! if not, create and empty file)
##
## TODO: should e read all data from scratch using opus_read?
## - also: langid filtering and link prob filtering?

%.${SRCEXT}.raw:
	mkdir -p ${dir $@}
	c=${patsubst %.${LANGPAIR}.${SRCEXT}.raw,%,${notdir $@}}; \
	if [ -e ${OPUSHOME}/$$c/latest/moses/${LANGPAIR}.txt.zip ]; then \
	  scp ${OPUSHOME}/$$c/latest/moses/${LANGPAIR}.txt.zip $@.zip; \
	  unzip -d ${dir $@} $@.zip -x README LICENSE; \
	  mv ${dir $@}$$c*.${LANGPAIR}.${SRCEXT} $@; \
	  mv ${dir $@}$$c*.${LANGPAIR}.${TRGEXT} \
	     ${@:.${SRCEXT}.raw=.${TRGEXT}.raw}; \
	  rm -f $@.zip ${@:.${SRCEXT}.raw=.xml} ${@:.${SRCEXT}.raw=.ids} ${dir $@}/README ${dir $@}/LICENSE; \
	elif [ -e ${OPUSHOME}/$$c/latest/xml/${LANGPAIR}.xml.gz ]; then \
	  echo "extract $$c (${LANGPAIR}) from OPUS"; \
	  opus_read ${OPUSREAD_ARGS} -rd ${OPUSHOME} -d $$c -s ${SRC} -t ${TRG} -wm moses -p raw > $@.tmp; \
	  cut -f1 $@.tmp > $@; \
	  cut -f2 $@.tmp > ${@:.${SRCEXT}.raw=.${TRGEXT}.raw}; \
	  rm -f $@.tmp; \
	else \
	  touch $@; \
	  touch ${@:.${SRCEXT}.raw=.${TRGEXT}.raw}; \
	fi


%.${TRGEXT}.raw: %.${SRCEXT}.raw
	@echo "done!"

## clean data
## OLD: apply cleanup script from Moses
##      --> this might not be a good idea before subword splitting for languages without spaces
## NEW: do this later after splitting into subword units
##
## TODO:
## - does this effect sentence piece / BPE models in some negative way?
## - should we increase the length filter when cleaning later? How much?
## - should we apply some other cleanup scripts here to get rid of some messy stuff?


# ## this is too strict for non-latin languages
# #	grep -i '[a-zäöå0-9]' |\

## OLD:
##
# %.clean.${SRCEXT}.gz: %.${SRCEXT}.${PRE} %.${TRGEXT}.${PRE}
# 	rm -f $@.${SRCEXT} $@.${TRGEXT}
# 	ln -s ${word 1,$^} $@.${SRCEXT}
# 	ln -s ${word 2,$^} $@.${TRGEXT}
# 	$(MOSESSCRIPTS)/training/clean-corpus-n.perl $@ $(SRCEXT) $(TRGEXT) ${@:.${SRCEXT}.gz=} 0 100
# 	rm -f $@.${SRCEXT} $@.${TRGEXT}
# 	paste ${@:.gz=} ${@:.${SRCEXT}.gz=.${TRGEXT}} |\
# 	perl -CS -pe 'tr[\x{9}\x{A}\x{D}\x{20}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}][]cd;' > $@.tmp
# 	rm -f ${@:.gz=} ${@:.${SRCEXT}.gz=.${TRGEXT}}
# 	cut -f1 $@.tmp | gzip -c > $@
# 	cut -f2 $@.tmp | gzip -c > ${@:.${SRCEXT}.gz=.${TRGEXT}.gz}
# 	rm -f $@.tmp


# %.clean.${TRGEXT}.gz: %.clean.${SRCEXT}.gz
# 	@echo "done!"



# %.clean.${SRCEXT}.gz: %.${SRCEXT}.${PRE} %.${TRGEXT}.${PRE}
# 	cat $< |\
# 	perl -CS -pe 'tr[\x{9}\x{A}\x{D}\x{20}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}][]cd;' |\
# 	gzip -c > $@

# %.clean.${TRGEXT}.gz: %.${TRGEXT}.${PRE}
# 	cat $< |\
# 	perl -CS -pe 'tr[\x{9}\x{A}\x{D}\x{20}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}][]cd;' |\
# 	gzip -c > $@



%.clean.${SRCEXT}.gz: %.${SRCEXT}.${PRE} %.${TRGEXT}.${PRE}
	cat ${word 1,$^} |\
	perl -CS -pe 'tr[\x{9}\x{A}\x{D}\x{20}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}][]cd;' |\
	perl -CS -pe 's/\&\s*\#\s*160\s*\;/ /g' > $@.1
	cat ${word 2,$^} |\
	perl -CS -pe 'tr[\x{9}\x{A}\x{D}\x{20}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}][]cd;' |\
	perl -CS -pe 's/\&\s*\#\s*160\s*\;/ /g' > $@.2
	paste $@.1 $@.2 |\
	scripts/filter/bitext-match-lang.py -s ${SRC} -t ${TRG} > $@.bitext
	cut -f1 $@.bitext | gzip -c > $@
	cut -f2 $@.bitext | gzip -c > $(@:.clean.${SRCEXT}.gz=.clean.${TRGEXT}.gz)
	rm -f $@.bitext $@.1 $@.2

#	paste $@.${SRCEXT} $@.${TRGEXT} |\
#	python3 bitext-match-lang.py -s ${SRC} -t ${TRG} > $@.bitext
#	cut -f1 $@.bitext > $@
#	cut -f2 $@.bitext > $(@:.src.clean.${PRE_SRC}=.trg.clean.${PRE_TRG})

%.clean.${TRGEXT}.gz: %.clean.${SRCEXT}.gz
	@echo "done!"


## add training data for each language combination
## and put it together in local space
${LOCAL_TRAIN_SRC}: ${DEV_SRC} ${DEV_TRG}
	mkdir -p ${dir $@}
	rm -f ${LOCAL_TRAIN_SRC} ${LOCAL_TRAIN_TRG}
	-for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    if [ ! `echo "$$s-$$t $$t-$$s" | egrep '${SKIP_LANGPAIRS}' | wc -l` -gt 0 ]; then \
	      if [ ${HELDOUTSIZE} -gt 0 ]; then \
	        ${MAKE} DATASET=${DATASET} SRC:=$$s TRG:=$$t \
		  add-to-local-train-and-heldout-data; \
	      else \
	        ${MAKE} DATASET=${DATASET} SRC:=$$s TRG:=$$t \
		  add-to-local-train-data; \
	      fi \
	    else \
	      echo "!!!!!!!!!!! skip language pair $$s-$$t !!!!!!!!!!!!!!!!"; \
	    fi \
	  done \
	done
ifeq (${USE_REST_DEVDATA},1)
	if [ -e ${DEV_SRC}.notused.gz ]; then \
	  zcat ${DEV_SRC}.notused.gz >> ${LOCAL_TRAIN_SRC}; \
	  zcat ${DEV_TRG}.notused.gz >> ${LOCAL_TRAIN_TRG}; \
	fi
endif


# 	    ${MAKE} DATASET=${DATASET} SRC:=$$s TRG:=$$t add-to-local-train-data; \

${LOCAL_TRAIN_TRG}: ${LOCAL_TRAIN_SRC}
	@echo "done!"


## add to the training data
add-to-local-train-data: ${CLEAN_TRAIN_SRC} ${CLEAN_TRAIN_TRG}
	@if [ `zcat ${CLEAN_TRAIN_SRC} | wc -l` != `zcat ${CLEAN_TRAIN_TRG} | wc -l` ]; then \
	  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"; \
	  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"; \
	  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"; \
	  echo "source and target are not of same lengt!"; \
	  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"; \
	  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"; \
	  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"; \
	  echo ${CLEAN_TRAIN_SRC}; \
	  echo ${CLEAN_TRAIN_TRG}; \
	fi
ifneq (${CLEAN_TRAIN_SRC},)
	echo "${CLEAN_TRAIN_SRC}" >> ${dir ${LOCAL_TRAIN_SRC}}/README
ifneq (${words ${TRGLANGS}},1)
	echo "more than one target language";
	zcat ${CLEAN_TRAIN_SRC} |\
	sed "s/^/>>${TRG}<< /" >> ${LOCAL_TRAIN_SRC}
else
	echo "only one target language"
	zcat ${CLEAN_TRAIN_SRC} >> ${LOCAL_TRAIN_SRC}
endif
	zcat ${CLEAN_TRAIN_TRG} >> ${LOCAL_TRAIN_TRG}
endif





## extract training data but keep some heldout data for each dataset
add-to-local-train-and-heldout-data: ${CLEAN_TRAIN_SRC} ${CLEAN_TRAIN_TRG}
ifneq (${CLEAN_TRAIN_SRC},)
	echo "${CLEAN_TRAIN_SRC}" >> ${dir ${LOCAL_TRAIN_SRC}}/README
	mkdir -p ${HELDOUT_DIR}/${SRC}-${TRG}
ifneq (${words ${TRGLANGS}},1)
	echo "more than one target language";
	for c in ${CLEAN_TRAIN_SRC}; do \
	  if (( `zcat $$c | head -$$(($(HELDOUTSIZE) + $(HELDOUTSIZE))) | wc -l` == $$(($(HELDOUTSIZE) + $(HELDOUTSIZE))) )); then \
	    zcat $$c | tail -n +$$(($(HELDOUTSIZE) + 1)) |\
	    sed "s/^/>>${TRG}<< /" >> ${LOCAL_TRAIN_SRC}; \
	    zcat $$c | head -$(HELDOUTSIZE) |\
	    sed "s/^/>>${TRG}<< /" | gzip -c \
	    > ${HELDOUT_DIR}/${SRC}-${TRG}/`basename $$c`; \
	  else \
	    zcat $$c | sed "s/^/>>${TRG}<< /" >> ${LOCAL_TRAIN_SRC}; \
	  fi \
	done
else
	echo "only one target language"
	for c in ${CLEAN_TRAIN_SRC}; do \
	  if (( `zcat $$c | head -$$(($(HELDOUTSIZE) + $(HELDOUTSIZE))) | wc -l` == $$(($(HELDOUTSIZE) + $(HELDOUTSIZE))) )); then \
	    zcat $$c | tail -n +$$(($(HELDOUTSIZE) + 1)) >> ${LOCAL_TRAIN_SRC}; \
	    zcat $$c | head -$(HELDOUTSIZE) |\
	    gzip -c > ${HELDOUT_DIR}/${SRC}-${TRG}/`basename $$c`; \
	  else \
	    zcat $$c >> ${LOCAL_TRAIN_SRC}; \
	  fi \
	done
endif
	for c in ${CLEAN_TRAIN_TRG}; do \
	  if (( `zcat $$c | head -$$(($(HELDOUTSIZE) + $(HELDOUTSIZE))) | wc -l` == $$(($(HELDOUTSIZE) + $(HELDOUTSIZE))) )); then \
	    zcat $$c | tail -n +$$(($(HELDOUTSIZE) + 1)) >> ${LOCAL_TRAIN_TRG}; \
	    zcat $$c | head -$(HELDOUTSIZE) |\
	    gzip -c > ${HELDOUT_DIR}/${SRC}-${TRG}/`basename $$c`; \
	  else \
	    zcat $$c >> ${LOCAL_TRAIN_TRG}; \
	  fi \
	done
endif





####################
# development data
####################

${DEV_SRC}.shuffled.gz:
	mkdir -p ${dir $@}
	rm -f ${DEV_SRC} ${DEV_TRG}
	-for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    if [ ! `echo "$$s-$$t $$t-$$s" | egrep '${SKIP_LANGPAIRS}' | wc -l` -gt 0 ]; then \
	      ${MAKE} SRC=$$s TRG=$$t add-to-dev-data; \
	    else \
	      echo "!!!!!!!!!!! skip language pair $$s-$$t !!!!!!!!!!!!!!!!"; \
	    fi \
	  done \
	done
	paste ${DEV_SRC} ${DEV_TRG} | shuf | gzip -c > $@


## if we have less than twice the amount of DEVMINSIZE in the data set
## --> extract some data from the training data to be used as devdata

${DEV_SRC}: %: %.shuffled.gz
## if we extract test and dev data from the same data set
## ---> make sure that we do not have any overlap between the two data sets
## ---> reserve at least DEVMINSIZE data for dev data and keep the rest for testing
ifeq (${DEVSET},${TESTSET})
	if (( `zcat $@.shuffled.gz | wc -l` < $$((${DEVSIZE} + ${TESTSIZE})) )); then \
	  if (( `zcat $@.shuffled.gz | wc -l` < $$((${DEVSMALLSIZE} + ${DEVMINSIZE})) )); then \
	    zcat $@.shuffled.gz | cut -f1 | head -${DEVMINSIZE} > ${DEV_SRC}; \
	    zcat $@.shuffled.gz | cut -f2 | head -${DEVMINSIZE} > ${DEV_TRG}; \
	    mkdir -p ${dir ${TEST_SRC}}; \
	    zcat $@.shuffled.gz | cut -f1 | tail -n +$$((${DEVMINSIZE} + 1)) > ${TEST_SRC}; \
	    zcat $@.shuffled.gz | cut -f2 | tail -n +$$((${DEVMINSIZE} + 1)) > ${TEST_TRG}; \
	  else \
	    zcat $@.shuffled.gz | cut -f1 | head -${DEVSMALLSIZE} > ${DEV_SRC}; \
	    zcat $@.shuffled.gz | cut -f2 | head -${DEVSMALLSIZE} > ${DEV_TRG}; \
	    mkdir -p ${dir ${TEST_SRC}}; \
	    zcat $@.shuffled.gz | cut -f1 | tail -n +$$((${DEVSMALLSIZE} + 1)) > ${TEST_SRC}; \
	    zcat $@.shuffled.gz | cut -f2 | tail -n +$$((${DEVSMALLSIZE} + 1)) > ${TEST_TRG}; \
	  fi; \
	else \
	  zcat $@.shuffled.gz | cut -f1 | head -${DEVSIZE} > ${DEV_SRC}; \
	  zcat $@.shuffled.gz | cut -f2 | head -${DEVSIZE} > ${DEV_TRG}; \
	  mkdir -p ${dir ${TEST_SRC}}; \
	  zcat $@.shuffled.gz | cut -f1 | head -$$((${DEVSIZE} + ${TESTSIZE})) | tail -${TESTSIZE} > ${TEST_SRC}; \
	  zcat $@.shuffled.gz | cut -f2 | head -$$((${DEVSIZE} + ${TESTSIZE})) | tail -${TESTSIZE} > ${TEST_TRG}; \
	  zcat $@.shuffled.gz | cut -f1 | tail -n +$$((${DEVSIZE} + ${TESTSIZE})) | gzip -c > ${DEV_SRC}.notused.gz; \
	  zcat $@.shuffled.gz | cut -f2 | tail -n +$$((${DEVSIZE} + ${TESTSIZE})) | gzip -c > ${DEV_TRG}.notused.gz; \
	fi
else
	zcat $@.shuffled.gz | cut -f1 | head -${DEVSIZE} > ${DEV_SRC}
	zcat $@.shuffled.gz | cut -f2 | head -${DEVSIZE} > ${DEV_TRG}
	zcat $@.shuffled.gz | cut -f1 | tail -n +$$((${DEVSIZE} + 1)) | gzip -c > ${DEV_SRC}.notused.gz
	zcat $@.shuffled.gz | cut -f2 | tail -n +$$((${DEVSIZE} + 1)) | gzip -c > ${DEV_TRG}.notused.gz
endif
	echo -n "devset = top "                         >> ${dir ${DEV_SRC}}/README
	wc -l < ${DEV_SRC} | tr "\n" ' '                >> ${dir ${DEV_SRC}}/README
	echo " lines of ${notdir $@}.shuffled!"         >> ${dir ${DEV_SRC}}/README
ifeq (${DEVSET},${TESTSET})
	echo -n "testset = last "                       >> ${dir ${TEST_SRC}}/README
	wc -l < ${TEST_SRC} | tr "\n" ' '               >> ${dir ${TEST_SRC}}/README
	echo " lines of ../val/${notdir $@}.shuffled!"  >> ${dir ${TEST_SRC}}/README
endif



#	  zcat $@.shuffled.gz | cut -f1 | tail -${TESTSIZE} > ${TEST_SRC}; \
#	  zcat $@.shuffled.gz | cut -f2 | tail -${TESTSIZE} > ${TEST_TRG}; \


${DEV_TRG}: ${DEV_SRC}
	@echo "done!"



### OLD: extract data from training data as dev/test set if the devdata is too small
### ---> this is confusing - skip this
###
### otherwise copy this directly after the target for ${DEV_SRC} above!
### and add dependency on train-data for ${DEV_SRC}.shuffled.gz like this:
### ${DEV_SRC}.shuffled.gz: ${TRAIN_SRC}.${PRE_SRC}.gz ${TRAIN_TRG}.${PRE_TRG}.gz
### and remove dependency on dev-data for ${LOCAL_TRAIN_SRC}, change
### ${LOCAL_TRAIN_SRC}: ${DEV_SRC} ${DEV_TRG}                 to
### ${LOCAL_TRAIN_SRC}:
#
#	if (( `zcat $@.shuffled.gz | wc -l` < $$((${DEVMINSIZE} + ${DEVMINSIZE})) )); then \
#	  echo "Need more devdata - take some from traindata!"; \
#	  echo ".......... (1) extract top $$((${DEVSIZE} + ${TESTSIZE})) lines"; \
#	  echo "Too little dev/test data in ${DEVSET}!"                                   >> ${dir $@}/README; \
#	  echo "Add top $$((${DEVSIZE} + ${TESTSIZE})) lines from ${DATASET} to dev/test" >> ${dir $@}/README; \
#	  echo "and remove those lines from training data"                                >> ${dir $@}/README; \
#	  zcat ${TRAIN_SRC}.${PRE_SRC}.gz | \
#		head -$$((${DEVSIZE} + ${TESTSIZE})) | \
#		sed 's/\@\@ //g' > $@.extra.${SRC}; \
#	  zcat ${TRAIN_TRG}.${PRE_TRG}.gz | \
#		head -$$((${DEVSIZE} + ${TESTSIZE})) | \
#		sed 's/\@\@ //g' > $@.extra.${TRG}; \
#	  echo ".......... (2) remaining lines for training"; \
#	  zcat ${TRAIN_SRC}.${PRE_SRC}.gz | \
#		tail -n +$$((${DEVSIZE} + ${TESTSIZE} + 1)) | \
#		sed 's/\@\@ //g' | gzip -c > $@.remaining.${SRC}.gz; \
#	  zcat ${TRAIN_TRG}.${PRE_TRG}.gz | \
#		tail -n +$$((${DEVSIZE} + ${TESTSIZE} + 1)) | \
#		sed 's/\@\@ //g' | gzip -c > $@.remaining.${TRG}.gz; \
#	  mv -f $@.remaining.${SRC}.gz ${TRAIN_SRC}.${PRE_SRC}.gz; \
#	  mv -f $@.remaining.${TRG}.gz ${TRAIN_TRG}.${PRE_TRG}.gz; \
#	  echo ".......... (3) append to devdata"; \
#	  mv $@.shuffled.gz $@.oldshuffled.gz; \
#	  paste $@.extra.${SRC} $@.extra.${TRG} > $@.shuffled; \
#	  zcat $@.oldshuffled.gz >> $@.shuffled; \
#	  rm $@.oldshuffled.gz; \
#	  gzip -f $@.shuffled; \
#	  rm -f $@.extra.${SRC} $@.extra.${TRG}; \
#	fi





add-to-dev-data: ${CLEAN_DEV_SRC} ${CLEAN_DEV_TRG}
ifneq (${CLEAN_DEV_SRC},)
ifneq (${words ${TRGLANGS}},1)
	echo "more than one target language";
	zcat ${CLEAN_DEV_SRC} |\
	sed "s/^/>>${TRG}<< /" >> ${DEV_SRC}
else
	echo "only one target language"
	zcat ${CLEAN_DEV_SRC} >> ${DEV_SRC}
endif
	zcat ${CLEAN_DEV_TRG} >> ${DEV_TRG}
endif


####################
# test data
####################
##
## if devset and testset are from the same source:
## --> use part of the shuffled devset
## otherwise: create the testset
## exception: TESTSET exists in TESTSET_DIR
## --> just use that one

${TEST_SRC}: ${DEV_SRC}
ifneq (${TESTSET},${DEVSET})
	mkdir -p ${dir $@}
	rm -f ${TEST_SRC} ${TEST_TRG}
	if [ -e ${TESTSET_DIR}/${TESTSET}.${SRCEXT}.${PRE}.gz ]; then \
	  ${MAKE} CLEAN_TEST_SRC=${TESTSET_DIR}/${TESTSET}.${SRCEXT}.${PRE}.gz \
		  CLEAN_TEST_TRG=${TESTSET_DIR}/${TESTSET}.${TRGEXT}.${PRE}.gz \
	  add-to-test-data; \
	else \
	  for s in ${SRCLANGS}; do \
	    for t in ${TRGLANGS}; do \
	      if [ ! `echo "$$s-$$t $$t-$$s" | egrep '${SKIP_LANGPAIRS}' | wc -l` -gt 0 ]; then \
	        ${MAKE} SRC=$$s TRG=$$t add-to-test-data; \
	      else \
	        echo "!!!!!!!!!!! skip language pair $$s-$$t !!!!!!!!!!!!!!!!"; \
	      fi \
	    done \
	  done; \
	  if [ ${TESTSIZE} -lt `cat $@ | wc -l` ]; then \
	    paste ${TEST_SRC} ${TEST_TRG} | shuf | gzip -c > $@.shuffled.gz; \
	    zcat $@.shuffled.gz | cut -f1 | tail -${TESTSIZE} > ${TEST_SRC}; \
	    zcat $@.shuffled.gz | cut -f2 | tail -${TESTSIZE} > ${TEST_TRG}; \
	    echo "testset = top ${TESTSIZE} lines of $@.shuffled!" >> ${dir $@}/README; \
	  fi \
	fi
else
	mkdir -p ${dir $@}
	if [ -e ${TESTSET_DIR}/${TESTSET}.${SRCEXT}.${PRE}.gz ]; then \
	  ${MAKE} CLEAN_TEST_SRC=${TESTSET_DIR}/${TESTSET}.${SRCEXT}.${PRE}.gz \
		  CLEAN_TEST_TRG=${TESTSET_DIR}/${TESTSET}.${TRGEXT}.${PRE}.gz \
	  add-to-test-data; \
	elif (( `zcat $<.shuffled.gz | wc -l` < $$((${DEVSIZE} + ${TESTSIZE})) )); then \
	  zcat $<.shuffled.gz | cut -f1 | tail -n +$$((${DEVMINSIZE} + 1)) > ${TEST_SRC}; \
	  zcat $<.shuffled.gz | cut -f2 | tail -n +$$((${DEVMINSIZE} + 1)) > ${TEST_TRG}; \
	else \
	  zcat $<.shuffled.gz | cut -f1 | tail -${TESTSIZE} > ${TEST_SRC}; \
	  zcat $<.shuffled.gz | cut -f2 | tail -${TESTSIZE} > ${TEST_TRG}; \
	fi
endif

${TEST_TRG}: ${TEST_SRC}
	@echo "done!"

add-to-test-data: ${CLEAN_TEST_SRC}
ifneq (${CLEAN_TEST_SRC},)
ifneq (${words ${TRGLANGS}},1)
	echo "more than one target language";
	zcat ${CLEAN_TEST_SRC} |\
	sed "s/^/>>${TRG}<< /" >> ${TEST_SRC}
else
	echo "only one target language"
	zcat ${CLEAN_TEST_SRC} >> ${TEST_SRC}
endif
	zcat ${CLEAN_TEST_TRG} >> ${TEST_TRG}
endif



## reduce training data size if necessary
ifdef TRAINSIZE
${TRAIN_SRC}.clean.${PRE_SRC}${TRAINSIZE}.gz: ${TRAIN_SRC}.clean.${PRE_SRC}.gz
	zcat $< | head -${TRAINSIZE} | gzip -c > $@

${TRAIN_TRG}.clean.${PRE_TRG}${TRAINSIZE}.gz: ${TRAIN_TRG}.clean.${PRE_TRG}.gz
	zcat $< | head -${TRAINSIZE} | gzip -c > $@
endif


# %.clean.gz: %.gz
#	mkdir -p ${TMPDIR}/${LANGPAIRSTR}/cleanup
#	gzip -cd < $< >  ${TMPDIR}/${LANGPAIRSTR}/cleanup/$(notdir $@).${SRCEXT}


########################
# tune data
# TODO: do we use this?
########################

${TUNE_SRC}: ${TRAIN_SRC}
	mkdir -p ${dir $@}
	rm -f ${TUNE_SRC} ${TUNE_TRG}
	-for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    ${MAKE} SRC=$$s TRG=$$t add-to-tune-data; \
	  done \
	done

${TUNE_TRG}: ${TUNE_SRC}
	@echo "done!"

add-to-tune-data: ${CLEAN_TUNE_SRC}
ifneq (${CLEAN_TUNE_SRC},)
ifneq (${words ${TRGLANGS}},1)
	echo "more than one target language";
	zcat ${CLEAN_TUNE_SRC} |\
	sed "s/^/>>${TRG}<< /" >> ${TUNE_SRC}
else
	echo "only one target language"
	zcat ${CLEAN_TUNE_SRC} >> ${TUNE_SRC}
endif
	zcat ${CLEAN_TUNE_TRG} >> ${TUNE_TRG}
endif



${LOCAL_MONO_DATA}.raw:
	mkdir -p ${dir $@}
	rm -f $@
	-for l in ${LANGS}; do \
	  ${MAKE} DATASET=${DATASET} LANGID:=$$l \
		add-to-local-mono-data; \
	done

add-to-local-mono-data:
	for c in ${MONOSET}; do \
	  if [ -e ${OPUSHOME}/$$c/latest/mono/${LANGID}.txt.gz ]; then \
	    zcat ${OPUSHOME}/$$c/latest/mono/${LANGID}.txt.gz |\
	    scripts/filter/mono-match-lang.py -l ${LANGID} >> ${LOCAL_MONO_DATA}.raw; \
	  fi \
	done

##----------------------------------------------
## tokenization
##----------------------------------------------


## normalisation for Chinese
%.zh_tw.tok: %.zh_tw.raw
	$(LOAD_MOSES) cat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/normalize-punctuation.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@

%.zh_cn.tok: %.zh_cn.raw
	$(LOAD_MOSES) cat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/normalize-punctuation.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@

%.zh.tok: %.zh.raw
	$(LOAD_MOSES) cat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/normalize-punctuation.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@

## generic target for tokenization
%.tok: %.raw
	$(LOAD_MOSES) cat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/normalize-punctuation.perl \
		-l ${lastword ${subst 1,,${subst 2,,${subst ., ,$(<:.raw=)}}}} |\
	$(TOKENIZER)/tokenizer.perl -a -threads $(THREADS) \
		-l ${lastword ${subst 1,,${subst 2,,${subst ., ,$(<:.raw=)}}}} |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@



### TODO: make language-specific pre-processing ....
### use SRC_CLEANUP_SCRIPTS TRG_CLEANUP_SCRIPTS

## only normalisation
%.norm.gz: %.gz
	$(LOAD_MOSES) zcat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/normalize-punctuation.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' | gzip -c > $@

%.norm: %.raw
	$(LOAD_MOSES) cat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/normalize-punctuation.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@

%.${SRCEXT}.norm: %.${SRCEXT}.raw
	$(LOAD_MOSES) cat $< ${SRC_CLEANUP_SCRIPTS} |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/normalize-punctuation.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@

%.${TRGEXT}.norm: %.${TRGEXT}.raw
	$(LOAD_MOSES) cat $< ${TRG_CLEANUP_SCRIPTS} |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/normalize-punctuation.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@


## minimal pre-processing
%.simple.gz: %.gz
	$(LOAD_MOSES) zcat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/deescape-special-chars.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' | gzip -c > $@

%.simple: %.raw
	$(LOAD_MOSES) cat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/deescape-special-chars.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@

%.${SRCEXT}.simple: %.${SRCEXT}.raw
	$(LOAD_MOSES) cat $< ${SRC_CLEANUP_SCRIPTS} |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/deescape-special-chars.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@

%.${TRGEXT}.simple: %.${TRGEXT}.raw
	$(LOAD_MOSES) cat $< ${TRG_CLEANUP_SCRIPTS} |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/deescape-special-chars.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@



## remove all spaces (treat everything as a long string)
%.nospace: %.raw
	$(LOAD_MOSES) cat $< |\
	$(TOKENIZER)/replace-unicode-punctuation.perl |\
	$(TOKENIZER)/remove-non-printing-char.perl |\
	$(TOKENIZER)/deescape-special-chars.perl |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' |\
	sed 's/ /▁/g' > $@


## generic targets to make it possible to work with compressed data
## when running the same pre-processing pipeline
## TODO: does that destroy anything?
## TODO: do we need this?

# %.raw: %.gz
# 	gzip -cd < $< > $@

# %.${PRE}.gz: %.${PRE}
# 	gzip -c < $< > $@






## the above should avoid having repeating the pipeline below

# %.norm.gz: %.gz
# 	$(LOAD_MOSES) zcat $< |\
# 	$(TOKENIZER)/replace-unicode-punctuation.perl |\
# 	$(TOKENIZER)/remove-non-printing-char.perl |\
# 	$(TOKENIZER)/normalize-punctuation.perl |\
# 	sed 's/  */ /g;s/^ *//g;s/ *$$//g' | gzip -c > $@

# %.simple.gz: %.gz
# 	$(LOAD_MOSES) zcat $< |\
# 	$(TOKENIZER)/replace-unicode-punctuation.perl |\
# 	$(TOKENIZER)/remove-non-printing-char.perl |\
# 	$(TOKENIZER)/deescape-special-chars.perl |\
# 	sed 's/  */ /g;s/^ *//g;s/ *$$//g' | gzip -c > $@

# %.nospace.gz: %.gz
# 	$(LOAD_MOSES) zcat $< |\
# 	$(TOKENIZER)/replace-unicode-punctuation.perl |\
# 	$(TOKENIZER)/remove-non-printing-char.perl |\
# 	$(TOKENIZER)/deescape-special-chars.perl |\
# 	sed 's/  */ /g;s/^ *//g;s/ *$$//g' |\
# 	sed 's/ /▁/g' |\
# 	gzip -c > $@





## increase max number of tokens to 250
## (TODO: should MIN_NTOKENS be 1?)
MIN_NR_TOKENS = 0
MAX_NR_TOKENS = 250

## apply the cleanup script from Moses
%.src.clean.${PRE_SRC}: %.src.${PRE_SRC} %.trg.${PRE_TRG}
	rm -f $@.${SRCEXT} $<.${TRGEXT}
	ln -s ${word 1,$^} $<.${SRCEXT}
	ln -s ${word 2,$^} $<.${TRGEXT}
	$(MOSESSCRIPTS)/training/clean-corpus-n.perl $< $(SRCEXT) $(TRGEXT) $@ ${MIN_NR_TOKENS} ${MAX_NR_TOKENS}
	rm -f $<.${SRCEXT} $<.${TRGEXT}
	mv $@.${SRCEXT} $@
	mv $@.${TRGEXT} $(@:.src.clean.${PRE_SRC}=.trg.clean.${PRE_TRG})

#	paste $@.${SRCEXT} $@.${TRGEXT} |\
#	scripts/filter/bitext-match-lang.py -s ${SRC} -t ${TRG} > $@.bitext
#	cut -f1 $@.bitext > $@
#	cut -f2 $@.bitext > $(@:.src.clean.${PRE_SRC}=.trg.clean.${PRE_TRG})
#	rm -f $@.${SRCEXT} $@.${TRGEXT} $@.bitext


%.trg.clean.${PRE_TRG}: %.src.clean.${PRE_SRC}
	@echo "done!"


# tokenize testsets
testsets/%.raw: testsets/%.gz
	gzip -cd < $< > $@

testsets/%.${PRE}.gz: testsets/%.${PRE}
	gzip -c < $< > $@

ALLTEST = $(patsubst %.gz,%.${PRE}.gz,${sort $(subst .${PRE},,${wildcard testsets/*/*.??.gz})})

tokenize-testsets prepare-testsets: ${ALLTEST}


##----------------------------------------------
## BPE
##----------------------------------------------

## source/target specific bpe
## - make sure to leave the language flags alone!
## - make sure that we do not delete the BPE code files
## if the BPE models already exist
## ---> do not create new ones and always keep the old ones
## ---> need to delete the old ones if we want to create new BPE models


# BPESRCMODEL = ${TRAIN_SRC}.bpe${SRCBPESIZE:000=}k-model
# BPETRGMODEL = ${TRAIN_TRG}.bpe${TRGBPESIZE:000=}k-model

## NEW: always use the same name for the BPE models
## --> avoid overwriting validation/test data with new segmentation models
##     if a new data set is used
BPESRCMODEL = ${WORKDIR}/train/${BPEMODELNAME}.src.bpe${SRCBPESIZE:000=}k-model
BPETRGMODEL = ${WORKDIR}/train/${BPEMODELNAME}.trg.bpe${TRGBPESIZE:000=}k-model


.PRECIOUS: ${BPESRCMODEL} ${BPETRGMODEL}
.INTERMEDIATE: ${LOCAL_TRAIN_SRC} ${LOCAL_TRAIN_TRG} ${LOCAL_TRAIN_SRC}.charfreq ${LOCAL_TRAIN_TRG}.charfreq

# ${BPESRCMODEL}: ${WORKDIR}/%.bpe${SRCBPESIZE:000=}k-model: ${TMPDIR}/${LANGPAIRSTR}/%
${BPESRCMODEL}: ${LOCAL_TRAIN_SRC}
ifeq ($(wildcard ${BPESRCMODEL}),)
	mkdir -p ${dir $@}
ifeq ($(TRGLANGS),${firstword ${TRGLANGS}})
	python3 ${SNMTPATH}/learn_bpe.py -s $(SRCBPESIZE) < $< > $@
else
	cut -f2- -d ' ' $< > $<.text
	python3 ${SNMTPATH}/learn_bpe.py -s $(SRCBPESIZE) < $<.text > $@
	rm -f $<.text
endif
else
	@echo "$@ already exists!"
	@echo "WARNING! No new BPE model is created even though the data has changed!"
	@echo "WARNING! Delete the file if you want to start from scratch!"
endif

## no labels on the target language side
# ${BPETRGMODEL}: ${WORKDIR}/%.bpe${TRGBPESIZE:000=}k-model: ${TMPDIR}/${LANGPAIRSTR}/%
${BPETRGMODEL}: ${LOCAL_TRAIN_TRG}
ifeq ($(wildcard ${BPETRGMODEL}),)
	mkdir -p ${dir $@}
	python3 ${SNMTPATH}/learn_bpe.py -s $(TRGBPESIZE) < $< > $@
else
	@echo "$@ already exists!"
	@echo "WARNING! No new BPE codes are created!"
	@echo "WARNING! Delete the file if you want to start from scratch!"
endif



%.src.bpe${SRCBPESIZE:000=}k: %.src ${BPESRCMODEL}
ifeq ($(TRGLANGS),${firstword ${TRGLANGS}})
	python3 ${SNMTPATH}/apply_bpe.py -c $(word 2,$^) < $< > $@
else
	cut -f1 -d ' ' $< > $<.labels
	cut -f2- -d ' ' $< > $<.text
	python3 ${SNMTPATH}/apply_bpe.py -c $(word 2,$^) < $<.text > $@.text
	paste -d ' ' $<.labels $@.text > $@
	rm -f $<.labels $<.text $@.text
endif

%.trg.bpe${TRGBPESIZE:000=}k: %.trg ${BPETRGMODEL}
	python3 ${SNMTPATH}/apply_bpe.py -c $(word 2,$^) < $< > $@


## this places @@ markers in front of punctuations
## if they appear to the right of the segment boundary
## (useful if we use BPE without tokenization)
%.segfix: %
	perl -pe 's/(\P{P})\@\@ (\p{P})/$$1 \@\@$$2/g' < $< > $@



%.trg.txt: %.trg
	mkdir -p ${dir $@}
	mv $< $@

%.src.txt: %.src
	mkdir -p ${dir $@}
	mv $< $@




##----------------------------------------------
## sentence piece
##----------------------------------------------


# SPMSRCMODEL = ${TRAIN_SRC}.spm${SRCBPESIZE:000=}k-model
# SPMTRGMODEL = ${TRAIN_TRG}.spm${TRGBPESIZE:000=}k-model

## NEW: always use the same name for the SPM models
## --> avoid overwriting validation/test data with new segmentation models
##     if a new data set is used
SPMSRCMODEL = ${WORKDIR}/train/${BPEMODELNAME}.src.spm${SRCBPESIZE:000=}k-model
SPMTRGMODEL = ${WORKDIR}/train/${BPEMODELNAME}.trg.spm${TRGBPESIZE:000=}k-model
# SPMEXTRA = --split_by_whitespace=false
SPMEXTRA = 

.PRECIOUS: ${SPMSRCMODEL} ${SPMTRGMODEL}

GENERATE_SPM_VOC = 0

# ${SPMSRCMODEL}: ${WORKDIR}/%.spm${SRCBPESIZE:000=}k-model: ${TMPDIR}/${LANGPAIRSTR}/%
${SPMSRCMODEL}: ${LOCAL_TRAIN_SRC}
ifeq ($(wildcard ${SPMSRCMODEL}),)
	mkdir -p ${dir $@}
ifeq ($(TRGLANGS),${firstword ${TRGLANGS}})
	grep . $< | shuf > $<.text
else
	cut -f2- -d ' ' $< | grep . | shuf > $<.text
endif
	${MAKE} ${LOCAL_TRAIN_SRC}.charfreq
	if [ `cat ${LOCAL_TRAIN_SRC}.charfreq | wc -l` -gt 1000 ]; then \
	  ${SPM_HOME}/spm_train ${SPMEXTRA} \
		--model_prefix=$@ --vocab_size=$(SRCBPESIZE) --input=$<.text \
		--character_coverage=0.9995 --hard_vocab_limit=false; \
	else \
	  ${SPM_HOME}/spm_train ${SPMEXTRA} \
		--model_prefix=$@ --vocab_size=$(SRCBPESIZE) --input=$<.text \
		--character_coverage=1.0 --hard_vocab_limit=false; \
	fi
	mv $@.model $@
ifeq (${GENERATE_SPM_VOC},1)
	${SPM_HOME}/spm_encode --model=$@ --generate_vocabulary < $<.text > $@.voc
endif
	rm -f $<.text
else
	@echo "$@ already exists!"
	@echo "WARNING! No new SPM model is created even though the data has changed!"
	@echo "WARNING! Delete the file if you want to start from scratch!"
endif


## no labels on the target language side
# ${SPMTRGMODEL}: ${WORKDIR}/%.spm${TRGBPESIZE:000=}k-model: ${TMPDIR}/${LANGPAIRSTR}/%
${SPMTRGMODEL}: ${LOCAL_TRAIN_TRG}
ifeq ($(wildcard ${SPMTRGMODEL}),)
	mkdir -p ${dir $@}
	grep . $< | shuf > $<.text
	${MAKE} ${LOCAL_TRAIN_TRG}.charfreq
	if [ `cat ${LOCAL_TRAIN_TRG}.charfreq | wc -l` -gt 1000 ]; then \
	  ${SPM_HOME}/spm_train ${SPMEXTRA} \
		--model_prefix=$@ --vocab_size=$(TRGBPESIZE) --input=$<.text \
		--character_coverage=0.9995 --hard_vocab_limit=false; \
	else \
	  ${SPM_HOME}/spm_train ${SPMEXTRA} \
		--model_prefix=$@ --vocab_size=$(TRGBPESIZE) --input=$<.text \
		--character_coverage=1.0 --hard_vocab_limit=false; \
	fi
	mv $@.model $@
ifeq (${GENERATE_SPM_VOC},1)
	${SPM_HOME}/spm_encode --model=$@ --generate_vocabulary < $<.text > $@.voc
endif
	rm -f $<.text
else
	@echo "$@ already exists!"
	@echo "WARNING! No new SPM model created!"
	@echo "WARNING! Delete the file if you want to start from scratch!"
endif






## sentence piece model trained on monolingual data
SPMMODEL   = ${SPMDIR}/${LANGSTR}/${BPEMODELNAME}.spm${BPESIZE:000=}k-model
SPMSRCMONO = ${SPMDIR}/${LANGSRCSTR}/${BPEMODELNAME}.spm${SRCBPESIZE:000=}k-model
SPMTRGMONO = ${SPMDIR}/${LANGTRGSTR}/${BPEMODELNAME}.spm${TRGBPESIZE:000=}k-model

## vocabulary files created from monolingual data
SPMVOCAB    = ${SPMDIR}/${LANGSTR}/${BPEMODELNAME}.spm${BPESIZE:000=}k.vocab.yml
SPMSRCVOCAB = ${SPMDIR}/${LANGSRCSTR}/${BPEMODELNAME}.spm${SRCBPESIZE:000=}k.vocab.yml
SPMTRGVOCAB = ${SPMDIR}/${LANGTRGSTR}/${BPEMODELNAME}.spm${TRGBPESIZE:000=}k.vocab.yml

.PRECIOUS: ${SPMMODEL} ${SPMSRCMONO} ${SPMTRGMONO} ${SPMVOCAB}

mono-spm-vocab: ${SPMVOCAB}

ifneq (${SPMVOCAB},${SPMSRCVOCAB})
  ${SPMSRCVOCAB}:
	${MAKE} LANGS=${SRCLANGS} BPESIZE=${SRCBPESIZE} mono-spm-vocab
endif

ifneq (${SPMVOCAB},${SPMTRGVOCAB})
  ${SPMTRGVOCAB}:
	${MAKE} LANGS=${TRGLANGS} BPESIZE=${TRGBPESIZE} mono-spm-vocab
endif


${SPMVOCAB}: ${LOCAL_MONO_DATA}.${PRE} ${SPMMODEL}
ifeq ($(wildcard ${SPMVOCAB}),)
	mkdir -p ${dir $@}
	${SPM_HOME}/spm_encode --model ${SPMMODEL} < $< |\
	${MARIAN}/marian-vocab --max-size ${VOCABSIZE} > $@
else
	@echo "$@ already exists!"
	@echo "WARNING! No new vocabulary is created even though the data has changed!"
	@echo "WARNING! Delete the file if you want to start from scratch!"
	touch $@
endif



## sentence piece model trained on monolingual data

mono-spm-model: ${SPMMODEL}

ifneq (${SPMMODEL},${SPMSRCMONO})
  ${SPMSRCMONO}:
	${MAKE} LANGS=${SRCLANGS} BPESIZE=${SRCBPESIZE} mono-spm-model
endif

ifneq (${SPMMODEL},${SPMTRGMONO})
  ${SPMTRGMONO}:
	${MAKE} LANGS=${TRGLANGS} BPESIZE=${TRGBPESIZE} mono-spm-model
endif


${SPMMODEL}: ${LOCAL_MONO_DATA}.${PRE}
ifeq ($(wildcard ${SPMMODEL}),)
	mkdir -p ${dir $@}
	grep . $< | shuf > $<.text
	${MAKE} ${LOCAL_MONO_DATA}.${PRE}.charfreq
	if [ `cat ${LOCAL_MONO_DATA}.${PRE}.charfreq | wc -l` -gt 1000 ]; then \
	  ${SPM_HOME}/spm_train ${SPMEXTRA} \
		--model_prefix=$@ --vocab_size=$(TRGBPESIZE) --input=$<.text \
		--character_coverage=0.9995 --hard_vocab_limit=false; \
	else \
	  ${SPM_HOME}/spm_train ${SPMEXTRA} \
		--model_prefix=$@ --vocab_size=$(TRGBPESIZE) --input=$<.text \
		--character_coverage=1.0 --hard_vocab_limit=false; \
	fi
	mv $@.model $@
	${SPM_HOME}/spm_encode --model=$@ --generate_vocabulary < $<.text > $@.voc
	rm -f $<.text
else
	@echo "$@ already exists!"
	@echo "WARNING! No new SPM model created!"
	@echo "WARNING! Delete the file if you want to start from scratch!"
endif

## SentencePiece parameters:
##
# --input_sentence_size (maximum size of sentences the trainer loads)  type: int32  default: 10000000
# --hard_vocab_limit (If set to false, --vocab_size is considered as a soft limit.)  type: bool  default: true
# --training_sentence_size (maximum size of sentences to train sentence pieces)  type: int32  default: 10000000
# --vocab_size (vocabulary size)  type: int32  default: 8000


## character frequence table
## --> used to decide about the character coverage level

## awk-based char-counter
#%.charfreq: %
#	sed 's/./& /g' < $< | tr ' ' "\n" | grep . |\
#	awk '!/^$$/{a[$$0]++}END{for (i in a)print i,a[i];}' > $@

## python-based char-counter (seems to be the fastest version)
%.charfreq: %
	head -10000000 $< > $<.10m
	python -c "import collections, pprint; pprint.pprint(dict(collections.Counter(open('$<.10m', 'r').read())))" > $@
	rm -f $<.10m

## slow version
%.charfreq2: %
	head -10000000 $< |\
	sed 's/./& /g' | \
	tr ' ' "\n" | grep . |\
	sort | uniq -c > $@



## TODO: should we have vocab limits?
## --vocabulary={vocab_file}.L1 --vocabulary_threshold=50
## see https://github.com/google/sentencepiece#c-from-source

%.src.spm${SRCBPESIZE:000=}k: %.src ${SPMSRCMODEL}
ifeq ($(TRGLANGS),${firstword ${TRGLANGS}})
	${SPM_HOME}/spm_encode --model $(word 2,$^) < $< > $@
else
	cut -f1 -d ' ' $< > $<.labels
	cut -f2- -d ' ' $< > $<.text
	${SPM_HOME}/spm_encode --model $(word 2,$^) < $<.text > $@.text
	paste -d ' ' $<.labels $@.text > $@
	rm -f $<.labels $<.text $@.text
endif

%.trg.spm${TRGBPESIZE:000=}k: %.trg ${SPMTRGMODEL}
	${SPM_HOME}/spm_encode --model $(word 2,$^) < $< > $@


## document-level models (with guided alignment)
%.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}.gz:
	${MAKE} PRE_SRC=spm${SRCBPESIZE:000=}k PRE_TRG=spm${TRGBPESIZE:000=}k wordalign
	./large-context.pl -l ${CONTEXT_SIZE} \
		${patsubst %.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}.gz,%.src.spm${SRCBPESIZE:000=}k.gz,$@} \
		${patsubst %.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}.gz,%.trg.spm${TRGBPESIZE:000=}k.gz,$@} \
		${patsubst %.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}.gz,%.spm${SRCBPESIZE:000=}k-spm${TRGBPESIZE:000=}k.src-trg.alg.gz,$@} \
	| gzip > $@.tmp.gz
	zcat $@.tmp.gz | cut -f1 | gzip -c > $@
	zcat $@.tmp.gz | cut -f2 | gzip -c > ${subst .src.,.trg.,$@}
	zcat $@.tmp.gz | cut -f3 | \
		gzip -c > ${patsubst %.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}.gz,\
		%.spm${SRCBPESIZE:000=}k.doc${CONTEXT_SIZE}-spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}.src-trg.alg.gz,$@}
	rm -f $@.tmp.gz

%.trg.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}.gz: %.src.spm${SRCBPESIZE:000=}k.doc${CONTEXT_SIZE}.gz
	@echo "done!"



## for validation and test data:
%.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}:
	${MAKE} PRE_SRC=spm${SRCBPESIZE:000=}k PRE_TRG=spm${TRGBPESIZE:000=}k devdata
	${MAKE} PRE_SRC=spm${SRCBPESIZE:000=}k PRE_TRG=spm${TRGBPESIZE:000=}k testdata
	./large-context.pl -l ${CONTEXT_SIZE} \
		${patsubst %.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE},%.src.spm${SRCBPESIZE:000=}k,$@} \
		${patsubst %.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE},%.trg.spm${TRGBPESIZE:000=}k,$@} \
	| gzip > $@.tmp.gz
	zcat $@.tmp.gz | cut -f1 > $@
	zcat $@.tmp.gz | cut -f2 > ${subst .src.,.trg.,$@}
	rm -f $@.tmp.gz

%.trg.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}: %.src.spm${TRGBPESIZE:000=}k.doc${CONTEXT_SIZE}
	@echo "done!"



##----------------------------------------------
## get data from local space and compress ...

${WORKDIR}/%.clean.${PRE_SRC}.gz: ${TMPDIR}/${LANGPAIRSTR}/%.clean.${PRE_SRC}
	mkdir -p ${dir $@}
	gzip -c < $< > $@

ifneq (${PRE_SRC},${PRE_TRG})
${WORKDIR}/%.clean.${PRE_TRG}.gz: ${TMPDIR}/${LANGPAIRSTR}/%.clean.${PRE_TRG}
	mkdir -p ${dir $@}
	gzip -c < $< > $@
endif




## make symbolic links to spm-models
## (previously we had data-specific models but now we want to re-use existing ones)

fix-spm-models:
	cd work-spm; \
	for l in ${ALL_LANG_PAIRS}; do \
	  cd $$l/train; \
	  if [ ! -e opus.src.spm32k-model ]; then \
	    ln -s *.src.spm32k-model opus.src.spm32k-model; \
	    ln -s *.trg.spm32k-model opus.trg.spm32k-model; \
	  fi; \
	  cd ../..; \
	done