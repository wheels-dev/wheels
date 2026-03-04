# [Feature] Multi-Channel Notification System

**Priority:** #3 — Highly desirable competitive differentiator
**Labels:** `enhancement`, `feature-request`, `priority-medium`

## Summary

Add a multi-channel notification system that allows sending notifications through multiple channels (email, database, SMS, Slack, webhooks) from a single notification class — inspired by Laravel's notification system, which is widely regarded as best-in-class.

## Justification

### Laravel's notification system is a massive DX win

Laravel Notifications is consistently cited as one of the framework's best features. A single `Notification` class can simultaneously:

- Send an email
- Store a database record (in-app notification)
- Fire a Slack message
- Send an SMS via Twilio
- Trigger a webhook

No other CFML framework offers anything comparable. This would be a genuine differentiator for Wheels.

### Current state in Wheels

Wheels has `app/mailers/` for email, but no unified notification concept. Developers who need database notifications, Slack alerts, or SMS must build each channel from scratch with no shared infrastructure for:

- Routing notifications to the right channels per user preference
- Queueing notifications via the background job system
- Storing and marking notifications as read/unread
- Formatting the same notification differently per channel

### Natural evolution of existing infrastructure

Wheels already has:
- **Mailer system** (`app/mailers/`) — becomes the email channel
- **Background jobs** (`app/jobs/`) — becomes the queue mechanism
- **Database migrations** — for the notifications table
- **Model callbacks** — for triggering notifications on events

## Specification

### Notification Class

```cfm
// app/notifications/OrderShippedNotification.cfc
component extends="wheels.Notification" {

    function config() {
        // Channels this notification delivers through
        via(["mail", "database", "slack"]);
    }

    // Email channel
    struct function toMail(required any notifiable) {
        return {
            subject: "Your order has shipped!",
            template: "emails/order-shipped",
            data: {
                orderId: this.data.orderId,
                trackingNumber: this.data.trackingNumber,
                userName: notifiable.firstName
            }
        };
    }

    // Database channel (in-app notifications)
    struct function toDatabase(required any notifiable) {
        return {
            title: "Order Shipped",
            body: "Your order ###this.data.orderId# has shipped. Tracking: #this.data.trackingNumber#",
            actionUrl: urlFor(route="order", key=this.data.orderId),
            icon: "truck"
        };
    }

    // Slack channel
    struct function toSlack(required any notifiable) {
        return {
            channel: "##orders",
            text: "Order ###this.data.orderId# shipped to #notifiable.fullName()#",
            color: "good"
        };
    }
}
```

### Sending Notifications

```cfm
// From a controller or model callback
user = model("User").findByKey(params.userId);

// Send to a single user
notify(
    notifiable=user,
    notification="OrderShipped",
    data={orderId: order.id, trackingNumber: "1Z999AA10123456784"}
);

// Send to multiple users
admins = model("User").findAll(where="role = 'admin'");
notifyAll(
    notifiables=admins,
    notification="NewOrderReceived",
    data={orderId: order.id, total: order.total}
);

// Queue for background delivery (uses existing job system)
notifyLater(
    notifiable=user,
    notification="OrderShipped",
    data={orderId: order.id, trackingNumber: tracking}
);
```

### Model Integration

```cfm
// app/models/User.cfc
component extends="Model" {
    function config() {
        // Adds notifications relationship and helper methods
        hasNotifications();

        // Per-user channel preferences (optional)
        property(name="notificationPreferences", sql="''");
    }

    // Define which channels this user receives (override per-user)
    array function notificationChannels() {
        return ["mail", "database"];  // default channels
    }

    // Route for mail channel
    string function routeNotificationForMail() {
        return this.email;
    }

    // Route for Slack channel
    string function routeNotificationForSlack() {
        return this.slackWebhookUrl;
    }
}
```

### Reading Database Notifications

```cfm
// Controller: app/controllers/Notifications.cfc
function index() {
    notifications = currentUser().notifications(page=params.page, perPage=20);
    unreadCount = currentUser().unreadNotificationCount();
}

function markAsRead() {
    notification = currentUser().findNotification(params.key);
    notification.markAsRead();
    redirectTo(back=true);
}

function markAllAsRead() {
    currentUser().markAllNotificationsAsRead();
    redirectTo(back=true);
}
```

### Database Notifications Table (Migration)

```cfm
function up() {
    transaction {
        t = changeTable(table="notifications");
        t.create();
        t.string(columnNames="id", primaryKey=true);  // UUID
        t.string(columnNames="type");                   // notification class name
        t.string(columnNames="notifiableType");         // "User", "Admin", etc.
        t.integer(columnNames="notifiableId");          // foreign key
        t.text(columnNames="data");                     // JSON payload
        t.datetime(columnNames="readAt", null=true);    // null = unread
        t.timestamps();
        // Indexes
        t.index(columns="notifiableType,notifiableId,readAt");
        t.index(columns="type");
    }
}
```

### Channels to Implement

| Channel | Priority | Description |
|---------|----------|-------------|
| **Database** | P0 — Ship with v1 | In-app notifications with read/unread |
| **Mail** | P0 — Ship with v1 | Integration with existing mailer system |
| **Slack** | P1 — Fast follow | Webhook-based Slack messages |
| **SMS** | P1 — Fast follow | Twilio/Vonage integration |
| **Webhook** | P1 — Fast follow | Generic HTTP POST to any URL |
| **Broadcast** | P2 — Future | SSE integration for real-time push |

### Files Generated / Modified

| Component | File | Purpose |
|-----------|------|---------|
| **Base class** | `wheels/Notification.cfc` | Base notification with channel routing |
| **Channel** | `wheels/notifications/DatabaseChannel.cfc` | Database storage channel |
| **Channel** | `wheels/notifications/MailChannel.cfc` | Email channel (wraps mailer) |
| **Channel** | `wheels/notifications/SlackChannel.cfc` | Slack webhook channel |
| **Model mixin** | `wheels/model/Notifiable.cfc` | `hasNotifications()` mixin |
| **Migration template** | Notifications table migration | UUID-based notification storage |
| **Generator** | `wheels generate notification Name` | CLI scaffolding |
| **View partial** | `app/views/shared/_notifications.cfm` | Notification dropdown partial |

## Impact Assessment

- **Developer experience:** Massive productivity gain — one class handles all channels
- **Unique in CFML:** No CFML framework has this; genuine differentiator
- **Builds on existing infrastructure:** Leverages mailers, jobs, and database

## References

- Laravel Notifications: https://laravel.com/docs/notifications
- Rails Action Mailbox + Noticed gem: https://github.com/excid3/noticed
- Django Notifications: https://github.com/django-notifications/django-notifications
