/// Multicast notifier for an Event type, like `UIControl`. Weakly holds
/// objects. Not thread-safe.
///
/// Inspired by this blog post by Ole Begemann (@oleb):
///  - http://oleb.net/blog/2014/07/swift-instance-methods-curried-functions/
public struct Notifier<Event: Hashable, UserInfo> {
    
    private typealias Notification = (UserInfo) -> Bool
    
    private var notifications: [Event: [ObjectIdentifier: Notification]]
    
    public init() {
        self.notifications = [:]
    }
    
    private mutating func addAction(for event: Event, key: ObjectIdentifier, body: Notification) {
        if var list = notifications[event] {
            list[key] = body
            notifications[event] = list
        } else {
            notifications[event] = [key: body]
        }
    }
    
    /// Add an observer for the given action.
    ///
    /// - warning: Only one `body` is kept for any given `owner`/`event` pair.
    /// If you add the same pair multiple times, only the newest `body` is used.
    public mutating func addObserver<T: AnyObject>(_ owner: T, for event: Event, body: (T) -> () -> ()) {
        addAction(for: event, key: ObjectIdentifier(owner)) { [weak owner] _ in
            guard let strongOwner = owner else { return false }
            body(strongOwner)()
            return true
        }
    }
    
    /// Add an observer for the given action, recieving side data.
    ///
    /// - warning: Only one `body` is kept for any given `owner`/`event` pair.
    /// If you add the same pair multiple times, only the newest `body` is used.
    public mutating func addObserver<T: AnyObject>(_ owner: T, for event: Event, body: (T) -> (UserInfo) -> ()) {
        addAction(for: event, key: ObjectIdentifier(owner)) { [weak owner] info in
            guard let strongOwner = owner else { return false }
            body(strongOwner)(info)
            return true
        }
    }
    
    public mutating func removeObserver<T: AnyObject>(_ owner: T, for event: Event) {
        let key = ObjectIdentifier(owner)
        let removedValue = notifications[event]?.removeValue(forKey: key)
        assert(removedValue != nil, "Unexpected observation removal - object \(owner) was not registered for \(event).")
    }
    
    public mutating func sendNotifications(for event: Event, info: UserInfo) {
        if var list = notifications[event] {
            for (key, notification) in list {
                if !notification(info) {
                    list.removeValue(forKey: key)
                }
            }
            notifications[event] = list
        }
    }
    
}
