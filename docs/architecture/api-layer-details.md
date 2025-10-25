# API Layer - Detailed Architecture

This document provides comprehensive details about the Ingestion API and Read API layers of the OpenGIN system.

---

## Overview

The API Layer consists of two Ballerina-based REST services that provide external access to the OpenGIN system:
- **Ingestion API**: Handles entity mutations (CREATE, UPDATE, DELETE)
- **Read API**: Handles entity queries and retrieval

Both APIs act as translation layers between external HTTP/JSON clients and the internal gRPC/Protobuf CRUD service.

---

## Ingestion API

### Overview

The Ingestion API is a Ballerina REST service that handles entity mutations (CREATE, UPDATE, DELETE) using HTTP/REST + JSON protocol with an OpenAPI contract for client integration.

### Service Implementation

The service exposes REST endpoints following OpenAPI specification with four main operations: POST /entities for creating entities, GET /entities/{id} for reading entities, PUT /entities/{id} for updating entities, and DELETE /entities/{id} for deleting entities. All endpoints accept JSON payloads and return JSON responses or errors.

### Request/Response Flow

#### CREATE Entity

**Request**:
```bash
POST /entities
Content-Type: application/json

{
  "id": "entity123",
  "kind": {
    "major": "Person",
    "minor": "Employee"
  },
  "created": "2024-01-01T00:00:00Z",
  "name": {
    "startTime": "2024-01-01T00:00:00Z",
    "endTime": "",
    "value": "John Doe"
  },
  "metadata": [
    {"key": "department", "value": "Engineering"},
    {"key": "role", "value": "Engineer"}
  ],
  "attributes": [
    {
      "key": "salary",
      "value": {
        "values": [
          {
            "startTime": "2024-01-01T00:00:00Z",
            "endTime": "",
            "value": 100000
          }
        ]
      }
    }
  ],
  "relationships": [
    {
      "key": "reports_to",
      "value": {
        "id": "rel123",
        "relatedEntityId": "manager456",
        "name": "reports_to",
        "startTime": "2024-01-01T00:00:00Z",
        "endTime": "",
        "direction": "outgoing"
      }
    }
  ]
}
```

**Response**:
```json
{
  "id": "entity123",
  "kind": {
    "major": "Person",
    "minor": "Employee"
  },
  "created": "2024-01-01T00:00:00Z",
  "name": {
    "startTime": "2024-01-01T00:00:00Z",
    "value": "John Doe"
  }
}
```

#### READ Entity

**Request**:
```bash
GET /entities/entity123
```

**Response**:
```json
{
  "id": "entity123",
  "kind": {
    "major": "Person",
    "minor": "Employee"
  },
  "created": "2024-01-01T00:00:00Z",
  "name": {
    "startTime": "2024-01-01T00:00:00Z",
    "value": "John Doe"
  },
  "metadata": [
    {"key": "department", "value": "Engineering"}
  ],
  "attributes": [],
  "relationships": []
}
```

#### UPDATE Entity

**Request**:
```bash
PUT /entities/entity123
Content-Type: application/json

{
  "id": "entity123",
  "kind": {
    "major": "Person",
    "minor": "Employee"
  },
  "metadata": [
    {"key": "department", "value": "Sales"}
  ]
}
```

**Response**:
```json
{
  "id": "entity123",
  "kind": {
    "major": "Person",
    "minor": "Employee"
  },
  "metadata": [
    {"key": "department", "value": "Sales"}
  ]
}
```

#### DELETE Entity

**Request**:
```bash
DELETE /entities/entity123
```

**Response**:
```
204 No Content
```

### JSON to Protobuf Conversion

The Ingestion API performs complex conversion between JSON and Protobuf formats:

**Key Conversions**:

The service performs three main data conversions from JSON to Protobuf format. Metadata conversion transforms JSON key-value pairs into Protobuf Any maps for flexible storage. Attributes conversion handles temporal data by converting JSON arrays to TimeBasedValueList structures with start/end times and packed values. Relationships conversion maps JSON relationship objects to Protobuf Relationship structures with entity IDs, names, temporal bounds, and direction information.

### gRPC Client Configuration

The gRPC client is configured with a 30-second timeout and retry logic that attempts up to 3 retries with exponential backoff (1 second initial interval, 2x backoff multiplier) for reliable communication with the Core API service.

**Environment Variables**:
```bash
CORE_SERVICE_URL=http://localhost:50051
INGESTION_SERVICE_HOST=0.0.0.0
INGESTION_SERVICE_PORT=8080
```

### Error Handling

The service handles four main error categories: validation errors for invalid JSON structure, conversion errors during JSON to Protobuf transformation, gRPC errors from CRUD service communication failures, and business logic errors such as entity conflicts or missing entities.

**Error Response Format**:
```json
{
  "error": {
    "code": "ENTITY_NOT_FOUND",
    "message": "Entity with ID 'entity123' not found",
    "details": {
      "entityId": "entity123"
    }
  }
}
```

---

## Read API

### Overview

The Read API is a Ballerina REST service that handles entity queries and retrieval using HTTP/REST + JSON protocol with an OpenAPI contract for client integration.

### Service Implementation

The Read API provides specialized endpoints for retrieving entity data:

- **GET /v1/entities/{id}/metadata** - Retrieve entity metadata
- **GET /v1/entities/{id}/relationships** - Get entity relationships with optional filtering (name, direction, relatedEntityId, activeAt)
- **GET /v1/entities/{id}/attributes** - Get entity attributes with optional filtering (name, activeAt)
- **GET /v1/entities/{id}** - Get complete entity with selective field output

All endpoints return JSON responses or errors.

### Query Operations

#### Get Metadata

**Request**:
```bash
GET /v1/entities/entity123/metadata
```

**Response**:
```json
{
  "metadata": {
    "department": "Engineering",
    "role": "Engineer",
    "employeeId": "EMP-123"
  }
}
```

**Use Case**: Retrieve flexible key-value metadata for an entity

#### Get Relationships

**Request**:
```bash
GET /v1/entities/entity123/relationships?name=reports_to&direction=outgoing
```

**Query Parameters**:
- `name`: Filter by relationship type
- `direction`: `outgoing` or `incoming`
- `relatedEntityId`: Filter by related entity
- `activeAt`: Temporal query (ISO 8601 timestamp)

**Response**:
```json
{
  "relationships": [
    {
      "id": "rel123",
      "name": "reports_to",
      "relatedEntityId": "manager456",
      "startTime": "2024-01-01T00:00:00Z",
      "endTime": null,
      "direction": "outgoing"
    }
  ]
}
```

**Use Case**: Graph traversal, finding related entities

#### Get Attributes

**Request**:
```bash
GET /v1/entities/entity123/attributes?name=salary&activeAt=2024-06-01T00:00:00Z
```

**Query Parameters**:
- `name`: Filter by attribute name
- `activeAt`: Get attribute value at specific time

**Response**:
```json
{
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
  }
}
```

**Use Case**: Time-series data, historical attribute values

#### Get Entity with Selective Fields

**Request**:
```bash
GET /v1/entities/entity123?output=metadata,relationships
```

**Query Parameters**:
- `output`: Comma-separated list of fields to retrieve
  - Options: `metadata`, `relationships`, `attributes`
  - If omitted: returns only basic entity info

**Response**:
```json
{
  "id": "entity123",
  "kind": {
    "major": "Person",
    "minor": "Employee"
  },
  "name": {
    "value": "John Doe",
    "startTime": "2024-01-01T00:00:00Z"
  },
  "created": "2024-01-01T00:00:00Z",
  "metadata": {
    "department": "Engineering"
  },
  "relationships": [
    {
      "name": "reports_to",
      "relatedEntityId": "manager456"
    }
  ]
}
```

**Use Case**: Optimized queries, reduce payload size

### Temporal Queries

The Read API supports temporal queries using the `activeAt` parameter:

**Example**: Get employee's salary on specific date
```bash
GET /v1/entities/entity123/attributes?name=salary&activeAt=2024-03-15T00:00:00Z
```

**Backend Filter**:
```sql
WHERE start_time <= '2024-03-15T00:00:00Z'
  AND (end_time IS NULL OR end_time >= '2024-03-15T00:00:00Z')
```

This returns only the attribute value that was active on March 15, 2024.

### gRPC Client Configuration

**Connection Setup**:
```ballerina
final grpc:Client crudClient = check new (
    string `${CORE_SERVICE_URL}`,
    {
        timeout: 30,
        retryConfiguration: {
            maxCount: 3,
            interval: 1,
            backoff: 2
        }
    }
);
```

**Environment Variables**:
```bash
CORE_SERVICE_URL=http://localhost:50051
READ_SERVICE_HOST=0.0.0.0
READ_SERVICE_PORT=8081
```

### Performance Optimization

**Selective Field Retrieval**:
- Only fetch requested fields from CRUD service
- Reduces database load
- Reduces network bandwidth
- Faster response times

**Example**:
```
Query: GET /v1/entities/entity123?output=metadata

Instead of:
  ├─ MongoDB (metadata)         ✓ Retrieved
  ├─ Neo4j (entity info)        ✓ Retrieved
  ├─ Neo4j (relationships)      ✗ Skipped
  └─ PostgreSQL (attributes)    ✗ Skipped
```

---

## Monitoring and Observability

### Logging

Both APIs log:
- Incoming requests (method, path, params)
- gRPC calls to CRUD service
- Response status codes
- Errors with stack traces

### Metrics (Planned)

- Request count by endpoint
- Response time percentiles
- Error rate
- Active connections
- gRPC call latency

### Tracing (Planned)

- Distributed tracing with OpenTelemetry
- Trace request flow: Client → API → Core → Database
- Identify bottlenecks

---

## Best Practices

### 1. Use Selective Retrieval

❌ **Don't**:
```bash
GET /entities/entity123
# Returns everything (slow, large payload)
```

✅ **Do**:
```bash
GET /v1/entities/entity123?output=metadata
# Returns only what you need (fast, small payload)
```

---

## Related Documentation

- [Main Architecture Overview](./overview.md)
- [Ingestion API](./ingestion-api.md)
- [Read API](./read-api.md)

---

**Document Version**: 1.0  
**Last Updated**: October 2024  
**Component**: API Layer

