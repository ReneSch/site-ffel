#!/bin/sh
# 
###############################################################################################
# Jenkins-Buildscript zu erstellung der Images
# 
# Dieses Script wird nach jedem Push auf dem Freifunk Buildserver ausgf�hrt 
# und erstelt die Images komplett neu.
# 
# Durch den Jenkins-Server werden folgende Systemvariablem gesetzt:
# $WORKSPACE - Arbeitsverzeichnis, hierhin wurde dieses repo geclont 
# $JENKINS_HOME - TBD 
# $BUILD_NUMBER - Nummer des aktuellen Buildvorganges (wird in der site.conf verwendet)
# 
###############################################################################################


# alte Build-Daten l�schen 

if [ -d "$WORKSPACE/gluon" ]; then
  rm -r $WORKSPACE/gluon
fi

# Verzeichnis f�r Gluon-Repo erstellen und initialisieren  
git clone https://github.com/freifunk-gluon/gluon.git $WORKSPACE/gluon

cd $WORKSPACE
git checkout e7e8445df404c44add352524765fc4e6fd228cc4

# Dateien in das Gluon-Repo kopieren
# In der site.conf werden hierbei Umgebungsvariablen durch die aktuellen Werte ersetzt

mkdir $WORKSPACE/gluon/site 

cp $WORKSPACE/modules $WORKSPACE/gluon/site 
cp $WORKSPACE/site.mk $WORKSPACE/gluon/site 
cp $WORKSPACE/site.conf $WORKSPACE/gluon/site 


# Gluon Pakete aktualisieren und Build ausf�hren 
cd $WORKSPACE/gluon
make update 
make GLUON_RELEASE=0.4.1+$BUILD_NUMBER

# Manifest f�r Autoupdater erstellen und mit den Key des Servers unterschreiben 
# Der private Schl�ssel des Servers muss in $JENKINS_HOME/secret liegen und das 
# Tools 'ecdsasign' muss auf dem Server verf�gbar sein.
# Repo: https://github.com/tcatm/ecdsautils

cd $WORKSPACE/gluon
make manifest GLUON_BRANCH=experimental
mv images/sysupgrade/experimental.manifest images/sysupgrade/manifest
sh contrib/sign.sh $JENKINS_HOME/secret images/sysupgrade/manifest
