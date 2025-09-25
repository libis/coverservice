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
### ./config/db/initial.sql
The initial SQL creates an SQL database.  
Tables created in this database are

- tenants [id, name, code, key]
- institutions [id, name, code, tenant_id, key]

Each institution is linked to a tenant (instutions.tenant_id => tenants.id)

### ./config/config.yml
- **cache**: Directory path for cached files / Cache expiration time
- **endpoint**: Part of the URL to access the service 
- **tenant**: Default tenant if not set in URI
- **region**: Region code
- **db**:  Path to the SQLite database used for storing metadata (e.g., ./db/covers.sqlite)  
- **cover_storage**: Template URI for storing cover images locally. 
- **image_converter_service**: URL template for image converting service.
- **converter_storage**: Path to a shared folder accessible by both the app and the image converter service, used to store original images before conversion.
- **default_cover_dimentions**:  Default dimensions for converted cover images (e.g., 480x480)
- **cover_extention_format**: File format for saved cover images (e.g., webp)
- **cover_providers**: Defines external services used to resolve cover images

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

The originally uploaded image file will be stored in the following directory structure: \<tenant>/\<institution>/org/.  
The image will then be resized and reformatted by an 'external' service. 
#### config.yml settings for image conversion service:
- **image_converter_service**: The URL where the image conversion service can be accessed.
- **default_cover_dimensions**: The maximum width and height for the newly generated image, while maintaining the original aspect ratio.
- **cover_extension_format**: The file extension that defines the format of the newly generated image.
### Delete cover
Delete request with type and code as form-data in the reques body
```bash
DELETE https://example.com/[sub_path]/:tenant/:institution?code=<alma_mmmsid>&type=<type> 
```
***query params***  
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