import lib_fileservices;
IMPORT STD;

EXPORT TxtMessage := MODULE,FORWARD
		EXPORT Bundle := MODULE(Std.BundleBase)
			EXPORT Name := 'TxtMessage';
			EXPORT Description := 'Using FileServices.sendemail one can send text messages';
			EXPORT Authors := ['Gavin Witz'];
			EXPORT DependsOn := [];
			EXPORT Version := '1.0.0';
		END;

/**
Returns a text message to a cell phone.
param Number      Cell phone number. 
param carrier     Cell phone carrier. 
param Subject     Subject of the text message. 
param Body     		Text message Body 
return            Text message to cellphone.*/

EXPORT SendTxtMessage(string Number,string carrier,string Subject='',string Body='') := FUNCTION

//Map carriers to there corresponding email address
						CellCarrier := MAP(carrier = 'tmobile' => 'tmomail.net',
													carrier = 't-mobile' => 'tmomail.net',
													carrier = 'att' => 'txt.att.net',
													carrier = 'AT&T' => 'txt.att.net',
              '');

				return lib_fileservices.FileServices.sendemail(number+'@'+ CellCarrier,subject,body);
END;

END;
