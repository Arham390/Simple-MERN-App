# Simple MERN CRUD Application

# Description
This project is a full-stack web application built using the MERN stack (MongoDB, Express, React, Node.js). It offers complete Create, Read, Update, and Delete (CRUD) functionality, allowing users to add, view, update, and delete entries seamlessly. The application is 
designed to manage user information, providing an interactive and responsive user interface.

# Features
- Create: Add new entries to the database.
- Read: View all the entries in a user-friendly interface.
- Update: Edit existing entries.
- Delete: Remove unwanted entries.

# Technologies Used
Frontend:
- React.js: A JavaScript library for building user interfaces.
- Redux Toolkit: Advanced state management for React applications.
- Toastify: For displaying elegant notifications.

Backend:
- Node.js: JavaScript runtime environment.
- Express: Web application framework for Node.js.
- MongoDB: NoSQL database for storing data.

# Installation
To run the app you need to have Node.js installed and follow these steps:
1. Download the repository locally or clone it:


```
git clone https://github.com/Kuzma02/Simple-MERN-App.git
```

2. Open terminal in the repository folder:

```
cd folder-name
```

3. Install backend dependencies

```
npm install
```

4. Install frontend dependencies:

```
cd client
npm install
```

5. Configure MongoDB:
Ensure MongoDB is installed and running on your machine.
Create a .env file in the root directory and add your MongoDB URI:

```
MONGO_URI=your_mongodb_uri
```

6. Run the application:

```
node app.js
```

7. In a new terminal, start the frontend:

```
cd client
npm run dev
```
