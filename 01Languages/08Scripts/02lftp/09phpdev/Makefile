FILE1 = phpdev.sh
BINPATH = /usr/bin

all: install

install: $(FILE1)

$(FILE1): $(BINPATH)/$(FILE1)

$(BINPATH)/$(FILE1): src/$(FILE1)
	sudo cp src/$(FILE1) $(BINPATH)
	if [ ! -x $(BINPATH)/$(FILE1) ]; then sudo chmod +x $(BINPATH)/$(FILE1); fi

.phony: clean
clean:
	if [ -f $(BINPATH)/$(FILE1) ]; then sudo rm $(BINPATH)/$(FILE1); fi

