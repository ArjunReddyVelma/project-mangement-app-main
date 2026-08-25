import React from 'react';

function ProjectList({ projects }) {
    if (projects.length === 0) {
        return <p className="empty-message">No projects found.</p>;
    }

    return (
        <div className="list-container project-list">
            {projects.map(project => (
                <div key={project.id} className="list-item card">
                    <div className="card-header">
                        <h3>{project.name}</h3>
                        <span className={`badge status-${project.status.toLowerCase()}`}>
                            {project.status}
                        </span>
                    </div>
                    <div className="card-body">
                        <p><strong>Category:</strong> {project.category}</p>
                        <p><strong>Owner:</strong> {project.owner}</p>
                    </div>
                </div>
            ))}
        </div>
    );
}

export default ProjectList;
