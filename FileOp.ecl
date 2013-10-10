EXPORT FileOp := MODULE
	IMPORT STD;
	
	EXPORT Bundle := MODULE(Std.BundleBase)
		EXPORT Name 			:= 'FileOp';
		EXPORT Description 		:= 'Abstracting Common Super File Operations';
		EXPORT Authors 			:= ['Omnibuzz'];
		EXPORT License 			:= 'http://www.apache.org/licenses/LICENSE-2.0';
		EXPORT Copyright 		:= 'Use, Improve, Extend, Distribute';
		EXPORT DependsOn 		:= [];
		EXPORT Version 			:= '1.0.0';
	END; 

	SHARED STRING Scope					:= '_FileOpInternal::';
	SHARED STRING PrevVersion		:= scope + 'Previous';
	SHARED STRING Edits		 			:= scope + 'Edits::';

	SHARED STRING GetNextPartName(STRING FileName)	:= FUNCTION
		RETURN FileName + Edits + 'Part_' + (STRING)(STD.File.GetSuperFileSubCount(FileName) + 1);
	END;
	
	SHARED STRING GetFileNameForPrevVersion(STRING FileName)	:= FUNCTION
		RETURN FileName + Edits + 'Part_Prev';
	END;
	
	SHARED STRING GetFileNameForCurrentVersion(STRING FileName)	:= FUNCTION
		RETURN FileName + Edits + 'Part_1';
	END;
	
	SHARED BOOLEAN CopyFile(STRING Source,STRING Destination, BOOLEAN IsShallowCopy) := FUNCTION
		Act 								:= STD.File.Copy(Source,'',Destination,,-1,,,TRUE,,IsShallowCopy);
		RETURN WHEN(TRUE,Act);
	END;
	
	SHARED BOOLEAN PopLastAppend(STRING FileName) := FUNCTION
		Act									:= SEQUENTIAL(STD.File.RemoveSuperFile(fileName,FileName + Edits + 'Part_' + (STRING)(STD.File.GetSuperFileSubCount(FileName)),TRUE),
																			STD.File.RemoveSuperFile(fileName + PrevVersion,FileName + Edits + 'Part_' + (STRING)(STD.File.GetSuperFileSubCount(FileName + PrevVersion)),FALSE));
		RETURN WHEN(TRUE,Act);
	END;
			
	SHARED AppendFilePart(DATASET ds,STRING FileName) := FUNCTION 
		PartName						:= GetNextPartName(FileName);
		Act 								:= SEQUENTIAL(OUTPUT(ds,,PartName,OVERWRITE), 				// Create Logical File
																			 STD.File.ClearSuperFile(FileName + PrevVersion),
																			 CopyFile(FileName,FileName + PrevVersion,TRUE),
																			 STD.File.DeleteLogicalFile(GetFileNameForPrevVersion(FileName)),
																			 STD.File.AddSuperFile(FileName,PartName));
		RETURN WHEN(TRUE,Act);
	END;
	
	EXPORT BOOLEAN CreateFile(DATASET ds,STRING FileName) := FUNCTION
		Act 								:= IF(Std.File.FileExists(FileName),
																										FAIL('File ' + FileName + ' already exists. Use a different filename or use OverWriteFile'),
																										SEQUENTIAL(Std.File.CreateSuperFile(FileName), 
																															 Std.File.CreateSuperFile(FileName + PrevVersion), 
																															 AppendFilePart(ds,FileName)));
		RETURN WHEN(TRUE,Act);
	END;
	
	EXPORT BOOLEAN AppendToFile(DATASET ds,STRING FileName) := FUNCTION
		Act 								:= 	SEQUENTIAL(Std.File.CreateSuperFile(FileName,FALSE,TRUE), 
																			 Std.File.CreateSuperFile(FileName + PrevVersion,FALSE,TRUE),
																			 AppendFilePart(ds,FileName));
		RETURN WHEN(TRUE,Act);
	END;
	
	
	EXPORT BOOLEAN OverWriteFile(DATASET ds, STRING FileName) := FUNCTION
		Act 								:= 	SEQUENTIAL(Std.File.CreateSuperFile(FileName,FALSE,TRUE), 
																			 Std.File.CreateSuperFile(FileName + PrevVersion,FALSE,TRUE),
																			 IF(STD.File.GetSuperFileSubCount(FileName) = 1,
																					 SEQUENTIAL(STD.File.Clearsuperfile(FileName),
																											STD.File.Clearsuperfile(FileName + PrevVersion,TRUE),
																											STD.File.RenameLogicalFile(GetFileNameForCurrentVersion(FileName), GetFileNameForPrevVersion(FileName))),
																					 SEQUENTIAL(STD.File.ClearSuperfile(FileName + PrevVersion),
																											IF(STD.File.GetSuperFileSubCount(FileName) > 0
																												,CopyFile(FileName,GetFileNameForPrevVersion(FileName),FALSE)
																												,CopyFile(FileName,GetFileNameForPrevVersion(FileName),TRUE)),
																											STD.File.ClearSuperfile(FileName,TRUE))),
																			OUTPUT(ds,,GetFileNameForCurrentVersion(FileName),OVERWRITE),
																			STD.File.AddSuperFile(FileName,GetFileNameForCurrentVersion(FileName)),
																			IF(STD.File.FileExists(GetFileNameForPrevVersion(FileName)),STD.File.AddSuperFile(FileName + PrevVersion,GetFileNameForPrevVersion(FileName))));
		RETURN WHEN(TRUE,Act);
	END;
	
	EXPORT BOOLEAN DeleteFile(STRING FileName) := FUNCTION
		Act									:= PARALLEL(STD.File.DeleteSuperFile(FileName + PrevVersion),
																		STD.File.DeleteSuperFile(FileName,TRUE),
																		STD.File.DeleteLogicalFile(GetFileNameForPrevVersion(FileName)));

	RETURN WHEN(TRUE,Act);
	END;
	
	EXPORT BOOLEAN DefragmentFile(STRING FileName) := FUNCTION
		IsDefragmentNecessary 			:= Std.File.FileExists(FileName) AND Std.File.FileExists(FileName + PrevVersion) AND STD.File.GetSuperFileSubCount(FileName + PrevVersion) > 1;
		LatestFileName 							:= FileName + Edits + 'Part_' + (STRING)(STD.File.GetSuperFileSubCount(FileName)):INDEPENDENT;
		LatestFileName_New					:= FileName + Edits + 'Part_2';
		DefragmentedFileName_Temp 	:= FileName + Edits + 'Part_Temp';
		DefragmentedFileName_New		:= GetFileNameForCurrentVersion(FileName);
		
		Act													:= IF(IsDefragmentNecessary,SEQUENTIAL(LatestFileName,
																																			 Std.File.ClearSuperFile(FileName),
																																			 CopyFile(FileName + PrevVersion,DefragmentedFileName_Temp,FALSE),
																																			 Std.File.ClearSuperFile(FileName + PrevVersion,TRUE),
																																			 STD.File.RenameLogicalFile(LatestFileName, LatestFileName_New),
																																			 STD.File.RenameLogicalFile(DefragmentedFileName_Temp, DefragmentedFileName_New),
																																			 STD.File.AddSuperFile(FileName,DefragmentedFileName_New),
																																			 STD.File.AddSuperFile(FileName,LatestFileName_New),
																																			 STD.File.AddSuperFile(FileName + PrevVersion,DefragmentedFileName_New)));
																																			 
		RETURN WHEN(TRUE,Act);																																	
		
	END;

	EXPORT BOOLEAN UndoLast(STRING FileName) := FUNCTION
			UndoCountPossible					:= STD.File.GetSuperFileSubCount(FileName + PrevVersion) : INDEPENDENT;
			CanUndo 									:= Std.File.FileExists(FileName) AND Std.File.FileExists(FileName + PrevVersion) AND UndoCountPossible > 0 : INDEPENDENT;
			IsOverWrittenFile					:= STD.File.FileExists(GetFileNameForPrevVersion(FileName)) AND UndoCountPossible = 1 : INDEPENDENT;
			
			Act												:= IF(CanUndo,
																							IF(IsOverwrittenFile, //Tough luck you got just one undo
																								 SEQUENTIAL(Std.File.ClearSuperFile(FileName,TRUE),
																														Std.File.ClearSuperFile(FileName + PrevVersion),
																														STD.File.RenameLogicalFile(GetFileNameForPrevVersion(FileName),GetFileNameForCurrentVersion(FileName))),
																								 SEQUENTIAL(PopLastAppend(FileName))),
																							FAIL('No previous versions available for the file '+ FileName + '. Please delete the file if not required'));
			RETURN WHEN(TRUE,Act);			
	END;
END;
