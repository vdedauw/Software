FILE = orders.sh
BINPATH = /usr/bin

all: install

install: $(FILE)

$(FILE): $(BINPATH)/$(FILE)

$(BINPATH)/$(FILE): src/$(FILE)
	cp src/$(FILE) $(BINPATH)
	if [ ! -x $(BINPATH)/$(FILE) ]; then chmod +x $(BINPATH)/$(FILE); fi

.phony: clean
clean:
	rm $(BINPATH)/$(FILE)


