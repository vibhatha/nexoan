# Database Schemas - Detailed Documentation

This document provides comprehensive details about the database schemas used in OpenGIN across MongoDB, Neo4j, and PostgreSQL.

---

## Overview

OpenGIN uses a multi-database architecture where each database is optimized for specific data types:

| Database | Purpose | Data Stored |
|----------|---------|-------------|
| MongoDB | Flexible metadata | Key-value metadata pairs |
| Neo4j | Graph relationships | Entity nodes and relationship edges |
| PostgreSQL | Structured attributes | Time-series attribute data with schemas |

---

## MongoDB Schema

### Database Information

### Collections

#### 1. metadata

**Purpose**: Store entity metadata as flexible key-value pairs

**Schema** (document structure):
```json
{
    "_id": "entity123",                    // Entity ID (Primary Key)
    "metadata": {                          // Metadata object
        "key1": "value1",
        "key2": "value2",
        "key3": 123,
        "key4": true,
        "nested": {
            "subkey": "subvalue"
        }
    },
    "created_at": ISODate("2024-01-01T00:00:00Z"),  // Optional timestamp
    "updated_at": ISODate("2024-01-01T00:00:00Z")   // Optional timestamp
}
```

**Example Document**:
```json
{
    "_id": "employee_001",
    "metadata": {
        "department": "Engineering",
        "role": "Software Engineer",
        "manager": "manager_123",
        "employeeId": "EMP-001",
        "hireDate": "2024-01-01",
        "location": "New York",
        "active": true,
        "skills": ["Go", "Ballerina", "Neo4j"],
        "performance": {
            "rating": 4.5,
            "lastReview": "2024-06-01"
        }
    }
}
```

#### 2. metadata_test

**Purpose**: Test collection for metadata (same schema as `metadata`)

Used during testing to isolate test data from production data.

---

## Neo4j Schema

### Database Information

**Connection**: 
- Bolt: `bolt://neo4j:7687`
- HTTP: `http://neo4j:7474`

### Node Types

#### Entity Node

**Label**: `:Entity`

**Properties**:
```cypher
{
    id: String,              // Unique entity identifier (REQUIRED)
    kind_major: String,      // Major entity classification (REQUIRED)
    kind_minor: String,      // Minor entity classification (optional)
    name: String,            // Entity name (REQUIRED)
    created: String,         // ISO 8601 timestamp (REQUIRED)
    terminated: String       // ISO 8601 timestamp (optional, null = active)
}
```

**Example**:
```cypher
(:Entity {
    id: "employee_001",
    kind_major: "Person",
    kind_minor: "Employee",
    name: "John Doe",
    created: "2024-01-01T00:00:00Z",
    terminated: null
})
```

### Relationship Types

**Dynamic Relationship System**: OpenGIN uses a completely generic relationship model where relationship types are not predefined. Users can create any relationship type they need by simply providing a `name` field in the relationship data.

**How it works**:
1. User provides relationship with `name` field (e.g., "reports_to", "depends_on", "manages")
2. System dynamically creates Neo4j relationship with that type
3. Neo4j relationship type becomes the uppercased version or exact value of the `name` field
4. No schema validation or predefined list of relationship types

#### Relationship Structure

All relationships in Neo4j store the following properties:

**Neo4j Properties** (what's actually stored in the graph):
```cypher
{
    Id: String,              // Relationship identifier (uppercase I)
    Created: DateTime,       // When relationship started (Neo4j datetime type)
    Terminated: DateTime     // When relationship ended (Neo4j datetime type, null = active)
}
```

**Important**: The `name` field from the API/Protobuf becomes the **relationship TYPE** in Neo4j, not a property. It appears in the Cypher syntax as `[:relationshipType]`.

**Note**: The `direction` field is not stored in Neo4j - it's determined by the direction of the arrow in the graph (→ for outgoing, ← for incoming).

**Relationship Types**:
Relationship types are **completely dynamic and user-defined**. The system does not enforce any predefined relationship types. When creating a relationship, the `name` field from the `Relationship` protobuf message becomes the Neo4j relationship type.

Examples from tests and usage:
- `reports_to`: Organizational hierarchy (from E2E tests)
- `depends_on`: Package dependencies (from unit tests)
- Any other name: Users can define any relationship type they need


### Performance Considerations (Future Work)

**Indexes**: Essential for fast lookups
- Always index on `id` property
- Consider indexes on `kind_major` and `kind_minor` for filtering
- Add indexes on frequently queried properties

**Relationship Traversal**:
- Use specific relationship types for better performance
- Limit traversal depth with `*1..3` syntax
- Use `LIMIT` to avoid large result sets

**Temporal Queries**:
- Index on `startTime` and `endTime` for temporal queries
- Use `IS NULL` checks for active relationships

---

## PostgreSQL Schema

### Core Tables

#### 1. attribute_schemas

**Purpose**: Define attribute schemas for different entity kinds

**Columns**:
- `id`: Auto-incrementing primary key
- `kind_major`: Entity major classification (e.g., "Person", "Organization")
- `kind_minor`: Entity minor classification (e.g., "Employee", "Contractor")
- `attr_name`: Attribute name (e.g., "salary", "address")
- `data_type`: Inferred data type (`int`, `float`, `string`, `bool`, `date`, `time`, `datetime`)
- `storage_type`: Storage strategy (`SCALAR`, `LIST`, `MAP`, `TABULAR`, `GRAPH`)
- `is_nullable`: Whether null values are allowed
- `created_at`: Schema creation timestamp
- `updated_at`: Schema last update timestamp

#### 2. entity_attributes

**Purpose**: Link entities to their attributes

**Columns**:
- `id`: Auto-incrementing primary key
- `entity_id`: Reference to entity (matches Entity.id from Neo4j)
- `attr_name`: Attribute name
- `schema_id`: Foreign key to `attribute_schemas`
- `created_at`: Link creation timestamp

### Type Mapping

| Inferred Type | PostgreSQL Type | Example |
|---------------|----------------|---------|
| int | INTEGER | 42, -100, 0 |
| float | DOUBLE PRECISION | 3.14, -0.001, 1.5e10 |
| string | TEXT | "Hello", "12345" |
| bool | BOOLEAN | true, false |
| date | DATE | 2024-01-01 |
| time | TIME | 14:30:00 |
| datetime | TIMESTAMP | 2024-01-01 14:30:00Z |
| array | TEXT[] or INTEGER[] | ["a", "b"] or [1, 2, 3] |
| object/map | JSONB | {"key": "value"} |


### Data Integrity

**No Distributed Transactions**: Currently, OpenGIN doesn't use distributed transactions. Each database operation is independent.

**Eventual Consistency**: System relies on application-level consistency:
- Entity ID is the common key across all databases
- Core API orchestrates all operations
- Errors are logged but don't rollback previous successful operations

---

## Backup and Restore

See [Backup Integration Guide](../deployment/BACKUP_INTEGRATION.md) for complete backup/restore workflow.

---

## Related Documentation

- [Main Architecture Overview](./overview.md)
- [How It Works](../how_it_works.md)
- [Data Types](../datatype.md)
- [Storage Types](../storage.md)

---

**Last Updated:** October 2024  
**Version:** 1.0.0 - alpha  
**Maintained By:** OpenGIN Development Team

