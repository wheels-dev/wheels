component extends="wheels.tests.Test" {

	function test_railo_invalid() {
		assert('Len($checkMinimumVersion(version="4.3.0.003", engine="Railo"))');
		assert('Len($checkMinimumVersion(version="4.2.1.008", engine="Railo"))');
		assert('Len($checkMinimumVersion(version="3.0.2", engine="Railo"))');
		assert('Len($checkMinimumVersion(version="4.2.1.000", engine="Railo"))');
		assert('Len($checkMinimumVersion(version="3.1.2", engine="Railo"))');
		assert('Len($checkMinimumVersion(version="3.1.2.020", engine="Railo"))');
	}

	function test_lucee_valid() {
		assert('!Len($checkMinimumVersion(version="5.3.2.77", engine="Lucee"))');
		assert('!Len($checkMinimumVersion(version="5.3.5.92", engine="Lucee"))');
	}

	function test_lucee_invalid() {
		assert('Len($checkMinimumVersion(version="5.3.1.103", engine="Lucee"))');
		assert('Len($checkMinimumVersion(version="4.5.5.006", engine="Lucee"))');
		assert('Len($checkMinimumVersion(version="4.5.1.021", engine="Lucee"))');
		assert('Len($checkMinimumVersion(version="4.4.0", engine="Lucee"))');
		assert('Len($checkMinimumVersion(version="4.5.0.023", engine="Lucee"))');
	}

	function test_adobe_valid() {
		assert('!Len($checkMinimumVersion(version="11,0,18,314030", engine="Adobe ColdFusion"))');
		assert('!Len($checkMinimumVersion(version="2016,0,10,314028", engine="Adobe ColdFusion"))');
		assert('!Len($checkMinimumVersion(version="2018,0,03,314033", engine="Adobe ColdFusion"))');
	}

	function test_adobe_invalid() {
		assert('Len($checkMinimumVersion(version="7", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="8,0,1,0", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="8,0", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="8,0,0,0", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="8,0,0,195765", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="8,0,1,195765", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="9,0,0,251028", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="10,0,0,282462", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="10,0,3,282462", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="10,0,4,277803", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="10,0,23,302580", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="11,0,3,282462", engine="Adobe ColdFusion"))');
		assert('Len($checkMinimumVersion(version="11,0,12,302575", engine="Adobe ColdFusion"))');
	}

}
