export function getProjects(projects, filters = {}) {
    let filteredProjects = [...projects];

    if (filters.search) {
        const term = filters.search.trim().toLowerCase();
        filteredProjects = filteredProjects.filter(p =>
            p.name.toLowerCase().includes(term)
        );
    }

    return filteredProjects.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}