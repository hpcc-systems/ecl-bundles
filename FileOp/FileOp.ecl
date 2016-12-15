EXPORT FileOp := MODULE
  IMPORT STD;
  
  EXPORT Bundle := MODULE(Std.BundleBase)
    EXPORT Name       := 'FileOp';
    EXPORT Description     := 'Abstracting Common Super File Operations. Files are written in THOR/FLAT format';
    EXPORT Authors       := ['Omnibuzz'];
    EXPORT License       := 'http://www.apache.org/licenses/LICENSE-2.0';
    EXPORT Copyright     := 'Use, Improve, Extend, Distribute';
    EXPORT DependsOn     := [];
    EXPORT Version       := '1.0.1';
  END; 
  
  SHARED Get(STRING FileName) := MODULE
    SHARED STRING Scope            := '_FileOpInternal::';
    
    // Super file holding all the subfiles of the current version. This holds the data as seen by the user
    EXPORT STRING CurrentSF       := FileName;
    
    // Super file holding all the subfiles of the previous version. This is the file that will be used for undo
    EXPORT STRING PreviousSF      := FileName + Scope + 'Previous';
    
    // Every new edit added will be done with this prefix
    EXPORT STRING Edits_Prefix    := FileName + scope + 'Edits::';
    
    // Every new snapshot created will be done using this prefix
    EXPORT STRING Snapshot_Prefix := FileName + scope + 'Snapshot::';
    
    // Super file to track all the snapshots created for the file
    EXPORT STRING SnapshotTrackSF := Snapshot_Prefix + 'Track';

    SHARED INTEGER4 GetFileFragments(STRING SuperFile) := FUNCTION
      RETURN IF(Std.File.FileExists(SuperFile),STD.File.GetSuperFileSubCount(SuperFile),0);
    END;
    
    EXPORT INTEGER4 CurrentSF_FragmentCount := GetFileFragments(CurrentSF);
    
    EXPORT INTEGER4 PreviousSF_FragmentCount := GetFileFragments(PreviousSF);
    
    EXPORT INTEGER4 SnapshotsCount := GetFileFragments(SnapshotTrackSF);
    
    // Checks if the file is safe for defragment or undo or over write. We do not allow that when there are snapshots created
    EXPORT BOOLEAN IsFileSafe := FUNCTION
      RETURN IF(SnapshotsCount = 0,TRUE,FALSE);
    END;
        
    EXPORT STRING NextPartName  := FUNCTION
      RETURN Edits_Prefix + 'Part_' + (STRING)(STD.File.GetSuperFileSubCount(CurrentSF) + 1);
    END;
    
    EXPORT STRING LatestPartName := FUNCTION
      RETURN Edits_Prefix + 'Part_' + (STRING)(STD.File.GetSuperFileSubCount(CurrentSF));
    END;
    
    // Overwrites does not fall under the parts naming convention. It is needed for allowing append and over writes on the same file over and over. 
    EXPORT STRING ForPrevVersion_OverWrite  := FUNCTION
      RETURN Edits_Prefix + 'Part_Prev';
    END;
    
    EXPORT STRING ForCurrentVersion_OverWrite  := FUNCTION
      RETURN Edits_Prefix + 'Part_1';
    END;
    
    EXPORT CreateCurrentSF := Std.File.CreateSuperFile(CurrentSF,FALSE,TRUE);
    
    EXPORT CreatePreviousSF:= Std.File.CreateSuperFile(PreviousSF,FALSE,TRUE);
    
    EXPORT CreateSnapshotSF:= Std.File.CreateSuperFile(SnapshotTrackSF,FALSE,TRUE);
    
    EXPORT CreateSFs :=     PARALLEL(CreateCurrentSF, CreatePreviousSF, CreateSnapshotSF);
  END;
  
  SHARED BOOLEAN CopyFile(STRING Source,STRING Destination, BOOLEAN IsShallowCopy) := FUNCTION
    Act                 := STD.File.Copy(Source,'',Destination,,-1,,,TRUE,,IsShallowCopy);
    RETURN WHEN(TRUE,Act);
  END;
  
  //Give the user File Name as input
  SHARED BOOLEAN PopLastAppend(STRING FileName) := FUNCTION
    Act                  := SEQUENTIAL(STD.File.RemoveSuperFile(Get(fileName).CurrentSF,Get(FileName).Edits_Prefix + 'Part_' + (STRING)(STD.File.GetSuperFileSubCount(Get(fileName).CurrentSF)),TRUE),
                                      STD.File.RemoveSuperFile(Get(FileName).PreviousSF,Get(FileName).Edits_Prefix + 'Part_' + (STRING)(STD.File.GetSuperFileSubCount(Get(fileName).PreviousSF)),FALSE));
    RETURN WHEN(TRUE,NOTHOR(Act));
  END;
  
  //Give the user File Name as input
  SHARED AppendFilePart(DATASET ds,STRING FileName) := FUNCTION 
    PartName            := Get(FileName).NextPartName;
    CreateLogicalFile   := OUTPUT(ds,,PartName,OVERWRITE);
    AppendFileToSF      := SEQUENTIAL(STD.File.ClearSuperFile(Get(FileName).PreviousSF),
                                       CopyFile(Get(FileName).CurrentSF,Get(FileName).PreviousSF,TRUE),
                                       STD.File.DeleteLogicalFile(Get(FileName).ForPrevVersion_OverWrite),
                                       STD.File.AddSuperFile(Get(FileName).CurrentSF,PartName));
    Act                 := SEQUENTIAL(CreateLogicalFile,
                                      NOTHOR(AppendFileToSF));
    RETURN WHEN(TRUE,Act);
  END;
  
  EXPORT BOOLEAN CreateFile(DATASET ds,STRING FileName) := FUNCTION
    Act                 := IF(Std.File.FileExists(Get(FileName).CurrentSF),
                                                    FAIL('File ' + FileName + ' already exists. Use a different filename or use OverWriteFile'),
                                                    SEQUENTIAL(NOTHOR(Get(FileName).CreateSFs), 
                                                               AppendFilePart(ds,FileName)));
    RETURN WHEN(TRUE,Act);
  END;
  
  EXPORT BOOLEAN AppendToFile(DATASET ds,STRING FileName) := FUNCTION
    Act                 :=   SEQUENTIAL(NOTHOR(Get(FileName).CreateSFs),
                                       AppendFilePart(ds,FileName));
    RETURN WHEN(TRUE,Act);
  END;
  
  EXPORT BOOLEAN OverWriteFile(DATASET ds, STRING FileName) := FUNCTION
    MoveCurFileToPrev   := IF(STD.File.GetSuperFileSubCount(Get(FileName).CurrentSF) = 1, // This whole condition is checked to avoid file re-write by renaming
                                             SEQUENTIAL(STD.File.Clearsuperfile(Get(FileName).CurrentSF),
                                                        STD.File.Clearsuperfile(Get(FileName).PreviousSF,TRUE),
                                                        STD.File.RenameLogicalFile(Get(FileName).ForCurrentVersion_OverWrite, Get(FileName).ForPrevVersion_Overwrite)),
                                             SEQUENTIAL(STD.File.ClearSuperfile(Get(FileName).PreviousSF),
                                                        IF(STD.File.GetSuperFileSubCount(Get(FileName).CurrentSF) > 0
                                                          ,CopyFile(Get(FileName).CurrentSF,Get(FileName).ForPrevVersion_Overwrite,FALSE)
                                                          ,CopyFile(Get(FileName).CurrentSF,Get(FileName).ForPrevVersion_Overwrite,TRUE)),
                                                        STD.File.ClearSuperfile(Get(FileName).CurrentSF,TRUE)));
                                                        
    AssociateToSFs      := SEQUENTIAL(STD.File.AddSuperFile(Get(FileName).CurrentSF,Get(FileName).ForCurrentVersion_Overwrite),
                                      IF(STD.File.FileExists(Get(FileName).ForPrevVersion_Overwrite),
                                         STD.File.AddSuperFile(Get(FileName).PreviousSF,Get(FileName).ForPrevVersion_Overwrite)));
                                         
    Act                 :=   IF(Get(FileName).IsFileSafe,
                               SEQUENTIAL(NOTHOR(Get(FileName).CreateSFs),
                                         NOTHOR(MoveCurFileToPrev),
                                        OUTPUT(ds,,Get(FileName).ForCurrentVersion_Overwrite,OVERWRITE),
                                        AssociateToSFs),
                                FAIL('Cannot overwrite File '+ FileName + '. There are snapshots created on the file. Please delete the snapshots first'));
    RETURN WHEN(TRUE,Act);
  END;
    
  EXPORT BOOLEAN DeleteAllSnapshots(STRING FileName) := FUNCTION
    Act                  := SEQUENTIAL(Get(FileName).CreateSnapshotSF, STD.File.ClearSuperFile(Get(FileName).SnapshotTrackSF,TRUE));
    RETURN WHEN(TRUE,NOTHOR(Act));
  END;
  
  EXPORT BOOLEAN DeleteFile(STRING FileName) := FUNCTION
    Act                  := SEQUENTIAL(STD.File.DeleteSuperFile(Get(FileName).SnapshotTrackSF,TRUE),
                                      STD.File.DeleteSuperFile(Get(FileName).PreviousSF),
                                      STD.File.DeleteSuperFile(Get(FileName).CurrentSF,TRUE),
                                      STD.File.DeleteLogicalFile(Get(FileName).ForPrevVersion_Overwrite));
    RETURN WHEN(TRUE,NOTHOR(Act));
  END;
  
  EXPORT BOOLEAN DefragmentFile(STRING FileName) := FUNCTION
    IsDefragmentNecessary       := Std.File.FileExists(Get(FileName).CurrentSF) AND 
                                   Std.File.FileExists(Get(FileName).PreviousSF) AND 
                                   STD.File.GetSuperFileSubCount(Get(FileName).PreviousSF) > 1;
    LatestFileName               := Get(FileName).LatestPartName :INDEPENDENT;
    LatestFileName_New          := Get(FileName).Edits_Prefix + 'Part_2';
    DefragmentedFileName_Temp   := Get(FileName).Edits_Prefix + 'Part_Temp';
    DefragmentedFileName_New    := Get(FileName).ForCurrentVersion_OverWrite;
    
    Act                          := IF(Get(FileName).IsFileSafe,
                                      IF(IsDefragmentNecessary,
                                        SEQUENTIAL(LatestFileName,
                                                   Std.File.ClearSuperFile(Get(FileName).CurrentSF),
                                                   CopyFile(Get(FileName).PreviousSF,DefragmentedFileName_Temp,FALSE),
                                                   Std.File.ClearSuperFile(Get(FileName).PreviousSF,TRUE),
                                                   STD.File.RenameLogicalFile(LatestFileName, LatestFileName_New),
                                                   STD.File.RenameLogicalFile(DefragmentedFileName_Temp, DefragmentedFileName_New),
                                                   STD.File.AddSuperFile(Get(FileName).CurrentSF,DefragmentedFileName_New),
                                                   STD.File.AddSuperFile(Get(FileName).CurrentSF,LatestFileName_New),
                                                   STD.File.AddSuperFile(Get(FileName).PreviousSF,DefragmentedFileName_New))),
                                      STD.System.Log.addWorkunitWarning('Cannot defragment File '+ FileName + '. There are snapshots created on the file. Please delete the snapshots first'));
                                                                       
    RETURN WHEN(Get(FileName).IsFileSafe,NOTHOR(Act));                                                                  
    
  END;

  EXPORT BOOLEAN UndoLast(STRING FileName) := FUNCTION
      PossibleUndoCount          := STD.File.GetSuperFileSubCount(Get(FileName).PreviousSF) : INDEPENDENT;
      CanUndo                   := Std.File.FileExists(Get(FileName).CurrentSF) AND Std.File.FileExists(Get(FileName).PreviousSF) AND PossibleUndoCount > 0 : INDEPENDENT;
      IsOverWrittenFile          := STD.File.FileExists(Get(FileName).ForPrevVersion_Overwrite) AND PossibleUndoCount = 1 : INDEPENDENT;
      
      Act                        := IF(Get(FileName).IsFileSafe,
                                      IF(CanUndo,
                                          IF(IsOverwrittenFile, //Tough luck you got just one undo
                                             SEQUENTIAL(Std.File.ClearSuperFile(Get(FileName).CurrentSF,TRUE),
                                                        Std.File.ClearSuperFile(Get(FileName).PreviousSF),
                                                        STD.File.RenameLogicalFile(Get(FileName).ForPrevVersion_Overwrite,Get(FileName).ForCurrentVersion_Overwrite)),
                                             SEQUENTIAL(PopLastAppend(FileName))),
                                          STD.System.Log.addWorkunitWarning('No previous versions available for the file '+ FileName + '. Please delete the file if not required')),
                                      STD.System.Log.addWorkunitWarning('Cannot Undo File '+ FileName + '. There are snapshots created on the file. Please delete the snapshots first'));
      RETURN WHEN(Get(FileName).IsFileSafe AND CanUndo,NOTHOR(Act));      
  END;
  
  EXPORT BOOLEAN DeleteSnapshot(STRING FileName, STRING SnapshotName) := FUNCTION
    Act                         := SEQUENTIAL(Get(FileName).CreateSnapshotSF, STD.File.RemoveSuperFile(Get(FileName).SnapshotTrackSF,SnapshotName,TRUE));
    RETURN WHEN(TRUE,NOTHOR(Act));
  END;
  
  EXPORT STRING CreateSnapshot(STRING FileName,STRING SnapshotName = Get(FileName).Snapshot_Prefix + WORKUNIT,BOOLEAN OverWrite = FALSE) := FUNCTION
    Act                         := IF(Std.File.FileExists(SnapshotName) AND NOT OverWrite, 
                                        FAIL('Snapshot ' + SnapshotName + ' already exists. Use a diffent name or Set OverWrite to TRUE'), 
                                        SEQUENTIAL(Get(FileName).CreateSnapshotSF,
                                                   DeleteSnapshot(FileName,SnapshotName),
                                                   CopyFile(Get(FileName).CurrentSF,SnapshotName,TRUE),
                                                   STD.File.SetFileDescription(SnapShotName,'Snapshot of:' + FileName + ' WU:' + WORKUNIT),
                                                   STD.File.AddSuperFile(Get(FileName).SnapshotTrackSF,SnapShotName)));
    RETURN WHEN(SnapshotName,NOTHOR(Act));
  END;

  EXPORT INTEGER4 GetFileFragments(STRING FileName) := Get(FileName).CurrentSF_FragmentCount;
  
  EXPORT BOOLEAN IsFileSafe(STRING FileName) := Get(FileName).IsFileSafe;
  
  EXPORT DATASET({STRING Name}) GetSnapshots(STRING FileName) := STD.File.SuperFileContents(Get(FileName).SnapshotTrackSF);
END;
