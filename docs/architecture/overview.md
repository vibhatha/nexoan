# OpenGIN Architecture Overview

## System Overview

**OpenGIN** is a data orchestration and networking framework. It is based on a polyglot database and a microservices-based design that handles entities with metadata, attributes, and relationships. The architecture follows a layered approach with REST/gRPC communication protocols.

---

## High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
│                   (Web/Mobile/Desktop Clients)                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP/REST + JSON
                           │
┌──────────────────────────┴─────────────────────────────────────┐
│                        API LAYER                               │
│  ┌─────────────────────┐        ┌──────────────────────┐       │
│  │   Ingestion API     │        │    Read API          │       │
│  │   (Ballerina)       │        │    (Ballerina)       │       │
│  │   Port: 8080        │        │    Port: 8081        │       │
│  │   - CREATE          │        │    - READ/QUERY      │       │
│  │   - UPDATE          │        │    - FILTER          │       │
│  │   - DELETE          │        │    - SEARCH          │       │
│  └─────────┬───────────┘        └──────────┬───────────┘       │
└────────────┼──────────────────────────────-┼───────────────────┘
             │                               │
             │        gRPC + Protobuf        │
             │                               │
┌────────────┴───────────────────────────────┴───────────────────┐
│                    Core LAYER                                  │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Core API (Go)                               │  │
│  │              Port: 50051 (gRPC)                          │  │
│  │                                                          │  │
│  │  Components:                                             │  │
│  │  ┌────────────────┐  ┌─────────────────────────────┐     │  │
│  │  │  gRPC Server   │  │  Engine                     │     │  │
│  │  │  - CreateEntity│  │  - AttributeProcessor       │     │  │
│  │  │  - ReadEntity  │  │  - GraphMetadataManager     │     │  │
│  │  │  - UpdateEntity│  │  - TypeInference            │     │  │
│  │  │  - DeleteEntity│  │  - StorageInference         │     │  │
│  │  └────────────────┘  └─────────────────────────────┘     │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐    │  │
│  │  │         Repository Layer                         │    │  │
│  │  │  ┌────────────┐ ┌────────────┐ ┌─────────────┐   │    │  │
│  │  │  │  MongoDB   │ │   Neo4j    │ │  PostgreSQL │   │    │  │
│  │  │  │  Repo      │ │   Repo     │ │    Repo     │   │    │  │
│  │  │  └────────────┘ └────────────┘ └─────────────┘   │    │  │
│  │  └──────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────┬─────────────────┬─────────────────────┬───────────────┘
         │                 │                     │
         │ Native Protocol │ Bolt Protocol       │ PostgreSQL Protocol
         │                 │                     │
┌────────┴─────────────────┴─────────────────────┴───────────────┐
│                      DATABASE LAYER                            │
│                                                                │
│  ┌───────────────┐   ┌─────────────────┐   ┌────────────────┐  │
│  │   MongoDB     │   │     Neo4j       │   │  PostgreSQL    │  │
│  │  Port: 27017  │   │ Port: 7474/7687 │   │  Port: 5432    │  │
│  │               │   │                 │   │                │  │
│  │  Storage:     │   │  Storage:       │   │  Storage:      │  │
│  │  - Metadata   │   │  - Entities     │   │  - Attributes  │  │
│  │  - Key-Value  │   │  - Relationships│   │  - Schemas     │  │
│  │    Pairs      │   │  - Graph Data   │   │  - Time-Series │  │
│  └───────────────┘   └─────────────────┘   └────────────────┘  │
└────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                   SUPPORTING SERVICES                            │
│  ┌──────────────┐  ┌────────────────┐  ┌──────────────────────┐  │
│  │   Cleanup    │  │  Backup/Restore│  │    Swagger UI        │  │
│  │   Service    │  │    Service     │  │    (API Docs)        │  │
│  └──────────────┘  └────────────────┘  └──────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Architecture Layers

### 1. API Layer (Client-Facing Services)

#### Ingestion API (Ballerina, Port 8080)
- Handles entity mutations (CREATE, UPDATE, DELETE) via REST endpoints
- Converts JSON to Protobuf and communicates with Core API via gRPC
- Provides OpenAPI contract for client integration
- **Documentation**: [Ingestion API Details](ingestion-api.md)

#### Read API (Ballerina, Port 8081)
- Handles entity queries and retrieval with selective field support
- Provides filtering, search capabilities, and formatted JSON responses
- Communicates with Core API via gRPC for data access
- **Documentation**: [Read API Details](read-api.md)

#### Swagger UI
- Provides interactive API documentation for Ingestion and Read APIs
- Serves OpenAPI specifications with testing capabilities

### 2. Service Layer

#### Core API (Go, gRPC, Port 50051)
Central orchestration service that manages data networking and all database interactions.

**Core Components**:

1. **gRPC Server**
   - Orchestrates entity operations across all three databases (MongoDB, Neo4j, PostgreSQL)
   - Handles metadata storage in MongoDB, entity nodes and relationships in Neo4j, and attributes in PostgreSQL
   - Supports selective field retrieval and distributed data assembly
   - Manages temporal data with start/end time support
   - Provides atomic operations with cross-database consistency

2. **Engine Layer**
   - Processes entity attributes and determines optimal storage strategies
   - Automatically infers data types (int, float, string, bool, date, time, datetime)
   - Determines storage types (tabular, graph, list, map, scalar) based on data structure
   - Manages graph metadata and relationship processing
   - Handles temporal data with time-based attribute values

3. **Repository Layer**
   - Manages metadata storage and retrieval in MongoDB with flexible document structures
   - Handles entity nodes and relationships in Neo4j with graph traversal and Cypher queries
   - Processes attribute storage in PostgreSQL with dynamic schema management and time-series support
   - Provides connection management and CRUD operations across all three databases

### 3. Database Layer

#### MongoDB (Port 27017)
- Provides flexible metadata storage with schema-less document structure
- Stores key-value pairs in `metadata` and `metadata_test` collections
- Ideal for dynamic metadata that doesn't require fixed schema

#### Neo4j (Port 7474 HTTP, 7687 Bolt)
- Stores entities as nodes and relationships as directed edges with temporal properties
- Optimized for graph traversal and complex relationship queries
- Handles entity connections with time-based relationship tracking

#### PostgreSQL (Port 5432)
- Manages time-based attribute storage with dynamic schema creation
- Provides ACID compliance and complex querying for time-series data
- Uses dynamic tables for each attribute type with entity-attribute mappings

### 4. Supporting Services

#### Cleanup Service
- Provides database cleanup for testing and maintenance across all three databases
- Triggered via Docker Compose profile for automated environment reset
- Clears PostgreSQL tables, MongoDB collections, and Neo4j nodes/relationships

#### Backup/Restore Service
- Manages data persistence and version control across all databases
- Provides local backup creation and GitHub-based storage with versioning
- Enables automated restore from GitHub releases for environment setup

---

## Data Model

### Entity Structure (Protobuf)

```protobuf
message Entity {
    string id = 1;                              // Unique identifier
    Kind kind = 2;                              // major/minor classification
    string created = 3;                         // Creation timestamp (ISO 8601)
    string terminated = 4;                      // Optional termination timestamp
    TimeBasedValue name = 5;                    // Entity name with temporal tracking
    map<string, google.protobuf.Any> metadata = 6;        // Flexible metadata
    map<string, TimeBasedValueList> attributes = 7;       // Time-based attributes
    map<string, Relationship> relationships = 8;          // Entity relationships
}

message Kind {
    string major = 1;                           // Primary classification
    string minor = 2;                           // Secondary classification
}

message TimeBasedValue {
    string startTime = 1;                       // Value valid from
    string endTime = 2;                         // Value valid until (empty = current)
    google.protobuf.Any value = 3;              // Actual value (any type)
}

message Relationship {
    string id = 1;                              // Relationship identifier
    string relatedEntityId = 2;                 // Target entity
    string name = 3;                            // Relationship type
    string startTime = 4;                       // Relationship valid from
    string endTime = 5;                         // Relationship valid until
    string direction = 6;                       // Relationship direction
}
```

### Storage Distribution Strategy

The entity data is strategically distributed across three databases:

**Example Entity:**
```json
{
  "id": "entity123",
  "kind": {"major": "Person", "minor": "Employee"},
  "name": "John Doe",
  "created": "2024-01-01T00:00:00Z",
  "metadata": {"department": "Engineering", "role": "Engineer"},
  "attributes": {
    "expenses": {
      "startTime": "2024-01-15T00:00:00Z",
      "endTime": "2024-01-17T23:59:59Z",
      "value": {
        "columns": ["type", "amount", "date", "category"],
        "rows": [
          ["Travel", 500, "2024-01-15", "Business"],
          ["Meals", 120, "2024-01-16", "Entertainment"],
          ["Equipment", 300, "2024-01-17", "Office"]
        ]
      }
    }
  },
  "relationships": {"reports_to": "manager123"}
}
```

**Storage Distribution:**

```
┌──────────────────────────────────────────────────────────────┐
│ MongoDB - Metadata Storage                                   │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Collection: metadata                                     │ │
│ │ {                                                        │ │
│ │   "_id": "entity123",                                    │ │
│ │   "metadata": {                                          │ │
│ │     "department": "Engineering",                         │ │
│ │     "role": "Engineer"                                   │ │
│ │   }                                                      │ │
│ │ }                                                        │ │
│ └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Neo4j - Entity & Relationship Storage                        │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Node:                                                    │ │
│ │ (entity123:Entity {                                      │ │
│ │   id: "entity123",                                       │ │
│ │   kind_major: "Person",                                  │ │
│ │   kind_minor: "Employee",                                │ │
│ │   name: "John Doe",                                      │ │
│ │   created: "2024-01-01T00:00:00Z"                        │ │
│ │ })                                                       │ │
│ │                                                          │ │
│ │ Relationship:                                            │ │
│ │ (entity123)-[:REPORTS_TO {                               │ │
│ │   id: "rel123",                                          │ │
│ │   startTime: "2024-01-01T00:00:00Z"                      │ │
│ │ }]->(manager123)                                         │ │
│ └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ PostgreSQL - Attribute Storage                               │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Table: attribute_schemas                                 │ │
│ │   {kind_major: "Person", attr_name: "expenses",          │ │
│ │    data_type: "table", storage_type: "tabular"}          │ │
│ │                                                          │ │
│ │ Table: entity_attributes                                 │ │
│ │   {entity_id: "entity123", attr_name: "expenses"}        │ │
│ │                                                          │ │
│ │ Table: attr_expenses                                     │ │
│ │   {row_id: 1,                                            │ │
│ │    type: "Travel", amount: 500,                          │ │
│ │    date: "2024-01-15", category: "Business"}             │ │
│ │   {row_id: 2,                                            │ │
│ │    type: "Meals", amount: 120,                           │ │
│ │    date: "2024-01-16", category: "Entertainment"}        │ │
│ │   {row_id: 3,                                            │ │
│ │    type: "Equipment", amount: 300,                       │ │
│ │    date: "2024-01-17", category: "Office"}               │ │
│ └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Flow Sequences

### Create Entity Flow

```
┌────────┐         ┌───────────────┐      ┌──────────────┐         ┌──────────┐
│ Client │         │ Ingestion API │      │ Core API     │         │ Databases│
└───┬────┘         └─────┬─────────┘      └──────┬───────┘         └────┬─────┘
    │                    │                       │                      │
    │ POST /entities     │                       │                      │
    │ (JSON payload)     │                       │                      │
    ├───────────────────>│                       │                      │
    │                    │                       │                      │
    │                    │ JSON to Protobuf      │                      │
    │                    │ conversion            │                      │
    │                    │                       │                      │
    │                    │ gRPC: CreateEntity    │                      │
    │                    ├──────────────────────>│                      │
    │                    │                       │                      │
    │                    │                       │ Save metadata        │
    │                    │                       ├─────────────────────>│
    │                    │                       │      (MongoDB)       │
    │                    │                       │                      │
    │                    │                       │ Create entity node   │
    │                    │                       ├─────────────────────>│
    │                    │                       │      (Neo4j)         │
    │                    │                       │                      │
    │                    │                       │ Create relationships │
    │                    │                       ├─────────────────────>│
    │                    │                       │      (Neo4j)         │
    │                    │                       │                      │
    │                    │                       │ Save attributes      │
    │                    │                       ├─────────────────────>│
    │                    │                       │    (PostgreSQL)      │
    │                    │                       │                      │
    │                    │    Entity (Protobuf)  │                      │
    │                    │<──────────────────────┤                      │
    │                    │                       │                      │
    │                    │ Protobuf to JSON      │                      │
    │                    │ conversion            │                      │
    │                    │                       │                      │
    │   201 Created      │                       │                      │
    │   (JSON response)  │                       │                      │
    │<───────────────────┤                       │                      │
    │                    │                       │                      │
```

### Read Entity Flow

```
┌────────┐         ┌───────────┐          ┌──────────────┐         ┌──────────┐
│ Client │         │ Read API  │          │ Core API     │         │ Databases│
└───┬────┘         └─────┬─────┘          └──────┬───────┘         └────┬─────┘
    │                    │                       │                      │
    │ GET /entities/123  │                       │                      │
    │ ?output=metadata,  │                       │                      │
    │  relationships,    │                       │                      │
    |  attributes        |                       |                      |
    ├───────────────────>│                       │                      │
    │                    │                       │                      │
    │                    │ gRPC: ReadEntity      │                      │
    │                    ├──────────────────────>│                      │
    │                    │                       │                      │
    │                    │                       │ Get entity info      │
    │                    │                       ├─────────────────────>│
    │                    │                       │    (Neo4j - always)  │
    │                    │                       │                      │
    │                    │                       │ Get metadata         │
    │                    │                       ├─────────────────────>│
    │                    │                       │  (MongoDB - if req'd)│
    │                    │                       │                      │
    │                    │                       │ Get relationships    │
    │                    │                       ├─────────────────────>│
    │                    │                       │  (Neo4j - if req'd)  │
    │                    │                       │                      │
    │                    │                       │ Get attributes       │
    │                    │                       ├─────────────────────>│
    │                    │                       │ (PostgreSQL -        │
    │                    │                       │             if req'd)│
    │                    │                       │ Assemble entity      │
    │                    │                       │                      │
    │                    │    Entity (Protobuf)  │                      │
    │                    │<──────────────────────┤                      │
    │                    │                       │                      │
    │                    │ Protobuf to JSON      │                      │
    │                    │ conversion            │                      │
    │                    │                       │                      │
    │   200 OK           │                       │                      │
    │   (JSON response)  │                       │                      │
    │<───────────────────┤                       │                      │
    │                    │                       │                      │
```

---

## Type System

### Type Inference System

**Primitive Types:**
- `int` - Whole numbers without decimal points
- `float` - Numbers with decimals or scientific notation
- `string` - Text data
- `bool` - True/false values
- `null` - Absence of value

**Special Types:**
- `date` - Calendar dates (YYYY-MM-DD, DD/MM/YYYY, etc.)
- `time` - Time of day (HH:MM:SS)
- `datetime` - Combined date and time with timezone (RFC3339)

**Type Inference Rules:**
1. Numbers with decimal points → `float`
2. Whole numbers → `int`
3. Text matching date patterns → `date`
4. Text matching time patterns → `time`
5. Text matching datetime patterns → `datetime`
6. Everything else → `string`

### Storage Type Inference

**Storage Types:**
1. **Tabular** - Has `columns` and `rows` fields
   ```json
   {"columns": ["id", "name"], "rows": [[1, "John"], [2, "Jane"]]}
   ```

2. **Graph** - Has `nodes` and `edges` fields
   ```json
   {"nodes": [{"id": "n1"}], "edges": [{"source": "n1", "target": "n2"}]}
   ```

3. **List** - Has `items` array
   ```json
   {"items": [1, 2, 3, 4, 5]}
   ```

4. **Scalar** - Single field with primitive value
   ```json
   {"value": 42}
   ```

5. **Map** - Key-value pairs (default)
   ```json
   {"key1": "value1", "key2": "value2"}
   ```

---

## Communication Protocols

| Layer | Protocol | Format | Port |
|-------|----------|--------|------|
| Client ↔ Ingestion API | HTTP/REST | JSON | 8080 |
| Client ↔ Read API | HTTP/REST | JSON | 8081 |
| APIs ↔ Core API | gRPC | Protobuf | 50051 |
| Core API ↔ MongoDB | MongoDB Wire Protocol | BSON | 27017 |
| Core API ↔ Neo4j | Bolt Protocol | Cypher | 7687 |
| Core API ↔ PostgreSQL | PostgreSQL Wire Protocol | SQL | 5432 |

---

## Network Architecture

**Docker Network**: `ldf-network` (bridge network)
All services run within the same Docker network:
- Container-based service discovery
- Internal communication via container names
- Health checks ensure proper startup sequencing
- Volume persistence for data storage

**Exposed Ports:**
- `8080` - Ingestion API (external access)
- `8081` - Read API (external access)
- `50051` - Core API (can be internal only)
- `27017` - MongoDB (development access)
- `7474/7687` - Neo4j (development access)
- `5432` - PostgreSQL (development access)

---

## Deployment

### Containerization
- **Technology**: Docker + Docker Compose
- **Orchestration File**: `docker-compose.yml`
- **Network**: `ldf-network` (bridge)
- **Volumes**: Persistent storage for all databases

### Health Checks

All services include health check configurations:
- **Database Health**: MongoDB ping, Neo4j HTTP check, PostgreSQL readiness
- **API Health**: Core API and Ingestion/Read APIs via TCP port checks

### Dependency Management

Services start in proper order using Docker Compose `depends_on`:

```
Databases (MongoDB, Neo4j, PostgreSQL)
  ↓
Core API (waits for all databases to be healthy)
  ↓
Ingestion & Read APIs (wait for Core API to be healthy)
```

### Docker Compose Profiles
- **Default**: Runs all core services
- **cleanup**: Database cleanup service (separate profile)

---

## Technology Stack

| Component | Technology | Language | Purpose |
|-----------|-----------|----------|---------|
| Ingestion API | Ballerina | Ballerina | REST API for mutations |
| Read API | Ballerina | Ballerina | REST API for queries |
| Core API | Go + gRPC | Go | Business logic orchestration |
| MongoDB | MongoDB 5.0+ | - | Metadata storage |
| Neo4j | Neo4j 5.x | - | Graph storage |
| PostgreSQL | PostgreSQL 14+ | - | Attribute storage |
| Protobuf | Protocol Buffers | - | Service communication |
| Docker | Docker + Compose | - | Containerization |
| Testing | Go test, Bal test, Python | Multiple | Unit & E2E tests |

---

## Key Features

### 1. Polyglot Database Strategy
- **Optimized Storage**: Each database serves its best use case
- **Data Separation**: Clear boundaries between metadata, entities, and attributes
- **Scalability**: Independent scaling of each database

### 2. Time-Based Data Support
- **Temporal Attributes**: Track attribute values over time
- **Temporal Relationships**: Time-bound entity relationships
- **Historical Queries**: Query data at specific points in time (activeAt parameter)

### 3. Type Inference
- **Automatic Detection**: No manual type specification required
- **Rich Type System**: Supports primitives and special types
- **Storage Optimization**: Determines optimal storage based on data structure

### 4. Schema Evolution (Not Supported Yet)
- **Dynamic Schemas**: PostgreSQL tables created on-demand
- **Attribute Flexibility**: New attributes don't require migrations
- **Kind-Based Organization**: Attributes organized by entity kind

### 5. Graph Relationships
- **Native Graph Storage**: Neo4j for optimal relationship queries
- **Bi-directional Support**: Forward and reverse relationship traversal
- **Relationship Properties**: Rich metadata on relationships

### 6. Backup & Restore
- **Polyglot Database Backup**: Coordinated backups across all databases
- **Version Management**: GitHub-based version control
- **One-Command Restore**: Simple restoration from any version

### 7. API Contract-First
- **OpenAPI Specifications**: APIs defined before implementation
- **Code Generation**: Service scaffolding from contracts
- **Documentation**: Swagger UI for interactive API docs

---

## Design Decisions

### Why A Polyglot Database?

**MongoDB for Metadata:**
- Schema-less structure for flexible metadata
- Fast key-value lookups
- Easy to add new metadata fields

**Neo4j for Entities & Relationships:**
- Native graph traversal
- Efficient relationship queries
- Cypher query language optimized for graphs

**PostgreSQL for Attributes:**
- ACID compliance for critical data
- Complex time-based queries
- Strong typing and constraints
- Efficient indexing for time-series data

### Why gRPC for Internal Communication?

- **Performance**: Binary protocol is faster than JSON
- **Type Safety**: Protobuf provides strong contracts
- **Code Generation**: Client/server stubs auto-generated
- **Streaming**: Support for streaming if needed in future

### Why Ballerina for APIs?

- **Cloud-Native**: Built for cloud and microservices
- **Type Safety**: Strong typing with type inference
- **OpenAPI Integration**: Native OpenAPI support
- **Network-Aware**: Built-in support for REST, gRPC, etc.

---

## Future Enhancements

1. **Connection Pooling** - Optimize database connections
2. **Caching Layer** - Redis for frequently accessed data
3. **Query Optimization** - Indexed queries and batch operations
4. **Error Recovery** - Rollback mechanisms and retry logic
5. **Transaction Support** - Distributed transactions across databases
6. **GraphQL API** - Alternative query interface
7. **Observability** - Distributed tracing and metrics
8. **Advanced Querying** - Join, Aggregation, filters across the polyglot database

---

## Related Documentation

- [How It Works](../how_it_works.md) - Detailed data flow documentation
- [Data Types](../datatype.md) - Type inference system details
- [Storage Types](../storage.md) - Storage type inference details
- [Backup Integration](../deployment/BACKUP_INTEGRATION.md) - Backup and restore guide
- [Core API](../architecture/core-api.md) - Core API documentation
- [Ingestion API](../architecture/ingestion-api.md) - Ingestion API documentation
- [Read API](../architecture/read-api.md) - Read API documentation

---

## Quick Reference

### Service Endpoints

```bash
# Update API
POST   http://localhost:8080/entities          # Create entity
GET    http://localhost:8080/entities/{id}     # Read entity
PUT    http://localhost:8080/entities/{id}     # Update entity
DELETE http://localhost:8080/entities/{id}     # Delete entity

# Query API
GET    http://localhost:8081/v1/entities/{id}/metadata       # Get metadata
GET    http://localhost:8081/v1/entities/{id}/relationships  # Get relationships
GET    http://localhost:8081/v1/entities/{id}/attributes     # Get attributes
```

### Docker Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Clean databases
docker-compose --profile cleanup run --rm cleanup /app/cleanup.sh pre

# Rebuild services
docker-compose build
```

---

**Last Updated:** October 2024  
**Version:** 1.0.0 - alpha  
**Maintained By:** OpenGIN Development Team

