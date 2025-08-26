component displayname="Authenticate This" output="false" author="Andrew Bellenie" support="andybellenie@gmail.com"{

	public function init(){
		this.version = "1.4,1.4.1,1.4.2,1.4.3,1.4.4,1.4.5,2.0";
		return this;
	}

	/**
	* Setup function and configuration for AuthenticateThis
	*
	* [section: Plugins]
	* [category: AuthenticateThis]
	*
	* @required Whether to enforce the prescence of a password for this model
	* @workFactor The bCrypt Workfactor: Defaults to 12
	* @passwordProperty The property name for the password, defaults to "password"
	* @hashProperty The property name for the generated password Hash, defaults to "passwordHash"
	* @changeRequiredProperty The property name for the password Change Required option
	* @formatRegEx The password validation regex
	* @formatErrorMessage Error message for incorrect password format
	* @randomPasswordLength generated Password length, defaults to 12
	*/
	public function authenticateThis(
		boolean required="true",
		numeric workFactor="12",
		string passwordProperty="password",
		string hashProperty="passwordHash",
		string changeRequiredProperty="passwordChangeRequired",
		string formatRegEx="^.*(?=.{8,})(?=.*\d)(?=.*[a-z]).*$",
		string formatErrorMessage="Password must be at least 8 characters long and contain a mixture of numbers and letters",
		numeric randomPasswordLength="12"
	) mixin="model" {
		variables.wheels.class.authenticateThis = Duplicate(arguments);
		variables.wheels.class.authenticateThis.bCrypt =  CreateObject( "java", "BCrypt" ).init();
		if ( arguments.required ) {
			validatesPresenceOf(property=arguments.passwordProperty, when="onCreate");
			validatesPresenceOf(property=arguments.passwordProperty, when="onUpdate", condition="StructKeyExists(this, 'updatePassword')");
		}
		validatesFormatOf(property=arguments.passwordProperty, regEx=arguments.formatRegEx, message=arguments.formatErrorMessage, allowBlank=true);
		validatesConfirmationOf(property=arguments.passwordProperty);
		beforeValidation(methods="hashPassword");
	}

	/**
	* Hashes a plaintext password
	*
	* [section: Plugins]
	* [category: AuthenticateThis]
	*
	*/
	function hashPassword() mixin="model" {
		var settings = variables.wheels.class.authenticateThis;
		if ( StructKeyExists(this, settings.passwordProperty) ) {
			this[settings.hashProperty] = settings.bCrypt.hashpw(this[settings.passwordProperty], settings.bCrypt.gensalt(settings.workFactor));
		}
	}

	/**
	* Checks a plaintext password against the stored hash
	*
	* [section: Plugins]
	* [category: AuthenticateThis]
	*
	*/
	boolean function checkPassword(required string password) mixin="model" {
		var settings = variables.wheels.class.authenticateThis;
		return settings.bCrypt.checkpw(arguments.password, this[settings.hashProperty]);
	}

	/**
	* Resets a password property on your model
	*
	* [section: Plugins]
	* [category: AuthenticateThis]
	*
	*/
	boolean function resetPassword()  mixin="model" {
		var settings = variables.wheels.class.authenticateThis;
		this[settings.passwordProperty] = generateRandomPassword();
		this[settings.changeRequiredProperty] = true;
		return this.update(validate=false);
	}

	/**
	* Generates a random password with at least one lowercase, uppercase and one number
	*
	* [section: Plugins]
	* [category: AuthenticateThis]
	*
	*/
	string function generateRandomPassword() mixin="model" {
		local.charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
		local.result = ArrayNew(1);
		ArrayAppend(local.result, Mid(local.charset, RandRange(1, 26), 1));
		//  1 lowercase
		ArrayAppend(local.result, Mid(local.charset, RandRange(27, 52), 1));
		//  1 uppercase
		ArrayAppend(local.result, Mid(local.charset, RandRange(53, 62), 1));
		//  1 number
		for ( i=1 ; i<=variables.wheels.class.authenticateThis.randomPasswordLength-3 ; i++ ) {
			ArrayAppend(local.result, Mid(local.charset, RandRange(1, 62), 1));
		}
		CreateObject("java", "java.util.Collections").Shuffle(local.result);
		return ArrayToList(local.result, "");
	}

}
