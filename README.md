# NEWS AND ANNOUNCEMENTS

Unfortunately, the data server is still down and the IT service is working on the issue. The pre-trained models are, therefore, not available at the moment. Sorry! Hopefully, everything will be up and running again later this week. Apologies for the inconvenience!


# Train Opus-MT models

This package includes scripts for training NMT models using MarianNMT and OPUS data for [OPUS-MT](https://github.com/Helsinki-NLP/Opus-MT). More details are given in the [Makefile](Makefile) but documentation needs to be improved. Also, the targets require a specific environment and right now only work well on the CSC HPC cluster in Finland.


## Pre-trained models

The subdirectory [models](https://github.com/Helsinki-NLP/Opus-MT-train/tree/master/models) contains information about pre-trained models that can be downloaded from this project. They are distribted with a [CC-BY 4.0 license](https://creativecommons.org/licenses/by/4.0/) license.


## Quickstart

Setting up:

```
git clone https://github.com/Helsinki-NLP/OPUS-MT-train.git
git submodule update --init --recursive --remote
make install
```

Training a multilingual NMT model (Finnish and Estonian to Danish, Swedish and English):

```
make SRCLANGS="fi et" TRGLANGS="da sv en" train
make SRCLANGS="fi et" TRGLANGS="da sv en" eval
make SRCLANGS="fi et" TRGLANGS="da sv en" release
```

More information is available in the documentation linked below.


## Documentation

* [Installation and setup](https://github.com/Helsinki-NLP/Opus-MT-train/tree/master/doc/Setup.md)
* [Details about tasks and recipes](https://github.com/Helsinki-NLP/Opus-MT-train/tree/master/doc/README.md)
* [Information about back-translation](https://github.com/Helsinki-NLP/Opus-MT-train/tree/master/backtranslate/README.md)
* [Information about Fine-tuning models](https://github.com/Helsinki-NLP/OPUS-MT-train/blob/master/finetune/README.md)
* [How to generate pivot-language-based translations](https://github.com/Helsinki-NLP/OPUS-MT-train/blob/master/pivoting/README.md)



## Tutorials

* [Training low-resource models](https://github.com/Helsinki-NLP/Opus-MT-train/tree/master/doc/tutorials/low-resource.md)
* [How to train models for the Tatoeba MT Challenge](https://github.com/Helsinki-NLP/Opus-MT-train/tree/master/doc/TatoebaChallenge.md)


## References

Please, cite the following paper if you use OPUS-MT software and models:

```
@InProceedings{TiedemannThottingal:EAMT2020,
  author = {J{\"o}rg Tiedemann and Santhosh Thottingal},
  title = {{OPUS-MT} — {B}uilding open translation services for the {W}orld},
  booktitle = {Proceedings of the 22nd Annual Conferenec of the European Association for Machine Translation (EAMT)},
  year = {2020},
  address = {Lisbon, Portugal}
 }
 ```


## Acknowledgements

None of this would be possible without all the great open source software including

* GNU/Linux tools
* [Marian-NMT](https://github.com/marian-nmt/)
* [eflomal](https://github.com/robertostling/eflomal)

... and many other tools like terashuf, pigz, jq, Moses SMT, fast_align, sacrebleu ...

We would also like to acknowledge the support by the [University of Helsinki](https://blogs.helsinki.fi/language-technology/), the [IT Center of Science CSC](https://www.csc.fi/en/home), the funding through projects in the EU Horizon 2020 framework ([FoTran](http://www.helsinki.fi/fotran), [MeMAD](https://memad.eu/), [ELG](https://www.european-language-grid.eu/)) and the contributors to the open collection of parallel corpora [OPUS](http://opus.nlpl.eu/).
