#
# Static Asset Builder
#
# Version:   0.1.1
# Author:    Jeremy Worboys <http://jeremyworboys.com>
# Copyright: Copyright (c) 2013 Jeremy Worboys
#

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------

PRODUCTION         = 0

# Output file-name
target-name        = app

# Path to the source directory relative to this file
src-dir            = lib

# Path to the output directory relative to this file
build-dir          = static

# Scripts
scripts-dir        = scripts
scripts-order      = main.js

# Styles
styles-dir         = styles
styles-order       = main.styl

# Fonts
fonts-dir          = fonts

# Images
images-dir         = images

# Binary locations
node_modules       = ./node_modules
cat                = /bin/cat
grep               = /usr/bin/grep
uglifyjs           = $(node_modules)/.bin/uglifyjs
coffee             = $(node_modules)/.bin/coffee
lessc              = $(node_modules)/.bin/lessc
stylus             = $(node_modules)/.bin/stylus
nib                = $(node_modules)/nib/lib/nib.js
cssmin             = $(node_modules)/.bin/cssmin
pngout             = /usr/local/bin/pngout
pngnq              = /usr/local/bin/pngnq
jpegoptim          = /usr/local/bin/jpegoptim

# Build binary options
ifeq ($(PRODUCTION),1)
uglify-opts        = --mangle --compress
lessc-opts         =
stylus-opts        = --use $(nib) --import nib
pngout-opts        = -s0 -n1 -f0
pngnq-opts         = -s1
jpegoptim-opts     = --strip-all
else
uglify-opts        =
lessc-opts         =
stylus-opts        = --use $(nib) --import nib
pngout-opts        = -s3 -n1
pngnq-opts         = -s10
jpegoptim-opts     =
endif



# ------------------------------------------------------------------------------
# GENERIC
# ------------------------------------------------------------------------------
.PHONY: all clean scripts styles fonts images

#
# Compile all assets
#
all: scripts styles fonts images

#
# Create target build directory
#
$(build-dir):
	mkdir -p $@

#
# Clean-up previous build
#
clean:
	rm -rf $(build-dir)

#
# Run simple Python server
#
server:
	python -m SimpleHTTPServer



# ------------------------------------------------------------------------------
# BINARIES
# ------------------------------------------------------------------------------

$(uglifyjs):
	npm install uglify-js

$(coffee):
	npm install coffee-script

$(lessc):
	npm install less

$(stylus):
	npm install stylus

$(nib):
	npm install nib

$(cssmin):
	npm install cssmin

$(pngout):
	$(error You need to install pngout manually. Get the binary from http://www.jonof.id.au/kenutils)

$(pngnq):
	brew install pngnq

$(jpegoptim):
	brew install jpegoptim



# ------------------------------------------------------------------------------
# SCRIPTS
# ------------------------------------------------------------------------------

scripts: $(uglifyjs) $(build-dir)/$(target-name).js

#
# Concatenate and compress intermediate JS files
#
$(build-dir)/$(target-name).js: $(addprefix $(build-dir)/.js/,$(addsuffix .js,$(scripts-order)))
	$(uglifyjs) $+ $(uglify-opts) --output $@ --source-map $@.map --source-map-url /$@.map --source-map-root /

#
# Copy source JS files
#
$(build-dir)/.js/%.js.js: $(src-dir)/$(scripts-dir)/%.js $(build-dir)/.js
	cp $< $@

#
# Compile source CoffeeScript files
#
$(build-dir)/.js/%.coffee.js: $(src-dir)/$(scripts-dir)/%.coffee $(build-dir)/.js $(coffee)
	$(cat) $< | $(coffee) $(coffee-opts) --compile --stdio > $@


#
# Create directory for intermediate JS files
#
$(build-dir)/.js:
	mkdir -p $@



# ------------------------------------------------------------------------------
# STYLES
# ------------------------------------------------------------------------------

fix-imports = sed -E "s/@import (['\"])(.*)(['\"])/@import \1$(subst /,\/,$(src-dir)/$(styles-dir))\/\2\3/g"

styles: $(cssmin) $(build-dir)/$(target-name).css

#
# Concatenate and compress intermediate CSS files
#
$(build-dir)/$(target-name).css: $(addprefix $(build-dir)/.css/,$(addsuffix .css,$(styles-order)))
ifeq ($(PRODUCTION),1)
	$(cat) $+ | $(cssmin) > $@
else
	$(cat) $+ > $@
endif

#
# Copy source CSS files
#
$(build-dir)/.css/%.css.css: $(src-dir)/$(styles-dir)/%.css $(build-dir)/.css
	cp $< $@

#
# Compile source Less files
#
$(build-dir)/.css/%.less.css: $(src-dir)/$(styles-dir)/%.less $(build-dir)/.css $(lessc)
	$(cat) $< | $(fix-imports) | $(lessc) $(lessc-opts) - $@

#
# Compile source Stylus files
#
$(build-dir)/.css/%.styl.css: $(src-dir)/$(styles-dir)/%.styl $(build-dir)/.css $(stylus) $(nib)
	$(cat) $< | $(fix-imports) | $(stylus) $(stylus-opts) > $@

#
# Create directory for intermediate CSS files
#
$(build-dir)/.css:
	mkdir -p $@



# ------------------------------------------------------------------------------
# FONTS
# ------------------------------------------------------------------------------

fonts: $(subst $(src-dir),$(build-dir),$(wildcard $(src-dir)/$(fonts-dir)/*))

#
# Move source fonts to target directory
#
$(build-dir)/$(fonts-dir)/%: $(src-dir)/$(fonts-dir)/% $(build-dir)/$(fonts-dir)
	cp $< $@

#
# Create target directory for fonts
#
$(build-dir)/$(fonts-dir):
	mkdir -p $(build-dir)/$(fonts-dir)



# ------------------------------------------------------------------------------
# IMAGES
# ------------------------------------------------------------------------------

images: $(subst $(src-dir),$(build-dir),$(wildcard $(src-dir)/$(images-dir)/*))

#
# Optimise and compress PNG images
#
$(build-dir)/$(images-dir)/%.png: $(src-dir)/$(images-dir)/%.png $(pngout) $(pngnq) $(build-dir)/$(images-dir)
	$(pngnq) $(pngnq-opts) -f -d $(build-dir)/$(images-dir) -e .png $<
	$(pngout) $@ $(pngout-opts) -y -q; exit 0

#
# Optimise and compress JPG images
#
$(build-dir)/$(images-dir)/%.jpg: $(src-dir)/$(images-dir)/%.jpg $(jpegoptim) $(build-dir)/$(images-dir)
	$(jpegoptim) $(jpegoptim-opts) -o -q -d $(build-dir)/$(images-dir) $< | $(grep) "optimised" || cp $< $@

#
# Copy remaining source images into target directory
# This rule comes last because rules are top down
#
$(build-dir)/$(images-dir)/%: $(src-dir)/$(images-dir)/% $(build-dir)/$(images-dir)
	cp $< $@

#
# Create target directory for images
#
$(build-dir)/$(images-dir):
	mkdir -p $(build-dir)/$(images-dir)
