# Description

This library is designed to use Keycloak identification in Rails application

## Installation

Add to Gemfile

```bash
gem "keycloak_ruby", git: "https://github.com/sergey-arkhipov/keycloak_ruby.git"

```

Now under active development, so you need create manually:

```ruby
# ApplicationController
  def jwt_service
    @jwt_service ||= KeycloakRuby::TokenService.new(session)
  end

  def authenticate_user!
    redirect_to login_path unless current_user&.active?
  end

  def current_user
    @current_user ||= jwt_service.find_user
  end

# SeesionController
  def login
    render :login, layout: "login"
  end

  def create
    auth_info = request.env["omniauth.auth"]
    jwt_service.store_tokens(auth_info[:credentials])
    user = User.find_by(email: auth_info.dig(:info, :email))
    return destroy unless user&.active?

    redirect_to root_path, notice: I18n.t("user.auth_success")
  end

  def destroy
    id_token = session[:id_token]
    jwt_service.clear_tokens
    logout_url = "#{KeycloakRuby.config.logout_url}?post_logout_redirect_uri=#{CGI.escape(root_url)}&" \
                 "id_token_hint=#{id_token}"

    redirect_to logout_url, allow_other_host: true
  end

```

It is assumed that you have a User model in Rails app

## Architecture Overview

### Component Diagram

```mermaid
flowchart TD
    subgraph Rails_Application["Rails Application"]
        A[Controller] --> B[TokenService]
        B --> C[TokenRefresher]
        C --> D[Keycloak Server]
        D -->|Refresh Token| C
        C -->|New Tokens| B
        B --> E[User Model]
        B --> F[ResponseValidator]
        C --> F
        F --> G[Errors]
        B --> H[JWT Decoder]
        H --> I[JWKS Cache]
    end

    style A fill:#f9f,stroke:#333
    style B fill:#bbf,stroke:#333
    style C fill:#bbf,stroke:#333
    style D fill:#f96,stroke:#333
    style E fill:#9f9,stroke:#333
    style F fill:#bbf,stroke:#333
    style G fill:#f66,stroke:#333
    style H fill:#bbf,stroke:#333
    style I fill:#ccf,stroke:#333

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

```

```
