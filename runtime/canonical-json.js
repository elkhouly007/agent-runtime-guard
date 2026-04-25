#!/usr/bin/env node
"use strict";

// canonical-json.js — Deterministic JSON stringify for contract hashing.
//
// Recursively sorts object keys so the same logical document always produces
// the same byte string regardless of insertion order. Handles: null, boolean,
// number, string, array, plain object. Rejects: functions, undefined, symbols.
// Zero external dependencies.

function canonicalJson(value) {
  if (value === null) return "null";
  const t = typeof value;
  if (t === "boolean" || t === "number") return JSON.stringify(value);
  if (t === "string") return JSON.stringify(value);
  if (Array.isArray(value)) {
    return "[" + value.map(canonicalJson).join(",") + "]";
  }
  if (t === "object") {
    const keys = Object.keys(value).sort();
    const pairs = keys
      .filter((k) => value[k] !== undefined)
      .map((k) => JSON.stringify(k) + ":" + canonicalJson(value[k]));
    return "{" + pairs.join(",") + "}";
  }
  throw new TypeError(`canonicalJson: unsupported type ${t}`);
}

module.exports = { canonicalJson };
