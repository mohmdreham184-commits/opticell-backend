const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const port = process.env.PORT || 3000;

/* HEALTH CHECK */
app.get("/", (req, res) => {
  res.status(200).send("OK 🚀");
});

/* SIMPLE API ONLY */
app.get("/api/reports", (req, res) => {
  res.json([
    { id: "1", title: "Batch 001", status: "normal" },
    { id: "2", title: "Batch 002", status: "warning" }
  ]);
});

/* START */
app.listen(port, "0.0.0.0", () => {
  console.log("Server running on", port);
});