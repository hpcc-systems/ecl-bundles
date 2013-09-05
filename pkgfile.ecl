IMPORT STD;
export pkgfile := module, FORWARD

export bundle := module(STD.BundleBase)
	Export Name := 'pkgfile';
	export Description := 'Build package file from ECL';
	export Authors := ['Ananth Venkatachalam'];
	export DependsOn := [];
	export Version := '1.0.0';
	export PlatformVersion := '4.0.0';
end;

EXPORT configs := module
	export integer generations := 10;
	export string cluster := 'fcra' : stored('cluster');
	export string env := 'qa' : stored('env');
end;

// File name definitions
EXPORT files(string filetype) := module
	export root := '~package::' + pkgfile.configs.env + '::' + pkgfile.configs.cluster ;
	export pfile := root + '::' + filetype + '::pkgfile';
	export backupfile := pfile + '::backup';
	export getflatpackage := dataset(pfile,pkgfile.layouts.flat_layouts.packageid,thor,opt);
	export getxmlpackage := dataset(pfile,pkgfile.layouts.xml_layouts.packageid,xml('RoxiePackages/Package'),opt);
end;

// Layouts

EXPORT layouts := module

	export xml_layouts := module
		export subfile := record
			string value {XPATH('@value')} := '';
		end;

		export superfile := record
			string id {XPATH('@id')} := '';
			dataset(subfile) subfiles {XPATH('SubFile')};
		end;

		export base := record
			string id {XPATH('@id')} := '';
			
		end;


		export environment := record
			string id {XPATH('@id')} := '';
			string val {XPATH('@val')} := '';
		end;

		export packageid := record, maxlength(30000)
			string id {XPATH('@id')} := '';
			string daliip {XPATH('@daliip')} := '';
			dataset(superfile) superfiles {XPATH('SuperFile')};
			string compulsory {XPATH('@compulsory')} := '';
			string eft {XPATH('@enablefieldtranslation')} := '';
			dataset(base) bases {XPATH('Base')};
			dataset(environment) environments {XPATH('Environment')};
			
		end;
		
	end;

	export flat_layouts := module
		
		export FileRecord := record
			string packageid := '';
			string superfile := '';
			string subfile := '';
			boolean isfullreplace := true;
		end;
		
		export packageid := record, maxlength(30000)
			string pkgcode;
			string id := '';
			ifblock(lib_stringlib.StringLib..stringtouppercase(self.pkgcode) = 'K')
				string daliip := '';
				string superfileid := '';
				string subfilevalue := '';
			END;
			ifblock(lib_stringlib.StringLib..stringtouppercase(self.pkgcode) = 'Q')
				string compulsory  := '';
				string eft := '';
				string baseid := '';
			END;
			ifblock(lib_stringlib.StringLib..stringtouppercase(self.pkgcode) = 'E')
				string environmentid  := '';
				string environmentval := '';
				
			END;
			string whenupdated;
		end;
	
		
	end;
		
	
end;

EXPORT Promote := module
	// Promote newly created files into backup superfile, maintains
	// configs.noofgenerations (defaulted to 10) 
	export Backup(string filetype) := function
	
		return	if (~fileservices.fileexists(files(filetype).backupfile),
									fileservices.createsuperfile(files(filetype).backupfile),
									if (~fileservices.fileexists(files(filetype).pfile),
										fileservices.createsuperfile(files(filetype).pfile),
						
										sequential
										(
											fileservices.StartSuperFileTransaction(),
											if (fileservices.getsuperfilesubcount(files(filetype).backupfile) = configs.generations,
												fileservices.RemoveSuperFile(files(filetype).backupfile,'~'+fileservices.getsuperfilesubname(files(filetype).backupfile,1),true)
												),
										
											fileservices.addsuperfile(files(filetype).backupfile, files(filetype).pfile,,true),
											fileservices.clearsuperfile(files(filetype).pfile),
											fileservices.FinishSuperFileTransaction()
											)
										)
							);
	end;
	// Promote newly created files into backup superfile
	// filetype = 'flat' or 'xml'
	export New(l_Dataset, filetype, filepromoted) := macro
		filepromoted := sequential(
								if (filetype = 'xml',
									output(l_Dataset,,pkgfile.files(filetype).pfile+WORKUNIT,xml('Package',heading('<RoxiePackages>\n','</RoxiePackages>\n'),OPT),overwrite),
									output(l_Dataset,,pkgfile.files(filetype).pfile+WORKUNIT,overwrite)
									),
								pkgfile.Promote.backup(filetype),
								fileservices.addsuperfile(pkgfile.files(filetype).pfile,pkgfile.files(filetype).pfile+WORKUNIT)
						);
	endmacro;
	
	
end;


// THIS MODULE CAN BE EXPANDED BY ADDING FUNCTIONALITIES WHEN NEW
// PACKAGE ID TYPES ARE INTRODUCED INTO THE ROXIE PACKAGE FILE
EXPORT add := module
	////////////////////////////////////////////////////////////////////////
	// Function: SFiles - to add Key Package ID, Superfiles and Subfiles
	// Paramters: FileRecord Dataset
	// Functionality: 1. add the files to package
	//								2. Remove files if it already exists and then re-add
	//								3. Based on the isfullreplace flag in FileRecord
	//								4. the subfiles will either be appended or replaced
	////////////////////////////////////////////////////////////////////////
	export SFiles(dataset(layouts.flat_layouts.FileRecord) File_DS) := function
		// Existing package - flat file 
		PKG_DS := pkgfile.files('flat').getflatpackage;
		// Take care of '~'
		layouts.flat_layouts.FileRecord PrefixTild(File_DS l) := transform
			self.superfile := '~'+regexreplace('~',l.superfile,'');
			self.subfile := '~'+regexreplace('~',l.subfile,'');
			self := l;
		end;
		
		FilePrefixed := project(File_DS,PrefixTild(left));
		// Superfiles that requires full replacement
		FullReplaceRecs := FilePrefixed(isfullreplace);
		// Subfiles that requires full replacement
		AppendRecs := FilePrefixed(~isfullreplace);
		
		// Remove the new full replacement records from existing package
		layouts.flat_layouts.packageid RemoveNew(PKG_DS l,FullReplaceRecs r) := transform
			self := l;
		end;
		
		NewRemoved := join(PKG_DS,FullReplaceRecs,left.id = right.packageid and
																						left.superfileid = right.superfile,
																						RemoveNew(left,right),
																						left only,
																						lookup);
																						
		// Remove the new non full replacement records from existing package
		layouts.flat_layouts.packageid RemoveExisting(NewRemoved l,AppendRecs r) := transform
			self := l;
		end;
		
		RemovedAllNew := join(NewRemoved,AppendRecs,left.id = right.packageid and
																						left.superfileid = right.superfile and
																						left.subfilevalue = right.subfile,
																						RemoveExisting(left,right),
																						left only,
																						lookup);
		
		// Convert New records of Package Layout
		layouts.flat_layouts.packageid ConvertNew(FilePrefixed l) := transform
			self.pkgcode := 'K';
			self.id := l.packageid;
			self.superfileid := l.superfile;
			self.subfilevalue := l.subfile;
			self.whenupdated := WORKUNIT[2..];
			self := [];
		end;
		
		NewConverted := project(FilePrefixed,ConvertNew(left));
		
		ADD_DS := RemovedAllNew + NewConverted;

		// Promote to Package Super File
		
		pkgfile.Promote.New(ADD_DS,'flat',filepromoted);
		
		return filepromoted;
	end;
	////////////////////////////END////////////////////////////////////////
	
	////////////////////////////////////////////////////////////////////////
	// Function: Queries - to add Query Package ID
	// Paramters: Package ID = Query name, 
	//						Baseid = superfile name or unique identifier that identifies
	//										a set of superfiles
	//						compulsory = attribute value for query
	//						eft = enablefieldtranslation value for query
	// Functionality: 1. add queries to package
	//								2. Remove queries if it already exists and then re-add
	// Note: Unlike adding keys, this function will allow users to add
	// one query at any given time, but a potential functionality can added
	// in the future to pass in a dataset for bulk updates
	////////////////////////////////////////////////////////////////////////
	
	export Queries(string l_packageid, string l_baseid = '', string l_compulsory = '1', string l_eft = 'true') := function
		// Full Package 
		PKG_DS := pkgfile.files('flat').getflatpackage;
		// New Package ID
		l_DS := dataset([{'Q',l_packageid,l_compulsory,l_eft,l_baseid,WORKUNIT[2..]}],layouts.flat_layouts.packageid);
		// Remove Package ID if it already exists
		New_DS := PKG_DS(~(pkgcode = 'Q' and id = l_packageid and baseid = l_baseid));
		
		ADD_DS := NEW_DS + l_DS;
		// Promote to Package Super File - Flat file
		pkgfile.Promote.New(ADD_DS,'flat',filepromoted);
		
		return filepromoted;
		
	end;
	////////////////////////////END////////////////////////////////////////
	
	////////////////////////////////////////////////////////////////////////
	// Function: Environment - to add Environment Variables
	// Paramters: Package ID = Defaulted to EnvironmentVariables, 
	//						id = environment variable name
	//						val = environment variable value
	// Functionality: 1. add environment variables to package
	//								2. Remove environments if it already exists and then re-add
	// Note: Unlike adding keys, this function will allow users to add
	// one environment variable at any given time, but a potential functionality can added
	// in the future to pass in a dataset for bulk updates
	////////////////////////////////////////////////////////////////////////
	
	export Environment(string l_packageid = 'EnvironmentVariables', string l_id = '',string l_val = '') := function
		 
		PKG_DS := pkgfile.files('flat').getflatpackage;
		l_DS := dataset([{'E',l_packageid,l_id,l_val,WORKUNIT[2..]}],layouts.flat_layouts.packageid);
		New_DS := PKG_DS(~(pkgcode = 'E' and id = l_packageid and environmentid = l_id));
		ADD_DS := NEW_DS + l_DS;
		
		pkgfile.Promote.New(ADD_DS,'flat',filepromoted);
		
		return filepromoted;
	end;
	
	////////////////////////////END////////////////////////////////////////
end;

// DELETE ENTRIES FROM ROXIE PACKAGE
EXPORT delete := module
	
	export packageid(string name) := function
		deleted := pkgfile.files('flat').getflatpackage(~(id = name or baseid = name));
		pkgfile.Promote.New(deleted,'flat',returndeleted);
		return returndeleted;
	end;

	export superfile(string name) := function
		deleted := pkgfile.files('flat').getflatpackage(superfileid <> name);
		pkgfile.Promote.New(deleted,'flat',returndeleted);
		return returndeleted;
	end;
	
	export subfile(string name) := function
		deleted := pkgfile.files('flat').getflatpackage(subfilevalue <> name);
		pkgfile.Promote.New(deleted,'flat',returndeleted);
		return returndeleted;
	end;
	
	export environment(string name) := function
		deleted := pkgfile.files('flat').getflatpackage(environmentid <> name);
		pkgfile.Promote.New(deleted,'flat',returndeleted);
		return returndeleted;
	end;
end;


// Module to Build Roxie Package File
EXPORT RoxiePackage := module

	// Flat file that holds all Package Meta
	shared flatpackage := pkgfile.files('flat').getflatpackage;

	////////////  Keys Package ////////////////////

	// Macro to get child datasets for superfiles
	shared getsubfileds(string l_pid, string l_superfileid) := function
		// Get all records related to a superfile
		Sfile_DS := flatpackage(id = l_pid and superfileid = l_superfileid);
		layouts.xml_layouts.superfile prepsuper(Sfile_DS l) := transform
			self.subfiles := dataset([{l.subfilevalue}],layouts.xml_layouts.subfile);
			self.id := l_superfileid;
		end;

		preppedsuper := project(Sfile_DS,prepsuper(left));
		// Rollup by superfile to create subfile child dataset
		layouts.xml_layouts.superfile rollsuper(preppedsuper l, preppedsuper r) := transform
			self.subfiles := l.subfiles + row({r.subfiles[1].value},layouts.xml_layouts.subfile);
			self := l;
		end;
		
		rolledsuper := rollup(preppedsuper,id,rollsuper(left,right));
		
		return rolledsuper;		
	end;
	
	// Function that returns the Key Package id Package
	shared GetKeysPackage() := function
		// Get all records related to Key Package Type (K) from flat package 
		Key_DS := dedup(flatpackage(pkgcode = 'K'),id,superfileid,all);
		pkgfile.layouts.xml_layouts.packageid prepsuperfile(Key_DS l) := transform
			self.superfiles := getsubfileds(l.id,l.superfileid);
			self := l;
			self := [];
		end;

		superfileprepped := project(Key_DS,prepsuperfile(left));
	
		pkgfile.layouts.xml_layouts.packageid rollupkeys(superfileprepped l, superfileprepped r) := transform
			self.superfiles := l.superfiles + row({r.superfiles[1].id,r.superfiles[1].subfiles},layouts.xml_layouts.superfile);
			self := l;
			
		end;

		keyspackage := rollup(superfileprepped,id,rollupkeys(left,right));
		return keyspackage;
	end;
	
	////////////  End Keys Package ////////////////////
	
	
	////////////  Queries Package ////////////////////
	
	// Get all base ids for a Query
	shared getbaseids(string l_pid) := function
		KeyIDs := dedup(flatpackage(pkgcode = 'K'),id,all);
		layouts.xml_layouts.base getAllBases(KeyIDs l) := transform
			self.id := l.id;
		end;
		// If the query has empty base id then get all Key Package ID's
		// will be included as a part of query
		getAllIDs := project(KeyIDs,getAllBases(left));
		
		
		QueriesBaseIDs := flatpackage(pkgcode = 'Q' and baseid <> '' and id = l_pid);
		layouts.xml_layouts.base getSelectedBases(QueriesBaseIDs l) := transform
			self.id := l.baseid;
		end;
		// get all the base ids associated to query
		getSelectedIDs := project(QueriesBaseIDs,getSelectedBases(left));
		
		Base_DS := if (count(flatpackage(id = l_pid and baseid = '')) > 0,
												// include all baseids
												getAllIDs,
												// include only existing baseids;
												getSelectedIDs
												);
		
		return Base_DS;		
	end;
	
	//////////// Get Queries Package //////////////////
	shared GetQueriesPackage() := function
		Queries_DS := dedup(sort(flatpackage(pkgcode = 'Q'),-whenupdated),id,all,keep(1));
		
		pkgfile.layouts.xml_layouts.packageid prepqueries(Queries_DS l) := transform
			self.bases := getbaseids(l.id);
			self := l;
			self := [];
		end;

		querieswithbase := project(Queries_DS,prepqueries(left));
	
		return querieswithbase;
	end;
	
	////////////  End Queries Package ////////////////////
	
	////////////  Environment Package ////////////////////

	//////////// Get Environment Package //////////////////
	shared GetEnvironmentPackage() := function
		Env_DS := flatpackage(pkgcode = 'E' and environmentid <> '');
		pkgfile.layouts.xml_layouts.packageid prepenvironment(Env_DS l) := transform
			self.environments := dataset([{l.environmentid,l.environmentval}],layouts.xml_layouts.environment);
			self := l;
			self := [];
		end;

		environmentprepped := project(Env_DS,prepenvironment(left));

		pkgfile.layouts.xml_layouts.packageid rollupenvironments(environmentprepped l, environmentprepped r) := transform
			self.environments := l.environments + row({r.environments[1].id,r.environments[1].val},layouts.xml_layouts.environment);
			self := l;
		end;

		environmentpackage := rollup(environmentprepped,id,rollupenvironments(left,right));
		return environmentpackage;
	
	end;
	
	////////////  End Environment Package ////////////////////
	
	
	///// Build and Promote Package //////
	
	export BuildPromotePackage() := function
	
		fullpackage := GetEnvironmentPackage() + GetQueriesPackage() + GetKeysPackage();

		pkgfile.Promote.New(fullpackage,'xml',filepromoted);
		
		return filepromoted;
	end;
	
	///// Build and Promote Package //////
	
	///// Get Package //////
	
	export GetPackage(string destip, string destlocation) := function

		return fileservices.Despray(pkgfile.files('xml').pfile,destip,destlocation,,,,TRUE);
	end;
	
	///// Get Package //////
end;

// Module to set attribute values for a Package ID

EXPORT SetAttributes := module
	export packageid(attributename,attributevalue,l_packageid,filepromoted) := macro
		PKG_DS := pkgfile.files('flat').getflatpackage;
		PKGID_DS := PKG_DS(id = l_packageid);
		pkgfile.layouts.flat_layouts.packageid populateattribute(PKGID_DS l) := transform
				self.attributename := attributevalue;
				self := l;
		end;
		l_attributeset := project(PKGID_DS,populateattribute(left));
	
		Full_DS := PKG_DS(id <> l_packageid) + l_attributeset;
		pkgfile.Promote.New(Full_DS,'flat',filepromoted);
	endmacro;
end;

end;

