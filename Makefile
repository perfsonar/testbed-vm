#
# Makefile for Vagrant-based testbed host
#


DIR := $(shell pwd)
KEY := $(shell pwd | tr / _)

default: build


REBUILD_LOG=rebuild.log
cron-add:
	@echo Adding crontab 
	@crontab -l 2>/dev/null \
	| sed -e '/KEY=$(KEY)/d' \
	| ( cat && echo '0 1 * * * make "KEY=$(KEY)" -C $(DIR) rebuild > $(DIR)/$(REBUILD_LOG) 2>&1') \
	| crontab
TO_CLEAN += $(REBUILD_LOG)

cron-remove:
	@echo Removing crontab 
	@crontab -l 2>/dev/null \
	| sed -e '/KEY=$(KEY)/d' \
	| crontab


BUILD_LOG=vagrant-up.log
up:
	rm -f $(BUILD_LOG)
	vagrant up | tee $(BUILD_LOG)
TO_CLEAN += $(BUILD_LOG)

build: up cron-add

destroy: cron-remove
	vagrant destroy -f

rebuild: destroy build

cron-rebuild:
	./rebuild

ssh:
	@vagrant ssh -c 'sudo -i'


TO_CLEAN += .vagrant

clean: destroy
	rm -rf $(TO_CLEAN)
	find . -name "*~" | xargs rm -f
