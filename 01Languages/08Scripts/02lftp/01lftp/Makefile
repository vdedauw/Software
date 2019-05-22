FILE1 = lftp.sh
BINPATH = /usr/bin

all: install

install: $(FILE1) $(FILE2)

$(FILE1): $(BINPATH)/$(FILE1)

$(BINPATH)/$(FILE1): src/$(FILE1)
	cp src/$(FILE1) $(BINPATH)
	if [ ! -x $(BINPATH)/$(FILE1) ]; then chmod +x $(BINPATH)/$(FILE1); fi

.phony: clean
clean:
	if [ -f $(BINPATH)/$(FILE1) ]; then sudo rm $(BINPATH)/$(FILE1); fi
