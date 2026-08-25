export function getTasks(tasks, filters = {}) {
    const validStatuses = ["All", "Active", "Completed"];
    let filteredTasks = [...tasks];

    const statusFilter = validStatuses.includes(filters.status)
        ? filters.status
        : "All";

    if (statusFilter !== "All") {
        filteredTasks = filteredTasks.filter(
            task => task.status === statusFilter
        );
    }

    return filteredTasks.sort(
        (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
    );
}

export function createTask(taskData, existingTasks) {
    // Basic validation
    if (!taskData.title) {
        throw new Error("Task title is required");
    }

    // TODO: Add more validation logic here (e.g. project validation, duplicate validation)

    const newTask = {
        id: `T-${Date.now()}`,
        ...taskData,
        status: taskData.status || "Active",
        createdAt: new Date().toISOString()
    };
    
    // TODO: Add side effects here (e.g. trigger notifications)

    return [...existingTasks, newTask];
}
