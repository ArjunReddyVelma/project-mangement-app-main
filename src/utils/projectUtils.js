export function getProjects(projects, filters = {}) {
    let filteredProjects = [...projects];

    // TODO: Apply filters here based on the filters object
    // Developers will add search, status filters, etc. in this section.

    return filteredProjects.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}
