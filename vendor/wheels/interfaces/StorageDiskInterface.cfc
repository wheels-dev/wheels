/**
 * Contract every storage disk driver must satisfy.
 *
 * A "disk" is a named, configured storage backend (local filesystem, S3, …).
 * Drivers expose one small, uniform surface so application code can swap
 * backends with a config change and no call-site edits — mirroring Laravel's
 * Filesystem and Rails' ActiveStorage::Service abstractions.
 *
 * Implementations live under `wheels.storage.drivers.*`. Resolve a configured
 * disk through `wheels.storage.StorageManager`.
 *
 * [section: Storage]
 * [category: Interface]
 */
interface {

	/**
	 * Store content at the given key, creating intermediate paths as needed.
	 *
	 * @key The opaque storage key (path-like, forward-slash separated).
	 * @content Binary or string content to write.
	 * @contentType MIME type hint (used by cloud backends; ignored by local).
	 * @visibility "public" or "private"; backends that support ACLs honour it.
	 * @return The stored key.
	 */
	public any function put(required string key, required any content, string contentType, string visibility);

	/**
	 * Read the content stored at the given key as binary.
	 *
	 * @key The storage key.
	 * @return Binary content. Throws Wheels.Storage.NotFound when absent.
	 */
	public any function get(required string key);

	/**
	 * Whether an object exists at the given key.
	 *
	 * @key The storage key.
	 */
	public boolean function exists(required string key);

	/**
	 * Delete the object at the given key.
	 *
	 * @key The storage key.
	 * @return true when an object was deleted, false when nothing was there.
	 */
	public boolean function delete(required string key);

	/**
	 * A non-expiring URL for the object (public objects / served route).
	 *
	 * @key The storage key.
	 */
	public string function url(required string key);

	/**
	 * A signed, time-limited URL granting temporary access to a private object.
	 *
	 * @key The storage key.
	 * @expiresIn Seconds until the URL expires (default 300).
	 * @contentDisposition Optional Content-Disposition the download should carry.
	 */
	public string function signedUrl(required string key, numeric expiresIn, string contentDisposition);

}
