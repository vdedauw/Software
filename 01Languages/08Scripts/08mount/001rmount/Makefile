FILE1 = rmount.sh
# remove the old version
FILE2 = mount.sh
BINPATH = /usr/bin

all: $(FILE1)

$(FILE1): $(BINPATH)/$(FILE1)

$(BINPATH)/$(FILE1): src/$(FILE1)
	if [ -f $(BINPATH)/$(FILE2) ]; then rm $(BINPATH)/$(FILE2); fi
	cp src/$(FILE1) $(BINPATH)
	if [ ! -x $(BINPATH)/$(FILE1) ]; then chmod +x $(BINPATH)/$(FILE1); fi

.phony: clean
clean:
	if [ -f $(BINPATH)/$(FILE2) ]; then rm $(BINPATH)/$(FILE2); fi
	if [ -f $(BINPATH)/$(FILE1) ]; then rm $(BINPATH)/$(FILE1); fi
