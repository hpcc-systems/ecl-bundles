EXPORT QueueOp := MODULE
  IMPORT STD;
  
  EXPORT Bundle := MODULE(Std.BundleBase)
    EXPORT Name          := 'QueueOp';
    EXPORT Description   := 'Queue Implementation - Multiple Writers single reader';
    EXPORT Authors       := ['Omnibuzz'];
    EXPORT License       := 'http://www.apache.org/licenses/LICENSE-2.0';
    EXPORT Copyright     := 'Use, Improve, Extend, Distribute';
    EXPORT DependsOn     := [];
    EXPORT Version       := '0.0.1';
  END; 
    
  SHARED Get(STRING QueueName) := MODULE
    SHARED STRING Scope                 := '::';
    EXPORT STRING MutexLockFile         := QueueName + Scope + 'Mutex';
    // Every new Item added will be done with this prefix
    EXPORT STRING Items_Prefix          := QueueName + scope + 'items::';
    EXPORT STRING Dequeued_Items_Prefix := QueueName + scope + 'dequeue::';
    
    SHARED StartMS   := STD.System.Debug.msTick() : STORED('StartMS');
    
    SHARED STRING14 getNow() := BEGINC++
      #OPTION action
      struct tm ltz;                                    // local timezone in "tm" structure
      time_t timeinsecs;                                // variable to store time in secs
      time(&timeinsecs);                                // Get time in sec since Epoch
      localtime_r(&timeinsecs,&ltz);                    // Convert to UTC time
      strftime(__result, 20, "%Y%m%d%H%M%S", &ltz);     // Formats yyyymmddhhmiss
    ENDC++;
    
    EXPORT NextQueueItemName   := FUNCTION
      Sleep1ms  := STD.System.Debug.Sleep(1);
      ItemName  := DATASET([{Items_Prefix + getNow() + INTFORMAT(((STD.System.Debug.msTick() - StartMS)%1000),3,1)}],{STRING Name});
      RETURN WHEN(ItemName,Sleep1ms, BEFORE);
    END;

    EXPORT BOOLEAN IsLocked       := Std.File.FileExists(MutexLockFile);
    
    EXPORT BOOLEAN LockQueue      := FUNCTION
      Act       := IF(IsLocked,
                      FAIL('Cannot Obtain lock. The Queue is already locked by another process. Please try after a while'),
                      OUTPUT(DATASET([{'1'}],{STRING1 a}),,MutexLockFile,THOR));
      RETURN WHEN(TRUE,Act);
    END;
    
    EXPORT BOOLEAN UnlockQueue    := FUNCTION
      Act       := STD.File.DeleteLogicalFile(MutexLockFile);
      RETURN WHEN(TRUE,Act);
    END;
    
    SHARED QueueItemsRec := {STRING Name};
    
    EXPORT DATASET(QueueItemsRec) QueueItems := FUNCTION
      RETURN NOTHOR(PROJECT(STD.File.LogicalFileList('*' + Std.Str.FilterOut(Items_Prefix,'~') + '*'),TRANSFORM(QueueItemsRec,SELF:= LEFT)));
    END;
    
    EXPORT INTEGER4 ItemsCount  := COUNT(QueueItems);
    
    EXPORT BOOLEAN AddToQueue(DATASET ds) := FUNCTION
      FileName          := NextQueueItemName[1].Name;
      WriteToFile       := OUTPUT(ds,,FileName);
      RETURN WHEN(TRUE,WriteToFile);
    END;
    
    // This function builds a temporary super file with all the queue items
    EXPORT STRING BuildTempSF := FUNCTION
      ItemsList                   := QueueItems;
      
      Rec                         := { STRING SF{MAXLENGTH(10000)};};
      Rec t1(ItemsList l, Rec r)  := TRANSFORM 
        SELF.SF := r.SF + ',' + l.Name; 
      END; 
      outVal                      := AGGREGATE(ItemsList,Rec,t1(LEFT,RIGHT)); 
      RETURN '~{' + outVal[1].SF[2..] + '}';
    END;

  END;

  EXPORT BOOLEAN Enqueue(DATASET ds, STRING QueueName) := FUNCTION
    Act           := Get(QueueName).AddToQueue(ds);
    RETURN Act;
  END;
  
  EXPORT STRING Peek(STRING QueueName) := FUNCTION
    RETURN SORT(Get(QueueName).QueueItems,Name)[1].Name;
  END;
  
  EXPORT STRING Dequeue(STRING QueueName,STRING LocationPrefix = Get(QueueName).Dequeued_Items_Prefix) := FUNCTION
    DequeueItem  := '~' + STD.Str.ToLowerCase(Peek(QueueName));
    FileName     := STD.Str.FindReplace(DequeueItem,STD.Str.ToLowerCase(Get(QueueName).Items_Prefix),STD.Str.ToLowerCase(LocationPrefix));
    Act          := IF(DequeueItem = '',
                          STD.System.Log.addWorkunitWarning('No items in queue ' + QueueName + ' to dequeue.'),
                          SEQUENTIAL(Get(QueueName).LockQueue,
                                      STD.File.RenameLogicalFile(DequeueItem,FileName),
                                      Get(QueueName).UnlockQueue));  
    RETURN WHEN(FileName,Act);
  END;
  
  EXPORT UNSIGNED4 QueueLength(STRING QueueName) := FUNCTION
    RETURN Get(QueueName).ItemsCount;
  END;
  
  EXPORT BOOLEAN ClearQueue(STRING QueueName, BOOLEAN Force = FALSE) := FUNCTION
    ClearLock    := IF(Force,Get(QueueName).UnlockQueue,TRUE);
    QueueItemsSF := Get(QueueName).BuildTempSF : INDEPENDENT;
    Act          := SEQUENTIAL(ClearLock,
                                IF(Get(QueueName).IsLocked,
                                    FAIL('Queue ' + QueueName + ' is locked. Cannot clear the queue.'),
                                    IF(NOT(QueueItemsSF = '~{}'),
                                        SEQUENTIAL(Get(QueueName).LockQueue,
                                                   NOTHOR(STD.File.ClearSuperFile(QueueItemsSF,TRUE)),
                                                   Get(QueueName).UnlockQueue)
                                      )
                                  )
                              );
   RETURN WHEN(NOT Get(QueueName).IsLocked,Act); 
  END;
    
  EXPORT STRING DequeueAll(STRING QueueName,STRING LocationPrefix = Get(QueueName).Dequeued_Items_Prefix) := FUNCTION
    QueueItemsSF := Get(QueueName).BuildTempSF : INDEPENDENT;
    DequeueItem  := STD.Str.ToLowerCase(Get(QueueName).NextQueueItemName[1].Name) : INDEPENDENT;
    FileName     := STD.Str.FindReplace(DequeueItem,STD.Str.ToLowerCase(Get(QueueName).Items_Prefix),STD.Str.ToLowerCase(LocationPrefix));
    Act          := IF(QueueItemsSF = '~{}',
                          STD.System.Log.addWorkunitWarning('No items in queue ' + QueueName + ' to dequeue.'),
                          SEQUENTIAL(Get(QueueName).LockQueue,
                                     NOTHOR(STD.file.Copy(QueueItemsSF,'',FileName,,-1,,,TRUE,,FALSE)),
                                     NOTHOR(STD.File.ClearSuperFile(QueueItemsSF,TRUE)),
                                     Get(QueueName).UnlockQueue));  
    RETURN WHEN(FileName,Act);
  END;
END;
