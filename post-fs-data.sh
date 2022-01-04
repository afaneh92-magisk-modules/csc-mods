#!/system/bin/sh
MODDIR=${0%/*}

mount --bind "$MODDIRomc_etcpath" "omc_etcpath"
mount --bind "$MODDIRomc_path" "omc_path"
