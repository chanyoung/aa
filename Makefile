SCRIPT      := backup.sh
PROGRAM     := mediawiki-backup
INSTALL     := install
INSTALL_DIR := /usr/bin

CRONTAB := crontab

.PHONY: install
install:
	$(INSTALL) -d -m 755 $(INSTALL_DIR)
	$(INSTALL) -m 755 $(SCRIPT) $(INSTALL_DIR)/$(PROGRAM)
	
	@read -p "Enter your wiki installed directory path: " install_path; \
	read -p "Enter your backup files output directory path: " out_path; \
	($(CRONTAB) -l; echo "0 */12 * * * $(INSTALL_DIR)/$(PROGRAM) -p $$install_path -o $$out_path") | $(CRONTAB) -

.PHONY: uninstall
uninstall:
	($(CRONTAB) -l | sed /$(PROGRAM)/d) | $(CRONTAB) -
	
	rm -f $(INSTALL_DIR)/$(PROGRAM)
