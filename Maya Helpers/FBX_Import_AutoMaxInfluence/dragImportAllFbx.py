# Automatic Setting of 'Maintain Max Influences' to 4 For All Meshes's Skin Cluster After Import
#
# Author: enimaroah from HF
# Version: 1.1
#
# Installation (example paths for Maya 2013):
# -------------------------------------------
# 1) From the menu click 'Window' -> 'Settings/Preferences' -> 'Plug-in Manager'.
# 2) The fist section begins with the MAYA_PLUG_IN_PATH, e.i. C:\Users\{your user}\Documents\Maya\scripts
#    The MAYA_PLUG_IN_PATH is defined in c:\Users\{your user}\Documents\maya\2013-x64\Maya.env like this:
#       MAYA_PLUG_IN_PATH = c:\Users\{your user}\Documents\maya\scripts
#    Restart Maya if you had to create that file or edit this entry.
# 3) Copy this file into the MAYA_PLUG_IN_PATH.
# 4) Press the 'Refresh' button if you dont see the file.
# 5) Check both checkboxes : 'Loaded' and 'Auto load'.
#
# Usage:
# ------
# 1) Drop a file into Maya for import. 'Maintain Max Influences' is set automatically.
# 2) If you want to suspend it, just uncheck the 'Loaded' in the 'Plug-in Manager'.
# 3) Uninstall by unckecking 'Auto load' in the 'Plug-in Manager'.
#
# Based on ideas from:
# --------------------
# 1) dragImportCollada.py by Kostas Gialitakis, kostas.gialitakis@gmail.com, kostas.se
# 2) sjtCopySkinWeights by Sveinbjorn J. Tryggvason <sjt@sjt.is>
#
# Change history:
# ---------------
# 24-Aug-2013 : version 1.0
# 26-Aug-2013 : setting the limits instead of recomputing the skin to these limits

import maya.cmds as cmds
import maya.mel as mel

def registerDragImportAllFbx():
	global dragImportAllFbxJob
	#Now we start listening for the trigger "readingFile" (such as importing files) and trigger the "processImport" function
	dragImportAllFbxJob = cmds.scriptJob(ct=["readingFile", processImport])

def unregisterDragImportAllFbx():
	global dragImportAllFbxJob
	if (dragImportAllFbxJob != None):
		cmds.scriptJob(kill=dragImportAllFbxJob)
		dragImportAllFbxJob = None

def processImport():
	#We call on the function which limits every mesh's skin cluster to 4 influences
	setMaintainMaxInfluences()

def setMaintainMaxInfluences():
	meshes = cmds.ls(type='mesh')
	for mesh in meshes:
		skinName = mel.eval('findRelatedSkinCluster ' + mesh)
		if (len(skinName) > 0):
			cmds.setAttr(skinName + ".maintainMaxInfluences", 1)
			cmds.setAttr(skinName + ".maxInfluences", 4)
			print mesh + "'s skin " + skinName + " obeys to a maximum of 4 influences now."

def initializePlugin(mobject):
	registerDragImportAllFbx()

def uninitializePlugin(mobject):
	unregisterDragImportAllFbx()
