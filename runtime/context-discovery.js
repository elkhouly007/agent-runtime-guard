#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const { findConfig } = require("./project-policy");

function detectProjectShape(projectRoot = "") {
  const root = String(projectRoot || "").trim();
  if (!root || !fs.existsSync(root)) return { hasConfig: false, markers: [], primaryStack: null };

  const checks = [
    ["package.json", "node"],
    ["tsconfig.json", "typescript"],
    ["pyproject.toml", "python"],
    ["requirements.txt", "python"],
    ["go.mod", "golang"],
    ["Cargo.toml", "rust"],
    ["pom.xml", "java"],
    ["build.gradle", "java"],
    ["build.gradle.kts", "kotlin"],
  ];

  const markers = checks
    .filter(([file]) => fs.existsSync(path.join(root, file)))
    .map(([, marker]) => marker);

  return {
    hasConfig: fs.existsSync(path.join(root, "ecc.config.json")),
    markers: [...new Set(markers)],
    primaryStack: markers[0] || null,
  };
}

function safeGit(args, cwd) {
  try {
    return execFileSync("git", args, {
      cwd,
      stdio: ["ignore", "pipe", "ignore"],
      encoding: "utf8",
      timeout: 1500,
    }).trim();
  } catch {
    return "";
  }
}

function discover(input = {}) {
  const rawTarget = String(input.targetPath || "").trim();
  const rawProjectRoot = String(input.projectRoot || "").trim();
  const targetPath = rawTarget || rawProjectRoot || process.cwd();
  const configSearchRoot = rawProjectRoot || targetPath;
  const configPath = String(input.configPath || "").trim() || findConfig(configSearchRoot);
  const inferredRoot = fs.existsSync(targetPath) && fs.statSync(targetPath).isDirectory() ? targetPath : path.dirname(targetPath);
  const projectRoot = configPath ? path.dirname(configPath) : (rawProjectRoot || inferredRoot);
  const gitRoot = safeGit(["rev-parse", "--show-toplevel"], projectRoot) || projectRoot;
  const branch = String(input.branch || "").trim()
    || String(process.env.ECC_BRANCH_OVERRIDE || "").trim()
    || safeGit(["symbolic-ref", "--short", "HEAD"], gitRoot)
    || safeGit(["rev-parse", "--abbrev-ref", "HEAD"], gitRoot);

  const shape = detectProjectShape(gitRoot);

  return {
    projectRoot: gitRoot,
    branch,
    configPath,
    hasConfig: shape.hasConfig,
    projectMarkers: shape.markers,
    primaryStack: shape.primaryStack,
  };
}

module.exports = { discover, detectProjectShape };
