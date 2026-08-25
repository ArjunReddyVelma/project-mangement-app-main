export const projects = [
  {
    id: "P-001",
    name: "Website Redesign",
    status: "Active",
    category: "Marketing",
    owner: "Alice Johnson",
    createdAt: "2023-10-01T10:00:00Z"
  },
  {
    id: "P-002",
    name: "Database Migration",
    status: "Active",
    category: "Engineering",
    owner: "Bob Smith",
    createdAt: "2023-10-05T14:30:00Z"
  },
  {
    id: "P-003",
    name: "Q4 Marketing Campaign",
    status: "Completed",
    category: "Marketing",
    owner: "Alice Johnson",
    createdAt: "2023-09-15T09:15:00Z"
  },
  {
    id: "P-004",
    name: "Mobile App V2",
    status: "Active",
    category: "Engineering",
    owner: "Charlie Davis",
    createdAt: "2023-10-10T11:45:00Z"
  },
  {
    id: "P-005",
    name: "Legacy System Decommission",
    status: "Archived",
    category: "Operations",
    owner: "Eve Wilson",
    createdAt: "2023-01-20T08:00:00Z"
  }
];

export const tasks = [
  {
    id: "T-001",
    title: "Update homepage hero image",
    description: "Replace the current image with the new fall campaign assets.",
    priority: "High",
    status: "Active",
    assignee: "Alice Johnson",
    projectId: "P-001",
    createdAt: "2023-10-02T10:00:00Z"
  },
  {
    id: "T-002",
    title: "Migrate user table",
    description: "Move the user data to the new PostgreSQL database.",
    priority: "High",
    status: "Active",
    assignee: "Bob Smith",
    projectId: "P-002",
    createdAt: "2023-10-06T14:30:00Z"
  },
  {
    id: "T-003",
    title: "Draft press release",
    description: "Write the press release for the new mobile app launch.",
    priority: "Medium",
    status: "Completed",
    assignee: "Alice Johnson",
    projectId: "P-004",
    createdAt: "2023-09-16T09:15:00Z"
  },
  {
    id: "T-004",
    title: "Implement push notifications",
    description: "Add push notifications for chat messages.",
    priority: "High",
    status: "Active",
    assignee: "Charlie Davis",
    projectId: "P-004",
    createdAt: "2023-10-11T11:45:00Z"
  },
  {
    id: "T-005",
    title: "Review server logs",
    description: "Check the logs for any errors before shutting down.",
    priority: "Low",
    status: "Completed",
    assignee: "Eve Wilson",
    projectId: "P-005",
    createdAt: "2023-01-21T08:00:00Z"
  },
  {
    id: "T-006",
    title: "Design new logo",
    description: "Create a modern logo for the website.",
    priority: "Medium",
    status: "Active",
    assignee: "Dana White",
    projectId: "P-001",
    createdAt: "2023-10-03T10:00:00Z"
  }
];

export const users = [
  {
    id: "U-001",
    name: "Alice Johnson",
    email: "alice@example.com",
    role: "Marketing Manager",
    status: "Active"
  },
  {
    id: "U-002",
    name: "Bob Smith",
    email: "bob@example.com",
    role: "Database Administrator",
    status: "Active"
  },
  {
    id: "U-003",
    name: "Charlie Davis",
    email: "charlie@example.com",
    role: "Mobile Developer",
    status: "Active"
  },
  {
    id: "U-004",
    name: "Eve Wilson",
    email: "eve@example.com",
    role: "Operations Manager",
    status: "Inactive"
  },
  {
    id: "U-005",
    name: "Dana White",
    email: "dana@example.com",
    role: "Designer",
    status: "Active"
  }
];

export const notifications = [
  {
    id: "N-001",
    message: "Alice updated the Website Redesign project.",
    type: "update",
    read: false,
    createdAt: "2023-10-12T09:00:00Z"
  },
  {
    id: "N-002",
    message: "Bob completed the Database Migration task.",
    type: "success",
    read: true,
    createdAt: "2023-10-08T15:00:00Z"
  }
];
