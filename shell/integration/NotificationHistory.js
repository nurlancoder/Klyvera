.pragma library

var maximumEntries = 30

function record(notifications, tracked, entry, notification) {
    notification.tracked = true
    return {
        "notifications": [entry].concat(notifications).slice(0, maximumEntries),
        "tracked": tracked.concat([notification])
    }
}

function activate(notifications, tracked, notificationId) {
    for (var i = 0; i < tracked.length; i++) {
        if (String(tracked[i].id) === notificationId) {
            tracked[i].invoke()
            break
        }
    }
    return {
        "notifications": notifications.map(function(entry) {
            if (entry.id !== notificationId || entry.read)
                return entry
            return Object.assign({}, entry, { "read": true })
        }),
        "tracked": tracked
    }
}

function dismiss(notifications, tracked, notificationId) {
    var remaining = []
    for (var i = 0; i < tracked.length; i++) {
        if (String(tracked[i].id) === notificationId)
            tracked[i].dismiss()
        else
            remaining.push(tracked[i])
    }
    return {
        "notifications": notifications.filter(function(entry) {
            return entry.id !== notificationId
        }),
        "tracked": remaining
    }
}

function clear(tracked) {
    for (var i = 0; i < tracked.length; i++)
        tracked[i].dismiss()
    return { "notifications": [], "tracked": [] }
}
