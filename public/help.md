# API Documentation

## Overview
This document provides details on how to interact with the API, including security requirements, URL structure, and available operations for reading, writing, and managing data.

---

## Security

To perform write operations, you must provide either:
- A **valid token** as a query parameter.
- A **valid JSON Web Token (JWT)** in the `Authorization` header.

### Token Authentication
Tokens can be supplied via query parameters:

```bash
POST https://example.com/[sub_path]/:tenant?token=ABCDE12345
```

### JWT Authentication
A valid JWT must be supplied as a Bearer token in the `Authorization` header:

```bash
POST https://example.com/[sub_path]/:tenant
Authorization: Bearer <your-jwt-token>
```
---

## Configuration
apikeys and tenent-institution structure are configured with ./config/db/initial.sql  
Other configuration parameters are set in ./config/config.yml
---

## Cover Service

### URL Structure
```plaintext
https://example.com/[sub_path]/:tenant/:institution
```

#### URL Components:
- **sub_path**: Optional. If configured in the `config.yml` file, it simplifies integration.
- **tenant**: Alma tenant code (e.g., `32KUL`, `41SLSP`).
- **institution**: Alma institution code (e.g., `32KUL_KUL`, `41SLSP_RZS`).


#### Example URLs
1. **With sub_path**  
   `https://example.com/covers/32KUL/32KUL_KUL/`  

### Response Format
The API responds is JSON.

---

## Operations
### Available (GET) 
Check if a id has an uploaded cover available
[!WARNING]  
**Depricated: availability is now handled by resolver search option.**

GET https://example.com/[sub_path]/:tenant/:institution/alma<AlmaID>? 

#### Response Format
```json
{
    "CVR": {
        "MMSID": {
            "<AlmaID>": {
                "available": true,
                "url": "<resolverlink>/<prefix><AlmaID>/thumbnail?set=covers"
            }
        }
    }
}
```

### Create/Update cover
Post request with cover (image-file), type and code as form-data in the reques body
```bash
POST https://example.com/[sub_path]/:tenant/:institution 
```
***form-data***  
cover : [image file]  
type : mmmsid    
code : [alma_mmmsid]  


### Delete cover
Delete request with type and code as form-data in the reques body
```bash
DELETE https://example.com/[sub_path]/:tenant/:institution 
```
***form-data***  
type : mmmsid   
code : [alma_mmmsid]

---

## Cover Service Audit [Do not use (Beta)]
```bash
GET  https://example.com/[sub_path]/:tenant/:institution/audit?token=<token with admin rights>
```
The response in in HTML
It contains all the entries for institution 


### Example 

| Execution Time            | Method | Cover               | User   |
|---------------------------|--------|---------------------|--------|
| 2025-05-14 16:36:15 +0200 | POST   | mmsid:1234569455789 | Marie  |
| 2025-05-16 06:46:17 +0200 | POST   | mmsid:1235757456789 | Walter |
| 2025-05-17 12:06:36 +0200 | DELETE | mmsid:9478393476789 | Jos    |


---