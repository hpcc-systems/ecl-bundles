EXPORT CloudTools := MODULE,FORWARD
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
  
/**
* Bundle for handling ssh-related functionality at the file-system level,
* including pulling files from remote Internet locations, compressing and
* decompressing files, and performing rudimentary file shape analysis.
*
* These functions should be called from hthor, and assumes that the ESP
* and landing zone are on the same server.  The default location for landing
* zone files may be changed by modifying the SHARED variable sDefaultPath
*/
  SHARED sDefaultPath:='/var/lib/HPCCSystems/mydropzone/';

/**
* Pull a file from the web into the specified location
*
* @param sUrl        The URL for the file to pull down
* @param sLocalPath  Optional: The absolute path location to place the file
*/
  EXPORT GetRemoteFile(STRING sURL,STRING sLocalPath=sDefaultPath):=PIPE('wget '+sURL+' -P '+sLocalPath,{STRING s;},CSV);
  
/**
* Get a listing of the files in the specified path
*
* @param sPath       Optional: The absolute path where the file resides
*/
  EXPORT FileList(STRING sPath=sDefaultPath):=PIPE('ls -1 '+sPath,{STRING s;},CSV);
  
/**
* Pull in the top rows from the text file to be viewed as a single-string
* dataset.
*
* @param sFileName   The name of the file
* @param sPath       Optional: The absolute path where the file resides
* @param iRowCount   Optional: The number of rows to return
* @return            A dataset containing the rows requested from the input file
*/
  EXPORT TopRows(STRING sFileName,STRING sPath=sDefaultPath,UNSIGNED4 iRowCount=100):=FUNCTION
    RETURN PIPE('bash -c "head -'+(STRING)iRowCount+' '+sPath+sFilename+'"',{STRING s;},csv(separator([]),quote([])));
  END;
  
/**
* Get a count of the number of rows in the XML file specified
*
* @param sFileName   The name of the file
* @param sPath       Optional: The absolute path where the file resides
* @param sRowTag     Name of the tag that is used to delimit a row in the XML file
* @return            Positive integer indicating the number of rows in the XML file
*/
  EXPORT RowCountXML(STRING sFileName,STRING sPath=sDefaultPath,STRING sRowTag):=FUNCTION
    RETURN (UNSIGNED)(PIPE('bash -c "cat '+sPath+sFilename+' | sed \'s/>[^<]*/\\n/g\' |grep \'</'+sRowTag+'\' | wc -l"',{STRING s;},CSV)[1].s);
  END;
  
/**
* Get a count of the number of rows in the delimited file specified
*
* @param sFileName   The name of the file
* @param sPath       Optional: The absolute path where the file resides
* @return            Positivie integer indicating the number of rows in the CSV file
*/
  EXPORT RowCountDelimited(STRING sFileName,STRING sPath=sDefaultPath):=FUNCTION
    RETURN (UNSIGNED)PIPE('bash -c "cat '+sPath+sFilename+' | wc -l"',{STRING s;},CSV)[1].s;
  END;
  
/**
* Get a count of the number of columns in the delimited file specified
* N.B.  Currently does not support quoting, which means data files with quotes
* may not report properly if the delimiter exists inside quoated text.
*
* @param sFileName   The name of the file
* @param sPath       Optional: The absolute path where the file resides
* @param sDelimiter  Optional: The character to use as the delimiter for row counting
* @return            Positivie integer indicating the number of columns in the CSV file
*/
  EXPORT ColumnCountDelimited(STRING sFilename,STRING sPath=sDefaultPath,sDelimiter=','):=(UNSIGNED)PIPE('bash -c "head -1 '+sPath+sFilename+' | sed \'s/[^,]//g\' | wc -c"',{STRING s;},CSV)[1].s;

/**
* Get a listing of the files in the specified zip file
* N.B. Work in progress.  Need to actually enable the use of the parameter for
* forcing the use of a specific compression program.  Also need to incorporate
* support for unzip, which enables multiple files within a zip file.
*
* @param sFileName             The name of the file
* @param sPath                 Optional: The absolute path where the file resides
* @param sCompressionProgram   Optional: Used to force a specific program (e.g. gzip, bzip2)
* @return                      Dataset containing a listing of files in the specified zip file
*/
EXPORT ZipFileList(STRING sFilename,STRING sPath=sDefaultPath,STRING sCompressionProgram=''):=TABLE(PIPE('gzip -l '+sFullPath+IF(REGEXFIND('.zip$',sPath+sFilename),' -S .zip',''),{STRING s;},CSV),{STRING filename:=REGEXFIND('([^\\/]+)$',s,1);})[2..];

/**
* Decompress the specified zip file
*
* @param sFileName              The name of the file
* @param sPath                  Optional: The absolute path where the file resides
* @param bKeepCompressed        Optional: Boolean indicating whether to keep the compressed file after decompressing (Default: TRUE)
* @param sCompressionProgram    Optional: Used to force a specific program (e.g. gzip, bzip2)
*/
  EXPORT UnzipFile(STRING sFilename,STRING sPath=sDefaultPath,BOOLEAN bKeepCompressed=TRUE,STRING sCompressionProgram=''):=FUNCTION
    sZipType:=REGEXFIND('([^.]+)$',sFilename,1);
    sZipProg:=MAP(
      sCompressionProgram!='' => sCompressionProgram,
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

/**
* Decompress the specified zip file, spray the resulting delimited file, and
* if requested remove the decompressed version of the file
* N.B. Need error trapping (or warning, anyway) for when any of the actions
* performed fails.
*
* @param sIP                      The IP address of the file
* @param sFullPath                The full path and file name of the file to spray
* @param maxrecordsize            Optional: The maximum record size (Default: 4096)
* @param srcCSVseparator          Optional: The character used as the delimiter (Default: ',')
* @param srcCSVterminator         Optional: The character(s) used as line terminator (Default: CR, CR/LF)
* @param srcCSVquote              Optional: The character used to quote text (Default: ' " ')
* @param destinationgroup         Name of the group into which to place the file (e.g. 'mythor')
* @param destinationlogicalname   Optional: The name to give the file when sprayed (Default: same as original file name)
* @param timout                   Optional: The timeout setting (Default: -1, indicating no timeout)
* @param espserverIPport          Optional: Explicit protocol, IP, port and directory instructions (Default: '')
* @param maxConnections           Optional: Maximum number of connections (Default: 1)
* @param allowoverwrite           Optional: Boolean indicating whether to allow an overwrite if the file already exists on the cluster (Default: FALSE)
* @param replicate                Optional: Boolean indicating whether to replicate (Default: FALSE)
* @param compress                 Optional: Boolean indicating whether to compress the sprayed file (Default: FALSE)
* @param sourceCsvEscape          Optional: Any escape characters that exist in the file (Default: '')
* @param removewhendone           Optional: Boolean indicating whether to remove the de-compressed file when the operation is complete (Default: FALSE)
*/
  EXPORT UnzipAndSprayDelimited(
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
      std.File.SprayDelimited(sIP,sFileToSpray,maxrecordsize,srcCSVseparator,srcCSVterminator,srcCSVquote,destinationgroup,sNewFile,timout,,maxConnections,allowoverwrite,replicate,compress,sourceCsvEscape),
      IF(removewhendone,STD.File.DeleteExternalFile(sIP,sFileToSpray),OUTPUT('File '+sUnzippedFile+' was not removed'))
    );
  END;
  
/**
* Decompress the specified zip file, spray the resulting XML file, and
* if requested remove the decompressed version of the file
* N.B. Need error trapping (or warning, anyway) for when any of the actions
* performed fails.  This function could be collapsed into the
* UnzipAndSprayDelimited, but the intention was to keep the calling structure
* the same as the std.File spray function call for portability.
*
* @param sIP                      The IP address of the file
* @param sFullPath                The full path and file name of the file to spray
* @param maxrecordsize            Optional: The maximum record size (Default: 4096)
* @param srcRowTag                The tag used to delimit a row in the XML file
* @param srcEncoding              Optional: The encoding to use (Default: utf-8)
* @param destinationgroup         Name of the group into which to place the file (e.g. 'mythor')
* @param destinationlogicalname   Optional: The name to give the file when sprayed (Default: same as original file name)
* @param timout                   Optional: The timeout setting (Default: -1, indicating no timeout)
* @param espserverIPport          Optional: Explicit protocol, IP, port and directory instructions (Default: '')
* @param maxConnections           Optional: Maximum number of connections (Default: 1)
* @param allowoverwrite           Optional: Boolean indicating whether to allow an overwrite if the file already exists on the cluster (Default: FALSE)
* @param replicate                Optional: Boolean indicating whether to replicate (Default: FALSE)
* @param compress                 Optional: Boolean indicating whether to compress the sprayed file (Default: FALSE)
* @param removewhendone           Optional: Boolean indicating whether to remove the de-compressed file when the operation is complete (Default: FALSE)
*/
  EXPORT UnzipAndSprayXML(
    STRING sIP,
    STRING sFullPath,
    UNSIGNED maxrecordsize=4096,
    STRING srcRowTag,
    STRING srcEncoding='utf8',
    STRING destinationgroup,
    STRING destinationlogicalname='',
    UNSIGNED timout=-1,
    STRING espserverIPport='',
    UNSIGNED maxConnections=1,
    BOOLEAN allowoverwrite=FALSE,
    BOOLEAN replicate=FALSE,
    BOOLEAN compress=FALSE,
    BOOLEAN removewhendone=FALSE
  ):=FUNCTION
    sPath:=REGEXREPLACE('[^\\/]+$',sFullPath,'');
    sUnzippedFile:=ZipFileList(sFullPath)[1].filename;
    sNewFile:=IF(destinationlogicalname='',sUnzippedFile,destinationlogicalname);
    sFileToSpray:=sPath+sUnzippedFile;
    RETURN SEQUENTIAL(
      UnzipFile(sFullPath),
      STD.File.SprayXML(sourceIP,sourcepath,maxrecordsize,srcRowTag,srcEncoding,destinationgroup,destinationlogicalname,timeout,espserverIPport,maxConnections,allowoverwrite,replicate,compress),
      IF(removewhendone,STD.File.DeleteExternalFile(sIP,sFileToSpray),OUTPUT('File '+sUnzippedFile+' was not removed'))
    );
  END;
  
/*
  Functions in development and considered for future expansion

  GetFromDropbox() // Requires username and password interaction
  PutToDropbox()
  CoumnCountXML()
  DesprayAndZip()
  SprayDelimitedSelective() // For spraying only certain columns from the LZ file
  AnalyzeDelimited() // AMBITIOUS: get metrics from the LZ file (e.g. min/max line size, min/max size per column, column shape/content information, etc.)
  AnalyzeXML()
  SuggestedLayoutXML()
  SuggestedLayoutDelimited()
  ** Need to add support for zip files with multiple members (use unzip instead of gunzip) and enable progressive file extraction, spray, deletion
  ** Script deploy/run/remove at the cluster level??
*/
END;


/*
  EXAMPLES

  LZLib.GetRemoteFile('http://dumps.wikimedia.org/enwiki/20130403/enwiki-20130403-pages-meta-current.xml.bz2');
  LZLib.UnzipFile('test2.gz');
  LZLib.UnzipFile('test.zip','/var/lib/HPCCSystems/someotherdropzone/');
  LZLib.UnzipAndSprayDelimited('192.168.6.130','/var/lib/HPCCSystems/mydropzone/test.zip',,,,,'mythor','test',,,,TRUE,,TRUE,,TRUE);
  LZLib.UnzipAndSprayDelimited('192.168.6.130','/var/lib/HPCCSystems/mydropzone/test.zip',,,,,'mythor',,,,,TRUE,,TRUE);
  LZLib.UnzipAndSprayDelimited('192.168.6.130','/var/lib/HPCCSystems/mydropzone/test.gz',,,,,'mythor','test',,,,TRUE,,TRUE,,TRUE);
  LZLib.UnzipAndSprayXML('192.168.6.130','/var/lib/HPCCSystems/mydropzone/test.gz',,'Row',,'mythor','test',,,,TRUE,,TRUE,TRUE);
  LZLib.ZipFileList('test.zip');
  LZLib.FileList();
  LZLib.TopRows('test.txt',,20);
  LZLib.RowCountXML('test.xml',,'Row');

*/