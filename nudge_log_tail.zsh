#!/bin/zsh

/usr/bin/grep User /private/var/log/Nudge.log  | /usr/bin/tail -n 1 | /usr/bin/awk '{print $1,$2,$6,$7,$8,$9, $10, $11,$12}'
