#!/bin/ksh -x
###############################################################
# < next few lines under version control, D O  N O T  E D I T >
# $Date$
# $Revision$
# $Author$
# $Id$
###############################################################

###############################################################
## Author: Rahul Mahajan  Org: NCEP/EMC  Date: April 2017

## Abstract:
## Ensemble forecast driver script
## EXPDIR : /full/path/to/config/files
## CDATE  : current analysis date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## ENSGRP : ensemble sub-group to make forecasts (1, 2, ...)
###############################################################

###############################################################
# Source relevant configs
configs="base fcst efcs"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

###############################################################
# Source machine runtime environment
. $BASE_ENV/${machine}.env efcs
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Set script and dependency variables
export CASE=$CASE_ENKF
export DATA=$RUNDIR/$CDATE/$CDUMP/efcs.grp$ENSGRP
[[ -d $DATA ]] && rm -rf $DATA

# Get ENSBEG/ENSEND from ENSGRP and NMEM_EFCSGRP
ENSEND=`echo "$NMEM_EFCSGRP * $ENSGRP" | bc`
ENSBEG=`echo "$ENSEND - $NMEM_EFCSGRP + 1" | bc`
export ENSBEG=$ENSBEG
export ENSEND=$ENSEND

cymd=$(echo $CDATE | cut -c1-8)
chh=$(echo  $CDATE | cut -c9-10)

# Default warm_start is OFF
export warm_start=".false."

# If RESTART conditions exist; warm start the model
memchar="mem"`printf %03i $ENSBEG`
if [ -f $ROTDIR/enkf.${CDUMP}.$cymd/$chh/$memchar/RESTART/${cymd}.${chh}0000.coupler.res ]; then
    export warm_start=".true."
    if [ -f $ROTDIR/enkf.${CDUMP}.$cymd/$chh/$memchar/${CDUMP}.t${chh}z.atminc.nc ]; then
        export read_increment=".true."
    else
        echo "WARNING: WARM START $CDUMP $CDATE WITHOUT READING INCREMENT!"
    fi
fi

# Since we do not update SST, SNOW or ICE via global_cycle;
# Pass these to the model; it calls surface cycle internally
if [ $warm_start = ".true." ]; then
    export FNTSFA="$DMPDIR/$CDATE/$CDUMP/${CDUMP}.t${chh}z.sstgrb"
    export FNACNA="$DMPDIR/$CDATE/$CDUMP/${CDUMP}.t${chh}z.engicegrb"
    export FNSNOA="$DMPDIR/$CDATE/$CDUMP/${CDUMP}.t${chh}z.snogrb"
fi

# Forecast length for EnKF forecast
export FHMIN=$FHMIN_ENKF
export FHOUT=$FHOUT_ENKF
export FHMAX=$FHMAX_ENKF

###############################################################
# Run relevant exglobal script
$ENKFFCSTSH
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Exit out cleanly
exit 0