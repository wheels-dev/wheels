# Server-Sent Events (SSE)

Part of the Wheels application guide; start with `../CLAUDE.md`.

```cfm
function notifications() {
    var data = model("Notification").findAll(where="userId=#params.userId#");
    renderSSE(data=SerializeJSON(data), event="notifications", id=params.lastId);
}

function stream() {
    var writer = initSSEStream();
    for (var item in items) sendSSEEvent(writer=writer, data=SerializeJSON(item), event="update");
    closeSSEStream(writer=writer);
}

if (isSSERequest()) { renderSSE(data="..."); }
```

Client: `const es = new EventSource('/controller/notifications');`
