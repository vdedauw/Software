FILE1 = lftp.publish.sh
FILE2 = lftp.backup.sh
BINPATH = /usr/bin

all: install

install: $(FILE1) $(FILE2)

$(FILE1): $(BINPATH)/$(FILE1)

$(FILE2): $(BINPATH)/$(FILE2)

$(BINPATH)/$(FILE1): src/$(FILE1)
	cp src/$(FILE1) $(BINPATH)
	if [ ! -x $(BINPATH)/$(FILE1) ]; then chmod +x $(BINPATH)/$(FILE1); fi

$(BINPATH)/$(FILE2): src/$(FILE2)
	cp src/$(FILE2) $(BINPATH)
	if [ ! -x $(BINPATH)/$(FILE2) ]; then chmod +x $(BINPATH)/$(FILE2); fi

.phony: clean
clean:
	if [ -f $(BINPATH)/$(FILE1) ]; then sudo rm $(BINPATH)/$(FILE1); fi
	if [ -f $(BINPATH)/$(FILE2) ]; then sudo rm $(BINPATH)/$(FILE2); fi
