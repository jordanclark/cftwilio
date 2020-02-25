component {

	function init(
		required string accountSID
	,	required string authToken
	,	string defaultFrom= ""
	,	required string version= "2010-04-01"
	,	numeric httpTimeOut= 120
	,	boolean debug= ( request.debug ?: false )
	) {
		this.accountSID= arguments.accountSID;
		this.authToken= arguments.authToken;
		this.defaultFrom= arguments.defaultFrom;
		this.apiUrl= "https://api.twilio.com/#arguments.version#/Accounts/" & arguments.accountSID;
		this.httpTimeOut= arguments.httpTimeOut;
		this.debug= arguments.debug;
		this.sendSMS= this.sendMessage;
		return this;
	}
	
	function debugLog(required input) {
		if ( structKeyExists( request, "log" ) && isCustomFunction( request.log ) ) {
			if ( isSimpleValue( arguments.input ) ) {
				request.log( "Twilio: " & arguments.input );
			} else {
				request.log( "Twilio: (complex type)" );
				request.log( arguments.input );
			}
		} else if( this.debug ) {
			cftrace( text=( isSimpleValue( arguments.input ) ? arguments.input : "" ), var=arguments.input, category="Twilio", type="information" );
		}
		return;
	}
	
	/**
	 * Returns a representation of your account.
	 */
	// function getAccount() {
	// 	var out= this.apiRequest(
	// 		api="GET "
	// 	);
	// 	return out;
	// }
	
	function sendMessage(required string to, required string message, string from=this.defaultFrom, string callback="") {
		var out= this.apiRequest(
			api= "POST /SMS/Messages"
		,	to= arguments.to
		,	body= arguments.message
		,	from= arguments.from
		,	statusCallback= arguments.callback
		);
		return out;
	}
	
	/**
	 * Returns a list of SMS messages made by your account.
	 */
	function getMessages(numeric limit=50, numeric page=0, string to="", string from="", string dateSent="") {
		var out= this.apiRequest(
			api="GET /SMS/Messages"
		,	num= arguments.limit
		,	page= arguments.page
		,	from= arguments.from
		,	to= arguments.to
		,	dateSent= arguments.dateSent
		);
		return out;
	}
	
	/**
	 * Returns a single SMS message specified by the provided Sid.
	 */
	function getMessage(required string messageID) {
		var out= this.apiRequest(
			api="GET /SMS/Messages/#trim( arguments.messageID )#"
		);
		return out;
	}
	
	struct function apiRequest(required string api) {
		var http= {};
		var item= "";
		var out= {
			success= false
		,	verb= listFirst( arguments.api, " " )
		,	error= ""
		,	status= ""
		,	statusCode= 0
		,	response= ""
		,	requestUrl= this.apiUrl & listRest( arguments.api, " " ) & ".json"
		};
		debugLog( "#out.verb# #out.requestUrl#" );
		//debugLog( out );
		cfhttp( result="http", method=arguments.requestMethod, url=out.requestUrl, charset="utf-8", throwOnError=false, password=this.authToken, timeOut=this.httpTimeOut, username=this.accountSid ) {
			for ( item in arguments ) {
				if ( arguments.requestMethod == "POST" ) {
					cfhttpparam( name=item, type="formfield", value=arguments[ item ] );
				} else {
					cfhttpparam( name=item, type="url", value=arguments[ item ] );
				}
			}
		}
		out.response= toString( http.fileContent );
		// debugLog( out.response );
		out.statusCode = http.responseHeader.Status_Code ?: 500;
		if ( left( out.statusCode, 1 ) == 4 || left( out.statusCode, 1 ) == 5 ) {
			out.error= "status code error: #out.statusCode#";
		} else if ( out.response == "Connection Timeout" || out.response == "Connection Failure" ) {
			out.error= out.response;
		} else if ( left( out.statusCode, 1 ) == 2 ) {
			out.success= true;
		}
		// parse response 
		try {
			if ( left( http.responseHeader[ "Content-Type" ], 16 ) == "application/json" ) {
				out.response= deserializeJSON( out.response );
			} else {
				out.error= "Invalid response type: " & http.responseHeader[ "Content-Type" ];
			}
			if ( isDefined( "out.response.message" ) ) {
				out.error= out.response.message;
			}
		} catch (any cfcatch) {
			out.error= "JSON Error: " & (cfcatch.message?:"No catch message") & " " & (cfcatch.detail?:"No catch detail");
		}
		if ( len( out.error ) ) {
			out.success= false;
		}
		this.debugLog( out.statusCode & " " & out.error );
		return out;
	}
	
}