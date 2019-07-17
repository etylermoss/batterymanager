# batterymanager.sh
Bash tool for setting keyboard and display brightness levels at battery %. Still a work in progress.

```
// Main script executable
batterymanager.sh       > /usr/local/bin/batterymanager
// Systemd unit files, to run the executable roughly every 5 minutes.
batterymanager.service  > /etc/systemd/system/batterymanager.service
batterymanager.timer    > /etc/systemd/system/batterymanager.timer
// User configuration, such as setting brightness levels.
batterymanager.conf     > /etc/batterymanager.conf
```
