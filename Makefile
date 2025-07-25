EMACS ?= emacs
BATCH = $(EMACS) --batch -Q
LOAD_PATH = -L .
ELS = kanata-kbd-mode.el
TESTS = kanata-kbd-mode-tests.el

.PHONY: all test clean 

all: test

lint:
	@echo "Running package-lint from MELPA..."
	@$(BATCH) $(LOAD_PATH) --eval "(require 'package)" \
    --eval "(add-to-list 'package-archives '(\"melpa\" . \"https://melpa.org/packages/\") t)" \
    --eval "(package-initialize)" \
    --eval "(unless (package-installed-p 'package-lint) (package-refresh-contents) (package-install 'package-lint))" \
    -l package-lint.el -f package-lint-batch-and-exit $(ELS)

clean:
	@echo "Cleaning..."
	@rm -f *.elc
