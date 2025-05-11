require('dotenv').config();
require('express-async-errors');

const express = require("express");
const app = express();
const cors = require('cors');
const connectDB = require("./db/connect");
const peopleRouter = require("./routes/people");

app.use(express.json());
app.use(cors());

app.use("/api/v1", peopleRouter);



const port = process.env.PORT || 3000;

const start = async () => {

    try {
        await connectDB(process.env.MONGODB_URI);
        app.listen(port, () => {
            console.log("Server listening on port " + port);
        })
    } catch (error) {
        console.log(error);
    }

}

start();