#!/usr/bin/env node
"use strict";

const { decide } = require("./decision-engine");
const { score } = require("./risk-score");
const { append, journalPaths } = require("./decision-journal");
const policy = require("./policy-store");
const session = require("./session-context");
const projectPolicy = require("./project-policy");
const contextDiscovery = require("./context-discovery");
const actionPlanner = require("./action-planner");
const promotionGuidance = require("./promotion-guidance");
const workflowRouter = require("./workflow-router");
const { classifyIntent } = require("./intent-classifier");
const { resolveRoute, DEFAULT_ROUTING_TABLE, KNOWN_INTENTS } = require("./route-resolver");

module.exports = { decide, score, append, journalPaths, ...policy, ...session, ...projectPolicy, ...contextDiscovery, ...actionPlanner, ...promotionGuidance, ...workflowRouter, classifyIntent, resolveRoute, DEFAULT_ROUTING_TABLE, KNOWN_INTENTS };
