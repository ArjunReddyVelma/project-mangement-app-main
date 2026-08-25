import React from 'react';

function UserList({ users }) {
    if (users.length === 0) {
        return <p className="empty-message">No users found.</p>;
    }

    return (
        <div className="list-container user-list">
            {users.map(user => (
                <div key={user.id} className="list-item card user-card">
                    <div className="user-info">
                        <strong>{user.name}</strong>
                        <span className="user-role">{user.role}</span>
                    </div>
                    <span className={`badge status-${user.status.toLowerCase()}`}>
                        {user.status}
                    </span>
                </div>
            ))}
        </div>
    );
}

export default UserList;
