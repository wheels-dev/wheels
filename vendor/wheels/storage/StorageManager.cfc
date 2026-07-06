/**
 * Resolves named storage disks from configuration and caches them.
 *
 * Mirrors Laravel's filesystem manager and AdonisJS Drive: configuration names
 * each disk and assigns it a `driver` ("local" or "s3"); application code asks
 * for a disk by name (or the default) and gets a uniform
 * `wheels.interfaces.StorageDiskInterface` back. Register the manager as a
 * singleton in `config/services.cfm` and expose it via a `storage()` helper.
 *
 * Config shape (set in config/settings.cfm):
 *   set(storage = {
 *       default = "local",
 *       disks = {
 *           local = { driver="local", root="/storage/uploads", urlPrefix="/uploads" },
 *           s3    = { driver="s3", bucket="…", region="…", accessKeyId="…", secretAccessKey="…" }
 *       }
 *   });
 *
 * [section: Storage]
 * [category: Core]
 */
component output="false" {

	variables.drivers = {
		"local" = "wheels.storage.drivers.LocalDisk",
		"s3" = "wheels.storage.drivers.S3Disk"
	};

	/**
	 * @config The storage config struct: { default, disks: { <name>: { driver, … } } }.
	 */
	public StorageManager function init(struct config = {}) {
		variables.config = arguments.config;
		variables.default = StructKeyExists(arguments.config, "default") ? arguments.config.default : "local";
		variables.disks = StructKeyExists(arguments.config, "disks") ? arguments.config.disks : {};
		variables.resolved = {};
		return this;
	}

	/**
	 * Resolve a disk by name (default disk when omitted). Disks are lazily
	 * instantiated and cached for the manager's lifetime.
	 *
	 * @name The configured disk name.
	 */
	public any function disk(string name = "") {
		local.diskName = Len(arguments.name) ? arguments.name : variables.default;

		if (StructKeyExists(variables.resolved, local.diskName)) {
			return variables.resolved[local.diskName];
		}

		if (!StructKeyExists(variables.disks, local.diskName)) {
			throw(
				type = "Wheels.Storage.UnknownDisk",
				message = "No storage disk named [#local.diskName#] is configured.",
				extendedInfo = "Configured disks: #StructKeyList(variables.disks)#."
			);
		}

		local.diskConfig = variables.disks[local.diskName];
		local.driverName = LCase(StructKeyExists(local.diskConfig, "driver") ? local.diskConfig.driver : "");
		if (!StructKeyExists(variables.drivers, local.driverName)) {
			throw(
				type = "Wheels.Storage.UnknownDriver",
				message = "Disk [#local.diskName#] uses unknown driver [#local.driverName#].",
				extendedInfo = "Known drivers: #StructKeyList(variables.drivers)#."
			);
		}

		local.instance = CreateObject("component", variables.drivers[local.driverName]).init(config = local.diskConfig);
		variables.resolved[local.diskName] = local.instance;
		return local.instance;
	}

	/**
	 * The name of the default disk.
	 */
	public string function getDefaultDiskName() {
		return variables.default;
	}

	/**
	 * Names of all configured disks.
	 */
	public array function diskNames() {
		return StructKeyArray(variables.disks);
	}

}
