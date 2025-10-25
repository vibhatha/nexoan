# Read API Documentation

The Read API is a RESTful service built with Ballerina that provides comprehensive data retrieval capabilities for the OpenGIN platform. It serves as the primary interface for querying entities, attributes, metadata, and relationships.

## Overview

The Read API acts as the query layer that:
- Receives HTTP/REST requests from clients
- Converts JSON requests to protobuf messages
- Communicates with the Core API via gRPC
- Transforms protobuf responses back to JSON
- Provides temporal querying capabilities
- Supports selective field retrieval

---

## Architecture

### Service Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        Read API (Ballerina)                     │
│                         Port: 8081                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                HTTP/REST Endpoints                      │    │
│  │  ┌─────────────┐ ┌─────────────┐ ┌──────────────┐       │    │
│  │  │GET /entities│ │GET /metadata│ │GET /relations│       │    │
│  │  │/attributes  │ │             │ │              │       │    │
│  │  └─────────────┘ └─────────────┘ └──────────────┘       │    │
│  │  ┌─────────────┐ ┌─────────────┐                        │    │
│  │  │GET /entities│ │POST /search │                        │    │
│  │  │/root        │ │             │                        │    │
│  │  └─────────────┘ └─────────────┘                        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Data Processing Layer                      │    │
│  │  ┌─────────────┐ ┌───────────────┐ ┌──────────────────┐ │    │
│  │  │JSON↔Protobuf│ │Type Conversion│ │ Value Extraction │ │    │
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

### 1. Get Entity Attributes

**Endpoint:** `GET /v1/entities/{entityId}/attributes/{attributeName}`

**Purpose:** Retrieve specific attribute values for an entity with temporal filtering.

**Parameters:**
- `entityId` (path) - Unique identifier of the entity
- `attributeName` (path) - Name of the attribute to retrieve
- `startTime` (query, optional) - Start time for temporal filtering
- `endTime` (query, optional) - End time for temporal filtering
- `fields` (query, optional) - Array of field names to include in response

**Response Types:**
- Single value: `{start?, end?, value?}`
- Multiple values: `{start?, end?, value?}[]`
- 404 Not Found: When attribute doesn't exist

**Example Request:**
```http
GET /v1/entities/entity123/attributes/salary?startTime=2024-01-01&endTime=2024-12-31&fields=amount,currency
```

**Example Response:**
```json
{
  "start": "2024-01-01T00:00:00Z",
  "end": "2024-12-31T23:59:59Z",
  "value": "100000"
}
```

### 2. Get Entity Metadata

**Endpoint:** `GET /v1/entities/{entityId}/metadata`

**Purpose:** Retrieve all metadata associated with an entity.

**Parameters:**
- `entityId` (path) - Unique identifier of the entity

**Response:** JSON object containing all metadata key-value pairs

**Example Request:**
```http
GET /v1/entities/entity123/metadata
```

**Example Response:**
```json
{
  "department": "Engineering",
  "role": "Software Engineer",
  "location": "San Francisco"
}
```

### 3. Get Related Entities

**Endpoint:** `POST /v1/entities/{entityId}/relations`

**Purpose:** Retrieve entities related to a specific entity through relationships.

**Request Body:**
```json
{
  "id": "relationship_id",
  "relatedEntityId": "target_entity_id",
  "name": "relationship_name",
  "startTime": "2024-01-01T00:00:00Z",
  "endTime": "2024-12-31T23:59:59Z",
  "direction": "outgoing",
  "activeAt": "2024-06-01T00:00:00Z"
}
```

**Parameters:**
- `entityId` (path) - Source entity identifier
- `activeAt` (body, optional) - Point in time for temporal queries
- `startTime`/`endTime` (body, optional) - Time range for relationships
- `direction` (body, optional) - Relationship direction filter

**Response:** Array of relationship objects with temporal information

**Example Response:**
```json
[
  {
    "id": "rel123",
    "relatedEntityId": "manager456",
    "name": "reports_to",
    "startTime": "2024-01-01T00:00:00Z",
    "endTime": null,
    "direction": "outgoing"
  }
]
```

### 4. Search Entities

**Endpoint:** `POST /v1/entities/search`

**Purpose:** Find entities based on various criteria including ID, kind, name, and temporal filters.

**Request Body:**
```json
{
  "id": "entity123",
  "kind": {
    "major": "Person",
    "minor": "Employee"
  },
  "name": "John Doe",
  "created": "2024-01-01T00:00:00Z",
  "terminated": null
}
```

**Response:** Array of matching entities with basic information

**Example Response:**
```json
[
  {
    "id": "entity123",
    "kind": {
      "major": "Person",
      "minor": "Employee"
    },
    "name": "John Doe",
    "created": "2024-01-01T00:00:00Z",
    "terminated": null
  }
]
```

### 5. Get Root Entities

**Endpoint:** `GET /v1/entities/root`

**Purpose:** Retrieve root entity IDs for a given kind (placeholder for future implementation).

**Parameters:**
- `kind` (query) - Entity kind to filter root entities

---

## Data Processing

### JSON to Protobuf Conversion

The Read API converts JSON requests to protobuf messages for communication with the Core API:

**Conversion Process:**
1. **Type Detection:** Analyzes JSON data types
2. **Protobuf Packing:** Uses `pbAny:pack()` for type-safe conversion
3. **Value Extraction:** Handles primitive types and complex structures
4. **Temporal Handling:** Preserves time-based information

**Supported Data Types:**
- `int` → Integer protobuf type
- `float` → Float protobuf type
- `string` → String protobuf type
- `boolean` → Boolean protobuf type
- `null` → Null protobuf type
- `array` → List protobuf type
- `object` → Struct protobuf type

### Protobuf to JSON Conversion

**Value Extraction Process:**
1. **Type URL Analysis:** Determines protobuf type from `typeUrl`
2. **Value Extraction:** Extracts actual values based on type
3. **String Conversion:** Converts all values to string representation
4. **Temporal Preservation:** Maintains start/end time information

---

## Temporal Querying

### Time-Based Filtering

The Read API supports comprehensive temporal querying:

**Temporal Parameters:**
- `startTime` - Beginning of time range
- `endTime` - End of time range
- `activeAt` - Point-in-time queries

**Temporal Logic:**
- **Time Range:** `startTime` and `endTime` together
- **Point-in-Time:** `activeAt` for specific moment
- **Mutual Exclusion:** Cannot use both time range and `activeAt`

**Example Temporal Queries:**
```http
# Get salary as of specific date
GET /v1/entities/entity123/attributes/salary?activeAt=2024-06-01T00:00:00Z

# Get relationships in time range
POST /v1/entities/entity123/relations
{
  "startTime": "2024-01-01T00:00:00Z",
  "endTime": "2024-12-31T23:59:59Z"
}
```

---

## Field Selection

### Selective Retrieval

The API supports field-level filtering to optimize performance:

**Field Parameters:**
- `fields` - Array of field names to include
- `output` - High-level output selection (metadata, attributes, relationships)

**Field Filtering Benefits:**
- **Performance:** Reduces data transfer
- **Bandwidth:** Minimizes network usage
- **Processing:** Faster response times
- **Security:** Limits data exposure

**Example Field Selection:**
```http
# Get only specific attribute fields
GET /v1/entities/entity123/attributes/expenses?fields=amount,date

# Get only metadata
GET /v1/entities/entity123/metadata
```

---

## Error Handling

### Error Types

1. **Validation Errors**
   - Invalid entity ID format
   - Missing required parameters
   - Conflicting temporal parameters

2. **Not Found Errors**
   - Entity doesn't exist
   - Attribute not found
   - Relationship not found

3. **Processing Errors**
   - Type conversion failures
   - Protobuf packing errors
   - gRPC communication errors

### Error Responses

**400 Bad Request:**
```json
{
  "error": "Invalid request parameters",
  "details": "Cannot use both time range and activeAt parameters together"
}
```

**404 Not Found:**
```json
{
  "error": "Attribute not found",
  "attribute": "salary",
  "entityId": "entity123"
}
```

---

## Configuration

### Environment Variables

```bash
# Core API Connection
CORE_SERVICE_URL=http://localhost:50051

# Service Configuration
READ_SERVICE_HOST=0.0.0.0
READ_SERVICE_PORT=8081

---

## Performance Considerations

### Optimization Strategies

1. **Selective Retrieval**
   - Use field filtering to reduce data transfer
   - Request only needed attributes/metadata
   - Leverage output parameter selection

2. **Temporal Queries**
   - Use `activeAt` for point-in-time queries
   - Limit time ranges to necessary periods
   - Cache frequently accessed temporal data

3. **Connection Management**
   - HTTP/2 support for better multiplexing
   - gRPC connection pooling
   - Configurable timeouts

### Monitoring

- **Request Metrics:** Response times, throughput
- **Error Rates:** 4xx/5xx error tracking
- **Temporal Queries:** Time-based query performance
- **Field Selection:** Impact of selective retrieval

---

## Development

### Local Development

```bash
# Start Core API first
cd opengin/core-api
go run cmd/server/service.go

# Start Read API
cd opengin/read-api
bal run
```

### Testing

```bash
# Run unit tests
bal test

# Test specific endpoints
curl -X GET "http://localhost:8081/v1/entities/entity123/metadata"
```

### Building

```bash
# Build JAR file
bal build

# Run
bal run
```

---

## API Contracts

### OpenAPI Specification

The Read API follows OpenAPI 3.0 specification with:
- Complete endpoint documentation
- Request/response schemas
- Error response definitions
- Parameter validation rules

### Response Formats

**Standard Response:**
```json
{
  "data": "...",
  "metadata": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0.0"
  }
}
```

**Error Response:**
```json
{
  "error": "Error message",
  "details": "Detailed error information",
  "code": "ERROR_CODE"
}
```

---

## Related Documentation

- [Core API](./core-api.md) - Backend service documentation
- [Ingestion API](./ingestion-api.md) - Data ingestion service
- [Architecture Overview](./overview.md) - System architecture
- [API Layer Details](./api-layer-details.md) - Complete API documentation
- [How It Works](../how_it_works.md) - End-to-end data flow

---

**Last Updated:** October 2024  
**Version:** 1.0.0 - alpha  
**Maintained By:** OpenGIN Development Team