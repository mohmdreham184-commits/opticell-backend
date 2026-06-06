const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

const port = process.env.PORT || 3000;

// test route
app.get("/", (req, res) => {
  res.send("Backend is working 🚀");
});

// example API (عدليه حسب مشروعك)
app.get("/api/reports", (req, res) => {
  res.json([
    { id: 1, name: "test report" }
  ]);
});

app.listen(port, () => {
  console.log("Server running on port " + port);
});