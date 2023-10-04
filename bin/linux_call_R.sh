#!/bin/bash

rfile=$1
shift # remove the first one of the list of arguments
R --vanilla --slave --args $* < $rfile
exit 0
