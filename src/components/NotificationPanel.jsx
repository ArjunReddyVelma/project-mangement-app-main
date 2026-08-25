import React from 'react';
import { Bell } from 'lucide-react';

function NotificationPanel({ notifications }) {
    return (
        <div className="notification-panel">
            <div className="panel-header">
                <h3>Notifications</h3>
                <Bell size={18} />
            </div>
            
            {notifications.length === 0 ? (
                <p className="empty-message">No new notifications.</p>
            ) : (
                <div className="notification-list">
                    {notifications.map(notification => (
                        <div 
                            key={notification.id} 
                            className={`notification-item ${notification.read ? 'read' : 'unread'}`}
                        >
                            <div className={`notification-icon type-${notification.type}`} />
                            <div className="notification-content">
                                <p>{notification.message}</p>
                                <span className="notification-time">
                                    {new Date(notification.createdAt).toLocaleDateString()}
                                </span>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

export default NotificationPanel;
