import "dotenv/config";
import express from "express";
import cors from "cors";
import { handleDemo } from "./routes/demo";
import { handleCreateStaffUser } from "./routes/create-staff-user";
import { handleUpdateTeacherClass } from "./routes/update-teacher-class";

export function createServer() {
  const app = express();

  // Middleware
  app.use(cors());
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // Example API routes
  app.get("/api/ping", (_req, res) => {
    const ping = process.env.PING_MESSAGE ?? "ping";
    res.json({ message: ping });
  });

  app.get("/api/demo", handleDemo);
  
  // Staff management routes
  app.post("/api/create-staff-user", handleCreateStaffUser);
  app.post("/api/update-teacher-class", handleUpdateTeacherClass);

  return app;
}
