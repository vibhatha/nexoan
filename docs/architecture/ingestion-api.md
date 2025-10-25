# Ingestion API Documentation

The Ingestion API is a RESTful service built with Ballerina that provides comprehensive data ingestion capabilities for the OpenGIN platform. It serves as the primary interface for creating, updating, and deleting entities with full temporal support.

## Overview

The Ingestion API acts as the data ingestion layer that:
- Receives HTTP/REST requests from clients
- Converts JSON payloads to protobuf messages
- Communicates with the Core API via gRPC
- Handles temporal data and complex attribute structures
- Provides entity lifecycle management (Create, Update, Delete)
- Supports metadata, attributes, and relationships

---

## Architecture

### Service Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Ingestion API (Ballerina)                    │
│                         Port: 8080                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                HTTP/REST Endpoints                      │    │
│  │  ┌───────────────┐ ┌─────────────┐ ┌────────────────┐   │    │
│  │  │POST /entities │ │PUT /entities│ │DELETE /entities│   │    │
│  │  │(Create)       │ │(Update)     │ │(Delete)        │   │    │
│  │  └───────────────┘ └─────────────┘ └────────────────┘   │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Data Processing Layer                      │    │
│  │  ┌─────────────┐ ┌───────────────┐ ┌──────────────────┐ │    │
│  │  │JSON↔Protobuf│ │Type Conversion│ │ Value Processing │ │    │
│  │  │Conversion   │ │               │ │                  │ │    │
│  │  └─────────────┘ └───────────────┘ └──────────────────┘ │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                gRPC Client                              │    │
│  │              (Core API Communication)                   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### 1. Create Entity

**Endpoint:** `POST /entities`

**Purpose:** Create a new entity with metadata, attributes, and relationships.

**Request Body:**
```json
{
  "id": "entity123",
  "kind": {
    "major": "Person",
    "minor": "Employee"
  },
  "name": {
    "startTime": "2024-01-01T00:00:00Z",
    "endTime": "",
    "value": "John Doe"
  },
  "created": "2024-01-01T00:00:00Z",
  "metadata": {
    "department": "Engineering",
    "role": "Software Engineer"
  },
  "attributes": {
    "personal_information": {
      "values": [
        {
          "startTime": "2024-01-01T00:00:00Z",
          "endTime": "",
          "value": {
            "columns": ["field", "value", "type"],
            "rows": [
              ["name", "John Doe", "string"],
              ["age", 30, "integer"],
              ["department", "Engineering", "string"]
            ]
          }
        }
      ]
    }
  },
  "relationships": {
    "reports_to": {
      "relatedEntityId": "manager123",
      "startTime": "2024-01-01T00:00:00Z",
      "endTime": "",
      "id": "rel123",
      "name": "reports_to"
    }
  }
}
```

**Response:** Created entity with all data

**Processing Flow:**
1. Validate JSON payload structure
2. Convert JSON to protobuf Entity
3. Send CreateEntity request to Core API
4. Return created entity

### 2. Update Entity

**Endpoint:** `PUT /entities/{id}`

**Purpose:** Update an existing entity with new data.

**Parameters:**
- `id` (path) - Entity ID to update

**Request Body:** Same structure as Create Entity

**Response:** Updated entity

**Processing Flow:**
1. Extract entity ID from URL path
2. Convert JSON payload to protobuf Entity
3. Create UpdateEntityRequest with ID and entity data
4. Send UpdateEntity request to Core API
5. Return updated entity

### 3. Delete Entity

**Endpoint:** `DELETE /entities/{id}`

**Purpose:** Remove an entity and all associated data.

**Parameters:**
- `id` (path) - Entity ID to delete

**Response:** `204 No Content` on success

**Processing Flow:**
1. Extract entity ID from URL path
2. Send DeleteEntity request to Core API
3. Return 204 No Content

### 4. Read Entity (Testing Only)

**Endpoint:** `GET /entities/{id}`

**Purpose:** Retrieve entity data (for testing purposes only).

**Parameters:**
- `id` (path) - Entity ID to retrieve

**Response:** Complete entity data

**Note:** This endpoint is marked for removal as it's only for testing purposes.

---

## Data Processing

### JSON to Protobuf Conversion

The Ingestion API performs sophisticated JSON to protobuf conversion:

**Conversion Process:**
1. **Decimal to Float Conversion:** Handles decimal values for protobuf compatibility
2. **Type Detection:** Analyzes JSON data types
3. **Protobuf Packing:** Uses `pbAny:pack()` for type-safe conversion
4. **Temporal Handling:** Preserves time-based information
5. **Complex Structure Processing:** Handles nested objects and arrays

**Supported Data Types:**
- `int` → Integer protobuf type
- `float` → Float protobuf type
- `string` → String protobuf type
- `boolean` → Boolean protobuf type
- `null` → Null protobuf type
- `array` → List protobuf type
- `object` → Struct protobuf type

---

## Temporal Data Support

### Time-Based Attributes

The API supports comprehensive temporal data handling:

**Temporal Structure:**
```json
{
  "attributes": {
    "personal_information": {
      "values": [
        {
          "startTime": "2024-01-01T00:00:00Z",
          "endTime": "",
          "value": {
            "columns": ["field", "value", "type"],
            "rows": [
              ["name", "John Doe", "string"],
              ["age", 30, "integer"],
              ["department", "Engineering", "string"]
            ]
          }
        }
      ]
    }
  }
}
```

**Temporal Features:**
- **Start Time:** When value becomes effective
- **End Time:** When value expires (empty string for current)
- **Multiple Values:** Support for historical data
- **Time Validation:** Ensures temporal consistency

### Entity Lifecycle

**Entity States:**
- **Created:** Initial entity creation timestamp
- **Active:** Current state with no termination
- **Terminated:** Entity marked as deleted/ended

**Lifecycle Management:**
```json
{
  "created": "2024-01-01T00:00:00Z",
  "terminated": null,  // null for active entities
  "name": {
    "startTime": "2024-01-01T00:00:00Z",
    "endTime": "",  // empty for current name
    "value": "John Doe"
  }
}
```

---

## Complex Data Structures

### Tabular Data Support

**Table Structure:**
```json
{
  "attributes": {
    "expenses": {
      "columns": ["type", "amount", "date", "category"],
      "rows": [
        ["Travel", 500, "2024-01-15", "Business"],
        ["Meals", 120, "2024-01-16", "Entertainment"]
      ]
    }
  }
}
```

**Processing:**
- **Column Definition:** Defines table structure
- **Row Data:** Array of row values
- **Type Inference:** Automatic type detection
- **Storage Strategy:** Determines optimal storage

### Relationship Management

**Relationship Structure:**
```json
{
  "relationships": {
    "reports_to": {
      "relatedEntityId": "manager123",
      "startTime": "2024-01-01T00:00:00Z",
      "endTime": "",
      "id": "rel123",
      "name": "reports_to"
    }
  }
}
```

**Relationship Features:**
- **Bidirectional:** Support for incoming and outgoing relationships
- **Temporal:** Time-based relationship validity
- **Typed:** Named relationship types
- **Identified:** Unique relationship IDs

---

## Error Handling

### Validation Errors

**Common Validation Issues:**
1. **Missing Required Fields**
   - Entity ID validation
   - Kind major/minor validation
   - Required relationship fields

2. **Type Mismatches**
   - Invalid data types
   - Malformed JSON structures
   - Type conversion failures

3. **Temporal Inconsistencies**
   - Invalid time formats
   - End time before start time
   - Missing temporal data

### Processing Errors

**Conversion Errors:**
- **Protobuf Packing Failures**
- **Type Conversion Errors**
- **Decimal to Float Issues**

**Communication Errors:**
- **gRPC Connection Failures**
- **Core API Timeouts**
- **Service Unavailable**

### Error Responses

**400 Bad Request:**
```json
{
  "error": "Invalid request format",
  "details": "Missing required field: id"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Processing failed",
  "details": "gRPC CreateEntity failed: connection timeout"
}
```

---

## Configuration

### Environment Variables

```bash
# Core API Connection
CORE_SERVICE_URL=http://localhost:50051

# Service Configuration
INGESTION_SERVICE_HOST=0.0.0.0
INGESTION_SERVICE_PORT=8080

```

---

## Performance Considerations

### Optimization Strategies

1. **Data Processing**
   - Efficient JSON parsing
   - Optimized protobuf conversion
   - Minimal memory allocation

2. **Connection Management**
   - HTTP/2 support for better multiplexing
   - gRPC connection pooling
   - Configurable timeouts

3. **Batch Processing**
   - Support for bulk operations
   - Efficient data serialization
   - Parallel processing capabilities

### Monitoring

- **Request Metrics:** Response times, throughput
- **Error Rates:** 4xx/5xx error tracking
- **Processing Times:** JSON conversion performance
- **gRPC Metrics:** Core API communication stats

---

## Data Flow Examples

### Create Entity Flow

```
1. Receive POST /entities request
2. Validate JSON payload structure
3. Convert JSON to protobuf Entity
4. Send CreateEntity to Core API
5. Core API processes:
   - Save metadata → MongoDB
   - Create entity → Neo4j
   - Process attributes → PostgreSQL
   - Create relationships → Neo4j
6. Return created entity
```

### Update Entity Flow

```
1. Receive PUT /entities/{id} request
2. Extract entity ID from URL
3. Convert JSON to protobuf Entity
4. Create UpdateEntityRequest
5. Send UpdateEntity to Core API
6. Core API updates all databases
7. Return updated entity
```

### Delete Entity Flow (Not Supported)

> **⚠️ Important Note**
>      
>       Only support deleting metadata not other components. 
>       Deletion of a non-leaf entity needs to be handled with a policy
>       which is yet to be introduced. 

```
1. Receive DELETE /entities/{id} request
2. Extract entity ID from URL
3. Send DeleteEntity to Core API
4. Core API removes from all databases
5. Return 204 No Content
```

---

## API Contracts

### Request/Response Formats

**Create Entity Request:**
```json
{
  "id": "string",
  "kind": {
    "major": "string",
    "minor": "string"
  },
  "name": {
    "startTime": "string",
    "endTime": "string",
    "value": "string"
  },
  "metadata": "object",
  "attributes": "object",
  "relationships": "object"
}
```

**Response Format:**
```json
{
  "id": "string",
  "kind": {
    "major": "string",
    "minor": "string"
  },
  "created": "string",
  "terminated": "string",
  "name": {
    "startTime": "string",
    "endTime": "string",
    "value": "string"
  },
  "metadata": [],
  "attributes": [],
  "relationships": []
}
```

---

## Related Documentation

- [Core API](./core-api.md) - Backend service documentation
- [Read API](./read-api.md) - Data retrieval service
- [Architecture Overview](./overview.md) - System architecture
- [API Layer Details](./api-layer-details.md) - Complete API documentation
- [How It Works](../how_it_works.md) - End-to-end data flow

---

**Last Updated:** October 2024  
**Version:** 1.0.0 - alpha  
**Maintained By:** OpenGIN Development Team