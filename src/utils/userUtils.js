export function getUsers(users, filters = {}) {
    let filteredUsers = [...users];

    if (filters.search) {
        const term = filters.search.trim().toLowerCase();
        filteredUsers = filteredUsers.filter(u =>
            u.name.toLowerCase().includes(term)
        );
    }

    return filteredUsers;
}