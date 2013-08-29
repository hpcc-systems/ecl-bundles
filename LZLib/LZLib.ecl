EXPORT LZLib := MODULE,FORWARD
  IMPORT Std;
  EXPORT Bundle := MODULE(Std.BundleBase)
    EXPORT Name := 'LZLib';
    EXPORT Description := 'Routines for performing Landing-Zone level file operations.';
    EXPORT Authors := ['Edin Muharamagic','Jo Prichard','David Wheelock'];
    EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
    EXPORT Copyright := 'Copyright (C) 2013 HPCC Systems';
    EXPORT DependsOn := [];
    EXPORT Version := '1.0.0';
  END;
  
  SHARED sDefaultPath:='/var/lib/HPCCSystems/mydropzone/';

  //-------------------------------------------------------------------------
  // Pull a file from the web into the specified location
  //-------------------------------------------------------------------------
  EXPORT GetRemoteFile(STRING sURL,STRING sLocalPath=sDefaultPath):=PIPE('wget '+sURL+' -P '+sLocalPath,{STRING s;},CSV);
  
  //-------------------------------------------------------------------------
  // Get a listing of the files in the specified path
  //-------------------------------------------------------------------------
  EXPORT FileList(STRING sPath=sDefaultPath):=PIPE('ls -1 '+sPath,{STRING s;},CSV);
  
  //-------------------------------------------------------------------------
  // Pull in the top rows from the text file to be viewed as a single-string
  // dataset.  Uses pipe ('|') as a place-holder delimiter so that the string
  // is not broken up by the necessary CSV clause in PIPE command.
  //-------------------------------------------------------------------------
  EXPORT TopRows(STRING sFileName,STRING sPath=sDefaultPath,UNSIGNED4 iRowCount=100):=FUNCTION
    RETURN PROJECT(PIPE('bash -c "head -'+(STRING)iRowCount+' '+sPath+sFilename+' | sed \'s/,/|/g\'"',{STRING s;},csv),TRANSFORM(RECORDOF(LEFT),SELF.s:=REGEXREPLACE('[|]',LEFT.s,',');));
  END;
  
  //-------------------------------------------------------------------------
  // Get a count of the number of rows in the CSV file specified
  //-------------------------------------------------------------------------
  EXPORT RowCountVariable(STRING sFileName,STRING sPath=sDefaultPath):=(UNSIGNED)PIPE('bash -c "cat '+sPath+sFilename+' | wc -l"',{STRING s;},CSV)[1].s;
  
  //-------------------------------------------------------------------------
  // Get a count of the number of columns in the CSV file specified
  //-------------------------------------------------------------------------
  EXPORT ColumnCountVariable(STRING sFilename,STRING sPath=sDefaultPath,sDelimiter=','):=(UNSIGNED)PIPE('bash -c "head -1 '+sPath+sFilename+' | sed \'s/[^,]//g\' | wc -c"',{STRING s;},CSV)[1].s;
  //NB: Still need to account for delimiters within quotes.

  //-------------------------------------------------------------------------
  // Get a listing of the files in the specified zip file
  //-------------------------------------------------------------------------
  EXPORT ZipFileList(STRING sFilename,STRING sPath=sDefaultPath):=TABLE(PIPE('gzip -l '+sFullPath+IF(REGEXFIND('.zip$',sPath+sFilename),' -S .zip',''),{STRING s;},CSV),{STRING filename:=REGEXFIND('([^\\/]+)$',s,1);})[2..];
  
  //-------------------------------------------------------------------------
  // Decompress the specified zip file
  //-------------------------------------------------------------------------
  EXPORT UnzipFile(STRING sFilename,STRING sPath=sDefaultPath,BOOLEAN bKeepCompressed=TRUE):=FUNCTION
    sZipType:=REGEXFIND('[^.]+$',sFilename,1);
    sZipProg:=MAP(
      sZipType IN ['bz2','ba','tbz2','tbz'] => 'bzip2 -d ',
      sZipType='zip' => 'gzip -S .zip -d ',
      'gzip -d '
    );
    RETURN SEQUENTIAL(
      IF(bKeepCompressed,OUTPUT(PIPE('cp '+sPath+sFilename+' '+sPath+sFilename+'.tmp',{STRING s;},CSV)),OUTPUT('No File Movement necessary')),
      OUTPUT(PIPE(sZipProg+sFullPath,{STRING s;},CSV)),
      IF(bKeepCompressed,OUTPUT(PIPE('mv '+sPath+sFilename+'.tmp '+sPath+sFilename,{STRING s;},CSV)),OUTPUT('No File Movement necessary'))
    );
  END;

  //-------------------------------------------------------------------------
  // Decompress the specified zip file, spray it, and if requested remove
  // the decompressed version of the file
  //-------------------------------------------------------------------------
  EXPORT UnzipAndSprayVariable(
    STRING sIP,
    STRING sFullPath,
    UNSIGNED maxrecordsize=4096,
    STRING srcCSVseparator=',',
    STRING srcCSVterminator='\n,\r\n',
    STRING srcCSVquote='"',
    STRING destinationgroup,
    STRING destinationlogicalname='',
    UNSIGNED timout=-1,
    STRING espserverIPport='',
    UNSIGNED maxConnections=1,
    BOOLEAN allowoverwrite=FALSE,
    BOOLEAN replicate=FALSE,
    BOOLEAN compress=FALSE,
    STRING sourceCsvEscape='',
    BOOLEAN removewhendone=FALSE
  ):=FUNCTION
    sPath:=REGEXREPLACE('[^\\/]+$',sFullPath,'');
    sUnzippedFile:=ZipFileList(sFullPath)[1].filename;
    sNewFile:=IF(destinationlogicalname='',sUnzippedFile,destinationlogicalname);
    sFileToSpray:=sPath+sUnzippedFile;
    RETURN SEQUENTIAL(
      UnzipFile(sFullPath),
      std.File.SprayVariable(sIP,sFileToSpray,maxrecordsize,srcCSVseparator,srcCSVterminator,srcCSVquote,destinationgroup,sNewFile,timout,,maxConnections,allowoverwrite,replicate,compress,sourceCsvEscape),
      IF(removewhendone,STD.File.DeleteExternalFile(sIP,sFileToSpray),OUTPUT('File '+sUnzippedFile+' was not removed'))
    );
  END;
  
/*
  Functions in development and considered for future expansion

  GetFromDropbox() // Requires username and password interaction
  PutToDropbox()
  RowCountXML()
  CoumnCountXML()
  UnzipAndSprayXML()
  DesprayAndZip()
  SprayVariableSelective() // For spraying only certain columns from the LZ file
  AnalyzeVariable() // AMBITIOUS: get metrics from the LZ file (e.g. min/max line size, min/max size per column, column shape/content information, etc.)
  AnalyzeXML()
  SuggestedLayoutXML()
  SuggestedLayoutVariable()
  ** Need to add support for zip files with multiple members (use unzip instead of gunzip) and enable progressive file extraction, spray, deletion
*/
END;


/*
  EXAMPLES

  LZLib.UnzipFile('test2.gz');
  LZLib.UnzipFile('test.zip','/var/lib/HPCCSystems/someotherdropzone/');
  LZLib.UnzipAndSpray('192.168.6.130','/var/lib/HPCCSystems/mydropzone/test.zip',,,,,'mythor','test',,,,TRUE,,TRUE,,TRUE);
  LZLib.UnzipAndSpray('192.168.6.130','/var/lib/HPCCSystems/mydropzone/test.zip',,,,,'mythor',,,,,TRUE,,TRUE);
  LZLib.UnzipAndSpray('192.168.6.130','/var/lib/HPCCSystems/mydropzone/test.gz',,,,,'mythor','test',,,,TRUE,,TRUE,,TRUE);
  LZLib.ZipFileList('test.zip');
  LZLib.FileList();
  LZLib.TopRows('test.txt',,20);

*/