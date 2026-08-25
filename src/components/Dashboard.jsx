import React, { useState, useEffect } from 'react';
import ProjectList from './ProjectList';
import TaskList from './TaskList';
import UserList from './UserList';
import NotificationPanel from './NotificationPanel';
import { projects as initialProjects, tasks as initialTasks, users as initialUsers, notifications as initialNotifications } from '../data/data';
import { getProjects } from '../utils/projectUtils';
import { getTasks, createTask } from '../utils/taskUtils';
import { calculateStats } from '../utils/dashboardUtils';
import { getUsers } from '../utils/userUtils';
function Dashboard() {
    const [projects, setProjects] = useState(initialProjects);
    const [tasks, setTasks] = useState(initialTasks);
    const [users, setUsers] = useState(initialUsers);
    const [notifications, setNotifications] = useState(initialNotifications);

    // Filters state
    const [projectFilters, setProjectFilters] = useState({});
    const [taskFilters, setTaskFilters] = useState({});
    const [userFilters, setUserFilters] = useState({});
    // Processed Data
    const displayedProjects = getProjects(projects, projectFilters);
    const displayedTasks = getTasks(tasks, taskFilters);
    const stats = calculateStats(displayedProjects, displayedTasks);
    const displayedUsers = getUsers(users, userFilters);
    const handleCreateTask = (taskData) => {
        try {
            const updatedTasks = createTask(taskData, tasks);
            setTasks(updatedTasks);
            
            // Note: Dev C might add notification logic here or in createTask directly
        } catch (error) {
            alert(error.message);
        }
    };

    return (
        <div className="dashboard-container">
            <header className="dashboard-header">
                <h1>Project Management Dashboard</h1>
                
                {/* CONFLICT ZONE 5: DASHBOARD CONTROLS */}
                <div className="dashboard-controls">
                                       <input
                        type="text"
                        placeholder="Search projects..."
                        onChange={e => setProjectFilters(prev => ({ ...prev, search: e.target.value }))}
                    />
                    <div className="stat-card">
                        <span>Total Tasks: {stats.totalTasks}</span>
                    </div>
                </div>
            </header>

            <div className="dashboard-content">
                <main className="main-content">
                    <section className="dashboard-section">
                        <h2>Projects</h2>
                        <ProjectList projects={displayedProjects} />
                    </section>

                    <section className="dashboard-section">
                        <h2>Tasks</h2>
                        <TaskList tasks={displayedTasks} onCreateTask={handleCreateTask} projects={projects} users={users} />
                    </section>

                    <section className="dashboard-section">
                        <h2>Team Members</h2>
                        <UserList users={displayedUsers} />                   
                    </section>
                </main>

                <aside className="sidebar">
                    <NotificationPanel notifications={notifications} />
                </aside>
            </div>
        </div>
    );
}

export default Dashboard;
