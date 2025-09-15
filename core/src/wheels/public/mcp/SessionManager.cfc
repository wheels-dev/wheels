component output="false" displayName="MCP Session Manager" {

	property name="sessions" type="struct";

	public any function init() {
		variables.sessions = {};
		variables.sessionTimeout = 3600; // 1 hour timeout
		return this;
	}

	public string function createSession() {
		local.sessionId = "mcp-" & createUUID();
		variables.sessions[local.sessionId] = {
			"id": local.sessionId,
			"created": now(),
			"lastAccessed": now(),
			"initialized": false,
			"capabilities": {},
			"clientInfo": {}
		};
		return local.sessionId;
	}

	public struct function getSession(required string sessionId) {
		if (structKeyExists(variables.sessions, arguments.sessionId)) {
			// Update last accessed time
			variables.sessions[arguments.sessionId].lastAccessed = now();
			return variables.sessions[arguments.sessionId];
		}
		throw(type="SessionNotFound", message="Session not found: #arguments.sessionId#");
	}

	public boolean function sessionExists(required string sessionId) {
		return structKeyExists(variables.sessions, arguments.sessionId);
	}

	public void function updateSession(required string sessionId, required struct data) {
		if (structKeyExists(variables.sessions, arguments.sessionId)) {
			structAppend(variables.sessions[arguments.sessionId], arguments.data, true);
			variables.sessions[arguments.sessionId].lastAccessed = now();
		} else {
			throw(type="SessionNotFound", message="Session not found: #arguments.sessionId#");
		}
	}

	public void function markInitialized(required string sessionId, struct capabilities = {}, struct clientInfo = {}) {
		if (structKeyExists(variables.sessions, arguments.sessionId)) {
			variables.sessions[arguments.sessionId].initialized = true;
			variables.sessions[arguments.sessionId].capabilities = arguments.capabilities;
			variables.sessions[arguments.sessionId].clientInfo = arguments.clientInfo;
			variables.sessions[arguments.sessionId].lastAccessed = now();
		} else {
			throw(type="SessionNotFound", message="Session not found: #arguments.sessionId#");
		}
	}

	public boolean function isInitialized(required string sessionId) {
		if (structKeyExists(variables.sessions, arguments.sessionId)) {
			return variables.sessions[arguments.sessionId].initialized;
		}
		return false;
	}

	public void function removeSession(required string sessionId) {
		if (structKeyExists(variables.sessions, arguments.sessionId)) {
			structDelete(variables.sessions, arguments.sessionId);
		}
	}

	public void function cleanupExpiredSessions() {
		local.currentTime = now();
		local.expiredSessions = [];

		for (local.sessionId in variables.sessions) {
			local.session = variables.sessions[local.sessionId];
			local.timeDiff = dateDiff("s", local.session.lastAccessed, local.currentTime);

			if (local.timeDiff > variables.sessionTimeout) {
				arrayAppend(local.expiredSessions, local.sessionId);
			}
		}

		for (local.expiredSessionId in local.expiredSessions) {
			removeSession(local.expiredSessionId);
		}
	}

	public array function getActiveSessions() {
		cleanupExpiredSessions();
		return structKeyArray(variables.sessions);
	}

	public struct function getSessionStats() {
		cleanupExpiredSessions();
		return {
			"totalSessions": structCount(variables.sessions),
			"initializedSessions": arrayLen(arrayFilter(structValues(variables.sessions), function(session) {
				return session.initialized;
			})),
			"oldestSession": structCount(variables.sessions) > 0 ?
				arrayMin(arrayMap(structValues(variables.sessions), function(session) {
					return session.created;
				})) : null
		};
	}
}