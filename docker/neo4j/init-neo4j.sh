#!/bin/bash

# Wait for Neo4j to be ready
echo "Waiting for Neo4j to be ready..."
until curl -s http://localhost:7474 > /dev/null; do
    sleep 2
done

# Create the default database if it doesn't exist
echo "Creating default database if it doesn't exist..."
cypher-shell -u neo4j -p neo4j123 -d system "CREATE DATABASE neo4j IF NOT EXISTS;"

echo "Neo4j initialization completed."
