## Architecture Overview

### Component Diagram

```mermaid
flowchart TD
    subgraph Rails Application
        A[Controller] -->|1. Authenticate| B[TokenService]
        A -->|2. Check Access| B
        B -->|3. Validate/Refresh| C[TokenRefresher]
        C -->|4. API Call| D[Keycloak Server]
        B -->|5. User Lookup| E[User Model]
    end

    subgraph KeycloakRuby Gem
        B --> F[ResponseValidator]
        C --> F
        F --> G[Errors]
        B --> H[JWT Decoder]
        H --> I[JWKS Cache]
    end

    D -->|6. Token Response| C
    C -->|7. Valid Tokens| B
    B -->|8. User/Claims| A

    style A fill:#f9f,stroke:#333
    style B fill:#bbf,stroke:#333
    style C fill:#bbf,stroke:#333
    style D fill:#f96,stroke:#333
    style E fill:#9f9,stroke:#333
```

### Authentication Sequence

```mermaid
sequenceDiagram
    participant C as Controller
    participant TS as TokenService
    participant TR as TokenRefresher
    participant KS as Keycloak Server
    participant RV as ResponseValidator
    participant JD as JWT Decoder

    C->>TS: authenticate(user_credentials)
    TS->>TR: call()
    TR->>KS: POST /token
    KS-->>TR: token_response
    TR->>RV: validate(response)
    RV-->>TR: validation_result
    alt Valid
        TR-->>TS: new_tokens
        TS->>JD: decode(access_token)
        JD->>TS: claims
        TS-->>C: user
    else Invalid
        RV->>TR: raise error
        TR->>TS: propagate error
        TS-->>C: nil
    end
```

### Key Flows

1. **Initial Authentication**:

   - Controller → TokenService → Keycloak Server
   - Stores tokens in session

2. **Token Refresh**:

   - TokenService → TokenRefresher → Keycloak Server
   - Automatic when token expires

3. **Access Validation**:

   - Verifies token signature and claims
   - Checks user existence in local DB

4. **Error Handling**:
   - Clear sessions on invalid tokens
   - Propagates meaningful errors

```

```
