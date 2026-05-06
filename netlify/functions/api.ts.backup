import serverless from "serverless-http";
import express from "express";
import cors from "cors";
import { handleCreateStaffUser } from "../../server/routes/create-staff-user";
import { handleUpdateTeacherClass } from "../../server/routes/update-teacher-class";

// Create Express app directly in the function
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API routes
app.get("/api/ping", (_req, res) => {
  const ping = process.env.PING_MESSAGE ?? "ping";
  res.json({ message: ping });
});

app.post("/api/create-staff-user", handleCreateStaffUser);
app.post("/api/update-teacher-class", handleUpdateTeacherClass);

// Export the serverless handler
export const handler = serverless(app);
