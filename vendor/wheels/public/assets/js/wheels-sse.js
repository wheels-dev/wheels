/**
 * WheelsSSE — Zero-dependency EventSource client for Wheels SSE channels.
 *
 * Features:
 * - Auto-reconnect with exponential backoff
 * - Last-Event-ID tracking for resume on reconnect
 * - Typed event listeners
 * - Channel/event filtering via URL params
 *
 * Usage:
 *   const sse = new WheelsSSE('/notifications/stream', {
 *     channel: 'user.42',
 *     events: ['notification', 'alert'],
 *     onMessage: (data, event) => console.log(event, data)
 *   });
 *
 *   sse.on('notification', (data) => { ... });
 *   sse.close();
 */
class WheelsSSE {
  /**
   * @param {string} url - SSE endpoint URL.
   * @param {Object} [options]
   * @param {string} [options.channel] - Channel to subscribe to (added as URL param).
   * @param {string[]} [options.events] - Event types to filter (added as URL param).
   * @param {string} [options.lastEventId] - Resume from this event ID.
   * @param {number} [options.reconnectInterval=1000] - Initial reconnect delay in ms.
   * @param {number} [options.maxReconnectInterval=30000] - Maximum reconnect delay in ms.
   * @param {number} [options.reconnectDecay=2] - Backoff multiplier.
   * @param {number} [options.maxRetries=0] - Max reconnect attempts (0 = unlimited).
   * @param {Function} [options.onOpen] - Called when connection opens.
   * @param {Function} [options.onError] - Called on connection error.
   * @param {Function} [options.onMessage] - Called for every event: (data, event, id).
   */
  constructor(url, options = {}) {
    this._url = url;
    this._channel = options.channel || '';
    this._events = options.events || [];
    this._lastEventId = options.lastEventId || '';
    this._reconnectInterval = options.reconnectInterval || 1000;
    this._maxReconnectInterval = options.maxReconnectInterval || 30000;
    this._reconnectDecay = options.reconnectDecay || 2;
    this._maxRetries = options.maxRetries || 0;
    this._onOpen = options.onOpen || null;
    this._onError = options.onError || null;
    this._onMessage = options.onMessage || null;
    this._listeners = {};
    this._retryCount = 0;
    this._closed = false;
    this._source = null;

    this._connect();
  }

  /** Get the last event ID received (for resume tracking). */
  get lastEventId() {
    return this._lastEventId;
  }

  /**
   * Register a listener for a specific event type.
   * @param {string} event - Event type name.
   * @param {Function} callback - Handler receiving parsed data.
   */
  on(event, callback) {
    if (!this._listeners[event]) {
      this._listeners[event] = [];
    }
    this._listeners[event].push(callback);

    // Register on active EventSource
    if (this._source) {
      this._source.addEventListener(event, (e) => this._handleEvent(e));
    }
    return this;
  }

  /**
   * Remove a listener for a specific event type.
   * @param {string} event - Event type name.
   * @param {Function} callback - The handler to remove.
   */
  off(event, callback) {
    if (this._listeners[event]) {
      this._listeners[event] = this._listeners[event].filter((cb) => cb !== callback);
    }
    return this;
  }

  /** Close the connection and stop reconnecting. */
  close() {
    this._closed = true;
    if (this._source) {
      this._source.close();
      this._source = null;
    }
  }

  /**
   * Static factory for quick subscriptions.
   * @param {string} url
   * @param {Object} options
   * @returns {WheelsSSE}
   */
  static subscribe(url, options = {}) {
    return new WheelsSSE(url, options);
  }

  /** @private Build the full URL with channel/events/lastEventId params. */
  _buildUrl() {
    const url = new URL(this._url, window.location.origin);
    if (this._channel) {
      url.searchParams.set('channel', this._channel);
    }
    if (this._events.length) {
      url.searchParams.set('events', this._events.join(','));
    }
    if (this._lastEventId) {
      url.searchParams.set('lastEventId', this._lastEventId);
    }
    return url.toString();
  }

  /** @private Establish the EventSource connection. */
  _connect() {
    if (this._closed) return;

    this._source = new EventSource(this._buildUrl());

    this._source.onopen = () => {
      this._retryCount = 0;
      if (this._onOpen) this._onOpen();
    };

    this._source.onerror = () => {
      if (this._closed) return;
      this._source.close();
      if (this._onError) this._onError();
      this._reconnect();
    };

    // Generic message handler
    this._source.onmessage = (e) => this._handleEvent(e);

    // Re-register typed listeners
    for (const event of Object.keys(this._listeners)) {
      this._source.addEventListener(event, (e) => this._handleEvent(e));
    }
  }

  /** @private Handle an incoming SSE event. */
  _handleEvent(e) {
    if (e.lastEventId) {
      this._lastEventId = e.lastEventId;
    }

    let data = e.data;
    try {
      data = JSON.parse(e.data);
    } catch (_) {
      // Use raw string if not valid JSON
    }

    // Global handler
    if (this._onMessage) {
      this._onMessage(data, e.type, e.lastEventId);
    }

    // Typed listeners
    const handlers = this._listeners[e.type];
    if (handlers) {
      for (const handler of handlers) {
        handler(data, e.lastEventId);
      }
    }
  }

  /** @private Reconnect with exponential backoff. */
  _reconnect() {
    if (this._closed) return;
    if (this._maxRetries > 0 && this._retryCount >= this._maxRetries) return;

    const delay = Math.min(
      this._reconnectInterval * Math.pow(this._reconnectDecay, this._retryCount),
      this._maxReconnectInterval
    );
    this._retryCount++;

    setTimeout(() => this._connect(), delay);
  }
}
